import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/history_provider.dart';
import '../../widgets/yandex_banner.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const routeName = '/history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('История')),
      bottomNavigationBar: const YandexStickyBanner(),
      body: historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('История пока пуста'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final isToday = item.isToday();
              final subtitle =
                  'Зачтено: ${item.effectiveMl} мл / ${item.target} мл · Всего: ${item.totalVolumeMl} мл';
              final percent =
                  (item.percent * 100).clamp(0, 999).toStringAsFixed(0);
              return ListTile(
                title: Text(isToday ? 'Сегодня' : _formatDate(item.date)),
                subtitle: Text('$subtitle · $percent%'),
                trailing: Text('$percent%'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
