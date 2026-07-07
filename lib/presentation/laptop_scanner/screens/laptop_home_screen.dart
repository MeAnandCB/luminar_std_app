import 'package:flutter/material.dart';
import '../api/laptop_api.dart';
import '../config.dart';
import '../time_ago.dart';
import 'history_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class LaptopHomeScreen extends StatefulWidget {
  const LaptopHomeScreen({
    super.key,
    this.prefillName = '',
    this.prefillStudentId = '',
    this.prefillBatch = '',
  });

  final String prefillName;
  final String prefillStudentId;
  final String prefillBatch;

  @override
  State<LaptopHomeScreen> createState() => _LaptopHomeScreenState();
}

class _LaptopHomeScreenState extends State<LaptopHomeScreen> {
  AppConfigLap? _config;
  LaptopApi? _api;

  List<LoanHistoryEntry> _all = [];
  bool _loading = true;
  String? _error;

  static const _blue    = Color(0xFF0369A1);
  static const _blueL   = Color(0xFF0EA5E9);
  static const _green   = Color(0xFF10B981);
  static const _red     = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final cfg = await AppConfigLap.load();
    if (!mounted) return;
    setState(() {
      _config = cfg;
      _api = LaptopApi(cfg);
    });
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_api == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.prefillStudentId.isEmpty) {
        setState(() { _loading = false; });
        return;
      }
      final data = await _api!.getHistory(widget.prefillStudentId);
      if (!mounted) return;
      setState(() { _all = data; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    }
  }

  List<LoanHistoryEntry> get _active   => _all.where((e) => e.isActive).toList();
  List<LoanHistoryEntry> get _returned => _all.where((e) => !e.isActive).toList();

  Future<void> _openScanner() async {
    if (_config == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LaptopScanScreen(
          prefillName:      widget.prefillName,
          prefillStudentId: widget.prefillStudentId,
          prefillBatch:     widget.prefillBatch,
        ),
      ),
    );
    if (mounted) _loadHistory();
  }

  Future<void> _openSettings() async {
    if (_config == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LaptopSettingsScreen(config: _config!)),
    );
    if (!mounted) return;
    final updated = await AppConfigLap.load();
    setState(() {
      _config = updated;
      _api = LaptopApi(updated);
    });
    _loadHistory();
  }

  Future<void> _openHistory() async {
    if (_api == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LaptopHistoryScreen(
        api: _api!,
        studentId: widget.prefillStudentId,
      )),
    );
    if (mounted) _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: _blue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(isDark),
            SliverToBoxAdapter(child: _buildHeroCard()),
            SliverToBoxAdapter(child: _buildStatsRow(isDark)),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(child: _buildError())
            else ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Currently Out',
                  '${_active.length}',
                  _red,
                  Icons.laptop_mac_rounded,
                  onViewAll: _openHistory,
                ),
              ),
              if (_active.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  color: _green,
                  label: 'All laptops are in!',
                ))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ActiveTile(loan: _active[i]),
                    childCount: _active.length > 5 ? 5 : _active.length,
                  ),
                ),
              if (_active.length > 5)
                SliverToBoxAdapter(
                  child: _viewMoreBtn('View all ${_active.length} active', _openHistory),
                ),
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Recent Returns',
                  '${_returned.length}',
                  _green,
                  Icons.history_rounded,
                  onViewAll: _openHistory,
                ),
              ),
              if (_returned.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState(
                  icon: Icons.inbox_rounded,
                  color: Colors.grey,
                  label: 'No returns yet',
                ))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ReturnedTile(loan: _returned[i]),
                    childCount: _returned.length > 3 ? 3 : _returned.length,
                  ),
                ),
              if (_returned.length > 3)
                SliverToBoxAdapter(
                  child: _viewMoreBtn('View full history', _openHistory),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
      floatingActionButton: _ScanFab(onTap: _openScanner),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Laptop Manager',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded),
          tooltip: 'History',
          onPressed: _openHistory,
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Settings',
          onPressed: _openSettings,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Hero card ──────────────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.laptop_mac_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Laptop Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Scan QR sticker to check out or return\na laptop — fast and trackable.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow(bool isDark) {
    final total     = _all.length;
    final outCount  = _active.length;
    final retCount  = _returned.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          _StatChip(
            label: 'Total',
            value: _loading ? '-' : '$total',
            color: _blueL,
            icon: Icons.devices_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Out Now',
            value: _loading ? '-' : '$outCount',
            color: _red,
            icon: Icons.output_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Returned',
            value: _loading ? '-' : '$retCount',
            color: _green,
            icon: Icons.keyboard_return_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    String title,
    String count,
    Color color,
    IconData icon, {
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const Spacer(),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'View all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _blue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: color.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewMoreBtn(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: _blue,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active loan tile ──────────────────────────────────────────────────────────

class _ActiveTile extends StatelessWidget {
  const _ActiveTile({required this.loan});
  final LoanHistoryEntry loan;

  @override
  Widget build(BuildContext context) {
    final initial = loan.studentName.trim().isNotEmpty
        ? loan.studentName.trim()[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.studentName.isNotEmpty ? loan.studentName : 'Unknown',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (loan.studentId.isNotEmpty) ...[
                      Icon(Icons.badge_rounded,
                          size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(loan.studentId,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                      if (loan.batch.isNotEmpty)
                        Text(' · ',
                            style:
                                TextStyle(color: Colors.grey.shade400)),
                    ],
                    if (loan.batch.isNotEmpty)
                      Text(loan.batch,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loan.assetTag.isNotEmpty ? loan.assetTag : 'OUT',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeAgo(loan.checkOutAt.toLocal()),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Returned loan tile ────────────────────────────────────────────────────────

class _ReturnedTile extends StatelessWidget {
  const _ReturnedTile({required this.loan});
  final LoanHistoryEntry loan;

  @override
  Widget build(BuildContext context) {
    final initial = loan.studentName.trim().isNotEmpty
        ? loan.studentName.trim()[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.teal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.studentName.isNotEmpty ? loan.studentName : 'Unknown',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.login_rounded,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(
                      timeAgo(loan.checkOutAt.toLocal()),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    if (loan.returnedAt != null) ...[
                      Text(' → ',
                          style: TextStyle(color: Colors.grey.shade400)),
                      Icon(Icons.logout_rounded,
                          size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        timeAgo(loan.returnedAt!.toLocal()),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              loan.assetTag.isNotEmpty ? loan.assetTag : '✓',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10B981),
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan FAB ──────────────────────────────────────────────────────────────────

class _ScanFab extends StatelessWidget {
  const _ScanFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0369A1).withValues(alpha: 0.40),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Scan QR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
