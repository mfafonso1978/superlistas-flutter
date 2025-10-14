// lib/presentation/views/shopping_lists/manage_members_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/domain/entities/member.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/presentation/providers/providers.dart';

class ManageMembersScreen extends ConsumerWidget {
  final ShoppingList list;

  const ManageMembersScreen({super.key, required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authViewModelProvider)?.id;
    final isOwner = list.ownerId == currentUserId;

    // Assista ao stream da lista para obter atualizações em tempo real
    final listAsync = ref.watch(singleListProvider(list.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Membros'),
        centerTitle: true,
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro: $error')),
        data: (updatedList) {
          return ListView.builder(
            itemCount: updatedList.members.length,
            itemBuilder: (context, index) {
              final member = updatedList.members[index];
              final bool isListOwner = member.uid == updatedList.ownerId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                  member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: member.photoUrl == null
                      ? Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  )
                      : null,
                ),
                title: Row(
                  children: [
                    Text(member.name),
                    if (isListOwner)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.verified_user,
                          color: theme.colorScheme.secondary,
                          size: 18,
                        ),
                      )
                  ],
                ),
                subtitle: Text(isListOwner ? 'Proprietário' : 'Membro'),
                trailing: (isOwner && !isListOwner)
                    ? IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: theme.colorScheme.error),
                  onPressed: () =>
                      _confirmRemoveMember(context, ref, updatedList, member),
                )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmRemoveMember(BuildContext context, WidgetRef ref,
      ShoppingList list, Member memberToRemove) async {
    final bool? confirm = await showGlassDialog<bool>(
      context: context,
      title: const Text('Remover Membro'),
      content:
      Text('Tem certeza que deseja remover "${memberToRemove.name}" da lista? Esta ação não pode ser desfeita.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remover'),
        ),
      ],
    );

    if (confirm == true && context.mounted) {
      final currentUserId = ref.read(authViewModelProvider)!.id;
      ref
          .read(shoppingListsViewModelProvider(currentUserId).notifier)
          .removeMember(listId: list.id, memberIdToRemove: memberToRemove.uid)
          .catchError((e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao remover: $e'), backgroundColor: Colors.red),
          );
        }
      });
      // A tela irá reconstruir automaticamente porque o singleListProvider será invalidado pelo ViewModel
    }
  }
}