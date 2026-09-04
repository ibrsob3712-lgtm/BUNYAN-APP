import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
final dbProvider = Provider((_) => BunyanDatabase.instance);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BunyanDatabase.instance.database;
  runApp(const ProviderScope(child: BunyanApp()));
}

class BunyanApp extends StatelessWidget {
  const BunyanApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'بُنيان',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff174A7C)),
      scaffoldBackgroundColor: const Color(0xffF5F7FA),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
    ),
    home: const Directionality(textDirection: TextDirection.rtl, child: Shell()),
  );
}

// ---------------- DATABASE ----------------

class BunyanDatabase {
  BunyanDatabase._();
  static final instance = BunyanDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(join(dir.path, 'bunyan_v1.db'), version: 2,
      onCreate: (db, version) async {
        await _create(db);
      },
    );
    return _db!;
  }

  Future<void> _create(Database db) async {
    await db.execute('CREATE TABLE projects(id TEXT PRIMARY KEY,name TEXT,location TEXT,purpose TEXT,createdAt TEXT)');
    await db.execute('CREATE TABLE buildings(id TEXT PRIMARY KEY,projectId TEXT,name TEXT,type TEXT,structuralSystem TEXT,address TEXT)');
    await db.execute('CREATE TABLE floors(id TEXT PRIMARY KEY,buildingId TEXT,name TEXT,level INTEGER)');
    await db.execute('CREATE TABLE elements(id TEXT PRIMARY KEY,floorId TEXT,type TEXT,code TEXT,location TEXT,details TEXT)');
    await db.execute('CREATE TABLE inspections(id TEXT PRIMARY KEY,buildingId TEXT,engineer TEXT,date TEXT,status TEXT,notes TEXT)');
    await db.execute('CREATE TABLE defects(id TEXT PRIMARY KEY,inspectionId TEXT,elementId TEXT,type TEXT,severity TEXT,description TEXT,status TEXT,createdAt TEXT)');
    await db.execute('CREATE TABLE measurements(id TEXT PRIMARY KEY,defectId TEXT,label TEXT,value REAL,unit TEXT)');
    await db.execute('CREATE TABLE photos(id TEXT PRIMARY KEY,defectId TEXT,path TEXT)');
    await db.execute('CREATE TABLE tests(id TEXT PRIMARY KEY,elementId TEXT,type TEXT,result TEXT,unit TEXT,date TEXT,notes TEXT)');
    await db.execute('CREATE TABLE assessments(id TEXT PRIMARY KEY,defectId TEXT,priority TEXT,score INTEGER,conditionText TEXT,recommendation TEXT,createdAt TEXT)');
  }

  Future<List<Map<String,dynamic>>> all(String table, {String? where, List<Object?>? args, String? order}) async =>
    (await database).query(table, where: where, whereArgs: args, orderBy: order);

  Future<void> insert(String table, Map<String,dynamic> data) async =>
    (await database).insert(table, data);

  Future<void> update(String table, Map<String,dynamic> data, String where, List<Object?> args) async =>
    (await database).update(table, data, where: where, whereArgs: args);

  Future<void> delete(String table, String where, List<Object?> args) async =>
    (await database).delete(table, where: where, whereArgs: args);

  Future<int> count(String table, {String? where, List<Object?>? args}) async =>
    Sqflite.firstIntValue(await (await database).rawQuery('SELECT COUNT(*) FROM $table${where==null?'':' WHERE $where'}', args)) ?? 0;

  Future<Map<String,int>> dashboard() async => {
    'projects': await count('projects'),
    'buildings': await count('buildings'),
    'inspections': await count('inspections'),
    'defects': await count('defects'),
  };

  Future<void> wipe() async {
    final d=await database;
    for(final t in ['assessments','photos','measurements','defects','tests','inspections','elements','floors','buildings','projects']) {
      await d.delete(t);
    }
  }
}

