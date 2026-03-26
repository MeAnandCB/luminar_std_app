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
