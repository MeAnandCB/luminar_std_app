import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:luminar_std/presentation/job_community/views/community_apply_sheet.dart';
import 'package:luminar_std/repository/chat_list_screen/models/message.dart' as chat_models;
import 'package:luminar_std/repository/job_community/job_community_model.dart';
import 'package:luminar_std/repository/job_community/job_community_service.dart';
import 'package:provider/provider.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({super.key, required this.community});

  final JobCommunity community;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  final _service = JobCommunityService();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          widget.community.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Community Chat'),
            Tab(text: 'Shared Jobs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CommunityChatTab(chatUid: widget.community.chatUid, service: _service),
          _CommunityJobsTab(community: widget.community, service: _service),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat tab — read-only timeline; job_share messages render as inline cards.
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityChatTab extends StatefulWidget {
  const _CommunityChatTab({required this.chatUid, required this.service});

  final String chatUid;
  final JobCommunityService service;

  @override
  State<_CommunityChatTab> createState() => _CommunityChatTabState();
}

class _CommunityChatTabState extends State<_CommunityChatTab> {
  static const _pageSize = 40;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  final List<CommunityMessage> _messages = [];
  final Set<String> _messageUids = {};
  int _nextPage = 2; // page 1 is always fetched by _load()/_poll()
  Timer? _pollTimer;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<chat_models.Message>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _load(markRead: true);
    // No dedicated community websocket in the spec — polling is the
    // guaranteed baseline. As a bonus, if the student's main chat WebSocket
    // happens to already be connected (they've opened the Chat tab this
    // session), we opportunistically listen on it for near-instant updates
    // below — but we never depend on it and never open a socket of our own.
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) => _poll());
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachWebSocket());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _wsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _attachWebSocket() {
    if (!mounted) return;
    try {
      final ws = context.read<ChatProvider>().webSocketService;
      if (ws == null) return;
      _wsSubscription = ws.messageStream.listen(_onSocketMessage);
    } catch (_) {
      // Best-effort enhancement only — polling above remains the source of truth.
    }
  }

  void _onSocketMessage(chat_models.Message message) {
    if (message.chatId != widget.chatUid) return;
    _mergeMessages([
      CommunityMessage(
        uid: message.uid,
        messageType: message.messageType,
        content: message.content,
        createdAt: message.createdAt,
        sender: CommunityMessageSender(
          id: message.sender.id,
          fullName: message.sender.fullName,
        ),
      ),
    ], markReadNew: true);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // reverse:true — older history sits toward maxScrollExtent.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// Initial load — page 1, newest messages.
  Future<void> _load({bool markRead = false}) async {
    if (_messages.isEmpty) setState(() => _loading = true);
    final res = await widget.service.getMessages(widget.chatUid, page: 1, pageSize: _pageSize);
    if (!mounted) return;

    if (res.success && res.data != null) {
      _hasMore = res.data!.length >= _pageSize;
      _nextPage = 2;
      setState(() {
        _loading = false;
        _error = null;
      });
      _mergeMessages(res.data!, markReadNew: markRead);
    } else if (_messages.isEmpty) {
      setState(() {
        _error = res.message ?? 'Failed to load messages';
        _loading = false;
      });
    }
  }

  /// Background refresh — re-fetches only the newest page and merges it in,
  /// so it never disturbs older pages the user has scrolled up to load.
  Future<void> _poll() async {
    final res = await widget.service.getMessages(widget.chatUid, page: 1, pageSize: _pageSize);
    if (!mounted || !res.success || res.data == null) return;
    _mergeMessages(res.data!, markReadNew: true);
  }

  /// Fetches the next (older) page when the user scrolls up toward history.
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    final res = await widget.service.getMessages(widget.chatUid, page: _nextPage, pageSize: _pageSize);
    if (!mounted) return;
    if (res.success && res.data != null) {
      _hasMore = res.data!.length >= _pageSize;
      _nextPage++;
      _mergeMessages(res.data!, markReadNew: false);
    } else {
      _hasMore = false;
    }
    if (mounted) setState(() => _loadingMore = false);
  }

  /// De-dupes by uid and keeps `_messages` sorted oldest→newest, regardless
  /// of what order the API/socket actually hands messages back in — that's
  /// what guarantees the latest message always lands at the bottom.
  void _mergeMessages(List<CommunityMessage> incoming, {required bool markReadNew}) {
    final newlyAdded = <CommunityMessage>[];
    for (final m in incoming) {
      if (_messageUids.add(m.uid)) newlyAdded.add(m);
    }
    if (newlyAdded.isEmpty) return;
    _messages.addAll(newlyAdded);
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(() {});
    if (markReadNew) {
      widget.service.markRead(widget.chatUid, newlyAdded.map((m) => m.uid).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildBody()),
        _DisabledChatInputBar(onTap: _showReadOnlyNotice),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => _load(markRead: true), child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Container(
      color: AppColors.scaffoldBackground,
      child: RefreshIndicator(
        onRefresh: () => _load(markRead: true),
        color: AppColors.primary,
        child: ListView.builder(
          controller: _scrollController,
          reverse: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          itemCount: _messages.length + (_loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (_loadingMore && index == _messages.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            // `_messages` is kept sorted oldest→newest; index 0 (bottom,
            // due to reverse:true) must map to the newest message.
            final message = _messages[_messages.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MessageBubble(message: message),
            );
          },
        ),
      ),
    );
  }

  void _showReadOnlyNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "This community is only for HR job postings — you can't reply here. Tap Apply on a job to apply directly.",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Looks like the app's normal chat input bar but is entirely inert — this
/// feed is a read-only HR broadcast channel, so every tap just explains why
/// instead of accepting text.
class _DisabledChatInputBar extends StatelessWidget {
  const _DisabledChatInputBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.5))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textHint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Replying is disabled in this community',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, color: AppColors.textHint),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final CommunityMessage message;

  @override
  Widget build(BuildContext context) {
    final share = message.jobShare;
    if (share != null) return _JobShareCard(share: share);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.sender != null && message.sender!.fullName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  message.sender!.fullName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.35),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM, hh:mm a').format(message.createdAt.toLocal()),
              style: TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobShareCard extends StatelessWidget {
  const _JobShareCard({required this.share});

  final JobShareContent share;

  static const double _spineWidth = 8;

  @override
  Widget build(BuildContext context) {
    // Deliberately the leanest possible tree: ONE CustomPaint (shape, spine
    // and shadow drawn as plain Canvas ops \u2014 Canvas.drawShadow/drawPath/
    // clipPath never touch the RenderObject/semantics tree) with the
    // Material/InkWell as its direct child. No Stack, no ClipPath, no
    // PhysicalShape \u2014 those, placed above an InkWell inside a scrolling
    // reversed ListView, tripped a Flutter framework semantics assertion
    // ('!semantics.parentDataDirty') here before.
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: CustomPaint(
          painter: _JobCardPainter(
            bodyColor: AppColors.cardBackground,
            spineColor: AppColors.primary,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => openCommunityApplySheet(
                context,
                communityUid: share.communityUid,
                jobUid: share.jobUid,
                jobTitle: share.title,
                companyName: share.company,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(_spineWidth + 10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge header, standalone \u2014 separates "what this is"
                    // from the job details below instead of competing with
                    // the icon/button for vertical space in one tall row.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_rounded, size: 10, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'JOB SHARED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.business_center_rounded, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                share.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                share.location.isEmpty
                                    ? share.company
                                    : '${share.company} \u00b7 ${share.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the ticket-notch card shape, its colored spine, and a soft shadow
/// entirely with Canvas ops (drawShadow/drawPath/clipPath) \u2014 no
/// ClipPath/PhysicalShape widget, so nothing here participates in the
/// render-object clip or semantics tree.
class _JobCardPainter extends CustomPainter {
  final Color bodyColor;
  final Color spineColor;

  _JobCardPainter({required this.bodyColor, required this.spineColor});

  static const double _radius = 14;
  static const double _notchDepth = 5;
  static const double _notchGap = 16;

  Path _shapePath(Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    return Path()
      ..moveTo(_radius, 0)
      ..lineTo(w - _radius, 0)
      ..quadraticBezierTo(w, 0, w, _radius)
      ..lineTo(w, h - _radius)
      ..quadraticBezierTo(w, h, w - _radius, h)
      ..lineTo(_radius, h)
      ..quadraticBezierTo(0, h, 0, h - _radius)
      ..lineTo(0, midY + _notchGap / 2)
      ..quadraticBezierTo(_notchDepth, midY, 0, midY - _notchGap / 2)
      ..lineTo(0, _radius)
      ..quadraticBezierTo(0, 0, _radius, 0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shapePath(size);

    canvas.drawShadow(path, spineColor, 3, false);
    canvas.drawPath(path, Paint()..color = bodyColor);

    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _JobShareCard._spineWidth, size.height),
      Paint()..color = spineColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _JobCardPainter oldDelegate) =>
      oldDelegate.bodyColor != bodyColor || oldDelegate.spineColor != spineColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Jobs tab — dedicated shared-jobs list (active shares of published jobs).
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityJobsTab extends StatefulWidget {
  const _CommunityJobsTab({required this.community, required this.service});

  final JobCommunity community;
  final JobCommunityService service;

  @override
  State<_CommunityJobsTab> createState() => _CommunityJobsTabState();
}

class _CommunityJobsTabState extends State<_CommunityJobsTab> {
  bool _loading = true;
  String? _error;
  List<CommunityJobShare> _jobs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.service.getCommunityJobs(widget.community.uid);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _jobs = res.data!.results;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load shared jobs';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (_jobs.isEmpty) {
      return Center(
        child: Text(
          'No jobs shared yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 74,
          color: AppColors.borderColor.withValues(alpha: 0.4),
        ),
        itemBuilder: (context, index) {
          final job = _jobs[index];
          return _SharedJobRow(
            job: job,
            onTap: () => openCommunityApplySheet(
              context,
              communityUid: widget.community.uid,
              jobUid: job.jobUid,
              jobTitle: job.title,
              companyName: job.company.name,
            ),
          );
        },
      ),
    );
  }
}

class _SharedJobRow extends StatelessWidget {
  const _SharedJobRow({required this.job, required this.onTap});

  final CommunityJobShare job;
  final VoidCallback onTap;

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.business_center_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (job.location.isNotEmpty) ...[
                          Icon(Icons.location_on_rounded, size: 12, color: AppColors.textHint),
                          const SizedBox(width: 3),
                          Text(job.location, style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                          const SizedBox(width: 10),
                        ],
                        Text(_timeAgo(job.sharedAt), style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
