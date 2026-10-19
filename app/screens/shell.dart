import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'downloads.dart';
import 'home.dart';
import 'library.dart';
import 'settings.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  static const _pages = [
    HomeScreen(),
    DownloadsScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final n = context.watch<AppState>().items.where((e) => e.active).length;
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _i, children: _pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          NavigationDestination(
              icon: Badge(
                isLabelVisible: n > 0,
                label: Text('$n'),
                child: const Icon(Icons.download_rounded),
              ),
              label: 'التحميلات'),
          const NavigationDestination(
              icon: Icon(Icons.folder_rounded), label: 'المكتبة'),
          const NavigationDestination(
              icon: Icon(Icons.tune_rounded), label: 'الإعدادات'),
        ],
      ),
    );
  }
}
