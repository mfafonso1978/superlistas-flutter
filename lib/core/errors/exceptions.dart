// lib/core/errors/exceptions.dart

// (Este arquivo pode ter outras exceções, mantenha-as)
// Adicione estas duas no final do arquivo:

class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException({this.message = 'Usuário não encontrado.'});
}

class PasswordUpdateException implements Exception {
  final String message;
  PasswordUpdateException({this.message = 'Falha ao atualizar a senha.'});
}