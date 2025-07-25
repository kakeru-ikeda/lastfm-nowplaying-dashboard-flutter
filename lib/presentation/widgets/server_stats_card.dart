import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';
import 'section_card.dart';
import 'app_loading_indicator.dart';

class ServerStatsCard extends ConsumerWidget {
  const ServerStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverStatsAsync = ref.watch(serverStatsProvider);

    return SectionCard(
      icon: Icons.analytics,
      title: 'Server Stats',
      child: serverStatsAsync.when(
        data: (stats) => _buildStatsContent(context, stats),
        loading: () => const ServerStatsLoadingIndicator(),
        error: (error, stack) => _buildErrorContent(error),
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, stats) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;
    
    return Column(
      children: [
        _buildStatItem(
          context,
          Icons.timer,
          'Uptime',
          _formatUptime(stats.uptime),
          accentColor,
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          context,
          Icons.api,
          'API Calls',
          '${stats.totalRequests}',
          accentColor,
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          context,
          Icons.people,
          'Connections',
          '${stats.activeConnections}',
          accentColor,
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          context,
          Icons.memory,
          'Memory',
          '${stats.memoryUsage.percentage}%',
          _getMemoryColor(stats.memoryUsage.percentage),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(Object error) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'Error loading stats',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    final duration = Duration(seconds: seconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Color _getMemoryColor(int percentage) {
    if (percentage > 80) return Colors.red;
    if (percentage > 60) return Colors.orange;
    return Colors.green;
  }
}
