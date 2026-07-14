import 'package:flutter/material.dart';
import 'package:nusa_admin/core/theme.dart';
import 'package:nusa_admin/features/admin/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NusaAdminApp());
}

class NusaAdminApp extends StatelessWidget {
  const NusaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NUSA Admin',
      debugShowCheckedModeBanner: false,
      theme: NusaTheme.light,
      home: const AdminDashboardScreen(),
    );
  }
}