// ---------------- APP SHELL ----------------

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState()=>_ShellState();
}
class _ShellState extends State<Shell> {
  int index=0;
  final pages=const [DashboardPage(), ProjectsPage(), InspectionPage(), AssessmentPage(), ReportsPage()];
  @override Widget build(BuildContext context)=>Scaffold(
    body: SafeArea(child: pages[index]),
    bottomNavigationBar: NavigationBar(
      selectedIndex:index,
      onDestinationSelected:(v)=>setState(()=>index=v),
      destinations:const[
        NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'الرئيسية'),
        NavigationDestination(icon:Icon(Icons.folder_outlined),selectedIcon:Icon(Icons.folder),label:'المشروعات'),
        NavigationDestination(icon:Icon(Icons.search_outlined),selectedIcon:Icon(Icons.search),label:'المعاينة'),
        NavigationDestination(icon:Icon(Icons.psychology_outlined),selectedIcon:Icon(Icons.psychology),label:'التقييم'),
        NavigationDestination(icon:Icon(Icons.description_outlined),selectedIcon:Icon(Icons.description),label:'التقارير'),
      ],
    ),
  );
}

// ---------------- COMMON ----------------

Future<bool> formDialog(BuildContext context, String title, Widget content, {String save='حفظ'}) async {
  return await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
    title:Text(title), content:SingleChildScrollView(child:content),
    actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),
      FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(save))],
  )) ?? false;
}
Widget sectionTitle(String text)=>Padding(padding:const EdgeInsets.only(bottom:10,top:8),child:Text(text,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)));
String now()=>DateTime.now().toIso8601String();

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override ConsumerState<DashboardPage> createState()=>_DashboardPageState();
}
class _DashboardPageState extends ConsumerState<DashboardPage> {
  Map<String,int> s={};
  @override void initState(){super.initState();load();}
  Future<void> load() async {s=await ref.read(dbProvider).dashboard();if(mounted)setState((){});}
  @override Widget build(BuildContext context)=>RefreshIndicator(
    onRefresh:load,
    child:ListView(padding:const EdgeInsets.all(18),children:[
      const Text('بُنيان',style:TextStyle(fontSize:30,fontWeight:FontWeight.bold)),
      const Text('منصة المعاينة ودعم تقييم المباني القائمة'),
      const SizedBox(height:18),
      GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:12,mainAxisSpacing:12,
        children:[
          StatCard('المشروعات',s['projects']??0,Icons.folder),
          StatCard('المباني',s['buildings']??0,Icons.apartment),
          StatCard('المعاينات',s['inspections']??0,Icons.search),
          StatCard('العيوب المسجلة',s['defects']??0,Icons.warning_amber),
        ]),
      const SizedBox(height:20),
      const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('تنبيه مهني: بُنيان أداة لتنظيم المعاينة ودعم اتخاذ القرار الهندسي ولا يصدر بمفرده حكمًا نهائيًا بسلامة المنشأ.'))),
    ]),
  );
}
class StatCard extends StatelessWidget {
  final String title; final int value; final IconData icon;
  const StatCard(this.title,this.value,this.icon,{super.key});
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
    Icon(icon),const Spacer(),Text('$value',style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),Text(title)
  ])));
}

