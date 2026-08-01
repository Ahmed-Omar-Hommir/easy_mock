import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http_pkg;

const baseUrl = 'https://www.example.com/api';
const cardsUrl = '$baseUrl/cards';
const pingUrl = '$baseUrl/ping';

Future<dynamic> getProductsV1() async {
  final response = await Dio().get<dynamic>(cardsUrl);
  return response.data;
}

Future<dynamic> getProductsV2() async {
  final response = await http_pkg.get(Uri.parse(cardsUrl));
  return jsonDecode(response.body);
}

Future<dynamic> getProductsWithAuth(String token) async {
  final response = await Dio().get<dynamic>(
    cardsUrl,
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data;
}

Future<dynamic> getProductsPage(int page) async {
  final response = await Dio().get<dynamic>(
    cardsUrl,
    queryParameters: {'page': page},
  );
  return response.data;
}

Future<dynamic> ping() async {
  final response = await Dio().get<dynamic>(pingUrl);
  return response.data;
}
