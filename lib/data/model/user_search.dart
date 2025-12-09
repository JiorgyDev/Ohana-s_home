class UserSearch {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String? bio;

  UserSearch({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    this.bio,
  });

  factory UserSearch.fromJson(Map<String, dynamic> json) {
    return UserSearch(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Usuario',
      email: json['email'] ?? '',
      avatar:
          json['avatar'] ??
          'https://res.cloudinary.com/wooheart/image/upload/v1/default-avatar.png',
      bio: json['bio'],
    );
  }
}