// ---------------- PROJECTS ----------------

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});
  @override ConsumerState<ProjectsPage> createState()=>_ProjectsPageState();
}
class _ProjectsPageState extends ConsumerState<ProjectsPage>{
  List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{rows=await ref.read(dbProvider).all('projects',order:'createdAt DESC');if(mounted)setState((){});}
  Future<void> add()async{
    final n=TextEditingController(),l=TextEditingController(),p=TextEditingController();
    final ok=await formDialog(context,'مشروع جديد',Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المشروع')),
      const SizedBox(height:10),TextField(controller:l,decoration:const InputDecoration(labelText:'الموقع')),
      const SizedBox(height:10),TextField(controller:p,decoration:const InputDecoration(labelText:'غرض التقييم')),
    ]));
    if(ok&&n.text.trim().isNotEmpty){await ref.read(dbProvider).insert('projects',{'id':_uuid.v4(),'name':n.text.trim(),'location':l.text.trim(),'purpose':p.text.trim(),'createdAt':now()});load();}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('المشروعات')),
    floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('مشروع جديد')),
    body:rows.isEmpty?const Center(child:Text('لا توجد مشروعات بعد')):RefreshIndicator(onRefresh:load,child:ListView.builder(padding:const EdgeInsets.all(16),itemCount:rows.length,itemBuilder:(c,i){final x=rows[i];return Card(child:ListTile(leading:const Icon(Icons.business),title:Text(x['name']),subtitle:Text('${x['location']??''}\n${x['purpose']??''}'),isThreeLine:true,onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ProjectDetailPage(project:x))).then((_)=>load())));})),
  );
}

class ProjectDetailPage extends ConsumerStatefulWidget {
  final Map<String,dynamic> project; const ProjectDetailPage({super.key,required this.project});
  @override ConsumerState<ProjectDetailPage> createState()=>_ProjectDetailPageState();
}
class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage>{
  List<Map<String,dynamic>> buildings=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{buildings=await ref.read(dbProvider).all('buildings',where:'projectId=?',args:[widget.project['id']]);if(mounted)setState((){});}
  Future<void> addBuilding()async{
    final n=TextEditingController(),a=TextEditingController();String type='سكني',system='خرسانة مسلحة';
    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(title:const Text('إضافة مبنى'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'اسم المبنى')),
      const SizedBox(height:8),DropdownButtonFormField(value:type,items:const[DropdownMenuItem(value:'سكني',child:Text('سكني')),DropdownMenuItem(value:'إداري',child:Text('إداري')),DropdownMenuItem(value:'تعليمي',child:Text('تعليمي')),DropdownMenuItem(value:'صناعي',child:Text('صناعي'))],onChanged:(v)=>setD(()=>type=v!)),
      const SizedBox(height:8),DropdownButtonFormField(value:system,items:const[DropdownMenuItem(value:'خرسانة مسلحة',child:Text('خرسانة مسلحة')),DropdownMenuItem(value:'صلب',child:Text('صلب')),DropdownMenuItem(value:'مختلط',child:Text('مختلط'))],onChanged:(v)=>setD(()=>system=v!)),
      const SizedBox(height:8),TextField(controller:a,decoration:const InputDecoration(labelText:'العنوان/الموقع')),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))])));
    if(ok==true&&n.text.trim().isNotEmpty){await ref.read(dbProvider).insert('buildings',{'id':_uuid.v4(),'projectId':widget.project['id'],'name':n.text.trim(),'type':type,'structuralSystem':system,'address':a.text});load();}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.project['name'])),floatingActionButton:FloatingActionButton(onPressed:addBuilding,child:const Icon(Icons.add_business)),body:ListView(padding:const EdgeInsets.all(16),children:[
    sectionTitle('بيانات المشروع'),Card(child:ListTile(title:Text(widget.project['purpose']??''),subtitle:Text(widget.project['location']??''))),
    const SizedBox(height:14),sectionTitle('المباني'),
    ...buildings.map((b)=>Card(child:ListTile(leading:const Icon(Icons.apartment),title:Text(b['name']),subtitle:Text('${b['type']} • ${b['structuralSystem']}'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>BuildingDetailPage(building:b)))))),
  ]));
}

