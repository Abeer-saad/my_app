import 'package:flutter/material.dart';

// Presentation only: both versions use the same fields and API DTO names.
class LibraryForm extends StatefulWidget {
  const LibraryForm({
    super.key,
    required this.resource,
    this.record,
    required this.books,
    required this.categories,
    required this.customers,
  });
  final String resource;
  final Map<String, dynamic>? record;
  final List<dynamic> books, categories, customers;
  @override
  State<LibraryForm> createState() => _LibraryFormState();
}

class _LibraryFormState extends State<LibraryForm> {
  final formKey = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  int? bookId, categoryId, customerId;
  List<String> get keys => switch (widget.resource) {
    'Books' => ['title', 'author', 'price'],
    'Categories' => ['name'],
    'Customers' => ['name', 'email', 'phone'],
    _ => ['borrowDate', 'returnDate'],
  };
  @override
  void initState() {
    super.initState();
    for (final key in keys) {
      var value = widget.record?[key]?.toString() ?? '';
      if (key.endsWith('Date') && value.length >= 10) {
        value = value.substring(0, 10);
      }
      fields[key] = TextEditingController(text: value);
    }
    bookId = widget.record?['bookId'] as int?;
    categoryId = widget.record?['categoryId'] as int?;
    customerId = widget.record?['customerId'] as int?;
  }

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Widget select(
    String label,
    List<dynamic> values,
    int? value,
    ValueChanged<int?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<int>(
      initialValue: values.any((x) => x['id'] == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map(
            (x) => DropdownMenuItem<int>(
              value: x['id'] as int,
              child: Text((x['title'] ?? x['name']).toString()),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Choose $label' : null,
    ),
  );
  void submit() {
    if (!formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      for (final entry in fields.entries) entry.key: entry.value.text.trim(),
    };
    if (widget.record != null) data['uuid'] = widget.record!['uuid'];
    if (widget.resource == 'Books') {
      data['price'] = double.parse(fields['price']!.text);
      data['categoryId'] = categoryId;
    }
    if (widget.resource == 'Borrowings') {
      data['bookId'] = bookId;
      data['customerId'] = customerId;
      for (final key in ['borrowDate', 'returnDate']) {
        data[key] = DateTime.parse(fields[key]!.text).toIso8601String();
      }
      if (DateTime.parse(data['returnDate'] as String)
          .isBefore(DateTime.parse(data['borrowDate'] as String))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return date cannot be before borrow date'),
          ),
        );
        return;
      }
    }
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text((widget.record == null ? 'Add ' : 'Edit ') + widget.resource),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final key in keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: fields[key],
                keyboardType: key == 'price'
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                readOnly: key.endsWith('Date'),
                onTap: !key.endsWith('Date')
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.tryParse(fields[key]!.text) ??
                              DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2200),
                        );
                        if (date != null) {
                          fields[key]!.text = date.toIso8601String().substring(
                            0,
                            10,
                          );
                        }
                      },
                decoration: InputDecoration(
                  labelText: key,
                  hintText: key.endsWith('Date') ? 'Choose date' : null,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  if (key == 'price') {
                    final price = double.tryParse(value);
                    if (price == null || !price.isFinite || price < 0) {
                      return 'Enter a valid price';
                    }
                  }
                  if (key == 'email' &&
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
            ),
          if (widget.resource == 'Books')
            select(
              'Category',
              widget.categories,
              categoryId,
              (value) => categoryId = value,
            ),
          if (widget.resource == 'Borrowings') ...[
            select('Book', widget.books, bookId, (value) => bookId = value),
            select(
              'Customer',
              widget.customers,
              customerId,
              (value) => customerId = value,
            ),
          ],
          ElevatedButton(onPressed: submit, child: const Text('Save')),
        ],
      ),
    ),
  );
}
