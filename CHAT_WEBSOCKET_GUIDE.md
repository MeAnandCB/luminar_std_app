# Chat & WebSocket Architecture Guide

How real-time chat is wired up in this app: which files do what, how data
flows from app launch to a message appearing on screen, and the non-obvious
design decisions worth knowing before you touch this code.

## File map

```
lib/
├── repository/chat_list_screen/
│   ├── models/
│   │   ├── chat.dart              Chat (a conversation: 1:1 / group / batch)
│   │   ├── message.dart           Message, ReplyToInfo, Reaction
│   │   └── user.dart              User (chat participant)
│   └── service/
│       ├── api_service.dart       ChatApiService — all REST calls
│       ├── websocket_service.dart WebSocketService — the live socket
│       ├── blocked_users_service.dart
│       └── report_service.dart
│
├── presentation/chat_list_screen/
│   ├── chat_list_screen.dart      List of conversations (the "Chat" tab)
│   └── controller/chat_provider.dart   ChatProvider — app-wide chat state
│
└── presentation/chat_screen/
    ├── chat_screen.dart           One open conversation (~5100 lines)
    └── widgets/                   audio player/recorder, forward sheet, etc.
```

Two more files matter even though they're not "chat" files:

- `lib/main.dart` — registers `ChatProvider` as a single app-wide
  `ChangeNotifierProvider`, and holds the global `navigatorKey` used to push
  `ChatScreen` from outside the widget tree (deep links, FCM taps).
- `lib/repository/FCM/fcm_service.dart` — routes `chat_message` push
  notifications into `ChatProvider.navigateToChat(chatUid)`.

## The big picture

There are **two transports**, not one:

- **REST** (`ChatApiService`, via the shared `ApiService`) does almost
  everything: fetch chat list, fetch/paginate messages, **send** a message,
  edit, delete, react, mark-read.
- **WebSocket** (`WebSocketService`) is used almost entirely for
  **receiving** live pushes (new messages from other users, delete/reaction
  events, online-presence updates) and a couple of outbound fire-and-forget
  broadcasts (presence ping, delete/reaction notify).

This is the single most important thing to understand: **sending a message
is a plain HTTP POST**, not a socket frame. `WebSocketService.sendMessage()`
is really just a thin wrapper that calls `ChatApiService.sendMessage()` —
see `websocket_service.dart:167-179`. The socket only carries the message
back down to *other* connected clients once the server broadcasts it.

```
Sender's device                      Server                    Other device
────────────────                     ──────                    ────────────
optimistic UI insert
  │
  ▼
POST /messages/send/  ───────────►  saves message
  │                                  broadcasts over WS  ───────►  WS message
  ▼                                                                  event →
reconcile optimistic                                              inserted
message with real one                                             into list
  │
  ▼
broadcastLocalMessage()
(local-only stream, so THIS
device's own chat list/preview
updates without a socket round trip)
```

## Lifecycle: app launch → message on screen

1. **App launch.** `ChatProvider` is created once (`main.dart`) but does
   **not** connect a socket yet — no chat UI has been touched.
2. **Bottom nav loads.** `BottomNavScreen._loadData()` calls
   `chatProvider.fetchUnreadCountOnly()` — one lightweight REST call
   (`/api/chats/unread-count/`) just to show a badge number. Still no socket.
3. **User taps the Chat tab** (`bottom_nav_screen.dart:296-313`). First time
   only: `_chatProvider.init()` runs. Every time after that, just
   `loadChats(showLoading: false)` (cheap REST refresh, socket already live).
4. **`ChatProvider.init()`** (`chat_provider.dart:164-264`):
   - Resolves the access token, builds `ChatApiService`.
   - Resolves the current `User` from cached login data.
   - `loadChats()` — REST `GET /api/chats/`.
   - Builds the WebSocket URL: `"${GlobalLinks.websocketUrl}chat/?token=$token"`
     (`wss://.../ws/chat/?token=...`).
   - Creates **one** `WebSocketService` and stores it on the provider —
     this instance is shared for the lifetime of the chat session.
   - Wires up 4 stream subscriptions (`_setupListeners`) and calls
     `connect()`.
