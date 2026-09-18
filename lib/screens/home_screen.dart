import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart' hide Banner;
import '../services/api.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<StoreBanner> banners = [];
  List<Category> categories = [];
  List<Product> popular = [];
  bool loading = true;
  int _bannerIndex = 0;
  Timer? _timer;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<Api>();
    try {
      final results = await Future.wait([
        api.banners().catchError((_) => <StoreBanner>[]),
        api.categories(),
        api.popular(),
      ]);
      setState(() {
        banners = results[0] as List<StoreBanner>;
        categories = results[1] as List<Category>;
        popular = results[2] as List<Product>;
        loading = false;
      });
      if (banners.length > 1) {
        _timer = Timer.periodic(const Duration(seconds: 4), (_) {
          _bannerIndex = (_bannerIndex + 1) % banners.length;
          _pageController.animateToPage(_bannerIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        });
      }
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String? _bannerLink(String link) {
    if (link.isEmpty) return null;
    if (link.startsWith('/') && !link.contains('/pages/')) return link;
    final m = RegExp(r'type=([\w-]+)').firstMatch(link);
    if (m != null) return '/products?cat=${m[1]}';
    final p = RegExp(r'product/product\?id=(\w+)').firstMatch(link);
    if (p != null) return '/products/${p[1]}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🍵', style: TextStyle(fontSize: 40)),
          SizedBox(height: 8),
          Text('加载中…', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          if (banners.isNotEmpty)
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _bannerIndex = i),
                itemCount: banners.length,
                itemBuilder: (_, i) {
                  final b = banners[i];
                  final target = _bannerLink(b.link);
                  return GestureDetector(
                    onTap: target != null ? () => context.push(target) : null,
                    child: Stack(fit: StackFit.expand, children: [
                      NetImage(b.image),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5)
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text(b.subtitle,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),
          _Section('品类导航', '按品类逛好物'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 1.6, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final c = categories[i];
                return Card(
                  child: InkWell(
                    onTap: () => context.push('/products?cat=${c.id}'),
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(c.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${c.productCount} 件',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
          _Section('热销好物', '精选道地本草'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8),
              itemCount: popular.length,
              itemBuilder: (_, i) => ProductCard(p: popular[i]),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/products'),
            child: const Text('查看全部商品 →'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title, sub;
  const _Section(this.title, this.sub);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title,
              style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
