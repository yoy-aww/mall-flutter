import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/common.dart';

class ProductListScreen extends StatefulWidget {
  final String? category;
  const ProductListScreen({super.key, this.category});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];
  List<Category> categories = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<Api>();
    try {
      final ps = await api.products();
      final cs = await api.categories();
      setState(() {
        products = ps;
        categories = cs;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = '加载失败，请稍后重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category ?? '';
    final filtered =
        cat.isEmpty ? products : products.where((p) => p.categoryId == cat).toList();
    final curCat = categories.where((c) => c.id == cat).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('${curCat?.name ?? '全部商品'} · ${filtered.length} 件',
              style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('全部', cat.isEmpty, () => context.go('/products')),
              ...categories.map((c) => _chip(c.name, cat == c.id,
                  () => context.go('/products?cat=${c.id}'))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text('😵 $error'))
                  : filtered.isEmpty
                      ? const Center(child: Text('暂无商品'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.68,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => ProductCard(p: filtered[i]),
                        ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF5B7C5D),
        labelStyle: TextStyle(color: on ? Colors.white : Colors.black87),
      ),
    );
  }
}