5. **User opens a conversation** (`ChatListScreen` → `ChatScreen`, or
   `ChatProvider.navigateToChat()` from a push notification). `ChatScreen`
   receives the **already-connected** `WebSocketService` via
   `widget.webSocketService` — it does *not* open a second socket. (It only
   creates its own if none was passed in, e.g. if you construct `ChatScreen`
   directly without going through `ChatProvider`.)
6. **`ChatScreen.initState()`** loads the first page of messages over REST
   (`_loadMessages()`, 50 messages, newest first) and subscribes to the
   *same* socket's `messageStream` / `deleteStream` / `statusStream`,
   filtering by `message.chatId == widget.chat.uid`.
7. **Sending**: optimistic insert → REST POST → reconcile →
   `broadcastLocalMessage()` (local-only echo so `ChatProvider`'s chat-list
   preview updates instantly without waiting on a socket round-trip).
8. **Receiving**: the *other* user's message arrives on the shared socket's
   `messageStream`. Both `ChatProvider` (updates the chat-list preview /
   unread count) and, if that chat is currently open, `ChatScreen` (inserts
   it into the visible list) react to the same event independently.
9. **Leaving the chat tab / logging out**: `ChatProvider.reset()` cancels
   all 4 subscriptions and calls `_webSocketService.disconnect()` — the
   socket is only ever fully torn down here (or on `dispose()`), not when a
   single `ChatScreen` closes.

## `WebSocketService` — the socket itself

`lib/repository/chat_list_screen/service/websocket_service.dart`

### Connecting

`connect()` opens a `WebSocketChannel` and listens with three callbacks:
`onDone` and `onError` both funnel into `_handleConnectionLost()` — the only
difference is `onError` also surfaces the error string first.

### Why there's a heartbeat (and the exact numbers)

A raw `WebSocketChannel` does **not** reliably tell you when a connection
has silently died — NAT/idle-timeout drops or the OS killing the socket
while the app is foregrounded fire neither `onDone` nor `onError`. Without
a heartbeat, `isConnected` (`_channel != null`) would report `true` forever
even on a dead socket.

- Every **25s** (`_heartbeatInterval`), a `{"action": "ping"}` frame is sent
  and, more importantly, `_lastActivityAt` is checked against **75s**
  (`_staleThreshold`, ≈ 3 missed heartbeats). If nothing has come in for
  75s — *any* inbound traffic counts, not just pongs — the connection is
  declared dead and torn down.
- Reconnect uses capped exponential backoff:
  `delay = clamp(5 * 2^attempt, 5, 30)` seconds, i.e. 5s, 10s, 20s, 30s,
  30s, 30s… (`_scheduleReconnect`, `_maxReconnectDelaySeconds = 30`).
  `_reconnectAttempts` resets to 0 on every successful `connect()`.
- `disconnect()` (intentional close, e.g. logout) cancels the reconnect
  timer and does **not** try again. `_handleConnectionLost()` (unintentional
  drop) always schedules a reconnect. This distinction is the whole reason
  there are two teardown paths instead of one.
- `ChatProvider` also nudges reconnection on app-lifecycle events
  (`didChangeAppLifecycleState` → `_ensureConnectivity()` on resume), so
  recovery doesn't purely depend on the backoff timer firing.

### Six broadcast streams

| Stream | Fed by | Consumed by |
|---|---|---|
| `messageStream` | real inbound WS messages | `ChatProvider`, `ChatScreen` |
| `localMessageStream` | `broadcastLocalMessage()` (self-echo, no server round trip) | `ChatProvider` only |
| `statusStream` | presence events | `ChatProvider`, `ChatScreen` (online dot) |
| `errorStream` | parse/connection errors | currently unused by UI, available for logging |
| `deleteStream` | delete confirmations (both self and inbound) | `ChatProvider`, `ChatScreen` |
| `reactionStream` | reaction events | `ChatScreen` |