class BuildingDetailPage extends ConsumerStatefulWidget {
  final Map<String,dynamic> building;const BuildingDetailPage({super.key,required this.building});
  @override ConsumerState<BuildingDetailPage> createState()=>_BuildingDetailPageState();
}
class _BuildingDetailPageState extends ConsumerState<BuildingDetailPage>{
  List<Map<String,dynamic>> floors=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{floors=await ref.read(dbProvider).all('floors',where:'buildingId=?',args:[widget.building['id']],order:'level ASC');if(mounted)setState((){});}
  Future<void> add()async{final n=TextEditingController(),l=TextEditingController(text:'${floors.length}');final ok=await formDialog(context,'إضافة طابق',Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'اسم الطابق')),TextField(controller:l,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'رقم المستوى'))]));if(ok&&n.text.isNotEmpty){await ref.read(dbProvider).insert('floors',{'id':_uuid.v4(),'buildingId':widget.building['id'],'name':n.text,'level':int.tryParse(l.text)??0});load();}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.building['name'])),floatingActionButton:FloatingActionButton(onPressed:add,child:const Icon(Icons.add)),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:ListTile(title:Text(widget.building['type']??''),subtitle:Text(widget.building['structuralSystem']??''))),
    const SizedBox(height:14),sectionTitle('الطوابق'),
    ...floors.map((f)=>Card(child:ListTile(title:Text(f['name']),subtitle:Text('المستوى ${f['level']}'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>FloorPage(floor:f)))))),
  ]));
}

class FloorPage extends ConsumerStatefulWidget {
  final Map<String,dynamic> floor;const FloorPage({super.key,required this.floor});
  @override ConsumerState<FloorPage> createState()=>_FloorPageState();
}
class _FloorPageState extends ConsumerState<FloorPage>{
  List<Map<String,dynamic>> elements=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{elements=await ref.read(dbProvider).all('elements',where:'floorId=?',args:[widget.floor['id']]);if(mounted)setState((){});}
  Future<void> add()async{
    final code=TextEditingController(),loc=TextEditingController(),det=TextEditingController();String type='عمود';
    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(title:const Text('إضافة عنصر إنشائي'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField(value:type,items:const[DropdownMenuItem(value:'عمود',child:Text('عمود')),DropdownMenuItem(value:'كمرة',child:Text('كمرة')),DropdownMenuItem(value:'بلاطة',child:Text('بلاطة')),DropdownMenuItem(value:'حائط',child:Text('حائط')),DropdownMenuItem(value:'أساس',child:Text('أساس')),DropdownMenuItem(value:'سلم',child:Text('سلم'))],onChanged:(v)=>setD(()=>type=v!)),
      TextField(controller:code,decoration:const InputDecoration(labelText:'كود العنصر')),
      TextField(controller:loc,decoration:const InputDecoration(labelText:'الموقع')),
      TextField(controller:det,decoration:const InputDecoration(labelText:'تفاصيل/أبعاد')),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))])));
    if(ok==true&&code.text.isNotEmpty){await ref.read(dbProvider).insert('elements',{'id':_uuid.v4(),'floorId':widget.floor['id'],'type':type,'code':code.text,'location':loc.text,'details':det.text});load();}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.floor['name'])),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('عنصر')),body:ListView(padding:const EdgeInsets.all(16),children:[
    sectionTitle('العناصر الإنشائية'),
    ...elements.map((e)=>Card(child:ListTile(leading:const Icon(Icons.account_tree_outlined),title:Text('${e['type']} – ${e['code']}'),subtitle:Text('${e['location']??''} ${e['details']??''}'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ElementPage(element:e)))))),
  ]));
}

