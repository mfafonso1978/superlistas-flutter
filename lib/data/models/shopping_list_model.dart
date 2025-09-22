import 'package:superlistas/domain/entities/shopping_list.dart';

class ShoppingListModel extends ShoppingList {
  ShoppingListModel({
    required String id,
    required String name,
    required DateTime creationDate,
    bool isArchived = false,
    double? budget,
    required String userId,
  }) : super(
    id: id,
    name: name,
    creationDate: creationDate,
    isArchived: isArchived,
    budget: budget,
    userId: userId,
  );

  factory ShoppingListModel.fromMap(Map<String, dynamic> map) {
    return ShoppingListModel(
      id: map['id'],
      name: map['name'],
      creationDate: DateTime.parse(map['creationDate']),
      isArchived: map['isArchived'] == 1,
      budget: map['budget'],
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'creationDate': creationDate.toIso8601String(),
      'isArchived': isArchived ? 1 : 0,
      'budget': budget,
      'userId': userId,
    };
  }
}