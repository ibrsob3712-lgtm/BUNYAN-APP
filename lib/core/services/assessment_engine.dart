class AssessmentResult {
  final int score; final String priority, rationale, nextStep;
  const AssessmentResult(this.score,this.priority,this.rationale,this.nextStep);
}
class AssessmentEngine {
  static AssessmentResult evaluate({required String defectType,required String severity,required int observations,bool abnormalTest=false,bool progressive=false}) {
    var score={'منخفضة':15,'متوسطة':40,'مرتفعة':70,'حرجة':90}[severity]??20;
    if(defectType=='هبوط/تشوه')score+=10;
    if(abnormalTest)score+=10;
    if(progressive)score+=10;
    if(observations>=5)score+=5;
    score = score.clamp(0, 100).toInt();
    if(score>=85)return AssessmentResult(score,'عاجلة','مؤشرات مسجلة تستدعي اهتمامًا فوريًا.','استكمال تقييم تفصيلي بواسطة مهندس مختص واتخاذ الاحتياطات المناسبة.');
    if(score>=65)return AssessmentResult(score,'مرتفعة','البيانات تشير إلى أولوية مرتفعة لمزيد من التقييم.','تحديد نطاق العيب وأسبابه وإجراء فحوص مستهدفة.');
    if(score>=35)return AssessmentResult(score,'متوسطة','الحالة تحتاج متابعة منظمة.','استكمال القياسات والمتابعة والفحوص عند الحاجة.');
    return AssessmentResult(score,'منخفضة','لا تظهر من البيانات الحالية أولوية مرتفعة.','المتابعة الدورية واستكمال الفحص الروتيني.');
  }
}
