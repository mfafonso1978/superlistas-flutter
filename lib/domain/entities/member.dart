// lib/domain/entities/member.dart

class Member {
  final String uid;
  final String name;
  final String? photoUrl;

  Member({
    required this.uid,
    required this.name,
    this.photoUrl,
  });
}