class ElementPage extends ConsumerStatefulWidget {
  final Map<String,dynamic> element;const ElementPage({super.key,required this.element});
  @override ConsumerState<ElementPage> createState()=>_ElementPageState();
}
class _ElementPageState extends ConsumerState<ElementPage>{
  List<Map<String,dynamic>> tests=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{tests=await ref.read(dbProvider).all('tests',where:'elementId=?',args:[widget.element['id']],order:'date DESC');if(mounted)setState((){});}
  Future<void> addTest()async{final result=TextEditingController(),unit=TextEditingController(),notes=TextEditingController();String type='فحص بصري';final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(title:const Text('إضافة فحص'),content:Column(mainAxisSize:MainAxisSize.min,children:[
    DropdownButtonFormField(value:type,items:const[DropdownMenuItem(value:'فحص بصري',child:Text('فحص بصري')),DropdownMenuItem(value:'مطرقة شميدت',child:Text('مطرقة شميدت')),DropdownMenuItem(value:'الموجات فوق الصوتية',child:Text('الموجات فوق الصوتية')),DropdownMenuItem(value:'اختبار عينات',child:Text('اختبار عينات')),DropdownMenuItem(value:'كربنة',child:Text('كربنة')),DropdownMenuItem(value:'غطاء خرساني',child:Text('غطاء خرساني'))],onChanged:(v)=>setD(()=>type=v!)),
    TextField(controller:result,decoration:const InputDecoration(labelText:'النتيجة')),
    TextField(controller:unit,decoration:const InputDecoration(labelText:'الوحدة')),
    TextField(controller:notes,maxLines:2,decoration:const InputDecoration(labelText:'ملاحظات')),
  ]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))])));
  if(ok==true){await ref.read(dbProvider).insert('tests',{'id':_uuid.v4(),'elementId':widget.element['id'],'type':type,'result':result.text,'unit':unit.text,'date':now(),'notes':notes.text});load();}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.element['code'])),floatingActionButton:FloatingActionButton.extended(onPressed:addTest,icon:const Icon(Icons.science_outlined),label:const Text('فحص')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:ListTile(title:Text(widget.element['type']),subtitle:Text(widget.element['details']??''))),
    const SizedBox(height:14),sectionTitle('سجل الفحوص'),...tests.map((t)=>Card(child:ListTile(title:Text(t['type']),subtitle:Text('${t['result']} ${t['unit']}\n${t['notes']??''}'))))
  ]));
}

// ---------------- INSPECTION + DEFECTS ----------------

class InspectionPage extends ConsumerStatefulWidget {
  const InspectionPage({super.key});
  @override ConsumerState<InspectionPage> createState()=>_InspectionPageState();
}
class _InspectionPageState extends ConsumerState<InspectionPage>{
  List<Map<String,dynamic>> inspections=[],buildings=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{final db=ref.read(dbProvider);inspections=await db.all('inspections',order:'date DESC');buildings=await db.all('buildings');if(mounted)setState((){});}
  Future<void> add()async{
    if(buildings.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أضف مبنى أولًا داخل أحد المشروعات')));return;}
    String buildingId=buildings.first['id'];final eng=TextEditingController(),notes=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(title:const Text('بدء جلسة معاينة'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField(value:buildingId,items:buildings.map((b)=>DropdownMenuItem(value:b['id'],child:Text(b['name']))).toList(),onChanged:(v)=>setD(()=>buildingId=v!)),
      TextField(controller:eng,decoration:const InputDecoration(labelText:'اسم المهندس')),
      TextField(controller:notes,maxLines:2,decoration:const InputDecoration(labelText:'ملاحظات عامة')),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('بدء'))])));
    if(ok==true){await ref.read(dbProvider).insert('inspections',{'id':_uuid.v4(),'buildingId':buildingId,'engineer':eng.text,'date':now(),'status':'نشطة','notes':notes.text});load();}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('المعاينة الميدانية')),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.play_arrow),label:const Text('بدء معاينة')),body:ListView(padding:const EdgeInsets.all(16),children:[
    sectionTitle('جلسات المعاينة'),...inspections.map((i)=>Card(child:ListTile(leading:const Icon(Icons.search),title:Text('معاينة ${i['date'].toString().substring(0,10)}'),subtitle:Text('المهندس: ${i['engineer']??''} • ${i['status']}'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>InspectionDetailPage(inspection:i)))))),
  ]));
}

