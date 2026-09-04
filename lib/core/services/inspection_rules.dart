class AssessmentResult {
  final int score;
  final String priority;
  final String rationale;
  final String nextStep;

  const AssessmentResult({
    required this.score,
    required this.priority,
    required this.rationale,
    required this.nextStep,
  });
}

/// Transparent rule engine for inspection prioritization.
/// This is a decision-support mechanism and not a structural safety verdict.
class InspectionRules {
  static AssessmentResult evaluate({
    required String defectType,
    required String severity,
    int affectedObservations = 1,
    bool hasAbnormalTestResult = false,
    bool isProgressive = false,
  }) {
    int score = switch (severity) {
      'حرجة' => 85,
      'مرتفعة' => 65,
      'متوسطة' => 35,
      _ => 15,
    };

    if (defectType == 'هبوط/تشوه') score += 10;
    if (hasAbnormalTestResult) score += 10;
    if (isProgressive) score += 10;
    if (affectedObservations >= 5) score += 5;
    score = score.clamp(0, 100).toInt();

    if (score >= 85) {
      return AssessmentResult(
        score: score,
        priority: 'عاجلة',
        rationale: 'شدة العيب أو خصائصه المسجلة تستدعي اهتمامًا فوريًا ومراجعة هندسية متخصصة.',
        nextStep: 'اتخاذ الإجراءات الاحترازية المناسبة واستكمال التقييم التفصيلي بواسطة مهندس مختص.',
      );
    }
    if (score >= 65) {
      return AssessmentResult(
        score: score,
        priority: 'مرتفعة',
        rationale: 'البيانات المسجلة تشير إلى أولوية مرتفعة لمزيد من التقييم.',
        nextStep: 'تحديد نطاق العيب وأسبابه وإجراء الفحوص المستهدفة قبل اختيار التدخل.',
      );
    }
    if (score >= 35) {
      return AssessmentResult(
        score: score,
        priority: 'متوسطة',
        rationale: 'الحالة تحتاج إلى متابعة منظمة واستكمال التوثيق.',
        nextStep: 'إجراء قياسات دورية أو فحوص إضافية عند الحاجة وفق تقييم المهندس.',
      );
    }
    return AssessmentResult(
      score: score,
      priority: 'منخفضة',
      rationale: 'لا تظهر من البيانات الحالية أولوية مرتفعة.',
      nextStep: 'الاستمرار في الفحص الروتيني والمتابعة الدورية.',
    );
  }
}
