import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../inspections/inspections_page.dart';

class BuildingsPage extends StatefulWidget {
  final Map<String, dynamic> project;

  const BuildingsPage({
    super.key,
    required this.project,
  });

  @override
  State<BuildingsPage> createState() => _BuildingsPageState();
}

class _BuildingsPageState extends State<BuildingsPage> {
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    rows = await AppDatabase.instance.query(
      'buildings',
      where: 'projectId=?',
      args: [widget.project['id']],
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> add() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    String buildingType = 'سكني';
    String structuralSystem = 'خرسانة مسلحة';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة مبنى'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المبنى',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: buildingType,
                    items: const [
                      DropdownMenuItem(
                        value: 'سكني',
                        child: Text('سكني'),
                      ),
                      DropdownMenuItem(
                        value: 'إداري',
                        child: Text('إداري'),
                      ),
                      DropdownMenuItem(
                        value: 'تعليمي',
                        child: Text('تعليمي'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        buildingType = value ?? buildingType;
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: structuralSystem,
                    items: const [
                      DropdownMenuItem(
                        value: 'خرسانة مسلحة',
                        child: Text('خرسانة مسلحة'),
                      ),
                      DropdownMenuItem(
                        value: 'صلب',
                        child: Text('صلب'),
                      ),
                      DropdownMenuItem(
                        value: 'مختلط',
                        child: Text('مختلط'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        structuralSystem =
                            value ?? structuralSystem;
                      });
                    },
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
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

    if (ok == true && nameController.text.trim().isNotEmpty) {
      await AppDatabase.instance.insert(
        'buildings',
        {
          'id': const Uuid().v4(),
          'projectId': widget.project['id'],
          'name': nameController.text.trim(),
          'type': buildingType,
          'structuralSystem': structuralSystem,
          'address': addressController.text.trim(),
        },
      );

      await load();
    }

    nameController.dispose();
    addressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.project['name']}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'المباني',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...rows.map(
            (building) => Card(
              child: ListTile(
                title: Text(
                  '${building['name']}',
                ),
                subtitle: Text(
                  '${building['type']} • '
                  '${building['structuralSystem']}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuildingInspectionPage(
                        building: building,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
