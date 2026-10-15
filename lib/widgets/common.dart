import 'package:flutter/material.dart';

import '../app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 38});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .31),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB399FF), Color(0xFF765FE8)],
          ),
          boxShadow: [
            BoxShadow(
              color: VaultColors.violet.withOpacity(.22),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.shield_rounded, color: Colors.white, size: size * .57),
            Positioned(
              right: size * .15,
              top: size * .12,
              child: Icon(Icons.auto_awesome, color: const Color(0xFFD8CEFF), size: size * .19),
            ),
          ],
        ),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.compact = false});
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tone = statusColor(label);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 9, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: tone.withOpacity(.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withOpacity(.17)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: compact ? 5 : 6, height: compact ? 5 : 6, decoration: BoxDecoration(color: tone, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: tone, fontSize: compact ? 9.5 : 10.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

Color statusColor(String status) {
  final value = status.toLowerCase();
  if (['healthy', 'production', 'done', 'active', 'online', 'good'].contains(value)) return VaultColors.green;
  if (['attention', 'blocked', 'urgent', 'testing', 'staging', 'warning'].contains(value)) return VaultColors.amber;
  if (['offline', 'paused', 'archived', 'overdue'].contains(value)) return VaultColors.red;
  if (['in progress', 'development', 'planning', 'design', 'idea'].contains(value)) return VaultColors.violet;
  return VaultColors.muted;
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.eyebrow, required this.title, required this.subtitle, this.actions, this.count});
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? actions;
  final String? count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.65),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(title, style: Theme.of(context).textTheme.headlineSmall),
                      if (count != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(.13),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            count!,
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? VaultColors.muted : const Color(0xFF727689),
                        ),
                  ),
                ],
              ),
            ),
            if (actions != null) ...[
              const SizedBox(width: 16),
              actions!,
            ],
          ],
        ),
      );
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({super.key, required this.label, required this.onPressed, this.icon = Icons.add_rounded, this.compact = false});
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: compact ? 16 : 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 16, vertical: compact ? 10 : 13),
          textStyle: TextStyle(fontSize: compact ? 11 : 12, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
      );
}

class QuietAction extends StatelessWidget {
  const QuietAction({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).dividerColor),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
      );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.margin, this.borderColor});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor ?? Theme.of(context).dividerColor.withOpacity(.85)),
        ),
        child: child,
      );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.description, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 44),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(.1),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.2)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
                ),
                const SizedBox(height: 17),
                Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 7),
                Text(description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6)),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 19),
                  PrimaryAction(label: actionLabel!, onPressed: onAction!, compact: true),
                ],
              ],
            ),
          ),
        ),
      );
}

class CountTag extends StatelessWidget {
  const CountTag(this.count, {super.key, this.color});
  final int count;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: (color ?? VaultColors.violet).withOpacity(.13), borderRadius: BorderRadius.circular(20)),
        child: Text('$count', style: TextStyle(color: color ?? VaultColors.violet, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}

class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.tone});
  final String label;
  final Color? tone;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: (tone ?? Theme.of(context).colorScheme.primary).withOpacity(.1), borderRadius: BorderRadius.circular(7)),
        child: Text('#$label', style: TextStyle(color: tone ?? Theme.of(context).colorScheme.primary, fontSize: 9.5, fontWeight: FontWeight.w600)),
      );
}

class TinyLabel extends StatelessWidget {
  const TinyLabel(this.value, {super.key, this.color});
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(value.toUpperCase(), style: TextStyle(color: color ?? VaultColors.muted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.3));
}
