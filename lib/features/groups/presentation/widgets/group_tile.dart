import 'package:flutter/material.dart';
import 'package:logisender/core/theme/app_colors.dart';
import 'package:logisender/core/telegram/telegram_models.dart';
import 'package:logisender/core/widgets/safe_text.dart';

/// Group list tile with gradient avatar, name, member count, and selection.
class GroupTile extends StatelessWidget {
  final TelegramGroup group;
  final bool isSelected;
  final VoidCallback onToggle;

  const GroupTile({
    super.key,
    required this.group,
    required this.isSelected,
    required this.onToggle,
  });

  Color get _typeColor {
    switch (group.type) {
      case ChatType.forum:
        return const Color(0xFFF0883E);
      case ChatType.supergroup:
        return AppColors.primary;
      case ChatType.channel:
        return AppColors.brandCyan;
      case ChatType.basicGroup:
        return AppColors.success;
    }
  }

  IconData get _typeIcon {
    switch (group.type) {
      case ChatType.forum:
        return Icons.forum_rounded;
      case ChatType.supergroup:
        return Icons.campaign_rounded;
      case ChatType.channel:
        return Icons.notifications_rounded;
      case ChatType.basicGroup:
        return Icons.groups_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : AppColors.borderSoft,
                width: 1,
              ),
              boxShadow: isSelected
                  ? AppColors.softShadow(AppColors.primary, 0.15)
                  : null,
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.primaryGradient
                        : LinearGradient(
                            colors: [
                              _typeColor.withValues(alpha: 0.25),
                              _typeColor.withValues(alpha: 0.1),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: group.title.isNotEmpty
                        ? SafeText(
                            group.title[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : _typeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          )
                        : Icon(_typeIcon, color: _typeColor, size: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SafeText(
                        group.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(_typeIcon, size: 13, color: _typeColor),
                          const SizedBox(width: 4),
                          SafeText(
                            _typeLabel,
                            style: TextStyle(color: _typeColor, fontSize: 11),
                          ),
                          if (group.memberCount > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.people_outline, size: 13, color: AppColors.textTertiary),
                            const SizedBox(width: 3),
                            SafeText(
                              _formatMemberCount(group.memberCount),
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Selection check
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary.withValues(alpha: 0.5),
                      width: 1.6,
                    ),
                    boxShadow: isSelected
                        ? AppColors.softShadow(AppColors.primary, 0.35)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _typeLabel {
    switch (group.type) {
      case ChatType.forum:
        return 'Forum';
      case ChatType.supergroup:
        return 'Superguruh';
      case ChatType.channel:
        return 'Kanal';
      case ChatType.basicGroup:
        return 'Guruh';
    }
  }

  String _formatMemberCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}