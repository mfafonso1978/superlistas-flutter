// lib/core/ui/widgets/glass_dialog.dart
//
// Dialog “glass” com:
// - NÃO encolhe com o teclado (só sobe o necessário)
// - Cabeçalho (ícone + título) centralizado e colado no topo
// - Botões Cancelar (azul) e Salvar (teal) lado a lado
// - Parâmetros completos para personalização, incluindo cor do título por tema

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required Widget title,         // Passe um Row(Icon + Text) aqui (não fixe cor/tamanho)
  required Widget content,       // Passe seu formulário/Widgets aqui
  required List<Widget> actions, // Ex.: [TextButton(...), ElevatedButton(...)]

  // ============================
  //   PARÂMETROS AJUSTÁVEIS
  // ============================

  // Fundo/fechamento:
  bool barrierDismissible = true,                 // AJUSTE AQUI: permitir fechar tocando fora
  Color barrierTint = Colors.black38,             // AJUSTE AQUI: véu de fundo

  // Tamanho/posicionamento do CARD:
  double maxHeightFraction = 0.40,                // <<< REDUZIDO DRASTICAMENTE (40% da tela)
  double minHeight = 200.0,                       // AJUSTE AQUI: altura mínima (dp)
  double maxWidth = 320.0,                        // AJUSTE AQUI: largura máxima (dp)
  double minWidth = 260.0,                        // AJUSTE AQUI: largura mínima (dp)
  EdgeInsets cardInsets =
  const EdgeInsets.symmetric(horizontal: 24, vertical: 24), // AJUSTE AQUI: margem do card na tela

  // Vidro/raio:
  double cardBorderRadius = 24.0,                 // AJUSTE AQUI: raio das bordas do card
  double blurSigma = 10.0,                        // AJUSTE AQUI: intensidade do blur de vidro
  double backgroundAlphaLight = 0.85,             // AJUSTE AQUI: opacidade no tema claro
  double backgroundAlphaDark  = 0.80,             // AJUSTE AQUI: opacidade no tema escuro

  // Inteligência contra topo/teclado:
  double topSafeExtra = 12.0,                     // AJUSTE AQUI: folga mínima do topo da TELA
  double bottomSafe  = 20.0,                      // AJUSTE AQUI: folga mínima acima do teclado

  // Cabeçalho (título + ícone):
  bool centerTitle = true,                        // AJUSTE AQUI: centraliza o cabeçalho
  double titleFontSize = 24.0,                    // AJUSTE AQUI: tamanho do texto do título
  FontWeight titleFontWeight = FontWeight.w700,   // AJUSTE AQUI: peso do título

  // >>> Cor do título por tema
  Color? titleColor,                              // Força uma cor única para claro/escuro (opcional)
  Color titleColorLight = Colors.black,           // Cor no tema claro (padrão preto)
  Color titleColorDark  = Colors.white,           // Cor no tema escuro (padrão branco)

  EdgeInsets titlePadding =
  const EdgeInsets.fromLTRB(16, 0, 16, 0),   // padding do título (top=0 cola no topo)
  double titleBottomGap = 28.0,                   // espaço logo abaixo do título
  double titleIconSize = 42.0,                    // tamanho do ícone do título
  Color titleIconColor = Colors.black54,          // cor do ícone do título

  // Conteúdo:
  EdgeInsets contentPadding =
  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),

  // Rodapé (ações):
  EdgeInsets actionsPadding =
  const EdgeInsets.fromLTRB(16, 12, 16, 16),
  bool actionsHorizontal = true,                  // true=lado a lado; false=empilhado
  double actionsGap = 12.0,                       // espaço entre botões
  double actionHeight = 44.0,                     // altura dos botões
  double actionRadius = 12.0,                     // raio dos botões
  Color cancelColor = Colors.blue,                // cor do botão Cancelar
  Color saveColor   = Colors.teal,                // cor do botão Salvar
  Color actionTextColor = Colors.white,           // cor do texto/ícone dos botões
  bool swapActionsOrder = false,                  // inverte ordem (Salvar | Cancelar)
}) {
  assert(
  maxHeightFraction > 0 && maxHeightFraction <= 0.95,
  'maxHeightFraction deve estar entre (0, 0.95]',
  );

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierTint,
    useRootNavigator: true,
    useSafeArea: false, // controlamos manualmente
    builder: (context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final media  = MediaQuery.of(context);
          final theme  = Theme.of(context);
          final scheme = theme.colorScheme;

          // ===== Cálculo de altura/largura e teclado =====
          final screenH    = constraints.maxHeight;
          final keyboard   = media.viewInsets.bottom;
          final availableH = screenH - cardInsets.vertical;

          final targetH = math.max(
            minHeight,
            math.min(availableH, screenH * maxHeightFraction),
          );

          final freeEachSide = (availableH - targetH) / 2.0;
          final double topSafe = media.padding.top + topSafeExtra;

          final rawLift = math.max(0.0, keyboard + bottomSafe - freeEachSide);
          final allowedLiftTopBound = math.max(0.0, freeEachSide - topSafe);
          final lift = rawLift.clamp(0.0, allowedLiftTopBound);

          final maxW = math.min(maxWidth, constraints.maxWidth - cardInsets.horizontal);
          final minW = math.min(minWidth, maxW);

          // ===== Fundo “glass” =====
          final bool isDark = theme.brightness == Brightness.dark;
          final Color baseColor = (isDark ? scheme.surface : Colors.white)
              .withOpacity(isDark ? backgroundAlphaDark : backgroundAlphaLight);

          // ===== Cabeçalho =====
          Widget buildTitle(Widget child) {
            final Color effectiveTitleColor =
                titleColor ?? (isDark ? titleColorDark : titleColorLight);

            final styled = DefaultTextStyle(
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: titleFontWeight,
                color: effectiveTitleColor,
              ),
              child: IconTheme.merge(
                data: IconThemeData(
                  size: titleIconSize,
                  color: titleIconColor,
                ),
                child: child,
              ),
            );
            if (centerTitle) {
              return Center(child: IntrinsicWidth(child: styled));
            }
            return styled;
          }

          // ===== Helpers para ações coloridas =====
          VoidCallback? extractOnPressed(Widget w) {
            if (w is TextButton)     return w.onPressed;
            if (w is ElevatedButton) return w.onPressed;
            if (w is OutlinedButton) return w.onPressed;
            return null;
          }

          Widget extractChild(Widget w) {
            if (w is TextButton)     return w.child ?? const SizedBox.shrink();
            if (w is ElevatedButton) return w.child ?? const SizedBox.shrink();
            if (w is OutlinedButton) return w.child ?? const SizedBox.shrink();
            return w;
          }

          List<Widget> _normalizeActions(List<Widget> raw) {
            return raw.where((w) => w is! SizedBox && w is! Spacer).toList();
          }

          Widget coloredAction({
            required Color color,
            required Widget child,
            required VoidCallback? onTap,
          }) {
            return Material(
              color: color,
              borderRadius: BorderRadius.circular(actionRadius),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(actionRadius),
                child: Center(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: actionTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(color: actionTextColor),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          }

          Widget buildActionsBar(List<Widget> actsRaw) {
            final acts = _normalizeActions(actsRaw);

            if (actionsHorizontal) {
              if (acts.length == 2) {
                final left  = swapActionsOrder ? acts[1] : acts[0]; // Cancelar
                final right = swapActionsOrder ? acts[0] : acts[1]; // Salvar
                return Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: actionHeight,
                        child: coloredAction(
                          color: cancelColor,
                          child: extractChild(left),
                          onTap: extractOnPressed(left),
                        ),
                      ),
                    ),
                    SizedBox(width: actionsGap),
                    Expanded(
                      child: SizedBox(
                        height: actionHeight,
                        child: coloredAction(
                          color: saveColor,
                          child: extractChild(right),
                          onTap: extractOnPressed(right),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (acts.length >= 3) {
                final delete = acts[0];
                final left   = swapActionsOrder ? acts[2] : acts[1]; // Cancelar
                final right  = swapActionsOrder ? acts[1] : acts[2]; // Salvar
                return Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44, minWidth: 100),
                      child: SizedBox(
                        height: actionHeight,
                        child: coloredAction(
                          color: Colors.red,
                          child: extractChild(delete),
                          onTap: extractOnPressed(delete),
                        ),
                      ),
                    ),
                    SizedBox(width: actionsGap),
                    Expanded(
                      child: SizedBox(
                        height: actionHeight,
                        child: coloredAction(
                          color: cancelColor,
                          child: extractChild(left),
                          onTap: extractOnPressed(left),
                        ),
                      ),
                    ),
                    SizedBox(width: actionsGap),
                    Expanded(
                      child: SizedBox(
                        height: actionHeight,
                        child: coloredAction(
                          color: saveColor,
                          child: extractChild(right),
                          onTap: extractOnPressed(right),
                        ),
                      ),
                    ),
                  ],
                );
              }
            }

            if (!actionsHorizontal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < acts.length; i++) ...[
                    SizedBox(
                      height: actionHeight,
                      width: double.infinity,
                      child: coloredAction(
                        color: i == acts.length - 1 ? saveColor : cancelColor,
                        child: extractChild(acts[i]),
                        onTap: extractOnPressed(acts[i]),
                      ),
                    ),
                    if (i != acts.length - 1) SizedBox(height: actionsGap),
                  ]
                ],
              );
            }

            return OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              spacing: actionsGap,
              overflowSpacing: actionsGap,
              children: acts,
            );
          }

          final actionsBar = buildActionsBar(actions);

          // ===== Construção do card/dialog =====
          return MediaQuery.removeViewInsets(
            removeBottom: true, // evita “encolher” com teclado
            context: context,
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: cardInsets,
                child: Transform.translate(
                  offset: Offset(0, -lift), // sobe só o necessário
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: minW,
                      maxWidth: maxW,
                      maxHeight: targetH, // teto (conteúdo rola se passar)
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(cardBorderRadius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                        child: Container(
                          color: baseColor,
                          child: AlertDialog(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            insetPadding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(cardBorderRadius),
                            ),

                            // Cabeçalho colado no topo
                            titlePadding: titlePadding,
                            title: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildTitle(title),
                                if (titleBottomGap > 0) SizedBox(height: titleBottomGap),
                              ],
                            ),

                            // Corpo (scrollável quando necessário)
                            contentPadding: contentPadding,
                            scrollable: true,
                            content: DefaultTextStyle(
                              style: theme.dialogTheme.contentTextStyle ??
                                  theme.textTheme.bodyMedium!,
                              child: content,
                            ),

                            // Rodapé (botões)
                            actionsPadding: actionsPadding,
                            actions: [actionsBar],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
