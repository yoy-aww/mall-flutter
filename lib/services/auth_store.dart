// 认证状态管理（对齐 mall-web/src/auth.ts）
// localStorage → shared_preferences；listeners → ChangeNotifier
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthStore extends ChangeNotifier {
  static const _storageKey = 'mall_auth';

  String? token;
  User? user;

  AuthStore() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final j = jsonDecode(raw);
        token = j['token'];
        if (j['user'] != null) user = User.fromJson(j['user']);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(
          _storageKey,
          jsonEncode({
            'token': token,
            'user': user?.toJson(),
          }));
    }
  }

  bool get isLoggedIn => token != null;

  Future<void> setLogin(String token, User user) async {
    this.token = token;
    this.user = user;
    await _save();
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    user = null;
    await _save();
    notifyListeners();
  }
}
