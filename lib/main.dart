import 'package:flutter/material.dart';
import 'injection_container.dart' as di;
import 'features/todo/presentation/pages/todo_page.dart';
import 'core/sync/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await di.init();

  // Start background sync service
  final syncService = di.sl<SyncService>();
  syncService.startPeriodicSync();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App - Offline First',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const TodoPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
