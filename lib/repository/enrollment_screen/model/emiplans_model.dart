import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ==================== MAIN SCREEN ====================

class EmiPlansScreen extends StatefulWidget {
  final String enrollmentId;

  EmiPlansScreen({required this.enrollmentId});

  @override
  _EmiPlansScreenState createState() => _EmiPlansScreenState();
}

class _EmiPlansScreenState extends State<EmiPlansScreen> {
  late Future<List<EmiPlan>> _futureEmiPlans;
  EmiPlan? _selectedPlan;
  EmiPreviewResponse? _previewData;
  bool _isLoadingPreview = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    print(
      '🚀 EmiPlansScreen initialized with enrollmentId: ${widget.enrollmentId}',
    );
    // Set the enrollment ID in the API service
    _apiService.setEnrollmentId(widget.enrollmentId);
    _futureEmiPlans = _apiService.fetchEmiPlans();
  }

  void _selectPlan(EmiPlan plan) async {
    print('🔍 _selectPlan called with plan:');
    print('   - ID: "${plan.id}"');
    print('   - Name: "${plan.name}"');
    print('   - Description: "${plan.description}"');
    print('   - Installment Count: ${plan.installmentCount}');

    // Validate plan ID
    if (plan.id.isEmpty) {
      print('❌ CRITICAL: Plan ID is empty!');

      // Show error dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error'),
          content: Text('Selected plan has no ID. Please try again.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK')),
          ],
        ),
      );

      setState(() {
        _errorMessage = 'Invalid plan selected: Plan ID is missing';
      });
      return;
    }

    setState(() {
      _selectedPlan = plan;
      _isLoadingPreview = true;
      _previewData = null;
      _errorMessage = null;
    });

    try {
      print('🚀 Calling fetchEmiPreview with plan ID: "${plan.id}"');
      final preview = await _apiService.fetchEmiPreview(plan.id);
      print('✅ Preview fetched successfully');
      setState(() {
        _previewData = preview;
        _isLoadingPreview = false;
      });
    } catch (e) {
      print('❌ Error loading preview: $e');
      setState(() {
        _isLoadingPreview = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load preview: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EMI Plans',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Top section - Selected Plan Container
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: _buildSelectedPlanContainer(),
          ),

          // Bottom section - EMI Plans List
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Available EMI Plans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<EmiPlan>>(
                    future: _futureEmiPlans,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        print('❌ Error in FutureBuilder: ${snapshot.error}');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16),
                              Text('Error loading plans'),
                              SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  snapshot.error.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _futureEmiPlans = _apiService
                                        .fetchEmiPlans();
                                  });
                                },
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No EMI plans available'));
                      }

                      final plans = snapshot.data!;
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        itemCount: plans.length,
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          final isSelected = _selectedPlan?.id == plan.id;

                          // Log each plan's ID when building the list
                          print(
                            '📋 Plan $index: ID="${plan.id}", Name="${plan.name}"',
                          );

                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            color: isSelected ? Colors.blue[50] : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                print(
                                  '👆 Tapped on plan: ID="${plan.id}", Name="${plan.name}"',
                                );
                                _selectPlan(plan);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            plan.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${plan.installmentCount} EMIs',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      plan.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'First EMI after ${plan.firstEmiAfterDays} days',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${_formatAmount(plan.minimumAmount)} - ₹${_formatAmount(plan.maximumAmount)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                        Text(
                                          '${plan.planDurationMonths.toStringAsFixed(1)} months',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlanContainer() {
    if (_selectedPlan == null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.credit_card, size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              'Select an EMI plan to view details',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_isLoadingPreview) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading EMI details...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 12),
            Text(
              'Error loading preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 12, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_previewData != null) {
      return EmiPreviewCompact(response: _previewData!);
    }

    return Container(); // Should not reach here
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    try {
      if (amount is String) {
        return double.parse(amount).toStringAsFixed(0);
      } else if (amount is num) {
        return amount.toStringAsFixed(0);
      }
      return '0';
    } catch (e) {
      return '0';
    }
  }
}

// ==================== COMPACT EMI PREVIEW WIDGET ====================

class EmiPreviewCompact extends StatelessWidget {
  final EmiPreviewResponse response;

