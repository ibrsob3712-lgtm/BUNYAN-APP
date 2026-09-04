import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';

class DefectsPage extends StatefulWidget { final Map<String,dynamic> inspection; const DefectsPage({super.key,required this.inspection}); @override State<DefectsPage> createState()=>_DefectsPageState(); }
class _DefectsPageState extends State<DefectsPage> {
  List<Map<String,dynamic>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {rows=await AppDatabase.instance.query('defects',where:'inspectionId=?',args:[widget.inspection['id']],order:'createdAt DESC');if(mounted)setState((){});}
  Future<void> add() async {
    final description=TextEditingController();String type='شرخ',severity='متوسطة';
    final ok=await showDialog<bool>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,setDialogState)=>AlertDialog(title:const Text('تسجيل عيب'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<String>(initialValue:type,items:const[DropdownMenuItem(value:'شرخ',child:Text('شرخ')),DropdownMenuItem(value:'تلف خرسانة',child:Text('تلف خرسانة')),DropdownMenuItem(value:'تآكل',child:Text('تآكل')),DropdownMenuItem(value:'هبوط/تشوه',child:Text('هبوط/تشوه')),DropdownMenuItem(value:'رطوبة/تسرب',child:Text('رطوبة/تسرب'))],onChanged:(v)=>setDialogState(()=>type=v??type)),DropdownButtonFormField<String>(initialValue:severity,items:const[DropdownMenuItem(value:'منخفضة',child:Text('منخفضة')),DropdownMenuItem(value:'متوسطة',child:Text('متوسطة')),DropdownMenuItem(value:'مرتفعة',child:Text('مرتفعة')),DropdownMenuItem(value:'حرجة',child:Text('حرجة'))],onChanged:(v)=>setDialogState(()=>severity=v??severity)),TextField(controller:description,maxLines:3,decoration:const InputDecoration(labelText:'الوصف'))]),actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('حفظ'))])));
    if(ok==true){await AppDatabase.instance.insert('defects',{'id':const Uuid().v4(),'inspectionId':widget.inspection['id'],'elementId':'','type':type,'severity':severity,'description':description.text,'status':'مفتوح','createdAt':DateTime.now().toIso8601String(),'updatedAt':DateTime.now().toIso8601String()});await load();}
  }
  Future<void> photo(Map<String,dynamic> item) async {final picked=await ImagePicker().pickImage(source:ImageSource.camera,imageQuality:75);if(picked==null)return;final dir=await getApplicationDocumentsDirectory();final folder=Directory(path.join(dir.path,'photos'));await folder.create(recursive:true);final destination=path.join(folder.path,'${const Uuid().v4()}${path.extension(picked.path)}');await File(picked.path).copy(destination);await AppDatabase.instance.insert('photos',{'id':const Uuid().v4(),'defectId':item['id'],'path':destination,'caption':'','createdAt':DateTime.now().toIso8601String()});}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('العيوب المسجلة')),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add_alert),label:const Text('عيب')),body:ListView(padding:const EdgeInsets.all(16),children:rows.map((item)=>Card(child:ListTile(leading:const Icon(Icons.warning_amber),title:Text('${item['type']} • ${item['severity']}'),subtitle:Text('${item['description'] ?? ''}'),trailing:IconButton(icon:const Icon(Icons.camera_alt),onPressed:()=>photo(item)))).toList()));
}
