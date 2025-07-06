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
          ref.read(selectedPeriodProvider.notifier).state = key;
        },
        icon: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected
                  ? const Color(AppConstants.primaryColorValue)
                  : Colors.white12,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: isSelected ? 4 : 0,
        ),
      ),
    );
  }
}
