import 'package:flutter/material.dart';

import '../data/LibraryService.dart';
import '../../LibraryForm.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.service});
  final LibraryService service;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String resource = 'Books';
  bool saving = false;
  late Future<List<dynamic>> records;
  List<dynamic> books = [], categories = [], customers = [];
  @override
  void initState() {
    super.initState();
    records = load();
  }

  Future<List<dynamic>> load() async {
    final result = await widget.service.getAll(resource);
    categories = await widget.service.getAll('Categories');
    books = await widget.service.getAll('Books');
    customers = await widget.service.getAll('Customers');
    return result;
  }

  void refresh() {
    setState(() {
      records = load();
    });
  }

  void message(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> edit([Map<String, dynamic>? record]) async {
    final data = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryForm(
          resource: resource,
          record: record,
          books: books,
          categories: categories,
          customers: customers,
        ),
      ),
    );
    if (data == null || !mounted) return;
    setState(() => saving = true);
    try {
      await widget.service.save(resource, data, editing: record != null);
      refresh();
    } catch (e) {
      message(e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> remove(Map<String, dynamic> record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: const Text('This action deletes this record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => saving = true);
    try {
      await widget.service.delete(resource, record['uuid'].toString());
      refresh();
    } catch (e) {
      message(e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget render(List<dynamic> data, bool busy, String? error) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          children: [
            for (final name in [
              'Books',
              'Categories',
              'Customers',
              'Borrowings',
            ])
              ChoiceChip(
                label: Text(name),
                selected: resource == name,
                onSelected: busy || saving
                    ? null
                    : (_) {
                        resource = name;
                        refresh();
                      },
              ),
          ],
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: busy || saving ? null : () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
          TextButton.icon(
            onPressed: busy || saving ? null : refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
      if (busy || saving) const LinearProgressIndicator(),
      if (error != null)
        Padding(padding: const EdgeInsets.all(16), child: Text(error)),
      Expanded(
        child: data.isEmpty
            ? Center(child: Text(busy ? 'Loading...' : 'No records'))
            : ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final record = Map<String, dynamic>.from(data[index] as Map);
                  final title =
                      (record['title'] ??
                              record['name'] ??
                              record['bookTitle'] ??
                              '')
                          .toString();
                  final details = record.entries
                      .where(
                        (entry) => ![
                          'id',
                          'uuid',
                          'title',
                          'name',
                        ].contains(entry.key),
                      )
                      .map((entry) => '${entry.key}: ${entry.value}')
                      .join('\n');
                  return Card(
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text(details),
                      onTap: busy || saving ? null : () => edit(record),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: busy || saving ? null : () => remove(record),
                      ),
                    ),
                  );
                },
              ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: records,
    builder: (context, snapshot) => render(
      snapshot.data ?? [],
      snapshot.connectionState == ConnectionState.waiting,
      snapshot.hasError ? snapshot.error.toString() : null,
    ),
  );
}
