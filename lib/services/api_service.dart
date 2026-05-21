import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  // Untuk Android emulator gunakan 10.0.2.2:3000
  // Untuk device nyata gunakan IP host misalnya 192.168.1.10:3000
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<List<Product>> fetchProducts() async {
    final uri = Uri.parse('$baseUrl/produk');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
    }

    throw Exception('Gagal memuat data produk: ${response.statusCode}');
  }
}
