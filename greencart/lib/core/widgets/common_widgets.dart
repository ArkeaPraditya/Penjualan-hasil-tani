import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/utils/order_status.dart';

class ProductImage extends StatelessWidget {
  const ProductImage(this.path, {super.key, this.fit = BoxFit.cover});
  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.soft,
          alignment: Alignment.center,
          child: const Icon(Icons.eco_outlined, color: AppColors.primary, size: 36),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppText.section, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: AppText.caption.copyWith(fontSize: 13), textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              SizedBox(width: 220, child: FilledButton(onPressed: onAction, child: Text(actionLabel!))),
            ],
          ]),
        ),
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.completed => (AppColors.soft, AppColors.dark),
      OrderStatus.cancelled => (const Color(0xFFFBEAEA), AppColors.error),
      OrderStatus.pending => (const Color(0xFFFAF1DC), const Color(0xFF8A6512)),
      _ => (const Color(0xFFE3F0E8), AppColors.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class AvatarInitials extends StatelessWidget {
  const AvatarInitials(this.name, {super.key, this.size = 64});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Text(initialsOf(name), style: TextStyle(color: Colors.white, fontSize: size * 0.36, fontWeight: FontWeight.w700)),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: AppText.section)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ]);
}

class SummaryRow extends StatelessWidget {
  const SummaryRow(this.label, this.value, {super.key, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppText.section : AppText.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: bold ? style : AppText.body.copyWith(color: AppColors.textSecondary)),
        Text(value, style: style),
      ]),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Terjadi kendala',
        message: message,
        actionLabel: 'Coba lagi',
        onAction: onRetry,
      );
}