class InspectionDetailPage extends ConsumerStatefulWidget {
  final Map<String,dynamic> inspection;const InspectionDetailPage({super.key,required this.inspection});
  @override ConsumerState<InspectionDetailPage> createState()=>_InspectionDetailPageState();
}
class _InspectionDetailPageState extends ConsumerState<InspectionDetailPage>{
  List<Map<String,dynamic>> defects=[],elements=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    final db=ref.read(dbProvider);
    defects=await db.all('defects',where:'inspectionId=?',args:[widget.inspection['id']],order:'createdAt DESC');
    elements=await (await db.database).rawQuery('SELECT e.* FROM elements e JOIN floors f ON e.floorId=f.id JOIN buildings b ON f.buildingId=b.id WHERE b.id=?',[widget.inspection['buildingId']]);
    if(mounted)setState((){});
  }
  Future<void> addDefect()async{
    if(elements.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('لم يتم تعريف عناصر إنشائية لهذا المبنى بعد')));return;}
    String elementId=elements.first['id'],type='شرخ',severity='متوسطة';final desc=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(title:const Text('تسجيل عيب'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField(value:elementId,items:elements.map((e)=>DropdownMenuItem(value:e['id'],child:Text('${e['type']} ${e['code']}'))).toList(),onChanged:(v)=>setD(()=>elementId=v!)),
      DropdownButtonFormField(value:type,items:const[DropdownMenuItem(value:'شرخ',child:Text('شرخ')),DropdownMenuItem(value:'تلف خرسانة',child:Text('تلف خرسانة')),DropdownMenuItem(value:'تآكل',child:Text('تآكل')),DropdownMenuItem(value:'رطوبة/تسرب',child:Text('رطوبة/تسرب')),DropdownMenuItem(value:'هبوط/تشوه',child:Text('هبوط/تشوه')),DropdownMenuItem(value:'تعشيش',child:Text('تعشيش'))],onChanged:(v)=>setD(()=>type=v!)),
      DropdownButtonFormField(value:severity,items:const[DropdownMenuItem(value:'منخفضة',child:Text('منخفضة')),DropdownMenuItem(value:'متوسطة',child:Text('متوسطة')),DropdownMenuItem(value:'مرتفعة',child:Text('مرتفعة')),DropdownMenuItem(value:'حرجة',child:Text('حرجة'))],onChanged:(v)=>setD(()=>severity=v!)),
      TextField(controller:desc,maxLines:3,decoration:const InputDecoration(labelText:'وصف العيب')),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))])));
    if(ok==true){await ref.read(dbProvider).insert('defects',{'id':_uuid.v4(),'inspectionId':widget.inspection['id'],'elementId':elementId,'type':type,'severity':severity,'description':desc.text,'status':'مفتوح','createdAt':now()});load();}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('تفاصيل المعاينة')),floatingActionButton:FloatingActionButton.extended(onPressed:addDefect,icon:const Icon(Icons.add_alert),label:const Text('تسجيل عيب')),body:ListView(padding:const EdgeInsets.all(16),children:[
    ...defects.map((d)=>Card(child:ListTile(leading:const Icon(Icons.warning_amber),title:Text('${d['type']} • ${d['severity']}'),subtitle:Text(d['description']??''),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>DefectPage(defect:d)))))),
  ]));
}

