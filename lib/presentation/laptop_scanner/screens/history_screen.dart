import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/laptop_api.dart';

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
  static const _prefsKey = 'laptop_history_student_id';

  late final TabController _tabs;
  final TextEditingController _studentIdController = TextEditingController();

  List<LoanHistoryEntry> _all = [];
  bool _loading = false;
  bool _needsStudentIdEntry = false;
  String? _studentId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefill = widget.studentId.trim();
    if (prefill.isNotEmpty) {
      await _saveAndUseStudentId(prefill);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey)?.trim() ?? '';
    if (!mounted) return;

    setState(() {
      _studentIdController.text = saved;
      _studentId = saved.isEmpty ? null : saved;
      _needsStudentIdEntry = saved.isEmpty;
    });

    if (_studentId != null && _studentId!.isNotEmpty) {
      await _loadHistory();
    }
  }

  Future<void> _saveAndUseStudentId(String value) async {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, cleaned);
    if (!mounted) return;

    setState(() {
      _studentId = cleaned;
      _studentIdController.text = cleaned;
      _needsStudentIdEntry = false;
      _error = null;
    });
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final studentId = _studentId?.trim();
    if (studentId == null || studentId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _needsStudentIdEntry = true;
        _error = null;
        _all = [];
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _needsStudentIdEntry = false;
    });

    try {
      final data = await widget.api.getHistory(studentId);
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(ApiException exception) {
    if (exception.statusCode == 401 || exception.statusCode == 500) {
      return "Couldn't load your history, try again.";
    }
    return exception.message.isNotEmpty
        ? exception.message
        : "Couldn't load your history, try again.";
  }

  Future<void> _changeStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (!mounted) return;

    setState(() {
      _studentId = null;
      _studentIdController.clear();
      _needsStudentIdEntry = true;
      _loading = false;
      _error = null;
      _all = [];
    });
  }

  Future<void> _submitStudentId() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your Student ID to continue.')),
      );
      return;
    }

    await _saveAndUseStudentId(studentId);
  }

  List<LoanHistoryEntry> get _active => _all.where((e) => e.isActive).toList();
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
          'My Laptop History',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_studentId != null && _studentId!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.person_rounded),
              tooltip: 'Change Student ID',
              onPressed: _changeStudentId,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadHistory,
          ),
        ],
        bottom: (!_needsStudentIdEntry && !_loading)
            ? TabBar(
                controller: _tabs,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
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
              )
            : null,
      ),
      body: _needsStudentIdEntry
          ? _StudentIdEntryView(
              controller: _studentIdController,
              onSubmit: _submitStudentId,
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _loadHistory)
                  : _all.isEmpty
                      ? const _EmptyHistoryView()
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

class _StudentIdEntryView extends StatelessWidget {
  const _StudentIdEntryView({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your Student ID',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'This lets the app show only your own laptop history.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) async => onSubmit(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. LUM2024001',
                    labelText: 'Student ID',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async => onSubmit(),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan});
  final LoanHistoryEntry loan;

  @override
  Widget build(BuildContext context) {
    final isActive = loan.isActive;
    final accent = isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final dateFmt = DateFormat('MMM d, h:mm a');

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
            const SizedBox(height: 10),
            Text(
              'Checked out: ${dateFmt.format(loan.checkOutAt.toLocal())}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              loan.returnedAt != null
                  ? 'Returned: ${dateFmt.format(loan.returnedAt!.toLocal())}'
                  : 'Still checked out',
              style: TextStyle(
                fontSize: 12,
                color: loan.returnedAt != null
                    ? Colors.grey.shade600
                    : const Color(0xFFEF4444),
                fontWeight: loan.returnedAt == null ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No history yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'You do not have any past laptop check-outs yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
