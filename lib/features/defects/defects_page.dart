import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';

class DefectsPage extends StatefulWidget {
  final Map<String, dynamic> inspection;

  const DefectsPage({
    super.key,
    required this.inspection,
  });

  @override
  State<DefectsPage> createState() => _DefectsPageState();
}

class _DefectsPageState extends State<DefectsPage> {
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    rows = await AppDatabase.instance.query(
      'defects',
      where: 'inspectionId=?',
      args: [widget.inspection['id']],
      order: 'createdAt DESC',
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> add() async {
    final descriptionController = TextEditingController();

    String defectType = 'شرخ';
    String severity = 'متوسطة';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('تسجيل عيب'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: defectType,
                    items: const [
                      DropdownMenuItem(
                        value: 'شرخ',
                        child: Text('شرخ'),
                      ),
                      DropdownMenuItem(
                        value: 'تلف خرسانة',
                        child: Text('تلف خرسانة'),
                      ),
                      DropdownMenuItem(
                        value: 'تآكل',
                        child: Text('تآكل'),
                      ),
                      DropdownMenuItem(
                        value: 'هبوط/تشوه',
                        child: Text('هبوط/تشوه'),
                      ),
                      DropdownMenuItem(
                        value: 'رطوبة/تسرب',
                        child: Text('رطوبة/تسرب'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        defectType = value ?? defectType;
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: severity,
                    items: const [
                      DropdownMenuItem(
                        value: 'منخفضة',
                        child: Text('منخفضة'),
                      ),
                      DropdownMenuItem(
                        value: 'متوسطة',
                        child: Text('متوسطة'),
                      ),
                      DropdownMenuItem(
                        value: 'مرتفعة',
                        child: Text('مرتفعة'),
                      ),
                      DropdownMenuItem(
                        value: 'حرجة',
                        child: Text('حرجة'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        severity = value ?? severity;
                      });
                    },
                  ),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      final now = DateTime.now().toIso8601String();

      await AppDatabase.instance.insert(
        'defects',
        {
          'id': const Uuid().v4(),
          'inspectionId': widget.inspection['id'],
          'elementId': '',
          'type': defectType,
          'severity': severity,
          'description': descriptionController.text.trim(),
          'status': 'مفتوح',
          'createdAt': now,
          'updatedAt': now,
        },
      );

      await load();
    }

    descriptionController.dispose();
  }

  Future<void> photo(Map<String, dynamic> item) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (picked == null) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();

    final photosFolder = Directory(
      path.join(directory.path, 'photos'),
    );

    await photosFolder.create(recursive: true);

    final destination = path.join(
      photosFolder.path,
      '${const Uuid().v4()}${path.extension(picked.path)}',
    );

    await File(picked.path).copy(destination);

    await AppDatabase.instance.insert(
      'photos',
      {
        'id': const Uuid().v4(),
        'defectId': item['id'],
        'path': destination,
        'caption': '',
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العيوب المسجلة'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add_alert),
        label: const Text('عيب'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...rows.map(
            (item) => Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber),
                title: Text(
                  '${item['type']} • ${item['severity']}',
                ),
                subtitle: Text(
                  '${item['description'] ?? ''}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => photo(item),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