### Inbound message shapes it has to handle

The server isn't 100% consistent about envelope shape, so `_handleMessage`
checks multiple forms in order:

1. `{"type": "message_deleted", "chat_uid": ..., "message_uid": ...}`
2. `{"type": "message_reaction", ...}`
3. A **bare message object** — detected by `data.containsKey('uid')` with no
   `type` wrapper at all (this is what a fresh message push looks like).
4. `{"type": "message" | "new_message", "data": {...}}` — a wrapped form.
5. `{"type": "presence" | "user_status" | "online_status", "data": ...}` —
   `data` can be a single object *or a list* of them; both are handled.

For (3) and (4), if the payload has `chat_uid` but not `chat`, it's copied
over (`messageData['chat'] = messageData['chat_uid']`) before
`Message.fromJson` — this keeps `Message.chatId` always equal to `Chat.uid`
(a UUID string) regardless of which key the server used, which is what lets
`message.chatId == widget.chat.uid` matching work reliably in `ChatScreen`.

### What actually goes out over the socket

Only three things are ever written to `_channel!.sink`:
- `{"action": "ping"}` (heartbeat)
- `{"action": "presence", "user_id": ..., "online": true/false}`
  (`updateUserStatus`)
- `{"type": "message_deleted", ...}` / `{"type": "message_reaction", ...}`
  — sent *after* the REST call already succeeded, purely to notify other
  connected clients faster than they'd otherwise find out.

Sending a text/file message, editing, marking read, fetching anything —
all REST, never the socket.

## `ChatProvider` — the app-wide state holder

`lib/presentation/chat_list_screen/controller/chat_provider.dart`

- One instance for the whole app (registered in `main.dart`). Owns the one
  `WebSocketService` instance and re-broadcasts what it needs via
  `ChangeNotifier.notifyListeners()`.
- **Unread count has two guards against races**, both worth understanding
  before changing this logic:
  - `_activeChatUid` — set by `ChatScreen` via `setActiveChat()` on
    enter/exit. Incoming messages for the chat currently open never
    increment its badge.
  - `_locallyReadChats` — when the user taps into a chat,
    `zeroChatBadge()` adds it here immediately (before the server-side
    mark-read REST call even lands). Without this, a stale `loadChats()`
    response arriving mid-tap could briefly resurrect the unread badge the
    user just cleared. It's naturally released once the server confirms
    `unreadCount == 0` for that chat in a later `loadChats()`.
- `navigateToChat(chatUid)` is the entry point used by FCM
  (`fcm_service.dart`, `type == 'chat_message'`) and any other deep link. It
  resolves the `Chat` from the already-loaded list (refreshing once if not
  found), then pushes `ChatScreen` via the **global** `navigatorKey` — not
  `Navigator.of(context)` — because this can be triggered from a background
  isolate context where no local `BuildContext` exists.
- `reset()` is called from the logout flow
  (`profile_screen.dart` → `ChatProvider.reset()`) — cancels all stream
  subscriptions and disconnects the socket. This is why logout needed to be
  defensive about this call throwing (see the `try/catch` around it in
  `_handleLogout`) — a torn-down socket in an unexpected state must never
  block the redirect to the login screen.

## `ChatScreen` — one open conversation

`lib/presentation/chat_screen/chat_screen.dart` (large — this section only
covers the core message flow, not attachments/voice/reactions UI).

- **Pagination**: 50 messages per page (`_pageSize`), reverse-chronological
  list (`reverse` ListView, newest at index 0). A scroll listener fires
  `_loadMoreMessages()` when within 200px of the (visual) bottom of the
  loaded list, i.e. the user scrolling toward older messages.
