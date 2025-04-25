import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutterquiz/model/categories.dart';

class CategoryService {
  Future<List<Category>> fetchCategories() async {
    final response =
        await http.get(Uri.parse('http://localhost:3000/categories'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
