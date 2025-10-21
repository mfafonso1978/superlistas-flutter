// lib/domain/entities/shopping_list.dart

import 'dart:convert';
import 'package:superlistas/data/models/shopping_list_model.dart';
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

  // <<< CORREÇÃO APLICADA AQUI >>>
  factory ShoppingList.fromRichMap(Map<String, dynamic> map) {
    // O mapa que vem do 'getRichShoppingListsForUser' é plano.
    // Primeiro, criamos o ShoppingListModel a partir do mapa plano.
    final listModel = ShoppingListModel.fromDbMap(map);

    // Agora, usamos os dados do modelo e os dados "enriquecidos" do mapa raiz.
    List<Member> memberList = (listModel.memberIds)
        .map((uid) => Member(uid: uid, name: 'Carregando...'))
        .toList();

    return ShoppingList(
      id: listModel.id,
      name: listModel.name,
      creationDate: listModel.creationDate,
      isArchived: listModel.isArchived,
      budget: listModel.budget,
      ownerId: listModel.ownerId,
      members: memberList,
      totalItems: (map['totalItems'] as int?) ?? 0,
      checkedItems: (map['checkedItems'] as int?) ?? 0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

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