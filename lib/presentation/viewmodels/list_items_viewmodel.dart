import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/errors/exceptions.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';
import 'package:superlistas/domain/entities/user_product.dart';
import 'package:uuid/uuid.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/presentation/providers/providers.dart';

class ListItemsViewModel extends StateNotifier<AsyncValue<List<Item>>> {
  final Ref ref;
  final ShoppingListRepository _repository;
  final String _shoppingListId;

  ListItemsViewModel(this.ref, this._repository, this._shoppingListId)
      : super(const AsyncValue.data([]));

  Future<UserProduct?> processBarcode(String barcode) async {
    final product = await _repository.findProductByBarcode(barcode);
    return product;
  }

  Future<void> _invalidateDependentProviders() async {
    try {
      final list = await _repository.getShoppingListById(_shoppingListId);
      final userId = list.ownerId;

      ref.invalidate(listItemsStreamProvider(_shoppingListId));
      ref.invalidate(shoppingListsStreamProvider(userId));
      ref.invalidate(dashboardViewModelProvider(userId));
      ref.invalidate(singleListProvider(_shoppingListId));
    } catch (_) {
      // Ignora erros
    }
  }

  Future<void> addItem(Item item, {String? scannedBarcode}) async {
    try {
      // ⚠️ BUSCA OS ITENS DIRETAMENTE DO REPOSITÓRIO (não do stream)
      final currentItems = await _repository.getItems(_shoppingListId);

      // 1️⃣ VERIFICA DUPLICATA POR CÓDIGO DE BARRAS (se fornecido)
      if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
        final isDuplicateBarcode = currentItems.any(
              (existingItem) =>
          existingItem.barcode != null &&
              existingItem.barcode!.isNotEmpty &&
              existingItem.barcode == scannedBarcode &&
              !existingItem.isChecked, // Ignora itens já marcados como comprados
        );

        if (isDuplicateBarcode) {
          throw DuplicateItemException(
            'Este produto (código de barras: $scannedBarcode) já está na lista.',
          );
        }
      }

      // 2️⃣ VERIFICA DUPLICATA POR NOME
      final normalizedNewItemName = item.name.trim().toLowerCase();
      if (normalizedNewItemName.isEmpty) {
        throw DuplicateItemException('O nome do item não pode estar vazio.');
      }

      final isDuplicateName = currentItems.any(
            (existingItem) =>
        existingItem.name.trim().toLowerCase() == normalizedNewItemName &&
            !existingItem.isChecked, // Ignora itens já marcados como comprados
      );

      if (isDuplicateName) {
        throw DuplicateItemException(
          'Um item com o nome "${item.name.trim()}" já existe na lista.',
        );
      }

      // 3️⃣ CRIA O ITEM
      final itemToAdd = Item(
        id: item.id.isEmpty ? const Uuid().v4() : item.id,
        name: item.name.trim(),
        category: item.category,
        price: item.price,
        quantity: item.quantity,
        unit: item.unit,
        isChecked: false, // Sempre começa desmarcado
        notes: item.notes,
        completionDate: null,
        barcode: scannedBarcode,
      );

      // 4️⃣ SALVA NO REPOSITÓRIO
      final list = await _repository.getShoppingListById(_shoppingListId);
      final userId = list.ownerId;

      await _repository.createItem(itemToAdd, _shoppingListId);

      // 5️⃣ SALVA O PRODUTO NO HISTÓRICO (se tiver código de barras)
      if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
        final productToSave = UserProduct(
          id: '',
          userId: userId,
          barcode: scannedBarcode,
          productName: itemToAdd.name,
          price: itemToAdd.price,
          unit: itemToAdd.unit,
          categoryId: itemToAdd.category.id,
          notes: itemToAdd.notes,
          createdAt: DateTime.now(),
        );
        await _repository.saveProduct(productToSave);
      }

      // 6️⃣ INVALIDA OS PROVIDERS
      await _invalidateDependentProviders();

    } catch (e) {
      if (e is! DuplicateItemException) {
        await _invalidateDependentProviders();
      }
      rethrow;
    }
  }

  Future<void> updateItem(Item item) async {
    final itemToUpdate = item.copyWith(
      completionDate:
      item.isChecked ? (item.completionDate ?? DateTime.now()) : null,
    );

    try {
      await _repository.updateItem(itemToUpdate, _shoppingListId);
      await _invalidateDependentProviders();
    } catch (e) {
      await _invalidateDependentProviders();
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      final list = await _repository.getShoppingListById(_shoppingListId);
      final userId = list.ownerId;

      await _repository.deleteItem(itemId, _shoppingListId, userId);
      await _invalidateDependentProviders();
    } catch (e) {
      await _invalidateDependentProviders();
      rethrow;
    }
  }
}
