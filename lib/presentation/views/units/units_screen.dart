// lib/presentation/views/units/units_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/ui/widgets/app_background.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/presentation/providers/providers.dart';

class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsViewModelProvider);
    final scheme = Theme.of(context).colorScheme;

    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final addUnitEnabled = remoteConfig.isAddUnitEnabled;
    final editUnitEnabled = remoteConfig.isEditUnitEnabled;
    final deleteUnitEnabled = remoteConfig.isDeleteUnitEnabled;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: Text('Gerenciar Unidades'),
      ),
      body: Stack(
        children: [
          AppBackground(),
          SafeArea(
            child: unitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
              data: (units) => ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return GlassCard(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(unit, style: TextStyle(color: scheme.onSurface)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (editUnitEnabled)
                            IconButton(
                              icon: Icon(Icons.edit_note_rounded, color: scheme.onSurfaceVariant),
                              onPressed: () => _showAddOrEditUnitDialog(context, ref, unit: unit),
                            ),
                          if (deleteUnitEnabled)
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: scheme.error),
                              onPressed: () => _showDeleteConfirmationDialog(context, ref, unit),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: addUnitEnabled ? FloatingActionButton(
        onPressed: () => _showAddOrEditUnitDialog(context, ref),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  void _showAddOrEditUnitDialog(BuildContext context, WidgetRef ref, {String? unit}) {
    final isEditMode = unit != null;
    final controller = TextEditingController(text: unit);
    final formKey = GlobalKey<FormState>();

    showGlassDialog(
      context: context,
      title: Text(isEditMode ? 'Editar Unidade' : 'Nova Unidade'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da unidade (ex: cx, fardo)'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'O nome não pode ser vazio.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              if (isEditMode) {
                ref.read(unitsViewModelProvider.notifier).updateUnit(unit!, controller.text);
              } else {
                ref.read(unitsViewModelProvider.notifier).addUnit(controller.text);
              }
              Navigator.pop(context);
            }
          },
          child: const Text('Salvar'),
        )
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, String unit) {
    showGlassDialog(
      context: context,
      title: const Text('Excluir Unidade'),
      content: Text('Tem certeza que deseja excluir a unidade "$unit"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            ref.read(unitsViewModelProvider.notifier).deleteUnit(unit);
            Navigator.of(context).pop();
          },
          child: const Text('Excluir'),
        )
      ],
    );
  }
}