import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'App1/screens/LibraryPages.dart' as app1;
import 'App2/screens/LibraryPages.dart' as app2;
import 'App2/providers/LibraryProvider.dart';
export 'connection.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Library Management',
    home: Scaffold(
      appBar: AppBar(title: const Text('Library Management')),
      body: Builder(
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const app1.MyApp()),
                ),
                child: const Text('App1 - HTTP'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => LibraryProvider(),
                      child: const app2.MyApp(),
                    ),
                  ),
                ),
                child: const Text('App2 - Provider'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
