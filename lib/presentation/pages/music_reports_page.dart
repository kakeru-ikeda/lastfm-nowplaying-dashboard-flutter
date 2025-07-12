import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/music_report_card.dart';
import '../widgets/period_selector.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';

class MusicReportsPage extends ConsumerWidget {
  const MusicReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(reportDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Music Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 日付リセットボタン (選択されている場合のみ表示)
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: '選択日をリセット',
              onPressed: () {
                ref.read(reportDateProvider.notifier).state = null;
                final selectedPeriod = ref.read(selectedPeriodProvider);
                ref.invalidate(musicReportProvider(selectedPeriod));
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final selectedPeriod = ref.read(selectedPeriodProvider);
              ref.invalidate(musicReportProvider(selectedPeriod));
            },
          ),
          const SizedBox(width: AppConstants.defaultPadding),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            const PeriodSelector(),
            const SizedBox(height: AppConstants.defaultPadding),

            // Music Report
            const MusicReportCard(),
          ],
        ),
      ),
    );
  }
}
