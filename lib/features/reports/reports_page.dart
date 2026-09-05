import 'dart:io';

import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../core/services/backup_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;

    setState(() {
      busy = true;
    });

    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تنفيذ العملية: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> generatePdf() {
    return _run(() async {
      final database = AppDatabase.instance;

      final projects = await database.query('projects');
      final buildings = await database.query('buildings');
      final inspections = await database.query('inspections');
      final defects = await database.query('defects');
      final assessments = await database.query('assessments');

      final document = pw.Document();

      document.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'BUNYAN - Inspection Summary',
              ),
            ),
            pw.Text(
              'Generated: ${DateTime.now()}',
            ),
            pw.Bullet(
              text: 'Projects: ${projects.length}',
            ),
            pw.Bullet(
              text: 'Buildings: ${buildings.length}',
            ),
            pw.Bullet(
              text: 'Inspections: ${inspections.length}',
            ),
            pw.Bullet(
              text: 'Defects: ${defects.length}',
            ),
            pw.Bullet(
              text: 'Assessments: ${assessments.length}',
            ),
            pw.SizedBox(height: 15),
            pw.Text(
              'This document organizes recorded inspection data and '
              'does not independently certify structural safety.',
            ),
          ],
        ),
      );

      final bytes = await document.save();

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
      );
    });
  }

  Future<void> exportBackup() {
    return _run(() async {
      final backupFile = await BackupService().exportJson();

      await Share.shareXFiles(
        [
          XFile(backupFile.path),
        ],
        text: 'BUNYAN backup file',
      );
    });
  }

  Future<void> restoreBackup() {
    return _run(() async {
      final result = await file_picker.FilePicker.pickFiles(
        type: file_picker.FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      final selectedPath = result.files.single.path;

      if (selectedPath == null) return;

      await BackupService().importJson(
        File(selectedPath),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تمت استعادة البيانات بنجاح.',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التقارير والنسخ الاحتياطي',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.picture_as_pdf,
              ),
              title: const Text(
                'إنشاء تقرير PDF',
              ),
              subtitle: const Text(
                'ملخص بيانات المشروع والمعاينات',
              ),
              enabled: !busy,
              onTap: busy ? null : generatePdf,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.upload_file,
              ),
              title: const Text(
                'تصدير نسخة احتياطية',
              ),
              subtitle: const Text(
                'إنشاء ملف JSON قابل للمشاركة والحفظ',
              ),
              enabled: !busy,
              onTap: busy ? null : exportBackup,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.restore,
              ),
              title: const Text(
                'استعادة نسخة احتياطية',
              ),
              subtitle: const Text(
                'استيراد ملف JSON من الهاتف',
              ),
              enabled: !busy,
              onTap: busy ? null : restoreBackup,
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'قبل استعادة نسخة احتياطية يُنصح بتصدير نسخة حديثة '
                'من البيانات الحالية.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
