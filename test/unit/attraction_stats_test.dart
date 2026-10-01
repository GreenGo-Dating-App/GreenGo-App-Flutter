import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/attractions/data/services/attraction_stats_service.dart';

void main() {
  test('dayKey is the zero-padded UTC date (matches the rules)', () {
    expect(AttractionStatsService.dayKey(DateTime.utc(2026, 1, 5, 23, 59)), '20260105');
    expect(AttractionStatsService.dayKey(DateTime.utc(2026, 12, 31)), '20261231');
    // A local time is converted to UTC first.
    final local = DateTime.utc(2026, 3, 1, 0, 30).toLocal();
    expect(AttractionStatsService.dayKey(local), '20260301');
  });
}
