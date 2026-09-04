import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  AppDatabase._(); static final instance=AppDatabase._(); Database? _db;
  Future<Database> get database async {
    if(_db!=null)return _db!;
    final dir=await getApplicationDocumentsDirectory();
    _db=await openDatabase(join(dir.path,'bunyan_v12.db'),version:3,onCreate:(db,v)=>_create(db));
    return _db!;
  }
  Future<void> _create(Database db) async {
    await db.execute('CREATE TABLE projects(id TEXT PRIMARY KEY,name TEXT,location TEXT,purpose TEXT,createdAt TEXT)');
    await db.execute('CREATE TABLE buildings(id TEXT PRIMARY KEY,projectId TEXT,name TEXT,type TEXT,structuralSystem TEXT,address TEXT)');
    await db.execute('CREATE TABLE floors(id TEXT PRIMARY KEY,buildingId TEXT,name TEXT,level INTEGER)');
    await db.execute('CREATE TABLE elements(id TEXT PRIMARY KEY,floorId TEXT,type TEXT,code TEXT,location TEXT,details TEXT)');
    await db.execute('CREATE TABLE inspections(id TEXT PRIMARY KEY,buildingId TEXT,engineer TEXT,date TEXT,status TEXT,notes TEXT)');
    await db.execute('CREATE TABLE defects(id TEXT PRIMARY KEY,inspectionId TEXT,elementId TEXT,type TEXT,severity TEXT,description TEXT,status TEXT,createdAt TEXT,updatedAt TEXT)');
    await db.execute('CREATE TABLE measurements(id TEXT PRIMARY KEY,defectId TEXT,label TEXT,value REAL,unit TEXT)');
    await db.execute('CREATE TABLE photos(id TEXT PRIMARY KEY,defectId TEXT,path TEXT,caption TEXT,createdAt TEXT)');
    await db.execute('CREATE TABLE tests(id TEXT PRIMARY KEY,elementId TEXT,type TEXT,result TEXT,unit TEXT,date TEXT,notes TEXT)');
    await db.execute('CREATE TABLE assessments(id TEXT PRIMARY KEY,defectId TEXT,priority TEXT,score INTEGER,conditionText TEXT,recommendation TEXT,createdAt TEXT)');
    await db.execute('CREATE TABLE defect_history(id TEXT PRIMARY KEY,defectId TEXT,action TEXT,note TEXT,createdAt TEXT)');
  }
  Future<List<Map<String,dynamic>>> query(String table,{String? where,List<Object?>? args,String? order}) async => (await database).query(table,where:where,whereArgs:args,orderBy:order);
  Future<void> insert(String table,Map<String,dynamic> data) async => (await database).insert(table,data);
  Future<void> update(String table,Map<String,dynamic> data,String where,List<Object?> args) async => (await database).update(table,data,where:where,whereArgs:args);
  Future<void> delete(String table,String where,List<Object?> args) async => (await database).delete(table,where:where,whereArgs:args);
  Future<int> count(String table) async => Sqflite.firstIntValue(await (await database).rawQuery('SELECT COUNT(*) FROM $table'))??0;
}
