// 外壳：顶部搜索栏 + 底部导航（对齐 mall-web App.tsx）
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/cart_store.dart';
import '../services/auth_store.dart';

class Shell extends StatelessWidget {
  final Widget child;
  const Shell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => context.go('/'),
          child: const Row(
            children: [
              Text('枸',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(width: 6),
              Text('道地本草', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          Consumer<CartStore>(
            builder: (_, cart, __) {
              final count = cart.summary.count;
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                onPressed: () => context.push('/cart'),
              );
            },
          ),
          Consumer<AuthStore>(
            builder: (_, auth, __) => IconButton(
              icon: auth.isLoggedIn
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white24,
                      child: Text(
                        (auth.user!.nickname.isNotEmpty
                                ? auth.user!.nickname
                                : auth.user!.username)
                            .characters
                            .first,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person_outline),
              onPressed: () => context.push('/profile'),
            ),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexFor(location),
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/products');
              break;
            case 2:
              context.go('/cart');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: '商品'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: '购物车'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }

  int _indexFor(String loc) {
    if (loc.startsWith('/products') || loc.startsWith('/search')) return 1;
    if (loc.startsWith('/cart') || loc.startsWith('/checkout')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  void _showSearch(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('搜索商品'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '搜 索 好 草 本'),
          onSubmitted: (q) {
            Navigator.pop(ctx);
            if (q.trim().isNotEmpty) {
              context.push('/search?q=${Uri.encodeComponent(q.trim())}');
            }
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final q = controller.text.trim();
              Navigator.pop(ctx);
              if (q.isNotEmpty) {
                context.push('/search?q=${Uri.encodeComponent(q)}');
              }
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }
}