- **Optimistic send** (`_sendMessage`, line ~2244): builds a local `Message`
  with `uid: DateTime.now().millisecondsSinceEpoch.toString()`, inserts it
  immediately, clears the input, then awaits the real REST call. On
  success, the optimistic entry is swapped for the server's real message
  (real UUID `uid`, server timestamps). On failure, the optimistic entry is
  removed and an error snackbar shown. `_isOptimistic()` checks whether a
  `uid` parses as an int (temporary) vs. a UUID (confirmed) — used to decide
  what UI affordances (e.g. delete) are safe to show.
- **Mark-as-read**: after the first page of messages loads, every message
  not sent by the current user has its `uid` collected and passed to
  `ChatProvider.markMessagesRead()` — a single batched REST call, not one
  per message.
- **File/image/voice messages**: uploaded to S3 first via
  `FileUploadService` (separate presigned-URL flow, see
  `widgets/preseigner_url.dart`), then `ChatApiService.sendFileMessage()` is
  called with the resulting URL/metadata — same "REST first, socket
  receives" pattern as text.
- **Blocked users**: `_mainMessages` getter filters `_messages` through
  `BlockedUsersService` on every build, rather than removing messages from
  the underlying list — so unblocking doesn't require a re-fetch.

## REST endpoints (all under `AppEndpoints`, prefixed `/api/chats/`)

| Purpose | Method | Path |
|---|---|---|
| List chats | GET | `chats/` |
| Fetch messages (paginated) | GET | `chats/{chatUid}/messages/` |
| Send message | POST | `chats/{chatUid}/messages/send/` |
| Edit message | PATCH | `chats/{chatUid}/messages/{messageUid}/edit/` |
| Delete message | DELETE | `chats/{chatUid}/messages/{messageUid}/delete/` |
| React / unreact | POST / DELETE | `chats/{chatUid}/messages/{messageUid}/reactions/` |
| Mark read (batched) | POST | `chats/{chatUid}/messages/mark-read/` |
| Unread badge count | GET | `chats/unread-count/` |
| Report content | POST | `chats/report/` |

WebSocket: `wss://api.crm.luminartechnohub.com/ws/chat/?token={accessToken}`
(`GlobalLinks.websocketUrl` + `chat/?token=`).

## Models — key fields

- **`Chat`** (`chat.dart`): `uid` (UUID, the id used everywhere),
  `chatType` (`individual | group | batch`), `otherParticipant` (1:1 only),
  `lastMessagePreview` (a loose `Map` — content/sender/type, built
  client-side by `ChatProvider._buildPreview()`), `unreadCount`.
- **`Message`** (`message.dart`): `uid`, `chatId` (always normalized to the
  UUID — see above), `messageType` (`text|image|video|file|audio`),
  `replyToInfo`/`replyTo`, `reactions` (`List<Reaction>?`), `isDeleted` /
  `isEdited` flags rather than removing/mutating content in place.
  `operator ==` and `hashCode` are keyed on `uid` alone — relevant if you
  ever put `Message` in a `Set` or rely on list `contains`.
- **`User`**: chat participant — `id`, `fullName`, `profilePic`, `email`.

## If you're building something similar elsewhere in this app

1. **Don't put send logic on the socket.** This app's pattern — REST for
   every mutating action, socket purely for fan-out to other clients — is
   simpler to reason about and survives socket drops without losing writes.
   Keep following it.
2. **One socket per session, not one per screen.** Let whatever
   provider/controller owns the feature hold the single `WebSocketService`
   and hand it down; only construct a new one as a fallback for
   direct/standalone navigation.
3. **`isConnected` alone is not liveness.** If you add another
   WebSocket-backed feature, budget for a heartbeat + staleness check like
   this one — `onDone`/`onError` are not guaranteed to fire on a real-world
   connection drop.
4. **Normalize server key inconsistencies once, at the parsing boundary**
   (`chat_uid` → `chat`), not scattered through UI code — `Message.fromJson`
   and the socket's `_handleMessage` are the only two places that need to
   know about it.
5. **Guard optimistic-update races explicitly** (`_activeChatUid`,
   `_locallyReadChats` here) rather than assuming server responses always
   arrive in the order you expect.
