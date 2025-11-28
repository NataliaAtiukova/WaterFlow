import 'package:home_widget/home_widget.dart';

import '../models/daily_progress.dart';

class WidgetService {
  static const widgetProvider = 'WaterWidgetProvider';
  static const addAction = 'add_200';

  Future<void> updateWidget(DailyProgress progress) async {
    final remaining =
        (progress.target - progress.effectiveMl).clamp(0, progress.target);
    await HomeWidget.saveWidgetData(
        'percent', (progress.percent * 100).round());
    await HomeWidget.saveWidgetData('remaining', remaining);
    await HomeWidget.updateWidget(
        name: widgetProvider, iOSName: widgetProvider);
  }
}
