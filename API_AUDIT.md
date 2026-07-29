# API Call Audit — Reliability & Performance

> **Status: all items below have been fixed.** See [Resolution log](#resolution-log) at the bottom for what changed and where. One correction to the original findings: the `AttendanceService.markAttendance()` entry attributed to `main.dart` in section 6.5 actually lives in `lib/presentation/scan_screen/scan_screen.dart` — `main.dart` only bootstraps providers and has no direct HTTP calls of its own.

Scope: every network call site in the app (`lib/`), audited for timeout handling, error handling, and duplicate/concurrent-call risk. Compiled from a full pass over the central HTTP client, all 26 `repository/*/service` files, and every presentation-layer file making direct `http` calls.

**Headline finding:** the app's central HTTP client, `ApiService` (`lib/core/services/api_services.dart`), applies **no timeout to any request** — `get`, `post`, `put`, `patch`, `delete`, and `multipart` all call `package:http` directly with no `.timeout()`. This one class is used by **24 of the app's ~26 repository service files**, meaning the large majority of the app's network calls — login, profile, enrollment, payments, gallery, attendance, jobs, referrals, NACTET registration — will hang indefinitely if the server accepts a connection but never responds. There is no OS-guaranteed short timeout to fall back on; a stalled request can leave a loading spinner or a disabled button stuck for the rest of the session.

Only **7 call sites in the entire codebase** apply an explicit timeout (see [Good patterns already in place](#good-patterns-already-in-place)). Everything else is unbounded.

---

## Executive summary

| Category | Count |
|---|---|
| Files with network calls audited | ~35 |
| Distinct API-calling methods inventoried | ~90 |
| Methods with a client-side timeout | **7** |
| Methods with no timeout (routed through `ApiService` or direct `http`) | **~83** |
| Confirmed dead/duplicate service code found along the way | 4 (`AttendanceService1`, `video_folder_video_service.dart`, `ProfileEditService.getProfileData`, `ChatApiService.removeReaction`) |
| Concrete double-submit / duplicate-order risks | 4 (Razorpay order creation ×2, referral submit, NACTET registration submit) |
| Correctness bugs found incidentally (not timeout-related) | 3 (see [Incidental bugs](#incidental-correctness-bugs-found-along-the-way)) |

---

## 1. Critical: `ApiService` has no timeout — fix once, fixes everything

`lib/core/services/api_services.dart` — every method follows this shape:

```dart
Future<ApiResponse<dynamic>> post({...}) async {
  final uri = _buildUri(endpoint, queryParams);
  try {
    final response = await http.post(uri, headers: _headers(token), body: jsonEncode(body));
    return _handleResponse(response);
  } catch (e) {
    return ApiResponse.error(e.toString(), null);
  }
}
```

No `.timeout()` on any of `get`/`post`/`put`/`patch`/`delete`, and the `multipart()` method's `request.send()` has none either. Because every method already catches all exceptions and converts them to `ApiResponse.error(...)` (never rethrowing), a fix here is genuinely one change that benefits all 24 dependent services at once — this is the highest-leverage fix in the whole audit.

**Suggested fix** (apply the same shape to all 6 methods):

```dart
final response = await http
    .post(uri, headers: _headers(token), body: jsonEncode(body))
    .timeout(const Duration(seconds: 20));
```

then let the existing `catch (e)` handle `TimeoutException` the same way it already handles everything else — `ApiResponse.error(e.toString(), null)` already works for this with no other code changes needed. A 15–20s budget matches what the app's own well-behaved call sites already use (`laptop_api.dart`, `app_update_service.dart` use 10–15s).

---

## 2. Ranked hanging / stuck-UI risks

Concrete cases where a hung request leaves the user stuck with no way out (spinner never resolves, button never re-enables, no cancel affordance):

1. **Login button** (`loginscreen/service.dart:login()`) — no timeout at any layer; `auth.isLoading` never clears, button stays disabled forever. The app's own `getCleanErrorMessage()` special-cases the string `"timeout"` in error messages, implying a timeout was expected here and never implemented.
2. **Payment flows** — `_openIciciPayment`/`_openIciciEmiPayment` (payment_screen.dart) and the Razorpay "Confirm"/"Pay Now" flows (`entrollment_screen.dart`, `payment_screen.dart`) all show a `showDialog(barrierDismissible: false, ...)` spinner *before* the awaited call. With no timeout, that dialog is genuinely undismissable if the server hangs — no cancel button, no back gesture.
3. **NACTET registration submit** (`nactet_registration_service.dart:submitRegistration`) — a **multipart file upload** with no timeout at all. This is the single largest hang-duration risk in the app: a large file over a slow/dropped connection has nothing to cut it off.
4. **Complete-profile / profile-edit submit** (`complete_profile/service.dart:submitProfile`) — bypasses `ApiService` entirely, using a raw `http.MultipartRequest` with no timeout of its own (a *second*, independently unprotected code path).
5. **Chat file/voice send** (`preseigner_url.dart`) — the presigned-URL request and the follow-up S3 upload both lack timeouts; `_isUploading` never resets on a hang, so attach/camera buttons stay disabled indefinitely and the message bubble is stuck in "uploading" forever.
6. **Chat read-receipts** (`ChatApiService.markMessagesAsRead`) — has a good in-flight guard (`_markingReadInProgress` set), but if the call itself hangs, that chat is locked out of ever marking messages read again until the app restarts (the guard is never cleared).
7. **WebSocket silent death** (`websocket_service.dart`) — see dedicated section below; this is a correctness issue, not just a timeout gap, and is the most serious finding in the chat layer.
8. **Live class / job detail / job list** — `_isLoading` flags in `live_class_controller.dart`, `job_detail_screen.dart`, `jobs_screen.dart` all have no ceiling; a hang leaves the spinner running with no error ever surfaced.
9. **Instagram carousel** (`instagram_view_screen.dart`) — two direct `http.get` calls, neither with a timeout, plus (separately) a long-lived Instagram access token hardcoded in source.

### WebSocket: the chat socket can appear "connected" while dead

This is worth calling out on its own. In `websocket_service.dart`:

- `isConnected` is defined as `_channel != null` — it checks that a channel *object* exists, not that the socket is actually alive.
- There is **no heartbeat/ping-pong** anywhere in the file, and **no periodic reconnect timer** — reconnection only happens reactively, inside `ChatProvider.didChangeAppLifecycleState()`, when the app resumes from background, and only if `isConnected` is false.
- Silent-death detection relies entirely on the transport's own `onDone`/`onError` callbacks. A NAT/idle-timeout drop, or the OS silently killing the socket while the app stays foregrounded, fires neither — `_channel` stays non-null, `isConnected` keeps returning `true`, and the app has no way to know it stopped receiving messages until the user force-closes it.

This means a real-world flaky-network chat session can go quiet with zero visible indication to the user or any code path that would try to recover.

---

## 3. Ranked duplicate / multiple-call risks

1. **Razorpay order creation, ×2** (`razorpay_service.dart:getPaymentDetails` / `getEmiPaymentDetails`) — the "Confirm"/"Pay Now" buttons that trigger these have **no re-entrancy guard** (`_isProcessing`-style flag) checked at the top of the handler. They rely solely on a modal loading dialog to block re-taps, which does not prevent a second tap landing before the dialog's first frame renders. A fast double-tap can fire two order-creation POSTs, i.e. two Razorpay orders, before either resolves. (The success-callback path itself does **not** re-verify payment server-side in these files — it just refreshes local state — so the actual double-charge exposure is entirely at this order-creation step.)
2. **Referral submission** (`referral_screen.dart:_submitForm`) — the submit button shows a spinner in place of its label while `_isSubmitting` is true, but the button itself is never disabled/gated by that flag — it's cosmetic only. Double-tap can fire two referral-lead POSTs.
3. **NACTET registration submit** — the controller sets `isLoading = true` at the top of `submit()`, but `submit()` never checks that flag before proceeding, so protection depends entirely on the UI button independently checking `controller.isLoading` before invoking it.
4. **EMI plan confirm** (`entrollment_screen.dart`) — same pattern as #1 but lower stakes: the confirm button's `onPressed` isn't disabled during the request; only the loading dialog (shown after a tap) discourages a second tap.
5. **Dashboard endpoint hit from 3 independent places** — `DashboardService.getDashboardData()`, `AttendanceService.getDashboard()` (an explicit fallback — the code comment at `attandance_controller.dart:63-66` acknowledges this was already a known duplicate-call concern), and `DashboardController`'s own cache. The cache guard (`if (!forceRefresh && _dashboard != null) return _dashboard;`) mitigates most of this, but **any caller passing `forceRefresh: true` bypasses the guard regardless of whether a fetch is already in flight** — several call sites do exactly this (`icici_payment_webview.dart`, `entrollment_screen.dart` post-payment refreshes).
6. **Profile data fetched independently by 3 separate screens** (`profile_edit_screen`, `complete_your_profile`, `profile_screen`) on every `initState`, instead of sharing one cached fetch through `ProfileController`.
7. **Pincode lookup fires on every keystroke** once length hits exactly 6, with no debounce and no request-sequencing — editing a digit while staying at length 6 fires a new request each time, and an earlier slower response can overwrite a later faster one (classic out-of-order race).
8. **Academic dropdowns fetched sequentially, in two separate places** (`referral_screen.dart`, `complete_profile_controller.dart`) — three GETs (`qualifications`, `specializations`, `courses`) awaited one after another instead of via `Future.wait`, doubling/tripling latency, duplicated across two independent call sites instead of shared.
9. **`getNactetStatus()` called from 4 separate sites** with no dedupe (`bottom_nav_screen.dart` ×1, `home_screen.dart` ×2, `refreshDashboard()`).
10. **Dead/duplicate code found along the way** (not bugs per se, but worth removing since they're maintenance noise): `AttendanceService1` in `attandance_screen/service.dart` is a byte-for-byte duplicate of `AttendanceService` with zero callers; `video_folder_video/video_folder_video_service.dart` is an empty file; `ProfileEditService.getProfileData()` is an unwired stub; `ChatApiService.sendReaction`/`removeReaction` appear to have no live callers (the actual reaction-add path uses `sendMessage` instead).

---

## 4. Incidental correctness bugs found along the way

Not timeout-related, but surfaced while tracing these call paths and worth fixing:

1. **`ChatApiService.removeReaction()`** (`chat_list_screen/service/api_service.dart`) references a `response` variable that is never assigned in that method — this looks like a leftover from an incomplete refactor and is worth a direct look (it may not even compile as written; it has no live callers today, which is likely why it hasn't surfaced).
2. **`LiveClassController.islinkLoading`** getter returns `_isLoading` instead of `_islinkLoading` — a separate `_islinkLoading` field exists but is never read. Any UI keyed off `islinkLoading` for a per-button spinner shows the wrong loading state, and the initial-list load and the join-link load incorrectly share one loading flag.
3. **Inconsistent `context.mounted` checks around session-expiry handling** in `enrollment_service.dart`'s controller: the success-path 401 handler (clears session + navigates to login) has no `context.mounted` check, while the adjacent exception-path branch does. Several other `initState`-postFrameCallback call sites (`complete_your_profile.dart`, `entrollment_screen.dart:_selectPlan`, `installment_service` future assignment) also call `setState`/use `context` after an `await` with no `mounted` guard — normally a narrow race, but the window widens significantly once you account for the fact that none of these awaits have a timeout.
4. **Verbose unconditional PII logging**: `complete_profile/service.dart` logs full multipart fields + response bodies via `developer.log` on every submit; `enrollment_service.dart` logs full payment/enrollment JSON (including amounts paid/pending) on every fetch. Neither is gated behind a debug/release check.
5. **Hardcoded long-lived Instagram access token** in `instagram_view_screen.dart` source (separate from the perf scope of this audit, but found in the same file and worth flagging).

---

## 5. Good patterns already in place

Worth calling out explicitly so a future cleanup pass doesn't accidentally regress these — these are the templates to copy when fixing the rest:

- **`app_update_service.dart`** — explicit 10s timeout on both the iOS and Android version-check requests, plus the whole check is memoized (`_pendingCheck ??= _performCheck()`) so concurrent callers (splash screen + app-wide update dialog) share one in-flight request instead of firing twice.
- **`splash_screen.dart`** — wraps `AppUpdateService.checkForUpdate()` in an *additional* 6s timeout with a catch-to-null fallback, so the splash screen can never hang waiting on the update check.
- **`presentation/laptop_scanner/api/laptop_api.dart`** — every call goes through one internal `_post`/`getHistory` helper, both with a consistent 15s timeout and a typed `ApiException`.
- **`audio_player.dart`** — the best single example in the app: 30s timeout, `mounted` check before `setState`, and a visible retry affordance shown to the user on failure/timeout instead of a silent stuck state.
- **`chat_screen.dart` file download** — 120s timeout (arguably long for a UI-blocking action, but at least bounded).
- **Pagination in-flight guards** — gallery, attendance, and chat message pagination all correctly check an `_isLoadingMore`-style flag before firing the next page, preventing duplicate concurrent pagination requests on fast scrolling.
- **FCM's `_waitForAPNSToken`** — a bounded poll loop (max 30 × 500ms = 15s), not an infinite retry.
- **Chat `markMessagesAsRead`** — explicit per-chat in-flight guard set, preventing duplicate concurrent read-receipt calls for the same chat.

---

## 6. Full inventory by feature area

### 6.1 Auth / Profile / Enrollment

| File | Method | HTTP verb + endpoint | Callers | Timeout? | Error handling | Notable issues |
|---|---|---|---|---|---|---|
| loginscreen/service.dart | `login()` | POST `/api/auth/student/login/` | `AuthProvider.login()` ← login button | N | No try/catch in method itself; relies on caller | No timeout at any layer; button disabled indefinitely on hang |
| forgot_pass/forgot_pass_service.dart | `sendOtp()` | POST `/api/auth/forgot-password/send-otp/` | `ForgotPasswordController.sendOtp()` ← Send OTP button | N | try/catch → `ApiResponse.error`, shown via SnackBar | none beyond timeout |
| " | `verifyOtp()` | POST `/api/auth/forgot-password/verify-otp/` | `ForgotPasswordController.verifyOtp()` ← Verify button | N | same | same |
| " | `resetPassword()` | POST `/api/auth/forgot-password/reset-password/` | `ForgotPasswordController.resetPassword()` ← Reset button | N | same | same |
| complete_profile/service.dart | `submitProfile()` | PATCH raw `http.MultipartRequest` to `/api/student/profile/{id}/update/` (bypasses `ApiService`) | Save Changes (profile edit), Complete Profile submit, resume upload, professional-link update — 4 call sites | N | try/catch, varies (returns error / rethrows) | Second unprotected network path outside `ApiService`; unconditional PII logging of fields + response body |
| profile_edit_screen/service/profile_edit_service.dart | `getProfileData()` | *(stub, no real network call)* | none found | n/a | n/a | Dead/unused stub |
| profile_screen/service/profile_screen_service.dart | `getProfileData()` | GET `/api/student_portal/profile/` | 3 screens' `initState` + `job_apply_sheet.dart` (bypasses `ProfileController`) | N | try/catch → `ApiResponse.error`; `job_apply_sheet.dart` swallows everything (`catch (_) {}`) | 3 independent re-fetches instead of shared cache; `complete_your_profile.dart` has no `mounted` check before `setState` after this await |
| academic_info/service.dart | `getQualifications()` / `getSpecializations()` / `getPublicCourses()` | GET `/api/public/lead/qualifications/`, `/api/specializations/list/`, `/api/public/courses/` | `referral_screen.dart`, `complete_profile_controller.dart` (both independently) | N | No try/catch in service methods themselves | Called sequentially instead of `Future.wait`, duplicated across 2 call sites; failures only `debugPrint`ed, dropdowns silently stay empty |
| enrollment_screen/service/enrollment_service.dart | `getEnrollmentData()` | GET `/api/student_portal/enrollments/` | `EnrollmentProvider.fetchEnrollData()` ← screen init + post-payment refreshes | N | try/catch → `ApiResponse.error` | 401-handling branch missing `context.mounted` check (inconsistent with adjacent branch); logs full payment PII unconditionally |
| enrollment_screen/service/installment_service.dart | `fetchEmiPlans()` | GET `/api/emi-plans/` | screen init + Retry button | N | try/catch → `ApiResponse.error` | No `mounted` guard around the `initState` future assignment |
| " | `confirmEmiPlan()` | POST `/api/student-enrollment/emi-confirm/` | Confirm button | N | try/catch, logs full request/response | Confirm button not disabled during request; only the after-tap dialog discourages a second tap |
| " | `fetchEmiPreview()` | POST `/api/student-enrollment/emi-preview/` | EMI plan tile tap | N | try/catch, SnackBar on failure | No `mounted` check; no guard against selecting a different plan mid-request (race can overwrite preview with stale data) |

### 6.2 Chat / Notifications / Live Class / Jobs

| File | Method | HTTP verb + endpoint | Callers | Timeout? | Error handling | Notable issues |
|---|---|---|---|---|---|---|
| chat_list_screen/service/api_service.dart | `fetchChats()` | GET `/api/chats/` (page_size hardcoded 100) | chat list load + forward-message sheet | N | Chat list shows error state; forward sheet swallows silently | Hardcoded page size caps the list at 100 chats |
| " | `fetchMessages()` / `_loadMoreMessages()` | GET `/api/chats/{id}/messages/` | message screen init + scroll pagination | N | try/catch, sets error state | Pagination has a good in-flight guard |
| " | `sendMessage()` | POST `/api/chats/{id}/messages/send/` | send button, emoji quick-reaction | N | Rolls back optimistic message + SnackBar on failure | No explicit double-submit guard on the send button itself; quick-reaction tap has zero guard |
| " | `editMessage()` | PATCH `/api/chats/{id}/messages/{id}/edit/` | edit-mode send | N | Rolls back optimistic edit on error | Properly guarded by `_isEditing` |
| " | `sendFileMessage()` | POST (same send endpoint) | file/camera attach flow | N | try/catch | Two sequential unbounded calls per file send (presigned URL, then this) — either hanging blocks attach UI forever |
| " | `deleteMessage()` | DELETE `/api/chats/{id}/messages/{id}/delete/` | delete-confirm dialog | N | SnackBar on failure | none beyond timeout |
| " | `sendReaction()` / `removeReaction()` | POST/DELETE `/api/chats/{id}/messages/{id}/reactions/` | **no live callers found** | N | `removeReaction` references an unassigned `response` variable | Dead code; possible compile issue, see [Incidental bugs](#incidental-correctness-bugs-found-along-the-way) |
| " | `fetchUnreadCount()` | GET `/api/chats/unread-count/` | badge refresh | N | Fully silent (`catch (_) {}`) | Stale badge forever on failure, no visible symptom |
| " | `markMessagesAsRead()` | POST `/api/chats/{id}/messages/mark-read/` | after messages load | N | `debugPrint` only | Good in-flight guard, but a hang locks that chat out of read-receipts for the app's lifetime |
| chat_list_screen/service/report_service.dart | `submitReport()` | POST `/api/chats/report/` (falls back to `mailto:` on failure) | Report dialog submit (awaited); block-user flow (fire-and-forget, **not awaited**) | N | Internal try/catch, never throws | The fire-and-forget call means a hang runs invisibly in the background with its result fully discarded |
| chat_list_screen/service/websocket_service.dart | connection lifecycle | WSS `wss://.../ws/chat/?token=...` | one long-lived app-wide socket via `ChatProvider` | n/a | see dedicated section above | `isConnected` only checks object existence, not liveness; no heartbeat; no periodic reconnect — **highest-severity finding in this area** |
| FCM/fcm_service.dart | *(no HTTP — Firebase SDK only)* | n/a | app startup, login, bottom-nav init | n/a | try/catch around `getToken()` | Refreshed FCM token is never sent to the backend (dead `TODO`) — server may push to a stale token indefinitely |
| live_class/service/live_class_service.dart | `getLiveClassDetails()` | GET `/api/student_portal/enrollments/for-class/` | live class screen init | N | try/catch, `print()` only, no UI error | `_isLoading` never clears on hang |
| " | `getLivelink()` | GET `/api/student_portal/enrollments/for-class/url/{id}/` | Join button | N | same | Shares the same `_isLoading` flag as the list load (see bug #2 above) |
| jobs/service/jobs_service.dart | `getJobDetail()` | GET `/api/student_portal/jobs/{id}/` | job detail screen init | N | try/catch → `ApiResponse.error` | Spinner stuck forever on hang |
| " | `getApplicationDetail()` | GET `/api/student_portal/jobs/applications/{id}/` | job detail init + after job load | N | same | Good in-flight guard (`_isLoadingApp`) |
| " | `markJobAsViewed()` | PATCH `/api/student_portal/jobs/{id}/` | fire-and-forget after detail load | N | Fully silent | Local "viewed" badge decrements optimistically regardless of whether the server call ever succeeds — client/server state can diverge permanently |
| " | `applyForJob()` | POST `/api/student_portal/jobs/{id}/apply/` | Apply confirmation | N | try/catch → `ApiResponse.error` | Correctly guarded by `_isSubmitting` |
| " | `getJobNotifications()` | GET `/api/student_portal/jobs/notifications/` | jobs screen init | N | try/catch → `ApiResponse.error` | Spinner stuck forever on hang |
| **Direct `http` in chat widgets** | file download | GET (arbitrary URL) | Download tap | **Y (120s)** | try/catch | Good — bounded, though long |
| " | audio playback fetch | GET (media URL) | Play tap | **Y (30s)** | try/catch + `mounted` check + retry UI | Best example in the app |
| " | presigned-URL request + S3 upload | POST | file/camera/voice send | N | Throws on non-2xx, caught upstream | `_isUploading` never resets on hang |
| " | bulk-forward | POST `/api/chats/messages/bulk/` (via `ApiService`) | Forward sheet send | N | Relies on `ApiService`'s internal catch | `_isSending` guard present but never clears on a hang |

### 6.3 Media / Gallery / Attendance / Home

| File | Method | HTTP verb + endpoint | Callers | Timeout? | Error handling | Notable issues |
|---|---|---|---|---|---|---|
| gallery_details_screen/service/gallery_details_service.dart | `getSubfolders()` / `getFolderVideos()` / `getVideosWithoutFolder()` | GET `/api/folders/`, `/api/videos/` | Folder browser load (via `Future.wait`) + pagination | N | try/catch, generic error | `Future.wait` means one hung sub-call blocks the whole screen even if the other succeeded |
| gallery_screen/service/gallery_screen_service.dart | `getGalleries()` | GET `/api/galleries/` | Gallery screen init + pagination + refresh | N | try/catch | Good in-flight guards present (`_isLoading`, `_isLoadingMore`) |
| video_folder_video/video_folder_video_service.dart | — | *(empty file)* | n/a | n/a | n/a | Dead file |
| attandance_screen/service.dart (`AttendanceService1`) | `getBatchAttendance()` | GET `/api/attendance/my-batch-attendance/{id}` | **no callers found** | N | try/catch | Dead duplicate of `AttendanceService` below |
| attandance_screen/service.dart (`AttendanceService`) | `getBatchAttendance()` | GET (same endpoint, w/ filters) | Attendance screen load, pagination, filters, QR-scan-return refresh | N | try/catch → `ApiResponse.error` | No guard against overlapping calls on rapid pull-to-refresh |
| " | `getDashboard()` | GET `/api/student_portal/dashboard/` | Fallback only, when sessions weren't preloaded | N | try/catch → `ApiResponse.error` | Explicit code comment acknowledges this exists specifically to avoid a known duplicate-call problem |
| home_screen/service.dart | `getDashboardData()` | GET `/api/student_portal/dashboard/` | `DashboardController`, called from ~7 different screens | N | try/catch → `ApiResponse.error`, handles 401 | Cache guard present but bypassed whenever any caller passes `forceRefresh: true` |
| " | `getNactetStatus()` | (delegates to NACTET service) | 4 separate call sites | N | `debugPrint` only, silent | No dedupe across the 4 sites |
| exam_screen/service.dart | `fetchExamSessions()` | GET `/api/student_portal/exams/sessions/` | Exam screen init/retry | N | try/catch → `ApiResponse.error` | none beyond timeout |
| " | `markVisibility()` | POST `/api/evaluation/exam-sessions/{id}/visibility/` | Card tap, after navigation already occurred | N | try/catch, response effectively discarded | Low impact — fire-and-forget in practice |
| " | `fetchExamResult()` | GET `/api/student_portal/exams/results/{id}/` | Result screen init/retry | N | try/catch → `ApiResponse.error` | none beyond timeout |
| locations/service.dart | `getLocations()` | GET `/api/locations/` | NACTET registration screen init | N | **No try/catch in the method itself** (only around JSON parsing) | Caller catches one level up; controller is a long-lived singleton with no in-flight guard on repeat `init()` calls |
| pincode/service.dart | `getPincodeData()` | GET `/api/postal-pincode/{code}/` | Pincode field `onChanged`, fires at length==6 | N | **No try/catch in the method itself** | Fires on every keystroke at length 6, no debounce, no response sequencing — out-of-order race possible |
| presentation/instagram_view_screen.dart | `fetchInstagramImages()` / `preloadNextBatch()` | GET `graph.instagram.com/me/media` (direct `http`, hardcoded access token) | Carousel init + scroll-triggered preload | N | try/catch, non-reset failures silently swallowed | No timeout; hardcoded long-lived token in source; missing `mounted` check before `precacheImage` in one path |

### 6.4 Payments / Referral / NACTET Registration

| File | Method | HTTP verb + endpoint | Callers | Timeout? | Error handling | Notable issues |
|---|---|---|---|---|---|---|
| payment_screen/service.dart | `getIciciSession()` / `getIciciEmiSession()` | POST `/api/student-payments/full/icici/{id}/`, `/api/payments/emi/icici/{id}/` | ICICI payment tap | N | try/catch, swallowed, returns `null` | Non-dismissible loading dialog shown before the call — stuck forever on hang |
| " | `getIciciPaymentUrl()` | POST (same ICICI full endpoint) | **no callers found** | N | same | Dead code, superseded by `getIciciSession` |
| " | `fetchPaymentGateways()` | GET `/api/payment/gateways/` | Payment/EMI confirm flows via `Future.wait` | N | Falls back to a hardcoded `[razorpay]` gateway on any failure, never surfaces the error | A hang here blocks the paired `Future.wait` call from ever resolving |
| " | `fetchEnrollmentDetails()` | GET `/api/enrollment/{id}/` | Payment screen load, NACTET branch auto-detect | N | try/catch → `ApiResponse.error`, shown via `setState` | none beyond timeout |
| razorpay/service/razorpay_service.dart | `getPaymentDetails()` (order creation) | POST `/api/student-payments/full/{id}/` | Confirm button | N | **No try/catch in the service method** — caller catches, logs only, never surfaces the error | **No double-tap guard** — highest-stakes duplicate-call risk in the app (possible duplicate Razorpay order) |
| " | `getEmiPaymentDetails()` (EMI order creation) | POST `/api/payments/emi/{id}/` | Pay Now / EMI row tap | N | same pattern | Same double-tap risk |
| referral_status/service/referral_status_service.dart | `getReferredStudentsHistory()` / `getReferredStudentsEnrolled()` | GET `/api/lead/my-referred-leads/`, `/api/student/{id}/referred-students/` | Referral status screen init + retry | N | try/catch, swallowed to `null`, generic error UI | Indefinite shimmer-loading spinner on hang |
| nactet_registration/service/nactet_registration_service.dart | `submitRegistration()` | POST multipart `/api/certificates/create/` | Registration form submit | N | try/catch → `ApiResponse.error` | **No timeout on a file upload — largest single hang-duration risk in the app**; `isLoading` set but not checked for re-entry inside `submit()` itself |
| " | `fetchCheckDisplayStatus()` | GET `/api/certificates/check-display/` | Screen init (×2 entry points) | N | try/catch, `debugPrint` only | `isCheckingStatus` can get stuck true on hang, though not screen-blocking |
| presentation/referral_screen/referral_screen.dart | direct `ApiService().post()` | POST `/api/hooks/referral-lead/` | Submit Referral button | N | try/catch/finally, SnackBar on all outcomes | Button not actually disabled during request (spinner is cosmetic) — double-tap can double-submit; also logs the raw payload via a stray `print()` |

### 6.5 App startup / attendance QR / laptop scanner (reviewed directly, not via subagent)

| File | Method | HTTP verb + endpoint | Callers | Timeout? | Error handling | Notable issues |
|---|---|---|---|---|---|---|
| main.dart (`AttendanceService`) | `markAttendance()` | POST `AppEndpoints.attandance` (direct `http`, not `ApiService`) | `QRScannerScreen._callAttendanceApi()` ← QR code detected | **N** | try/catch, shows "Network Error" dialog on exception | Good duplicate-fire guard (`_detected` flag fires exactly once), good error UI — but no timeout, so a hang leaves "Marking attendance..." on screen indefinitely with camera stopped |
| main.dart (`MyApp`) | startup connectivity + update check | delegates to `AppUpdateService.checkForUpdate()` | `initState` postFrameCallback | Indirect (inner calls have 10s each) | — | Not wrapped in its own timeout the way `splash_screen.dart`'s copy is, but bounded to ~10-20s by the inner calls; memoization means this doesn't duplicate splash's own concurrent call — low risk |
| splash_screen.dart | update check | `AppUpdateService.checkForUpdate().timeout(6s)` | 3.5s post-launch timer | **Y (6s)** | catch → null fallback | Good pattern, see above |
| presentation/laptop_scanner/api/laptop_api.dart | `lookup()` / `checkout()` / `returnItems()` / `getHistory()` | POST/GET, all through one `_post`/`getHistory` helper | Laptop scan/checkout/return sheets | **Y (15s)** | Typed `ApiException`, surfaced via inline banners | Good pattern, see above |

---

## 7. Suggested fix priority

1. **Add a timeout to `ApiService`'s 6 methods** (one change, fixes ~24 files at once). Use 15–20s to match the app's own existing good examples.
2. **Add a timeout to the 4 direct-`http` paths that bypass `ApiService`**: `main.dart:AttendanceService.markAttendance`, `complete_profile/service.dart:submitProfile`, `preseigner_url.dart` (both the presigned-URL POST and the S3 upload), `instagram_view_screen.dart` (both calls).
3. **Add a real re-entrancy guard** (checked at the very top of the handler, not just a cosmetic spinner) to: Razorpay order creation (both variants), referral submit, NACTET registration submit, EMI confirm.
4. **Fix the WebSocket liveness gap** — add a heartbeat/ping or a periodic "last message received" staleness check so `isConnected` reflects reality, not just object existence.
5. **Fix the two incidental bugs**: `ChatApiService.removeReaction`'s unassigned `response` reference, and `LiveClassController.islinkLoading`'s wrong-field getter.
6. **Remove the 4 pieces of dead/duplicate code** identified above — no functional risk, but they're maintenance noise and one of them (`AttendanceService1`) could confuse a future edit into "fixing" the wrong class.
7. **Debounce the pincode lookup** and add a request-sequence guard so a stale response can't overwrite a newer one.
8. Lower priority: unify the 3 independent profile-data fetches behind `ProfileController`'s cache; parallelize the sequential academic-dropdown fetches; gate the PII-heavy `developer.log` calls in `complete_profile/service.dart` and `enrollment_service.dart` behind a debug-only check.

---

## Resolution log

All eight items above have been implemented:

1. **`api_services.dart`** — added a 20s timeout to `get`/`post`/`put`/`patch`/`delete` and a 60s timeout to `multipart`'s `request.send()` (uploads legitimately take longer than a plain JSON call, but still need a ceiling).
2. Added timeouts to the four direct-`http` paths that bypassed `ApiService`: `scan_screen.dart`'s `AttendanceService.markAttendance` (20s), `complete_profile/service.dart`'s `submitProfile` multipart upload (60s), `preseigner_url.dart`'s presigned-URL POST (20s) and S3 upload (60s), and both `instagram_view_screen.dart` calls (20s each).
3. Added a real re-entrancy guard (checked at the top of the handler, before the loading dialog even shows) to: `entrollment_screen.dart`'s Confirm button (covers both Razorpay order creation and EMI confirm) and its `_openIciciPayment`; `payment_screen.dart`'s `_handlePayment` (covers both Pay Now and the EMI row tap) and its `_openIciciEmiPayment`; `referral_screen.dart`'s submit button; `NactetRegistrationController.submit()`.
4. **WebSocket liveness** (`websocket_service.dart`) — added a 25s heartbeat that sends a lightweight app-level ping and checks time-since-last-activity; if nothing has been heard for 75s (~3 missed heartbeats) the connection is torn down and a capped-backoff reconnect (5s → 10s → 20s → 30s) kicks in automatically. Also fixed a related gap: `onDone`/`onError` previously never nulled `_channel`, so even a clean server-side close wouldn't flip `isConnected` to false — they now go through the same teardown-and-reconnect path. `disconnect()` (explicit, e.g. logout) still does not auto-reconnect.
5. Fixed `ChatApiService.removeReaction()` — it was unconditionally returning success regardless of the underlying DELETE's actual result; now checks `response.success` like every other method in the file. Fixed `LiveClassController.islinkLoading` — its getter returned `_isLoading` instead of `_islinkLoading`, and `getLiveClassLinkDetails()` was toggling the wrong field, so tapping "Join" on a live class was flickering the *entire list* into its loading state; both now use `_islinkLoading` correctly.
6. Removed confirmed-dead code: `AttendanceService1` (byte-for-byte duplicate of `AttendanceService`, zero callers, plus its `main.dart` provider registration), the empty `video_folder_video_service.dart`, and the unwired `ProfileEditService` stub. Left `ChatApiService.sendReaction`/`removeReaction` in place (bug-fixed, not deleted) — they're a real feature surface not yet wired to UI, and deleting a feature is a bigger call than this audit was meant to make unilaterally.
7. Debounced the pincode lookup in `complete_your_profile.dart` (400ms) and added a request-sequence counter so an in-flight lookup superseded by further edits can no longer overwrite the district field with a stale result.
8. Unified the profile-data fetch: `complete_your_profile.dart`, `profile_screen.dart`, and `job_apply_sheet.dart` (which previously bypassed `ProfileController` entirely via a raw `ProfileScreenService()` call) now all check `profileController.profileData == null` before fetching, sharing one cached load. Parallelized the academic-dropdown fetches in `referral_screen.dart` and `complete_profile_controller.dart` (both requests now fire concurrently instead of one awaiting the other). Gated the PII-bearing `developer.log` calls in `complete_profile/service.dart` and `enrollment_service.dart` behind `kDebugMode`.

Verified with `flutter analyze lib` after every change — zero errors throughout, and the final full pass is clean (only pre-existing, unrelated warnings/info remain).

**Not fixed, and intentionally left for you to decide:** the hardcoded long-lived Instagram access token in `instagram_view_screen.dart`. Rotating or relocating a live credential isn't a call to make unilaterally during a reliability pass — it needs a replacement mechanism (secure config / remote config / backend proxy) decided by whoever owns that integration.
