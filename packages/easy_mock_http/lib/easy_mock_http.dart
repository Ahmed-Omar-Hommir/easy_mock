/// Low-level HTTP mocking for tests, built on `dart:io` [HttpOverrides].
///
/// Goal: keep network tests easy to mock, easy to write, readable, and
/// maintainable. Instead of stubbing a transport package, this mocks HTTP at
/// the lowest level — the `dart:io` [HttpClient] that every client sits on.
/// Dio and `package:http` both create one under the hood, so a single
/// [HttpOverrides] swap covers both: the code under test keeps its real client
/// and injects nothing. Stub replies with [mockHttp]'s `when` and assert sends
/// with `verify`. Tests stay flat Arrange / Act / Assert:
///
/// ```dart
/// test('ping replies pong', () async {
///   // Arrange
///   final http = mockHttp();
///   http.when.get(
///     'https://www.example.com/api/ping',
///     response: {'pong': true},
///   );
///
///   // Act
///   final response = await Dio().get('https://www.example.com/api/ping');
///
///   // Assert
///   expect(response.data, {'pong': true});
///   http.verify.get('/api/ping').calledOnce;
/// });
/// ```
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

part 'src/models.dart';
part 'src/mock_http.dart';
part 'src/stubbing.dart';
part 'src/verification.dart';
part 'src/matching.dart';
part 'src/io_fakes.dart';
