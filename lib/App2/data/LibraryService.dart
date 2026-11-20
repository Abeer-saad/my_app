import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../connection.dart';

class LibraryService {
  String? _cookie;
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_cookie != null) headers['Cookie'] = _cookie!;
    final uri = Uri.parse('$apiUrl/api/$path');
    final http.Response response;
    switch (method) {
      case 'POST':
        response = await http
            .post(uri, headers: headers, body: jsonEncode(data))
            .timeout(const Duration(seconds: 20));
      case 'PUT':
        response = await http
            .put(uri, headers: headers, body: jsonEncode(data))
            .timeout(const Duration(seconds: 20));
      case 'DELETE':
        response = await http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
      default:
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
    }
    final cookie = response.headers['set-cookie'];
    if (cookie != null) _cookie = cookie.split(';').first;
    dynamic result;
    if (response.body.isNotEmpty) {
      try {
        result = jsonDecode(response.body);
      } catch (_) {
        result = response.body;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        result is Map
            ? result['message'] ?? result['title'] ?? 'Request failed'
            : result ?? 'Request failed: ${response.statusCode}',
      );
    }
    return result;
  }

  Future<List<dynamic>> getAll(String resource) async =>
      List<dynamic>.from(await request(resource) as List);
  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async =>
      Map<String, dynamic>.from(
        await request('users/login', method: 'POST', data: data) as Map,
      );
  Future<void> register(Map<String, dynamic> data) async {
    await request('users/register', method: 'POST', data: data);
  }

  Future<void> logout() async {
    await request('users/logout', method: 'POST');
    _cookie = null;
  }

  Future<void> save(
    String resource,
    Map<String, dynamic> data, {
    bool editing = false,
  }) async {
    await request(resource, method: editing ? 'PUT' : 'POST', data: data);
  }

  Future<void> delete(String resource, String uuid) async {
    await request('$resource/$uuid', method: 'DELETE');
  }
}
