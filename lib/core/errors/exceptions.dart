// lib/core/errors/exceptions.dart

class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException({this.message = 'Usuário não encontrado.'});
}

class PasswordUpdateException implements Exception {
  final String message;
  PasswordUpdateException({this.message = 'Falha ao atualizar a senha.'});
}

// <<< NOVO <<<
/// Lançada ao tentar adicionar um item que já existe na lista.
class DuplicateItemException implements Exception {
  final String message;
  DuplicateItemException(this.message);
}