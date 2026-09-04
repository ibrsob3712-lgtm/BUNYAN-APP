import 'package:flutter_test/flutter_test.dart';
import 'package:bunyan/core/services/assessment_engine.dart';
void main(){
 test('critical defect becomes urgent',(){
   final r=AssessmentEngine.evaluate(defectType:'شرخ',severity:'حرجة',observations:1);
   expect(r.priority,'عاجلة');
 });
 test('progressive deformation increases score',(){
   final r=AssessmentEngine.evaluate(defectType:'هبوط/تشوه',severity:'متوسطة',observations:6,progressive:true);
   expect(r.score,greaterThan(50));
 });
}
