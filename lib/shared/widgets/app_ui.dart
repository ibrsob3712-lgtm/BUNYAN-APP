import 'package:flutter/material.dart';
class AppSection extends StatelessWidget {
 final String title; final Widget child; const AppSection({super.key,required this.title,required this.child});
 @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))),child]);
}
class EmptyState extends StatelessWidget {
 final String title,message; final IconData icon; const EmptyState({super.key,required this.title,required this.message,required this.icon});
 @override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:60),const SizedBox(height:12),Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text(message,textAlign:TextAlign.center)])));
}
