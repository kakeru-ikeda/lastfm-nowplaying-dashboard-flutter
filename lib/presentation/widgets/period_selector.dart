import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';
import 'simple_card.dart';

class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  static const periods = [
    {'key': 'daily', 'label': 'Daily', 'icon': Icons.today},
    {'key': 'weekly', 'label': 'Weekly', 'icon': Icons.date_range},
    {'key': 'monthly', 'label': 'Monthly', 'icon': Icons.calendar_month},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Period',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children:
                periods.map((period) {
                  final isSelected = selectedPeriod == period['key'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildPeriodButton(
                        context,
                        ref,
                        period['key'] as String,
                        period['label'] as String,
                        period['icon'] as IconData,
                        isSelected,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(
    BuildContext context,
    WidgetRef ref,
    String key,
    String label,
    IconData icon,
    bool isSelected,
  ) {
    return AnimatedContainer(
      duration: AppConstants.defaultAnimationDuration,
      child: ElevatedButton.icon(
        onPressed: () {
          // 期間切替時に適切な初期日付を設定
          final today = DateTime.now();
          String? initialDate;
          
          switch (key) {
            case 'daily':
              // 日次レポート用: YYYY-MM-DD形式
              initialDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              break;
            case 'weekly':
              // 週次レポートの場合は今日の日付を設定しておき、チャート側で週の範囲に変換
              initialDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              break;
            case 'monthly':
              // 月次レポート用: YYYY-MM形式
              initialDate = '${today.year}-${today.month.toString().padLeft(2, '0')}';
              break;
          }
          
          ref.read(reportDateProvider.notifier).state = initialDate;
          ref.read(selectedPeriodProvider.notifier).state = key;
        },
        icon: Icon(
          icon, 
          color: isSelected 
            ? (Theme.of(context).colorScheme.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white)
            : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected 
              ? (Theme.of(context).colorScheme.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white)
              : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: isSelected ? 4 : 0,
        ),
      ),
    );
  }
}
