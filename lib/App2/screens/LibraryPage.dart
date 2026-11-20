import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/LibraryProvider.dart';
import '../../LibraryForm.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String resource = 'Books';
  bool saving = false;
  LibraryProvider get state => context.read<LibraryProvider>();
  List<dynamic> get books => state.books;
  List<dynamic> get categories => state.categories;
  List<dynamic> get customers => state.customers;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) refresh();
    });
  }

  void refresh() {
    state.load(resource);
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
      await state.save(resource, data, editing: record != null);
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
      await state.delete(resource, record['uuid'].toString());
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
                        setState(() => resource = name);
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
  Widget build(BuildContext context) => Consumer<LibraryProvider>(
    builder: (context, provider, child) =>
        render(provider.records, provider.isLoading, provider.error),
  );
}
