import 'package:flutter/material.dart';
import '../core/database/app_database.dart';
import '../features/dashboard/dashboard_page.dart';

class BunyanApp extends StatefulWidget {
  const BunyanApp({super.key});
  @override State<BunyanApp> createState() => _BunyanAppState();
}
class _BunyanAppState extends State<BunyanApp> {
  Future<void>? _init;
  @override void initState() { super.initState(); _init = AppDatabase.instance.database.then((_) {}); }
  @override Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'بُنيان',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff174A7C)),
            scaffoldBackgroundColor: const Color(0xffF5F7FA),
            inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
          ),
          home: const Directionality(textDirection: TextDirection.rtl, child: DashboardPage()),
        );
      },
    );
  }
}
