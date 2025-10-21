// lib/data/models/shopping_list_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListModel {
  final String id;
  final String name;
  final DateTime creationDate;
  final bool isArchived;
  final double? budget;          // pode ser nulo
  final String ownerId;
  final List<String> memberIds;

  ShoppingListModel({
    required this.id,
    required this.name,
    required this.creationDate,
    required this.isArchived,
    required this.budget,
    required this.ownerId,
    required this.memberIds,
  });

  /* -------- CONVERSORES -------- */

  /// Firestore/JSON → Model
  factory ShoppingListModel.fromMap(Map<String, dynamic> map) {
    // Lógica robusta para lidar com datas do Firestore (Timestamp) ou de JSON (String)
    DateTime parsedDate;
    final dateValue = map['creationDate'];
    if (dateValue is Timestamp) {
      parsedDate = dateValue.toDate();
    } else if (dateValue is String) {
      parsedDate = DateTime.parse(dateValue);
    } else {
      // Fallback seguro caso o campo esteja ausente ou nulo
      parsedDate = DateTime.now();
    }

    return ShoppingListModel(
      id: map['id'] as String,
      name: map['name'] as String,
      creationDate: parsedDate, // Usa a data já convertida
      isArchived: map['isArchived'] is bool
          ? map['isArchived'] as bool
          : (map['isArchived'] as int? ?? 0) == 1,
      budget: (map['budget'] as num?)?.toDouble(),
      ownerId: map['ownerId'] as String,
      memberIds: map['memberIds'] is List
          ? List<String>.from(map['memberIds'])
          : ((map['memberIds'] as String?)?.split(',') ?? <String>[]),
    );
  }

  // <<< CORREÇÃO APLICADA AQUI >>>
  /// SQLite → Model
  factory ShoppingListModel.fromDbMap(Map<String, dynamic> map) {
    return ShoppingListModel(
      id: map['id'] as String,
      name: map['name'] as String,
      creationDate: DateTime.parse(map['creationDate'] as String),
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      budget: (map['budget'] as num?)?.toDouble(),
      ownerId: map['ownerId'] as String,
      // Voltando a usar a coluna correta "members"
      memberIds: (map['members'] as String?)?.split(',') ?? <String>[],
    );
  }

  /* -------- SAÍDA -------- */

  // <<< CORREÇÃO APLICADA AQUI >>>
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'name': name,
      'creationDate': creationDate.toIso8601String(),
      'isArchived': isArchived ? 1 : 0,
      'budget': budget,
      'ownerId': ownerId,
      // Voltando a usar a coluna correta "members"
      'members': memberIds.join(','),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'name': name,
      'creationDate': creationDate.toIso8601String(),
      'isArchived': isArchived,
      'budget': budget,
      'ownerId': ownerId,
      'memberIds': memberIds,
    };
  }
}