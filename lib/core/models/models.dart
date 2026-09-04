class ProjectModel {
  final String id, name, location, purpose, createdAt;
  ProjectModel({required this.id,required this.name,required this.location,required this.purpose,required this.createdAt});
  Map<String,dynamic> toMap()=>{'id':id,'name':name,'location':location,'purpose':purpose,'createdAt':createdAt};
  factory ProjectModel.fromMap(Map<String,dynamic> m)=>ProjectModel(id:m['id'],name:m['name']??'',location:m['location']??'',purpose:m['purpose']??'',createdAt:m['createdAt']??'');
}
class BuildingModel {
  final String id,projectId,name,type,structuralSystem,address;
  BuildingModel({required this.id,required this.projectId,required this.name,required this.type,required this.structuralSystem,required this.address});
  Map<String,dynamic> toMap()=>{'id':id,'projectId':projectId,'name':name,'type':type,'structuralSystem':structuralSystem,'address':address};
  factory BuildingModel.fromMap(Map<String,dynamic> m)=>BuildingModel(id:m['id'],projectId:m['projectId'],name:m['name']??'',type:m['type']??'',structuralSystem:m['structuralSystem']??'',address:m['address']??'');
}
