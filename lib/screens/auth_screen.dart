import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api.dart';
import '../services/auth_store.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool loading = false;
  String error = '';
  final userCtl = TextEditingController();
  final passCtl = TextEditingController();
  final nickCtl = TextEditingController();
  final phoneCtl = TextEditingController();

  Future<void> _submit() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final api = context.read<Api>();
      final auth = context.read<AuthStore>();
      final r = isLogin
          ? await api.login(userCtl.text.trim(), passCtl.text)
          : await api.register(userCtl.text.trim(), passCtl.text,
              nickname: nickCtl.text.trim(), phone: phoneCtl.text.trim());
      await auth.setLogin(r.token, r.user);
      if (mounted) {
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(from ?? '/');
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(isLogin ? '登录' : '注册',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('道地本草 · 中药材商城',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  if (!isLogin) ...[
                    TextField(
                        controller: nickCtl,
                        decoration:
                            const InputDecoration(labelText: '昵称')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: phoneCtl,
                        decoration:
                            const InputDecoration(labelText: '手机号（可选）'),
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                      controller: userCtl,
                      decoration: const InputDecoration(
                          labelText: '用户名（至少 3 位）')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: passCtl,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText:
                              isLogin ? '密码' : '密码（至少 6 位）')),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : _submit,
                      child: Text(loading
                          ? '处理中...'
                          : isLogin
                              ? '登 录'
                              : '注 册'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      isLogin = !isLogin;
                      error = '';
                    }),
                    child: Text(isLogin
                        ? '还没有账号？立即注册'
                        : '已有账号？去登录'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
