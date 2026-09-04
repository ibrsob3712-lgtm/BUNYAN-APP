import 'package:flutter_test/flutter_test.dart';
import 'package:bunyan/core/services/inspection_rules.dart';

void main() {
  test('critical defects receive urgent priority', () {
    final result = InspectionRules.evaluate(
      defectType: 'شرخ',
      severity: 'حرجة',
    );
    expect(result.priority, 'عاجلة');
    expect(result.score, greaterThanOrEqualTo(85));
  });

  test('low severity receives low priority without modifiers', () {
    final result = InspectionRules.evaluate(
      defectType: 'شرخ',
      severity: 'منخفضة',
    );
    expect(result.priority, 'منخفضة');
  });
}
