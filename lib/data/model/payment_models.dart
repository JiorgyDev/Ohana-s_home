// lib/models/payment_models.dart

/// Modelo para donaciones únicas (Apoyo)
class PaymentHistory {
  final String id;
  final double amount;
  final String description;
  final String status; // 'succeeded', 'pending', 'failed'
  final DateTime createdAt;

  PaymentHistory({
    required this.id,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? 'Donación',
      status: json['status'] ?? 'succeeded',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'amount': amount,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper para formatear el monto
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  // Helper para formatear la fecha
  String get formattedDate {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  // Helper para el estado
  String get statusText {
    switch (status) {
      case 'succeeded':
        return '✅ Completado';
      case 'pending':
        return '⏳ Pendiente';
      case 'failed':
        return '❌ Fallido';
      default:
        return status;
    }
  }
}

/// Modelo para suscripción general mensual ($5/$10/$60/$150)
class SubscriptionInfo {
  final String plan; // '5', '10', '60', '150'
  final String status; // 'active', 'canceled', 'past_due'
  final DateTime? startDate;
  final DateTime? nextPayment;
  final DateTime? canceledAt;

  SubscriptionInfo({
    required this.plan,
    required this.status,
    this.startDate,
    this.nextPayment,
    this.canceledAt,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: json['plan']?.toString() ?? '5',
      status: json['status'] ?? 'active',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      nextPayment: json['nextPayment'] != null
          ? DateTime.parse(json['nextPayment'])
          : null,
      canceledAt: json['canceledAt'] != null
          ? DateTime.parse(json['canceledAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'nextPayment': nextPayment?.toIso8601String(),
      'canceledAt': canceledAt?.toIso8601String(),
    };
  }

  // Helper para el nombre del plan
  String get planName {
    switch (plan) {
      case '5':
        return 'Granito de arena';
      case '10':
        return 'Luz de esperanza';
      case '60':
        return 'Ángel de la guarda';
      case '150':
        return 'Corazón dorado';
      default:
        return 'Plan $plan';
    }
  }

  // Helper para el monto formateado
  String get formattedAmount => '\$$plan USD/mes';

  // Helper para la fecha formateada
  String get formattedStartDate {
    if (startDate == null) return 'N/A';
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${startDate!.day} ${months[startDate!.month - 1]} ${startDate!.year}';
  }

  String get formattedNextPayment {
    if (nextPayment == null) return 'N/A';
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${nextPayment!.day} ${months[nextPayment!.month - 1]} ${nextPayment!.year}';
  }

  // Helper para el estado
  String get statusText {
    switch (status) {
      case 'active':
        return '✅ Activa';
      case 'canceled':
        return '❌ Cancelada';
      case 'past_due':
        return '⚠️ Pago vencido';
      default:
        return status;
    }
  }

  bool get isActive => status == 'active';
}

/// Modelo para adopción mensual ($5/$10/$20)
class AdoptionInfo {
  final String id;
  final String plan; // '5', '10', '20'
  final String? petId;
  final String? petName;
  final String? petImage;
  final String status; // 'active', 'canceled'
  final DateTime? startDate;
  final DateTime? nextPayment;
  final DateTime? canceledAt;

  AdoptionInfo({
    required this.id,
    required this.plan,
    this.petId,
    this.petName,
    this.petImage,
    required this.status,
    this.startDate,
    this.nextPayment,
    this.canceledAt,
  });

  factory AdoptionInfo.fromJson(Map<String, dynamic> json) {
    return AdoptionInfo(
      id: json['_id'] ?? '',
      plan: json['plan']?.toString() ?? '5',
      petId: json['petId']?['_id'] ?? json['petId'],
      petName: json['petId']?['name'] ?? json['petName'] ?? 'Mascota',
      petImage: json['petId']?['imageUrls']?[0] ?? json['petImage'],
      status: json['status'] ?? 'active',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      nextPayment: json['nextPayment'] != null
          ? DateTime.parse(json['nextPayment'])
          : null,
      canceledAt: json['canceledAt'] != null
          ? DateTime.parse(json['canceledAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'plan': plan,
      'petId': petId,
      'petName': petName,
      'petImage': petImage,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'nextPayment': nextPayment?.toIso8601String(),
      'canceledAt': canceledAt?.toIso8601String(),
    };
  }

  // Helper para el nombre del plan
  String get planName {
    switch (plan) {
      case '5':
        return 'Plan Guardián';
      case '10':
        return 'Plan Protector';
      case '20':
        return 'Plan Ángel';
      default:
        return 'Plan $plan';
    }
  }

  // Helper para el monto formateado
  String get formattedAmount => '\$$plan USD/mes';

  // Helper para la fecha formateada
  String get formattedStartDate {
    if (startDate == null) return 'N/A';
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${startDate!.day} ${months[startDate!.month - 1]} ${startDate!.year}';
  }

  String get formattedNextPayment {
    if (nextPayment == null) return 'N/A';
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${nextPayment!.day} ${months[nextPayment!.month - 1]} ${nextPayment!.year}';
  }

  // Helper para el estado
  String get statusText {
    switch (status) {
      case 'active':
        return '✅ Activa';
      case 'canceled':
        return '❌ Cancelada';
      case 'past_due':
        return '⚠️ Pago vencido';
      default:
        return status;
    }
  }

  bool get isActive => status == 'active';
}

/// Modelo para agrupar todo el historial de pagos
class PaymentHistoryData {
  final List<PaymentHistory> donations;
  final SubscriptionInfo? generalSubscription;
  final List<AdoptionInfo> adoptions;

  PaymentHistoryData({
    required this.donations,
    this.generalSubscription,
    required this.adoptions,
  });

  factory PaymentHistoryData.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryData(
      donations:
          (json['donations'] as List<dynamic>?)
              ?.map((e) => PaymentHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generalSubscription: json['generalSubscription'] != null
          ? SubscriptionInfo.fromJson(
              json['generalSubscription'] as Map<String, dynamic>,
            )
          : null,
      adoptions:
          (json['adoptions'] as List<dynamic>?)
              ?.map((e) => AdoptionInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'donations': donations.map((e) => e.toJson()).toList(),
      'generalSubscription': generalSubscription?.toJson(),
      'adoptions': adoptions.map((e) => e.toJson()).toList(),
    };
  }

  // Helpers
  bool get hasDonations => donations.isNotEmpty;
  bool get hasActiveSubscription => generalSubscription?.isActive ?? false;
  bool get hasAdoptions => adoptions.isNotEmpty;
  int get activeAdoptionsCount => adoptions.where((a) => a.isActive).length;
}
