// lib/core/ui/widgets/glass_dialog.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required Widget title,
  required Widget content,
  required List<Widget> actions,
  bool barrierDismissible = true,
  Color barrierTint = Colors.black38,
  double maxHeightFraction = 0.40,
  double minHeight = 200.0,
  double maxWidth = 320.0,
  double minWidth = 260.0,
  EdgeInsets cardInsets = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
  double cardBorderRadius = 24.0,
  double blurSigma = 10.0,
  double backgroundAlphaLight = 0.85,
  double backgroundAlphaDark = 0.80,
  double topSafeExtra = 12.0,
  double bottomSafe = 20.0,
  bool centerTitle = true,
  double titleFontSize = 24.0,
  FontWeight titleFontWeight = FontWeight.w700,
  Color? titleColor,
  Color titleColorLight = Colors.black,
  Color titleColorDark = Colors.white,
  EdgeInsets titlePadding = const EdgeInsets.fromLTRB(16, 0, 16, 0),
  double titleBottomGap = 28.0,
  double titleIconSize = 42.0,
  Color titleIconColor = Colors.black54,
  EdgeInsets contentPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  EdgeInsets actionsPadding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  bool actionsHorizontal = true,
  double actionsGap = 12.0,
  double actionHeight = 44.0,
  double actionRadius = 12.0,
  // ALTERAÇÃO 1: Cores dos botões agora são opcionais (nuláveis) e não têm valor padrão fixo.
  Color? cancelColor,
  Color? saveColor,
  Color actionTextColor = Colors.white,
  bool swapActionsOrder = false,
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
    useSafeArea: false,
    builder: (context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          final screenH = constraints.maxHeight;
          final keyboard = media.viewInsets.bottom;
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

          final bool isDark = theme.brightness == Brightness.dark;
          final Color baseColor = (isDark ? scheme.surface : Colors.white)
              .withAlpha((255 * (isDark ? backgroundAlphaDark : backgroundAlphaLight)).toInt());

          Widget buildTitle(Widget child) {
            final Color effectiveTitleColor = titleColor ?? (isDark ? titleColorDark : titleColorLight);

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

          VoidCallback? extractOnPressed(Widget w) {
            if (w is TextButton) return w.onPressed;
            if (w is ElevatedButton) return w.onPressed;
            if (w is OutlinedButton) return w.onPressed;
            if (w is FilledButton) return w.onPressed;
            return null;
          }

          Widget extractChild(Widget w) {
            if (w is TextButton) return w.child ?? const SizedBox.shrink();
            if (w is ElevatedButton) return w.child ?? const SizedBox.shrink();
            if (w is OutlinedButton) return w.child ?? const SizedBox.shrink();
            if (w is FilledButton) return w.child ?? const SizedBox.shrink();
            return w;
          }

          List<Widget> normalizeActions(List<Widget> raw) {
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
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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

          // ALTERAÇÃO 2: A função `buildActionsBar` foi reescrita para usar as cores do tema.
          Widget buildActionsBar(List<Widget> actsRaw) {
            final acts = normalizeActions(actsRaw);
            // Pega o ColorScheme do tema atual
            final scheme = Theme.of(context).colorScheme;

            if (acts.length == 1) {
              final action = acts.first;
              return SizedBox(
                height: actionHeight,
                child: coloredAction(
                  // Usa a cor passada, ou a cor secundária (teal) do tema como padrão
                  color: saveColor ?? scheme.secondary,
                  child: extractChild(action),
                  onTap: extractOnPressed(action),
                ),
              );
            }

            if (actionsHorizontal && acts.length == 2) {
              final left = swapActionsOrder ? acts[1] : acts[0];
              final right = swapActionsOrder ? acts[0] : acts[1];
              return Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: actionHeight,
                      child: coloredAction(
                        // Usa a cor passada, ou um azul padrão para o "cancelar"
                        color: cancelColor ?? Colors.blue.shade700,
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
                        // Usa a cor passada, ou a cor secundária (teal) do tema para o "salvar"
                        color: saveColor ?? scheme.secondary,
                        child: extractChild(right),
                        onTap: extractOnPressed(right),
                      ),
                    ),
                  ),
                ],
              );
            }

            return OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: actionsGap,
              children: acts,
            );
          }

          final actionsBar = buildActionsBar(actions);

          return MediaQuery.removeViewInsets(
            removeBottom: true,
            context: context,
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: cardInsets,
                child: Transform.translate(
                  offset: Offset(0, -lift),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: minW,
                      maxWidth: maxW,
                      maxHeight: targetH,
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
                            titlePadding: titlePadding,
                            title: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildTitle(title),
                                if (titleBottomGap > 0) SizedBox(height: titleBottomGap),
                              ],
                            ),
                            contentPadding: contentPadding,
                            scrollable: true,
                            content: DefaultTextStyle(
                              style: theme.dialogTheme.contentTextStyle ?? theme.textTheme.bodyMedium!,
                              child: content,
                            ),
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