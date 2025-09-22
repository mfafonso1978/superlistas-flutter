// lib/core/ui/widgets/shared_widgets.dart
import 'dart:ui';
import 'package:flutter/material.dart';

// --- WIDGET 1: GlassAppBar ---
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  const GlassAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color foregroundColor = isDark ? scheme.onSurface : Colors.white;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AppBar(
          title: title,
          titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w800,
          ),
          iconTheme: IconThemeData(color: foregroundColor),
          backgroundColor: isDark
              ? scheme.surface.withOpacity(0.2)
              : Colors.white.withOpacity(0.15),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// --- WIDGET 2: GlassCard ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const GlassCard({super.key, required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            scheme.surface.withOpacity(0.6),
            scheme.surface.withOpacity(0.4),
          ]
              : [
            Colors.white.withOpacity(0.7),
            Colors.white.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

// --- WIDGET 3: Indicator ---
class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  const Indicator({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: onSurface), overflow: TextOverflow.ellipsis,)),
        ],
      ),
    );
  }
}