import 'package:flutter/material.dart';
import 'package:logisender/core/constants/app_strings.dart';
import 'package:logisender/core/theme/app_colors.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/core/widgets/glass_card.dart';

/// Template list card with gradient icon, preview, and actions.
class TemplateCard extends StatelessWidget {
  final AdTemplate template;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final isSmart = template.isSmart;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: isSmart ? AppColors.successGradient : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: AppColors.softShadow(
                    isSmart ? AppColors.success : AppColors.primary,
                    0.3,
                  ),
                ),
                child: Icon(
                  isSmart ? Icons.auto_awesome_rounded : Icons.article_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          isSmart ? Icons.auto_awesome : Icons.circle,
                          size: 11,
                          color: isSmart ? AppColors.success : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSmart ? AppStrings.smartTemplate : AppStrings.standard,
                          style: TextStyle(
                            color: isSmart ? AppColors.success : AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
                color: AppColors.surfaceElevated,
                onSelected: (value) {
                  switch (value) {
                    case 'duplicate':
                      onDuplicate();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(AppStrings.duplicate, style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Text(
              template.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}