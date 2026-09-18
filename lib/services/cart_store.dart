// 购物车（对齐 mall-web/src/cart.ts：按用户隔离、游客合并、登录迁移）
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_store.dart';

class CartItem {
  final String id;
  final String name;
  final String image;
  final double price;
  final double originalPrice;
  final int stock;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.stock,
    this.quantity = 1,
  });

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: j['id'],
        name: j['name'],
        image: j['image'],
        price: (j['price'] as num).toDouble(),
        originalPrice: (j['originalPrice'] as num).toDouble(),
        stock: j['stock'] ?? 0,
        quantity: j['quantity'] ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'price': price,
        'originalPrice': originalPrice,
        'stock': stock,
        'quantity': quantity,
      };
}

class CartStore extends ChangeNotifier {
  static const _legacyKey = 'guyibu_cart';
  static const _guestKey = 'guyibu_cart_guest';
  static const _prefix = 'guyibu_cart_';

  final AuthStore auth;
  List<CartItem> items = [];

  CartStore(this.auth) {
    _load();
    auth.addListener(_onAuthChanged);
  }

  String _keyFor(String? userId) =>
      userId == null ? _guestKey : '$_prefix$userId';

  void _onAuthChanged() {
    final userId = auth.user?.id;
    if (userId != null) _mergeGuestInto(userId);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(auth.user?.id);
    // legacy 一次性迁移
    final legacy = prefs.getString(_legacyKey);
    if (legacy != null && prefs.getString(key) == null) {
      await prefs.setString(key, legacy);
      await prefs.remove(_legacyKey);
    }
    items = _parse(prefs.getString(key));
    notifyListeners();
  }

  List<CartItem> _parse(String? raw) {
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(auth.user?.id);
    await prefs.setString(
        key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> _mergeGuestInto(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final guest = _parse(prefs.getString(_guestKey));
    if (guest.isEmpty) return;
    final base = _parse(prefs.getString('$_prefix$userId'));
    for (final g in guest) {
      final idx = base.indexWhere((x) => x.id == g.id);
      if (idx >= 0) {
        base[idx].quantity =
            (base[idx].quantity + g.quantity).clamp(0, g.stock);
      } else {
        base.add(g);
      }
    }
    await prefs.setString(
        '$_prefix$userId', jsonEncode(base.map((e) => e.toJson()).toList()));
    await prefs.remove(_guestKey);
  }

  Future<void> _update(List<CartItem> Function(List<CartItem>) fn) async {
    items = fn(List.of(items));
    await _persist();
    notifyListeners();
  }

  void add(CartItem item, [int n = 1]) {
    _update((list) {
      final idx = list.indexWhere((x) => x.id == item.id);
      if (idx >= 0) {
        list[idx].quantity = (list[idx].quantity + n).clamp(0, item.stock);
      } else {
        item.quantity = n.clamp(1, item.stock);
        list.add(item);
      }
      return list;
    });
  }

  void setQuantity(String id, int qty) {
    _update((list) {
      final idx = list.indexWhere((x) => x.id == id);
      if (idx < 0) return list;
      final q = qty.clamp(0, list[idx].stock);
      if (q == 0) {
        list.removeAt(idx);
      } else {
        list[idx].quantity = q;
      }
      return list;
    });
  }

  void remove(String id) =>
      _update((list) => list.where((x) => x.id != id).toList());

  void clear() => _update((_) => []);

  ({double total, int count}) get summary => items.fold(
        (total: 0.0, count: 0),
        (s, x) => (total: s.total + x.price * x.quantity, count: s.count + x.quantity),
      );
}