  const EmiPreviewCompact({required this.response});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status message if any
        if (response.message.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.message,
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Summary Row
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Plan: ${_selectedPlan?.name ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${response.emiPreview.installmentCount} Installments',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      '₹${_formatAmount(response.emiPreview.totalEmiAmount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),

        // Date Range Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'First EMI',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDate(response.emiPreview.firstEmiDate),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Last EMI',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDate(response.emiPreview.lastEmiDate),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        // Quick Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                _showFullPreviewDialog(context);
              },
              icon: Icon(Icons.visibility, size: 16),
              label: Text('View Full Details'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
            ),
          ],
        ),
      ],
    );
  }

  void _showFullPreviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'EMI Plan Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: EmiPreviewDetails(response: response),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  EmiPlan? get _selectedPlan {
    // This is a workaround - in a real app, you'd pass the selected plan
    return null;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    try {
      if (amount is String) {
        return double.parse(amount).toStringAsFixed(0);
      } else if (amount is num) {
        return amount.toStringAsFixed(0);
      }
      return '0';
    } catch (e) {
      return '0';
    }
  }
}

// ==================== FULL EMI PREVIEW DETAILS WIDGET ====================

class EmiPreviewDetails extends StatelessWidget {
  final EmiPreviewResponse response;

  const EmiPreviewDetails({required this.response});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total EMI Amount',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '₹${_formatAmount(response.emiPreview.totalEmiAmount)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Installments',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '${response.emiPreview.installmentCount} Payments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'First EMI',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDate(response.emiPreview.firstEmiDate),
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last EMI',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDate(response.emiPreview.lastEmiDate),
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // EMI Plan Details Expansion Tile
        _buildExpansionTile(
          title: 'EMI Plan Details',
          icon: Icons.info_outline,
          children: [
            _buildDetailRow('Plan Name', response.emiPlanDetails.planName),
            _buildDetailRow('Description', response.emiPlanDetails.description),
            _buildDetailRow(
              'Installments',
              '${response.emiPlanDetails.installmentCount} payments',
            ),
            _buildDetailRow(
              'Frequency',
              response.emiPlanDetails.installmentFrequencyReadable,
            ),
            _buildDetailRow(
              'First EMI After',
              '${response.emiPlanDetails.firstEmiAfterDays} days',
            ),
            _buildDetailRow(
              'Amount Range',
              '₹${_formatAmount(response.emiPlanDetails.minimumAmount)} - ₹${_formatAmount(response.emiPlanDetails.maximumAmount)}',
            ),
            _buildDetailRow(
              'Duration',
              '${response.emiPlanDetails.planDurationMonths.toStringAsFixed(1)} months',
            ),
          ],
        ),

        // Payment Schedule Expansion Tile
        if (response.installmentBreakdown.schedule.isNotEmpty)
          _buildExpansionTile(
            title: 'Payment Schedule',
            icon: Icons.calendar_month,
            initiallyExpanded: true,
            children: [
              // Schedule header
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Due Date',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '#',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              // Schedule items
              ...response.installmentBreakdown.schedule.map(
                (item) => Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                    color: item.isFirstInstallment
                        ? Colors.green[50]
                        : item.isLastInstallment
                        ? Colors.orange[50]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.formattedDueDate,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            if (item.isFirstInstallment)
                              Text(
                                'First',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else if (item.isLastInstallment)
                              Text(
                                'Last',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '#${item.installmentNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '₹${_formatAmount(item.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: item.isLastInstallment
                                ? Colors.orange[800]
                                : Colors.black,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        // Rounding Information Expansion Tile
        if (response
            .installmentBreakdown
            .roundingDetails
            .methodology
            .isNotEmpty)
          _buildExpansionTile(
            title: 'Rounding Information',
            icon: Icons.info_outline,
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  response.installmentBreakdown.roundingDetails.methodology,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
            ],
          ),

        // Important Notes Expansion Tile
        if (response.nextSteps.importantNotes.isNotEmpty)
          _buildExpansionTile(
            title: 'Important Notes',
            icon: Icons.warning_amber_rounded,
            children: response.nextSteps.importantNotes
                .map(
                  (note) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(note, style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

        // Calculation Formula
        if (response.emiPreview.calculationFormula.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate, size: 16, color: Colors.blue[700]),
                    SizedBox(width: 8),
                    Text(
                      'Calculation',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  response.emiPreview.calculationFormula,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExpansionTile({
    required String title,
    required IconData icon,
    List<Widget> children = const [],
    bool initiallyExpanded = false,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.blue[700]),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        initiallyExpanded: initiallyExpanded,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    try {
      if (amount is String) {
        return double.parse(amount).toStringAsFixed(0);
      } else if (amount is num) {
        return amount.toStringAsFixed(0);
      }
      return '0';
    } catch (e) {
      return '0';
    }
  }
}

// ==================== API SERVICE ====================

class ApiService {
  static const String baseUrl = '${GlobalLinks.baseUrl}/api';

  // Store enrollment ID to use in requests
  String? _enrollmentId;

  // Method to set enrollment ID
  void setEnrollmentId(String enrollmentId) {
    print('🔑 Setting enrollment ID: $enrollmentId');
    _enrollmentId = enrollmentId;
  }

  Future<List<EmiPlan>> fetchEmiPlans() async {
    print('📡 Fetching EMI plans...');
    try {
      final accessKey = await AppUtils.getAccessKey();
      print('🔑 Access key retrieved');

      final url = Uri.parse('$baseUrl/emi-plans/');
      print('🌐 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessKey',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ JSON parsed successfully');
        print('📊 JSON data type: ${jsonData.runtimeType}');

        // Log the entire response structure
        print('🔍 Full response: $jsonData');

        // Handle different response structures
        List<dynamic> plansJson = [];
        if (jsonData is List) {
          plansJson = jsonData;
          print('📋 Response is a List with ${plansJson.length} items');
        } else if (jsonData is Map) {
          print('📋 Response is a Map with keys: ${jsonData.keys}');

          if (jsonData.containsKey('results')) {
            plansJson = jsonData['results'] as List<dynamic>;
            print('📋 Using "results" array with ${plansJson.length} items');
          } else if (jsonData.containsKey('emi_plans')) {
            plansJson = jsonData['emi_plans'] as List<dynamic>;
            print('📋 Using "emi_plans" array with ${plansJson.length} items');
          } else if (jsonData.containsKey('data')) {
            plansJson = jsonData['data'] as List<dynamic>;
            print('📋 Using "data" array with ${plansJson.length} items');
          } else {
            // Try to find any list in the response
            jsonData.forEach((key, value) {
              if (value is List) {
                plansJson = value;
                print('📋 Found list in key "$key" with ${value.length} items');
              }
            });
          }
        }

        print('📊 Number of plans found: ${plansJson.length}');

        // Log each plan's raw data
        for (var i = 0; i < plansJson.length; i++) {
          print('📦 Plan $i raw data: ${plansJson[i]}');
        }

        return plansJson.map((json) => EmiPlan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load EMI plans: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in fetchEmiPlans: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<EmiPreviewResponse> fetchEmiPreview(String emiPlanId) async {
    print('📡 Fetching EMI preview for plan: "$emiPlanId"');

    final Map<String, dynamic> payload = {
      'emi_plan_id': "fc383b4e-5e24-4563-96c6-8f79a1ac5310",
      'enrollment_id': "137f329b-d002-4042-b30a-088de2058736",
    };

    // Validate emiPlanId
    if (emiPlanId.isEmpty) {
      throw Exception('emi_plan_id cannot be empty');
    }

    // Check if enrollment ID is set
    if (_enrollmentId == null || _enrollmentId!.isEmpty) {
      throw Exception('Enrollment ID is required but not set');
    }

    try {
      final accessKey = await AppUtils.getAccessKey();
      print('🔑 Access key retrieved');

      final url = Uri.parse('$baseUrl/student-enrollment/emi-preview/');
      print('🌐 URL: $url');

      print('📤 Payload: $payload');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessKey',
        },
        body: json.encode(payload),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ JSON parsed successfully');
        return EmiPreviewResponse.fromJson(jsonData);
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to load EMI preview: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in fetchEmiPreview: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }
}

// ==================== MODEL CLASSES ====================

class EmiPlan {
  final String id;
  final String name;
  final String description;
  final int installmentCount;
  final int installmentFrequencyDays;
  final String installmentFrequencyReadable;
  final int firstEmiAfterDays;
  final double minimumAmount;
  final double maximumAmount;
  final bool isActive;
  final int planDurationDays;
  final double planDurationMonths;

  EmiPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.installmentCount,
    required this.installmentFrequencyDays,
    required this.installmentFrequencyReadable,
    required this.firstEmiAfterDays,
    required this.minimumAmount,
    required this.maximumAmount,
    required this.isActive,
    required this.planDurationDays,
    required this.planDurationMonths,
  });

  factory EmiPlan.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing EmiPlan from JSON: $json');

    // Helper function to safely parse double values
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    // Helper function to safely parse int values
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    // Check all possible ID fields
    String planId = '';
    if (json.containsKey('id')) {
      planId = json['id']?.toString() ?? '';
      print('   Found "id" field: "$planId"');
    }
    if (json.containsKey('plan_id')) {
      planId = json['plan_id']?.toString() ?? '';
      print('   Found "plan_id" field: "$planId"');
    }
    if (json.containsKey('emi_plan_id')) {
      planId = json['emi_plan_id']?.toString() ?? '';
      print('   Found "emi_plan_id" field: "$planId"');
    }

    // If still empty, try to get from any field that might contain ID
    if (planId.isEmpty) {
      json.forEach((key, value) {
        if (key.toLowerCase().contains('id') && value != null) {
          print('   Possible ID field: "$key" = "$value"');
          if (planId.isEmpty) {
            planId = value.toString();
          }
        }
      });
    }

    final emiPlan = EmiPlan(
      id: planId,
      name: json['plan_name'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      installmentCount: parseInt(json['installment_count']),
      installmentFrequencyDays: parseInt(json['installment_frequency_days']),
      installmentFrequencyReadable:
          json['installment_frequency_readable'] ?? 'Monthly',
      firstEmiAfterDays: parseInt(json['first_emi_after_days']),
      minimumAmount: parseDouble(json['minimum_amount']),
      maximumAmount: parseDouble(json['maximum_amount']),
      isActive: json['is_active'] ?? true,
      planDurationDays: parseInt(json['plan_duration_days']),
      planDurationMonths: parseDouble(json['plan_duration_months']),
    );

    print('✅ Parsed EmiPlan - ID: "${emiPlan.id}", Name: "${emiPlan.name}"');
    return emiPlan;
  }
}

class EmiPreviewResponse {
  final String status;
  final String message;
  final String previewTimestamp;
  final EmiPlanDetails emiPlanDetails;
  final EmiPreview emiPreview;
  final InstallmentBreakdown installmentBreakdown;
  final NextSteps nextSteps;

  EmiPreviewResponse({
    required this.status,
    required this.message,
    required this.previewTimestamp,
    required this.emiPlanDetails,
    required this.emiPreview,
    required this.installmentBreakdown,
    required this.nextSteps,
  });

  factory EmiPreviewResponse.fromJson(Map<String, dynamic> json) {
    return EmiPreviewResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      previewTimestamp: json['preview_timestamp'] ?? '',
      emiPlanDetails: EmiPlanDetails.fromJson(json['emi_plan_details'] ?? json),
      emiPreview: EmiPreview.fromJson(json['emi_preview'] ?? json),
      installmentBreakdown: InstallmentBreakdown.fromJson(
        json['installment_breakdown'] ?? json,
      ),
      nextSteps: NextSteps.fromJson(json['next_steps'] ?? {}),
    );
  }
}

class EmiPlanDetails {
  final String planName;
  final String description;
  final int installmentCount;
  final int installmentFrequencyDays;
  final String installmentFrequencyReadable;
  final int firstEmiAfterDays;
  final double minimumAmount;
  final double maximumAmount;
  final bool isActive;
  final int planDurationDays;
  final double planDurationMonths;

  EmiPlanDetails({
    required this.planName,
    required this.description,
    required this.installmentCount,
    required this.installmentFrequencyDays,
    required this.installmentFrequencyReadable,
    required this.firstEmiAfterDays,
    required this.minimumAmount,
    required this.maximumAmount,
    required this.isActive,
    required this.planDurationDays,
    required this.planDurationMonths,
  });

  factory EmiPlanDetails.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    return EmiPlanDetails(
      planName: json['plan_name'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      installmentCount: parseInt(json['installment_count']),
      installmentFrequencyDays: parseInt(json['installment_frequency_days']),
      installmentFrequencyReadable:
          json['installment_frequency_readable'] ?? 'Monthly',
      firstEmiAfterDays: parseInt(json['first_emi_after_days']),
      minimumAmount: parseDouble(json['minimum_amount']),
      maximumAmount: parseDouble(json['maximum_amount']),
      isActive: json['is_active'] ?? true,
      planDurationDays: parseInt(json['plan_duration_days']),
      planDurationMonths: parseDouble(json['plan_duration_months']),
    );
  }
}

class EmiPreview {
  final String emiPlanName;
  final int installmentCount;
  final double totalEmiAmount;
  final double roundingDifference;
  final String firstEmiDate;
  final String lastEmiDate;
  final String projectedCompletionDate;
  final int installmentFrequencyDays;
  final String roundingFactor;
  final String calculationFormula;
  final bool completesBeforeBatchEnds;

  EmiPreview({
    required this.emiPlanName,
    required this.installmentCount,
    required this.totalEmiAmount,
    required this.roundingDifference,
    required this.firstEmiDate,
    required this.lastEmiDate,
    required this.projectedCompletionDate,
    required this.installmentFrequencyDays,
    required this.roundingFactor,
    required this.calculationFormula,
    required this.completesBeforeBatchEnds,
  });

  factory EmiPreview.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    return EmiPreview(
      emiPlanName: json['emi_plan_name'] ?? json['plan_name'] ?? '',
      installmentCount: parseInt(json['installment_count']),
      totalEmiAmount: parseDouble(json['total_emi_amount'] ?? json['amount']),
      roundingDifference: parseDouble(json['rounding_difference']),
      firstEmiDate: json['first_emi_date'] ?? '',
      lastEmiDate: json['last_emi_date'] ?? '',
      projectedCompletionDate: json['projected_completion_date'] ?? '',
      installmentFrequencyDays: parseInt(json['installment_frequency_days']),
      roundingFactor: json['rounding_factor'] ?? '',
      calculationFormula: json['calculation_formula'] ?? '',
      completesBeforeBatchEnds: json['completes_before_batch_ends'] ?? true,
    );
  }
}

class InstallmentBreakdown {
  final List<Installment> schedule;
  final RoundingDetails roundingDetails;

  InstallmentBreakdown({required this.schedule, required this.roundingDetails});

  factory InstallmentBreakdown.fromJson(Map<String, dynamic> json) {
    return InstallmentBreakdown(
      schedule: (json['schedule'] as List? ?? [])
          .map((item) => Installment.fromJson(item))
          .toList(),
      roundingDetails: RoundingDetails.fromJson(json['rounding_details'] ?? {}),
    );
  }
}

class Installment {
  final int installmentNumber;
  final String dueDate;
  final double amount;
  final String formattedDueDate;
  final bool isFirstInstallment;
  final bool isLastInstallment;
  final bool roundedToHundred;

  Installment({
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.formattedDueDate,
    required this.isFirstInstallment,
    required this.isLastInstallment,
    required this.roundedToHundred,
  });

  factory Installment.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    return Installment(
      installmentNumber: parseInt(json['installment_number']),
      dueDate: json['due_date'] ?? '',
      amount: parseDouble(json['amount']),
      formattedDueDate: json['formatted_due_date'] ?? json['due_date'] ?? '',
      isFirstInstallment: json['is_first_installment'] ?? false,
      isLastInstallment: json['is_last_installment'] ?? false,
      roundedToHundred: json['rounded_to_hundred'] ?? false,
    );
  }
}

class RoundingDetails {
  final bool roundingApplied;
  final String roundingFactor;
  final String methodology;
  final List<String> benefits;

  RoundingDetails({
    required this.roundingApplied,
    required this.roundingFactor,
    required this.methodology,
    required this.benefits,
  });

  factory RoundingDetails.fromJson(Map<String, dynamic> json) {
    return RoundingDetails(
      roundingApplied: json['rounding_applied'] ?? false,
      roundingFactor: json['rounding_factor'] ?? '',
      methodology: json['methodology'] ?? '',
      benefits: List<String>.from(json['benefits'] ?? []),
    );
  }
}

class NextSteps {
  final List<String> importantNotes;

  NextSteps({required this.importantNotes});

  factory NextSteps.fromJson(Map<String, dynamic> json) {
    return NextSteps(
      importantNotes: List<String>.from(json['important_notes'] ?? []),
    );
  }
}
