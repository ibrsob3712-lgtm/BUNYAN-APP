import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../defects/defects_page.dart';

class InspectionsPage extends StatefulWidget {
  const InspectionsPage({super.key});

  @override
  State<InspectionsPage> createState() => _InspectionsPageState();
}

class _InspectionsPageState extends State<InspectionsPage> {
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> buildings = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    rows = await AppDatabase.instance.query(
      'inspections',
      order: 'date DESC',
    );

    buildings = await AppDatabase.instance.query(
      'buildings',
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> start() async {
    if (buildings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف مبنى أولًا'),
        ),
      );
      return;
    }

    String buildingId = '${buildings.first['id']}';
    final engineerController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('بدء معاينة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: buildingId,
                    items: buildings
                        .map(
                          (building) => DropdownMenuItem<String>(
                            value: '${building['id']}',
                            child: Text(
                              '${building['name']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        buildingId = value ?? buildingId;
                      });
                    },
                  ),
                  TextField(
                    controller: engineerController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المهندس',
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
                  child: const Text('بدء'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true && engineerController.text.trim().isNotEmpty) {
      await AppDatabase.instance.insert(
        'inspections',
        {
          'id': const Uuid().v4(),
          'buildingId': buildingId,
          'engineer': engineerController.text.trim(),
          'date': DateTime.now().toIso8601String(),
          'status': 'نشطة',
          'notes': '',
        },
      );

      await load();
    }

    engineerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعاينات'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: start,
        icon: const Icon(Icons.play_arrow),
        label: const Text('بدء'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...rows.map(
            (inspection) {
              final dateText =
                  '${inspection['date'] ?? ''}'.length >= 10
                      ? '${inspection['date']}'.substring(0, 10)
                      : '${inspection['date'] ?? ''}';

              return Card(
                child: ListTile(
                  title: Text(
                    'معاينة $dateText',
                  ),
                  subtitle: Text(
                    'المهندس: ${inspection['engineer']}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DefectsPage(
                          inspection: inspection,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BuildingInspectionPage extends StatelessWidget {
  final Map<String, dynamic> building;

  const BuildingInspectionPage({
    super.key,
    required this.building,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${building['name']}'),
      ),
      body: const Center(
        child: Text(
          'يمكن بدء معاينة هذا المبنى من تبويب المعاينة الميدانية.',
        ),
      ),
    );
  }
}