class DefectPage extends ConsumerStatefulWidget {
  final Map<String,dynamic> defect;const DefectPage({super.key,required this.defect});
  @override ConsumerState<DefectPage> createState()=>_DefectPageState();
}
class _DefectPageState extends ConsumerState<DefectPage>{
  List<Map<String,dynamic>> measurements=[],photos=[],assessments=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{final db=ref.read(dbProvider);measurements=await db.all('measurements',where:'defectId=?',args:[widget.defect['id']]);photos=await db.all('photos',where:'defectId=?',args:[widget.defect['id']]);assessments=await db.all('assessments',where:'defectId=?',args:[widget.defect['id']],order:'createdAt DESC');if(mounted)setState((){});}
  Future<void> addMeasurement()async{final l=TextEditingController(),v=TextEditingController(),u=TextEditingController(text:'mm');final ok=await formDialog(context,'إضافة قياس',Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:l,decoration:const InputDecoration(labelText:'اسم القياس')),TextField(controller:v,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'القيمة')),TextField(controller:u,decoration:const InputDecoration(labelText:'الوحدة'))]));if(ok&&double.tryParse(v.text)!=null){await ref.read(dbProvider).insert('measurements',{'id':_uuid.v4(),'defectId':widget.defect['id'],'label':l.text,'value':double.parse(v.text),'unit':u.text});load();}}
  Future<void> addPhoto()async{
    final picker=ImagePicker();final x=await picker.pickImage(source:ImageSource.camera,imageQuality:80);
    if(x!=null){final dir=await getApplicationDocumentsDirectory();final folder=Directory(join(dir.path,'bunyan_photos'));if(!await folder.exists())await folder.create(recursive:true);final dest=join(folder.path,'${_uuid.v4()}${extension(x.path)}');await File(x.path).copy(dest);await ref.read(dbProvider).insert('photos',{'id':_uuid.v4(),'defectId':widget.defect['id'],'path':dest});load();}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('ملف العيب')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${widget.defect['type']} • ${widget.defect['severity']}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),const SizedBox(height:8),Text(widget.defect['description']??'')])),
    const SizedBox(height:12),Row(children:[Expanded(child:FilledButton.icon(onPressed:addPhoto,icon:const Icon(Icons.camera_alt),label:const Text('التقاط صورة'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:addMeasurement,icon:const Icon(Icons.straighten),label:const Text('إضافة قياس')))]),
    sectionTitle('الصور'),...photos.map((p)=>Padding(padding:const EdgeInsets.only(bottom:8),child:File(p['path']).existsSync()?ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(File(p['path']),height:180,width:double.infinity,fit:BoxFit.cover)):const Text('الصورة غير متاحة'))),
    sectionTitle('القياسات'),...measurements.map((m)=>Card(child:ListTile(title:Text(m['label']),trailing:Text('${m['value']} ${m['unit']}')))),
    if(assessments.isNotEmpty)...[sectionTitle('آخر تقييم'),Card(child:ListTile(title:Text(assessments.first['priority']),subtitle:Text(assessments.first['recommendation']??'')))]
  ]));
}

// ---------------- ASSESSMENT ----------------

class AssessmentPage extends ConsumerStatefulWidget {
  const AssessmentPage({super.key});
  @override ConsumerState<AssessmentPage> createState()=>_AssessmentPageState();
}
class _AssessmentPageState extends ConsumerState<AssessmentPage>{
  List<Map<String,dynamic>> defects=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{defects=await ref.read(dbProvider).all('defects',order:'createdAt DESC');if(mounted)setState((){});}
  Map<String,dynamic> assess(Map<String,dynamic> d){
    int score={'منخفضة':15,'متوسطة':40,'مرتفعة':70,'حرجة':90}[d['severity']]??20;
    if(d['type']=='هبوط/تشوه') score+=5;
    score=score.clamp(0,100);
    if(score>=85)return {'score':score,'priority':'عاجلة','condition':'مؤشرات مرتفعة تستدعي اهتمامًا فوريًا','recommendation':'استكمال التقييم التفصيلي بواسطة مهندس مختص واتخاذ إجراءات احترازية مناسبة وفق ظروف الموقع.'};
    if(score>=65)return {'score':score,'priority':'مرتفعة','condition':'الحالة تحتاج إلى تقييم تفصيلي','recommendation':'تحديد نطاق العيب وأسبابه وإجراء الفحوص المناسبة قبل تحديد التدخل.'};
    if(score>=35)return {'score':score,'priority':'متوسطة','condition':'الحالة تحتاج إلى متابعة منظمة','recommendation':'استكمال التوثيق والقياسات والمتابعة أو إجراء فحوص مستهدفة عند الحاجة.'};
    return {'score':score,'priority':'منخفضة','condition':'لا تظهر من البيانات الحالية أولوية مرتفعة','recommendation':'استكمال الفحص الروتيني والمتابعة الدورية.'};
  }
  Future<void> run(Map<String,dynamic> d)async{final r=assess(d);await ref.read(dbProvider).insert('assessments',{'id':_uuid.v4(),'defectId':d['id'],'priority':r['priority'],'score':r['score'],'conditionText':r['condition'],'recommendation':r['recommendation'],'createdAt':now()});if(mounted){await load();showDialog(context:context,builder:(c)=>AlertDialog(title:Text('الأولوية: ${r['priority']}'),content:Text('المؤشر التنظيمي: ${r['score']}/100\n\n${r['condition']}\n\n${r['recommendation']}\n\nهذه نتيجة مساعدة وليست حكمًا نهائيًا على سلامة المنشأ.'),actions:[FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('حسنًا'))]));}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('دعم التقييم الهندسي')),body:ListView(padding:const EdgeInsets.all(16),children:[
    const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('يقوم المحرك الحالي بتنظيم الأولوية اعتمادًا على البيانات المسجلة. القواعد قابلة للتطوير ولا يجب استخدامها منفردة لإصدار قرار سلامة.'))),
    sectionTitle('العيوب المتاحة للتقييم'),
    ...defects.map((d)=>Card(child:ListTile(title:Text('${d['type']} • ${d['severity']}'),subtitle:Text(d['description']??''),trailing:FilledButton(onPressed:()=>run(d),child:const Text('تحليل'))))),
  ]));
}

