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
    };
  }

  // Método para crear una copia con cambios
  PetModel copyWith({int? likes, int? comments, int? shares, bool? isLiked}) {
    return PetModel(
      id: this.id,
      name: this.name,
      description: this.description,
      imageUrls: this.imageUrls,
      species: this.species,
      breed: this.breed,
      age: this.age,
      adoptionStatus: this.adoptionStatus,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      adopcion: this.adopcion,
      apoyo: this.apoyo,
    );
  }
}
