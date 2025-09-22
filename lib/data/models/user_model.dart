import 'package:superlistas/domain/entities/user.dart';

class UserModel extends User {
  final String password; // Apenas o modelo de dados conhece a senha

  UserModel({
    required String id,
    required String name,
    required String email,
    required this.password,
  }) : super(id: id, name: name, email: email);

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
    };
  }
}