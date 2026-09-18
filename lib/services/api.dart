// API 层（对齐 mall-web/src/api.ts 和 mallandroid/ApiClient.kt）
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'auth_store.dart';
import 'cart_store.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  static const baseUrl = 'http://43.153.148.187:3000/api';

  final AuthStore auth;
  Api(this.auth);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
      };

  Future<T> _request<T>(
    String path,
    T Function(dynamic) parse, {
    String method = 'GET',
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    http.Response res;
    switch (method) {
      case 'POST':
        res = await http.post(uri, headers: _headers, body: jsonEncode(body));
        break;
      case 'PUT':
        res = await http.put(uri, headers: _headers, body: jsonEncode(body ?? {}));
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: _headers);
        break;
      default:
        res = await http.get(uri, headers: _headers);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw ApiException(json['error'] ?? '请求失败 (${res.statusCode})');
    }
    return parse(json['data']);
  }

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) from) =>
      (data as List?)
              ?.map((e) => from(Map<String, dynamic>.from(e)))
              .toList() ??
          [];

  // ===== Banners / Categories / Products =====
  Future<List<StoreBanner>> banners() =>
      _request('/banners', (d) => _list(d, StoreBanner.fromJson));
  Future<List<Category>> categories() =>
      _request('/categories', (d) => _list(d, Category.fromJson));
  Future<List<Product>> products() =>
      _request('/products', (d) => _list(d, Product.fromJson));
  Future<Product> productById(String id) =>
      _request('/products/$id', (d) => Product.fromJson(d));
  Future<List<Product>> productsByCategory(String cat) =>
      _request('/products/category/$cat', (d) => _list(d, Product.fromJson));
  Future<List<Product>> popular() =>
      _request('/products/popular', (d) => _list(d, Product.fromJson));
  Future<List<Product>> search(String q) =>
      _request('/products/search?q=${Uri.encodeComponent(q)}',
          (d) => _list(d, Product.fromJson));

  // ===== Auth =====
  Future<({String token, User user})> login(
      String username, String password) async {
    final d = await _request(
      '/auth/login',
      (d) => d,
      method: 'POST',
      body: {'username': username, 'password': password},
    );
    return (
      token: d['token'] as String,
      user: User.fromJson(Map<String, dynamic>.from(d['user'])),
    );
  }

  Future<({String token, User user})> register(String username, String password,
      {String? nickname, String? phone}) async {
    final d = await _request(
      '/auth/register',
      (d) => d,
      method: 'POST',
      body: {
        'username': username,
        'password': password,
        if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    return (
      token: d['token'] as String,
      user: User.fromJson(Map<String, dynamic>.from(d['user'])),
    );
  }

  Future<void> updateMe({String? nickname, String? phone}) => _request(
        '/auth/users/${auth.user?.id}',
        (d) => d,
        method: 'PUT',
        body: {
          if (nickname != null) 'nickname': nickname,
          if (phone != null) 'phone': phone,
        },
      );

  Future<void> changePassword(String oldP, String newP) => _request(
        '/auth/change-password',
        (d) => d,
        method: 'POST',
        body: {'oldPassword': oldP, 'newPassword': newP},
      );

  // ===== Orders =====
  Future<List<Order>> myOrders() =>
      _request('/orders?userId=${auth.user?.id ?? ''}', (d) {
        if (d is List) return _list(d, Order.fromJson);
        return _list(d['list'], Order.fromJson);
      });

  Future<Order> orderById(String id) =>
      _request('/orders/$id', (d) => Order.fromJson(d));

  Future<OrderPreview> previewOrder(List<CartItem> items, String method) =>
      _request(
        '/orders/preview',
        (d) => OrderPreview.fromJson(d),
        method: 'POST',
        body: {
          'items': items
              .map((e) => {'productId': e.id, 'quantity': e.quantity})
              .toList(),
          'shippingMethod': method,
        },
      );

  Future<OrderCreateResult> createOrder({
    required List<CartItem> items,
    required String shippingAddress,
    required String receiverName,
    required String receiverPhone,
    String? remark,
    String shippingMethod = 'standard',
  }) =>
      _request(
        '/orders',
        (d) => OrderCreateResult.fromJson(d),
        method: 'POST',
        body: {
          'items': items
              .map((e) => {'productId': e.id, 'quantity': e.quantity})
              .toList(),
          'shippingAddress': shippingAddress,
          'receiverName': receiverName,
          'receiverPhone': receiverPhone,
          'shippingMethod': shippingMethod,
          if (remark != null && remark.isNotEmpty) 'remark': remark,
        },
      );

  Future<Order> orderAction(String id, String action,
          {String? reason}) =>
      _request('/orders/$id/$action', (d) => Order.fromJson(d),
          method: 'POST',
          body: reason != null ? {'reason': reason} : {});

  // ===== Reviews =====
  Future<List<Review>> reviews(String productId) =>
      _request('/reviews?productId=${Uri.encodeComponent(productId)}',
          (d) => _list(d, Review.fromJson));
  Future<ReviewStats> reviewStats(String productId) => _request(
      '/reviews/product/${Uri.encodeComponent(productId)}/stats',
      (d) => ReviewStats.fromJson(d));
  Future<void> createReview({
    required String productId,
    required int rating,
    required String content,
    List<String>? images,
  }) =>
      _request('/reviews', (d) => d,
          method: 'POST',
          body: {
            'productId': productId,
            'userId': auth.user?.id ?? '',
            'rating': rating,
            'content': content,
            if (images != null) 'images': images,
          });

  // ===== Upload =====
  Future<String> uploadImage(File file) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'))
      ..headers.addAll({
        if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
      })
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final res = await req.send();
    final body = jsonDecode(await res.stream.bytesToString());
    if (body['success'] != true) {
      throw ApiException(body['error'] ?? '上传失败');
    }
    return body['data']['url'] as String;
  }

  // ===== Addresses =====
  Future<List<Address>> addresses() =>
      _request('/addresses', (d) => _list(d, Address.fromJson));
  Future<void> createAddress(Address a) =>
      _request('/addresses', (d) => d, method: 'POST', body: a.toJson());
  Future<void> updateAddress(String id, Address a) =>
      _request('/addresses/$id', (d) => d, method: 'PUT', body: a.toJson());
  Future<void> deleteAddress(String id) =>
      _request('/addresses/$id', (d) => d, method: 'DELETE');

  // ===== After-sales =====
  Future<List<AfterSale>> aftersales() =>
      _request('/aftersales', (d) => _list(d, AfterSale.fromJson));
  Future<void> createAfterSale({
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    required String description,
  }) =>
      _request('/aftersales', (d) => d,
          method: 'POST',
          body: {
            'orderId': orderId,
            'items': items,
            'reason': reason,
            'description': description,
          });

  // ===== Notifications =====
  Future<NotificationResponse> notifications() =>
      _request('/notifications', (d) => NotificationResponse.fromJson(d));
  Future<void> markRead(String id) =>
      _request('/notifications/$id/read', (d) => d, method: 'PUT');
  Future<void> markAllRead() =>
      _request('/notifications/all/read', (d) => d, method: 'PUT');

  // ===== RAG =====
  Future<Map<String, dynamic>> ragAsk(String question) =>
      _request('/rag/ask', (d) => Map<String, dynamic>.from(d),
          method: 'POST', body: {'question': question});
}
