import 'package:flutter/material.dart';
import '../api/laptop_api.dart';
import '../time_ago.dart';

class LaptopHistoryScreen extends StatefulWidget {
  const LaptopHistoryScreen({
    super.key,
    required this.api,
    required this.studentId,
  });
  final LaptopApi api;
  final String studentId;

  @override
  State<LaptopHistoryScreen> createState() => _LaptopHistoryScreenState();
}

class _LaptopHistoryScreenState extends State<LaptopHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<LoanHistoryEntry> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.api.getHistory(widget.studentId);
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    }
  }

  List<LoanHistoryEntry> get _active   => _all.where((e) => e.isActive).toList();
  List<LoanHistoryEntry> get _returned => _all.where((e) => !e.isActive).toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laptop History',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.laptop_mac_rounded, size: 15),
                const SizedBox(width: 6),
                Text(_loading ? 'Active' : 'Active (${_active.length})'),
              ]),
            ),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.history_rounded, size: 15),
                const SizedBox(width: 6),
                Text(_loading ? 'Returned' : 'Returned (${_returned.length})'),
              ]),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _LoanList(loans: _active, isActive: true),
                    _LoanList(loans: _returned, isActive: false),
                  ],
                ),
    );
  }
}

// ── Loan list ─────────────────────────────────────────────────────────────────

class _LoanList extends StatelessWidget {
  const _LoanList({required this.loans, required this.isActive});
  final List<LoanHistoryEntry> loans;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle_outline_rounded : Icons.inbox_rounded,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              isActive ? 'All laptops are in!' : 'No returns yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: loans.length,
        itemBuilder: (context, i) => _LoanCard(loan: loans[i]),
      ),
    );
  }
}

// ── Loan card ─────────────────────────────────────────────────────────────────

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan});
  final LoanHistoryEntry loan;

  @override
  Widget build(BuildContext context) {
    final isActive = loan.isActive;
    final accent = isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final initial = loan.studentName.trim().isNotEmpty
        ? loan.studentName.trim()[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.20),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Laptop row ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.laptop_mac_rounded, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.laptopName.isNotEmpty ? loan.laptopName : 'Laptop',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (loan.assetTag.isNotEmpty)
                        Text(
                          loan.assetTag,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isActive ? 'OUT' : 'RETURNED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),

            // ── Student row ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.deepPurple.withValues(alpha: 0.12)
                        : Colors.teal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.deepPurple : Colors.teal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.studentName.isNotEmpty ? loan.studentName : 'Unknown',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          if (loan.studentId.isNotEmpty) ...[
                            Icon(Icons.badge_rounded,
                                size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text(
                              loan.studentId,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            if (loan.batch.isNotEmpty) ...[
                              Text(' · ',
                                  style: TextStyle(color: Colors.grey.shade400)),
                            ],
                          ],
                          if (loan.batch.isNotEmpty)
                            Text(
                              loan.batch,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Time row ────────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.login_rounded, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'Taken ${timeAgo(loan.checkOutAt.toLocal())}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                if (!isActive && loan.returnedAt != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.logout_rounded, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Returned ${timeAgo(loan.returnedAt!.toLocal())}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
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
