import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../projects/projects_page.dart';
import '../inspections/inspections_page.dart';
import '../assessment/assessment_page.dart';
import '../reports/reports_page.dart';

class DashboardPage extends StatefulWidget { const DashboardPage({super.key}); @override State<DashboardPage> createState()=>_DashboardPageState(); }
class _DashboardPageState extends State<DashboardPage> {
 int index=0; Map<String,int> s={};
 final pages=const[DashboardHome(),ProjectsPage(),InspectionsPage(),AssessmentPage(),ReportsPage()];
 @override void initState(){super.initState();load();}
 Future<void> load()async{final d=AppDatabase.instance;s={'projects':await d.count('projects'),'buildings':await d.count('buildings'),'inspections':await d.count('inspections'),'defects':await d.count('defects')};if(mounted)setState((){});}
 @override Widget build(BuildContext c)=>Scaffold(body:SafeArea(child:index==0?DashboardHome(stats:s,onRefresh:load):pages[index]),bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const[
 NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'الرئيسية'),
 NavigationDestination(icon:Icon(Icons.folder_outlined),selectedIcon:Icon(Icons.folder),label:'المشروعات'),
 NavigationDestination(icon:Icon(Icons.search_outlined),selectedIcon:Icon(Icons.search),label:'المعاينة'),
 NavigationDestination(icon:Icon(Icons.psychology_outlined),selectedIcon:Icon(Icons.psychology),label:'التقييم'),
 NavigationDestination(icon:Icon(Icons.description_outlined),selectedIcon:Icon(Icons.description),label:'التقارير')]));
}
class DashboardHome extends StatelessWidget {
 final Map<String,int> stats; final Future<void> Function()? onRefresh;
 const DashboardHome({super.key,this.stats=const{},this.onRefresh});
 @override Widget build(BuildContext c)=>RefreshIndicator(onRefresh:onRefresh??()async{},child:ListView(padding:const EdgeInsets.all(18),children:[
 const Text('بُنيان',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),const Text('منصة ميدانية لتوثيق وتقييم المباني القائمة'),const SizedBox(height:18),
 GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:12,mainAxisSpacing:12,children:[
 _stat('المشروعات',stats['projects']??0,Icons.folder),_stat('المباني',stats['buildings']??0,Icons.apartment),_stat('المعاينات',stats['inspections']??0,Icons.search),_stat('العيوب',stats['defects']??0,Icons.warning_amber)]),
 const SizedBox(height:18),const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('وضع ميداني: تُحفظ البيانات محليًا لتقليل الاعتماد على الإنترنت. التطبيق أداة دعم وتوثيق ولا يمثل شهادة سلامة إنشائية.')))]));
 Widget _stat(String t,int n,IconData i)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i),const Spacer(),Text('$n',style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),Text(t)])));
}