// ---------------- REPORTS + BACKUP ----------------

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override ConsumerState<ReportsPage> createState()=>_ReportsPageState();
}
class _ReportsPageState extends ConsumerState<ReportsPage>{
  bool busy=false;
  Future<void> report()async{
    setState(()=>busy=true);
    final db=ref.read(dbProvider);
    final projects=await db.all('projects');
    final buildings=await db.all('buildings');
    final inspections=await db.all('inspections');
    final defects=await db.all('defects');
    final doc=pw.Document();
    doc.addPage(pw.MultiPage(build:(context)=>[
      pw.Header(level:0,child:pw.Text('BUNYAN – Building Assessment Summary')),
      pw.Paragraph(text:'Generated: ${DateTime.now()}'),
      pw.Bullet(text:'Projects: ${projects.length}'),
      pw.Bullet(text:'Buildings: ${buildings.length}'),
      pw.Bullet(text:'Inspections: ${inspections.length}'),
      pw.Bullet(text:'Recorded defects: ${defects.length}'),
      pw.SizedBox(height:20),
      pw.Text('Professional notice: This report organizes recorded field data and does not constitute a final structural safety certificate without qualified engineering review.'),
    ]));
    final bytes=await doc.save();
    if(mounted){setState(()=>busy=false);await Printing.layoutPdf(onLayout:(_)=>bytes);}
  }
  Future<void> backupInfo()async{
    final dir=await getApplicationDocumentsDirectory();
    if(mounted)showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('النسخ الاحتياطي'),content:Text('توجد قاعدة البيانات المحلية داخل مساحة التطبيق:\n${dir.path}\n\nيمكن في الإصدار الإنتاجي إضافة تصدير واستيراد ملف قاعدة بيانات مشفر ومشاركته عبر خدمات الهاتف.'),actions:[FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('حسنًا'))]));
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('التقارير والبيانات')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:ListTile(leading:const Icon(Icons.picture_as_pdf),title:const Text('إنشاء تقرير PDF'),subtitle:const Text('ملخص احترافي للبيانات المسجلة'),trailing:busy?const CircularProgressIndicator():const Icon(Icons.arrow_back),onTap:busy?null:report)),
    const SizedBox(height:10),Card(child:ListTile(leading:const Icon(Icons.backup_outlined),title:const Text('النسخ الاحتياطي'),subtitle:const Text('معلومات قاعدة البيانات المحلية'),onTap:backupInfo)),
  ]));
}
