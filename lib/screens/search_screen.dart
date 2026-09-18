import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/common.dart';

class SearchScreen extends StatefulWidget {
  final String q;
  const SearchScreen({super.key, required this.q});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Product> results = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      results = await context.read<Api>().search(widget.q);
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text('搜索「${widget.q}」 · ${results.length} 件',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      Expanded(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text('😵 $error'))
                : results.isEmpty
                    ? const Center(child: Text('没有找到相关商品'))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8),
                        itemCount: results.length,
                        itemBuilder: (_, i) => ProductCard(p: results[i]),
                      ),
      ),
    ]);
  }
}
