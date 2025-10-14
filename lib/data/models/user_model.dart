// lib/data/models/user_model.dart

import 'package:superlistas/domain/entities/user.dart';

class UserModel extends User {
  final String? password; // Apenas para o DB local

  UserModel({
    required String id,
    required String name,
    required String email,
    String? photoUrl,
    this.password,
  }) : super(
    id: id,
    name: name,
    email: email,
    photoUrl: photoUrl,
  );

  // Construtor para ler do banco de dados local (SQlite)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'] ?? 'Nome Desconhecido',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      password: map['password'],
    );
  }

  // Construtor para ler do Firestore
  factory UserModel.fromFirestoreMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? 'Nome Desconhecido',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  // Método para salvar no banco de dados local (SQlite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'password': password,
    };
  }
}