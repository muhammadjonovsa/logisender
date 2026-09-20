import 'package:flutter/material.dart';
import 'package:logisender/core/constants/app_strings.dart';
import 'package:logisender/core/theme/app_colors.dart';
import 'package:logisender/core/widgets/safe_text.dart';
import 'package:logisender/core/telegram/telegram_models.dart';

/// Log entry tile for send logs — modern status chip design.
class LogTile extends StatelessWidget {
  final SendLog log;

  const LogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_statusIcon, size: 18, color: _statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeText(
                  log.chatName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (log.messageText != null) ...[
                  const SizedBox(height: 2),
                  SafeText(
                    log.messageText!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(log.sentTime),
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (log.status) {
      case SentStatus.sent:
        return AppColors.success;
      case SentStatus.failed:
        return AppColors.error;
      case SentStatus.floodWait:
        return AppColors.warning;
      case SentStatus.pending:
      case SentStatus.retrying:
        return AppColors.info;
    }
  }

  String get _statusLabel {
    switch (log.status) {
      case SentStatus.sent:
        return 'Yuborildi';
      case SentStatus.failed:
        return 'Xato';
      case SentStatus.floodWait:
        return 'FloodWait';
      case SentStatus.pending:
        return 'Kutilmoqda';
      case SentStatus.retrying:
        return 'Qayta urinish';
    }
  }

  IconData get _statusIcon {
    switch (log.status) {
      case SentStatus.sent:
        return Icons.check_rounded;
      case SentStatus.failed:
        return Icons.close_rounded;
      case SentStatus.floodWait:
        return Icons.hourglass_top_rounded;
      case SentStatus.pending:
        return Icons.schedule_rounded;
      case SentStatus.retrying:
        return Icons.refresh_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return AppStrings.justNow;
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}