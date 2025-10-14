// lib/domain/entities/shopping_list.dart

import 'dart:convert';
import 'package:superlistas/domain/entities/member.dart';

class ShoppingList {
  final String id;
  final String name;
  final DateTime creationDate;
  final int totalItems;
  final int checkedItems;
  final bool isArchived;
  final double? budget;
  final double totalCost;
  final String ownerId;
  final List<Member> members;

  ShoppingList({
    required this.id,
    required this.name,
    required this.creationDate,
    this.totalItems = 0,
    this.checkedItems = 0,
    this.isArchived = false,
    this.budget,
    this.totalCost = 0.0,
    required this.ownerId,
    this.members = const [],
  });

  double get progress => totalItems > 0 ? checkedItems / totalItems : 0.0;
  bool get isCompleted => totalItems > 0 && totalItems == checkedItems;

  factory ShoppingList.fromRichMap(Map<String, dynamic> map, {List<Member>? enrichedMembers}) {
    List<dynamic> rawMemberList = [];

    if (map['members'] is String && (map['members'] as String).isNotEmpty) {
      rawMemberList = jsonDecode(map['members'] as String);
    } else if (map['members'] is List) {
      rawMemberList = map['members'];
    }

    final memberList = enrichedMembers ??
        rawMemberList
            .map((uid) => Member(uid: uid as String, name: 'Carregando...'))
            .toList();

    return ShoppingList(
      id: map['id'],
      name: map['name'],
      creationDate: DateTime.parse(map['creationDate']),
      isArchived: map['isArchived'] == 1,
      budget: map['budget'],
      ownerId: map['ownerId'] ?? map['userId'],
      members: memberList,
      totalItems: (map['totalItems'] as int?) ?? 0,
      checkedItems: (map['checkedItems'] as int?) ?? 0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // <<< MUDANÇA APLICADA AQUI: copyWith agora inclui os totais >>>
  ShoppingList copyWith({
    String? id,
    String? name,
    DateTime? creationDate,
    int? totalItems,
    int? checkedItems,
    bool? isArchived,
    double? budget,
    double? totalCost,
    String? ownerId,
    List<Member>? members,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      creationDate: creationDate ?? this.creationDate,
      totalItems: totalItems ?? this.totalItems,
      checkedItems: checkedItems ?? this.checkedItems,
      isArchived: isArchived ?? this.isArchived,
      budget: budget ?? this.budget,
      totalCost: totalCost ?? this.totalCost,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
    );
  }
}