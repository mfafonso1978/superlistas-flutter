// lib/domain/entities/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl; // <<< MUDANÇA AQUI: Adicionado campo para a foto

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl, // <<< MUDANÇA AQUI: Adicionado ao construtor
  });
}