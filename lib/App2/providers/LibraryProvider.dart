import 'package:flutter/foundation.dart';

import '../data/LibraryService.dart';

class LibraryProvider extends ChangeNotifier {
  final LibraryService _service = LibraryService();
  Map<String, dynamic>? user;
  bool isLoading = false;
  String? error;
  List<dynamic> records = [];
  List<dynamic> books = [];
  List<dynamic> categories = [];
  List<dynamic> customers = [];
  Future<void> login(Map<String, dynamic> data) async {
    user = await _service.login(data);
    notifyListeners();
  }

  Future<void> register(Map<String, dynamic> data) => _service.register(data);
  Future<void> logout() async {
    await _service.logout();
    user = null;
    records = [];
    books = [];
    categories = [];
    customers = [];
    notifyListeners();
  }

  Future<void> load(String resource) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      records = await _service.getAll(resource);
      categories = await _service.getAll('Categories');
      books = await _service.getAll('Books');
      customers = await _service.getAll('Customers');
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(
    String resource,
    Map<String, dynamic> data, {
    bool editing = false,
  }) async {
    await _service.save(resource, data, editing: editing);
    await load(resource);
  }

  Future<void> delete(String resource, String uuid) async {
    await _service.delete(resource, uuid);
    await load(resource);
  }
}
