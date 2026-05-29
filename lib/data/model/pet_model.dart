// lib/models/pet_model.dart
class PetModel {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final String species;
  final String breed;
  final int age;
  final String adoptionStatus;
  int likes;
  int comments;
  int shares;
  bool isLiked;
  final int adopcion;
  final int apoyo;
  final PetAdoptionInfo? adoptionInfo; // ✅ NUEVO (renombrado)

  PetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.species,
    required this.breed,
    required this.age,
    required this.adoptionStatus,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.isLiked,
    required this.adopcion,
    required this.apoyo,
    this.adoptionInfo, // ✅ NUEVO (renombrado)
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Sin nombre',
      description: json['description'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      species: json['species'] ?? 'unknown',
      breed: json['breed'] ?? 'unknown',
      age: json['age'] ?? 0,
      adoptionStatus: json['adoptionStatus'] ?? 'available',
      likes: json['likesCount'] ?? 0,
      comments: json['commentsCount'] ?? 0,
      shares: json['shares'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      adopcion: json['adopcion'] ?? 0,
      apoyo: json['apoyo'] ?? 0,
      adoptionInfo: json['adoptionInfo'] != null
          ? PetAdoptionInfo.fromJson(json['adoptionInfo'])
          : null, // ✅ NUEVO (renombrado)
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'imageUrls': imageUrls,
      'species': species,
      'breed': breed,
      'age': age,
      'adoptionStatus': adoptionStatus,
      'likesCount': likes,
      'commentsCount': comments,
      'shares': shares,
      'isLiked': isLiked,
      'adopcion': adopcion,
      'apoyo': apoyo,
      'adoptionInfo': adoptionInfo?.toJson(), // ✅ NUEVO
    };
  }

  PetModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? imageUrls,
    String? species,
    String? breed,
    int? age,
    String? adoptionStatus,
    int? likes,
    int? comments,
    int? shares,
    bool? isLiked,
    int? adopcion,
    int? apoyo,
    PetAdoptionInfo? adoptionInfo, // ✅ NUEVO (renombrado)
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      adoptionStatus: adoptionStatus ?? this.adoptionStatus,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      adopcion: adopcion ?? this.adopcion,
      apoyo: apoyo ?? this.apoyo,
      adoptionInfo: adoptionInfo ?? this.adoptionInfo, // ✅ NUEVO (renombrado)
    );
  }
}

// ============================================
// ✅ NUEVO: Clase para parsear adoptionInfo del pet
// ============================================
class PetAdoptionInfo {
  final String plan; // 'guardian', 'protector', 'angel'
  final double amount;
  final String? startDate;
  final String? endDate;
  final String status; // 'active', 'cancelled'
  final String? stripeSubscriptionId;

  PetAdoptionInfo({
    required this.plan,
    required this.amount,
    this.startDate,
    this.endDate,
    required this.status,
    this.stripeSubscriptionId,
  });

  factory PetAdoptionInfo.fromJson(Map<String, dynamic> json) {
    return PetAdoptionInfo(
      plan: json['plan'] ?? 'guardian',
      amount: (json['amount'] ?? 0).toDouble(),
      startDate: json['startDate'],
      endDate: json['endDate'],
      status: json['status'] ?? 'active',
      stripeSubscriptionId: json['stripeSubscriptionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'amount': amount,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'stripeSubscriptionId': stripeSubscriptionId,
    };
  }

  // Helper para obtener el nombre del plan
  String get planName {
    switch (plan) {
      case 'guardian':
        return 'Plan Guardián';
      case 'protector':
        return 'Plan Protector';
      case 'angel':
        return 'Plan Ángel';
      default:
        return 'Plan $plan';
    }
  }

  // Helper para saber si está activo
  bool get isActive => status == 'active';
}
