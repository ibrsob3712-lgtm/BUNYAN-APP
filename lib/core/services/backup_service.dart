import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';

class BackupService {
  static const tables=['projects','buildings','floors','elements','inspections','defects','measurements','photos','tests','assessments','defect_history'];
  Future<File> exportJson() async {
    final db=AppDatabase.instance; final data=<String,dynamic>{'version':'1.2.0','createdAt':DateTime.now().toIso8601String()};
    for(final t in tables){data[t]=await db.query(t);}
    final dir=await getApplicationDocumentsDirectory();
    final file=File(join(dir.path,'bunyan_backup_${DateTime.now().millisecondsSinceEpoch}.json'));
    return file.writeAsString(jsonEncode(data));
  }
  Future<void> importJson(File file) async {
    final decoded=jsonDecode(await file.readAsString());
    if(decoded is! Map) throw const FormatException('ملف النسخة الاحتياطية غير صالح');
    final map=Map<String,dynamic>.from(decoded);
    final database=await AppDatabase.instance.database;
    await database.transaction((txn) async {
      for(final t in tables){if(map[t] is List){for(final row in map[t]){await txn.insert(t,Map<String,dynamic>.from(row),conflictAlgorithm:ConflictAlgorithm.replace);}}}
    });
  }
}
