// lib/data/models/shopping_list_model.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:superlistas/domain/entities/member.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';

class ShoppingListModel extends ShoppingList {
  final List<String> memberIds;

  ShoppingListModel({
    required String id,
    required String name,
    required DateTime creationDate,
    bool isArchived = false,
    double? budget,
    required String ownerId,
    required this.memberIds,
    List<Member> members = const [],
  }) : super(
    id: id,
    name: name,
    creationDate: creationDate,
    isArchived: isArchived,
    budget: budget,
    ownerId: ownerId,
    members: members,
  );

  // Construtor para ler do Firestore ou DB Local
  factory ShoppingListModel.fromMap(Map<String, dynamic> map) {
    List<String> membersList = [];
    if (map['members'] is String) {
      // Vem do DB local como uma string JSON
      membersList = List<String>.from(jsonDecode(map['members']));
    } else if (map['members'] is List) {
      // Vem do Firestore como uma lista
      membersList = List<String>.from(map['members'] ?? []);
    }

    return ShoppingListModel(
      id: map['id'],
      name: map['name'],
      creationDate: map['creationDate'] is String
          ? DateTime.parse(map['creationDate'])
          : (map['creationDate'] as Timestamp).toDate(),
      isArchived: (map['isArchived'] is int)
          ? map['isArchived'] == 1
          : map['isArchived'],
      budget: map['budget'],
      ownerId: map['ownerId'] ?? map['userId'],
      memberIds: membersList,
    );
  }

  // Método para salvar no Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'name': name,
      'creationDate': Timestamp.fromDate(creationDate),
      'isArchived': isArchived,
      'budget': budget,
      'ownerId': ownerId,
      'members': memberIds,
    };
  }

  // Método para salvar no DB Local
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'name': name,
      'creationDate': creationDate.toIso8601String(),
      'isArchived': isArchived ? 1 : 0,
      'budget': budget,
      'ownerId': ownerId,
      'members': jsonEncode(memberIds), // Salva a lista como string JSON
    };
  }
}