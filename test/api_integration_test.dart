import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/App2/providers/LibraryProvider.dart';
import 'package:my_app/App1/data/LibraryService.dart' as app1;
import 'package:my_app/App2/data/LibraryService.dart' as app2;

void main() {
  const enabled = bool.fromEnvironment('RUN_API_TESTS');
  const runId = String.fromEnvironment('TEST_RUN_ID', defaultValue: 'manual');
  for (final variant in ['App1', 'App2']) {
    test('$variant authenticated library CRUD round trip', () async {
      final dynamic service = variant == 'App1'
          ? app1.LibraryService()
          : app2.LibraryService();
      final username = 'verify_${runId}_$variant';
      final email = '${username.toLowerCase()}@example.invalid';
      final account = <String, dynamic>{
        'name': 'Integration verification',
        'email': email,
        'username': username,
        'password': 'VerifyOnly-$runId!',
      };
      await service.register(account);
      await expectLater(service.register(account), throwsException);
      final user = await service.login({
        'email': email,
        'password': account['password'],
      });
      expect(user['username'], username);
      expect(user.containsKey('passwordHash'), isFalse);
      if (variant == 'App2') {
        final provider = LibraryProvider();
        await provider.login({'email': email, 'password': account['password']});
        expect(provider.user?['username'], username);
        await provider.load('Books');
        expect(provider.error, isNull);
        expect(provider.isLoading, isFalse);
        await provider.logout();
        expect(provider.user, isNull);
        provider.dispose();
      }
      Map<String, dynamic>? category, book, customer, borrowing;
      Future<Map<String, dynamic>> findRecord(
        String resource,
        String key,
        String value,
      ) async {
        final List<dynamic> data = await service.getAll(resource);
        return Map<String, dynamic>.from(
          data.singleWhere((dynamic item) => item[key] == value) as Map,
        );
      }

      try {
        await service.save('Categories', {'name': username});
        category = await findRecord('Categories', 'name', username);
        await service.save('Books', {
          'title': username,
          'author': 'Verification',
          'price': 12.5,
          'categoryId': category['id'],
        });
        book = await findRecord('Books', 'title', username);
        expect(book['categoryName'], username);
        await service.save('Books', {
          'uuid': book['uuid'],
          'title': username,
          'author': 'Updated',
          'price': 15,
          'categoryId': category['id'],
        }, editing: true);
        book = await findRecord('Books', 'title', username);
        expect(book['author'], 'Updated');
        await expectLater(
          service.delete('Categories', category['uuid']),
          throwsException,
        );
        await service.save('Customers', {
          'name': username,
          'email': email,
          'phone': '0500000000',
        });
        customer = await findRecord('Customers', 'name', username);
        await expectLater(
          service.save('Borrowings', {
            'bookId': book['id'],
            'customerId': customer['id'],
            'borrowDate': '2026-11-16',
            'returnDate': '2026-11-15',
          }),
          throwsException,
        );
        await service.save('Borrowings', {
          'bookId': book['id'],
          'customerId': customer['id'],
          'borrowDate': '2026-11-16',
          'returnDate': '2026-11-23',
        });
        borrowing = await findRecord('Borrowings', 'bookTitle', username);
        expect(borrowing['customerName'], username);
        await expectLater(
          service.delete('Books', book['uuid']),
          throwsException,
        );
        await expectLater(
          service.delete('Customers', customer['uuid']),
          throwsException,
        );
        final details = await service.request("Books/${book['uuid']}");
        expect(details['title'], username);
        await expectLater(
          service.request('Books/not-a-record'),
          throwsException,
        );
      } finally {
        if (borrowing != null) {
          await service.delete('Borrowings', borrowing['uuid']);
        }
        if (book != null) await service.delete('Books', book['uuid']);
        if (customer != null) {
          await service.delete('Customers', customer['uuid']);
        }
        if (category != null) {
          await service.delete('Categories', category['uuid']);
        }
      }
      await service.logout();
      await expectLater(service.getAll('Books'), throwsException);
    }, skip: !enabled);
  }
}
