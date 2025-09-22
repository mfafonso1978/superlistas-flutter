// lib/core/ui/widgets/icon_picker_dialog.dart
import 'package:flutter/material.dart';
import 'package:superlistas/core/constants/category_icons.dart';

Future<IconData?> showIconPicker({
  required BuildContext context,
  required IconData selectedIcon,
}) {
  return showDialog<IconData>(
    context: context,
    builder: (BuildContext context) {
      return _IconPickerDialog(initialIcon: selectedIcon);
    },
  );
}

class _IconPickerDialog extends StatefulWidget {
  final IconData initialIcon;
  const _IconPickerDialog({required this.initialIcon});

  @override
  State<_IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<_IconPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
    _tabController = TabController(
      length: CategoryIcons.iconGroups.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      // Título centralizado com ícone ao lado
      titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
      title: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apps_rounded, color: scheme.secondary, size: 24),
            const SizedBox(width: 10),
            Text('Selecionar Ícone', style: theme.textTheme.titleLarge),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.only(top: 12.0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            // Aba selecionada com texto/indicador TEAL
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.teal,
              unselectedLabelColor: scheme.onSurface.withOpacity(0.7),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              indicatorColor: Colors.teal,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: CategoryIcons.iconGroups.keys
                  .map((title) => Tab(text: title))
                  .toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: CategoryIcons.iconGroups.values.map((iconList) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: iconList.length,
                    itemBuilder: (context, index) {
                      final icon = iconList[index];
                      final isSelected =
                          _selectedIcon.codePoint == icon.codePoint &&
                              _selectedIcon.fontFamily == icon.fontFamily;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIcon = icon;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.secondary.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? scheme.secondary
                                  : (isDark ? Colors.white30 : Colors.black26),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? scheme.secondary
                                : scheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      // Botões lado a lado, ambos ELEVATED:
      // - Cancelar: fundo azul, texto branco
      // - Selecionar: fundo teal, texto branco
      actions: [
        SizedBox(
          height: 44,
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop<IconData?>(null),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop<IconData?>(_selectedIcon),
                  child: const Text('Selecionar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
