import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/app_database.dart';
import '../../core/services/backup_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pdf() => _run(() async {
    final d = AppDatabase.instance;
    final projects = await d.query('projects');
    final buildings = await d.query('buildings');
    final inspections = await d.query('inspections');
    final defects = await d.query('defects');
    final assessments = await d.query('assessments');
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(build: (c) => [
      pw.Header(level: 0, child: pw.Text('BUNYAN - Inspection Summary')),
      pw.Text('Generated: ${DateTime.now()}'),
      pw.Bullet(text: 'Projects: ${projects.length}'),
      pw.Bullet(text: 'Buildings: ${buildings.length}'),
      pw.Bullet(text: 'Inspections: ${inspections.length}'),
      pw.Bullet(text: 'Defects: ${defects.length}'),
      pw.Bullet(text: 'Assessments: ${assessments.length}'),
      pw.SizedBox(height: 15),
      pw.Text('This document organizes recorded inspection data and does not independently certify structural safety.'),
    ]));
    final bytes = await doc.save();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  });

  Future<void> backup() => _run(() async {
    final f = await BackupService().exportJson();
    await Share.shareXFiles([XFile(f.path)], text: 'BUNYAN backup file');
  });

  Future<void> restore() => _run(() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;
    await BackupService().importJson(File(result.files.single.path!));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت استعادة البيانات بنجاح.')));
  });

  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('التقارير والنسخ الاحتياطي')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: ListTile(leading: const Icon(Icons.picture_as_pdf), title: const Text('إنشاء تقرير PDF'), subtitle: const Text('ملخص بيانات المشروع والمعاينات'), enabled: !busy, onTap: pdf)),
      Card(child: ListTile(leading: const Icon(Icons.upload_file), title: const Text('تصدير نسخة احتياطية'), subtitle: const Text('إنشاء ملف JSON قابل للمشاركة والحفظ'), enabled: !busy, onTap: backup)),
      Card(child: ListTile(leading: const Icon(Icons.restore), title: const Text('استعادة نسخة احتياطية'), subtitle: const Text('استيراد ملف JSON من الهاتف'), enabled: !busy, onTap: restore)),
      if (busy) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
      const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('قبل استعادة نسخة احتياطية يُنصح بتصدير نسخة حديثة من البيانات الحالية.'))),
    ]),
  );
}
