import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../services/auth_store.dart';
import '../services/cart_store.dart';
import '../widgets/common.dart';

class ProductDetailScreen extends StatefulWidget {
  final String id;
  const ProductDetailScreen({super.key, required this.id});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? p;
  String? categoryName;
  List<Review> reviews = [];
  ReviewStats stats = ReviewStats();
  bool error = false;
  bool showForm = false;
  int rating = 5;
  final contentCtl = TextEditingController();
  List<String> images = [];
  bool uploading = false;
  bool submitting = false;
  String msg = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<Api>();
    try {
      final prod = await api.productById(widget.id);
      setState(() => p = prod);
      api.categories().then((cs) {
        final c = cs.where((x) => x.id == prod.categoryId).firstOrNull;
        if (c != null && mounted) setState(() => categoryName = c.name);
      }).catchError((_) {});
    } catch (_) {
      setState(() => error = true);
    }
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final api = context.read<Api>();
    api.reviews(widget.id).then((r) => setState(() => reviews = r)).catchError((_) {});
    api.reviewStats(widget.id).then((s) => setState(() => stats = s)).catchError((_) {});
  }

  Future<void> _pickImages() async {
    if (images.length >= 6) {
      setState(() => msg = '最多上传6张图片');
      return;
    }
    final picked = await ImagePicker().pickMultiImage(limit: 6 - images.length);
    if (picked.isEmpty) return;
    setState(() => uploading = true);
    try {
      final api = context.read<Api>();
      for (final f in picked) {
        final url = await api.uploadImage(File(f.path));
        images.add(url);
      }
      setState(() {});
    } catch (e) {
      setState(() => msg = e.toString());
    } finally {
      setState(() => uploading = false);
    }
  }

  Future<void> _submitReview() async {
    final auth = context.read<AuthStore>();
    if (!auth.isLoggedIn) return;
    if (contentCtl.text.trim().isEmpty) {
      setState(() => msg = '请写几句评价');
      return;
    }
    setState(() {
      submitting = true;
      msg = '';
    });
    try {
      await context.read<Api>().createReview(
          productId: widget.id,
          rating: rating,
          content: contentCtl.text.trim(),
          images: images);
      setState(() {
        showForm = false;
        contentCtl.clear();
        images = [];
        rating = 5;
        msg = '评价成功，感谢您的反馈！';
      });
      _loadReviews();
    } catch (e) {
      setState(() => msg = e.toString());
    } finally {
      setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prod = p;
    if (error) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('😵', style: TextStyle(fontSize: 48)),
          const Text('商品不存在'),
          TextButton(
              onPressed: () => context.go('/products'),
              child: const Text('← 返回列表')),
        ]),
      );
    }
    if (prod == null) return const Center(child: CircularProgressIndicator());

    final price = prod.price;
    final save =
        prod.discountedPrice != null ? prod.originalPrice - price : 0.0;
    final auth = context.watch<AuthStore>();

    return ListView(
      children: [
        AspectRatio(aspectRatio: 1, child: NetImage(prod.image)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (prod.tags.isNotEmpty)
              Wrap(
                  spacing: 6,
                  children: prod.tags.map((t) => TagChip(t)).toList()),
            const SizedBox(height: 8),
            Text(prod.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (categoryName != null)
              Text('分类：$categoryName',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: [
              Text('¥${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              if (prod.discountedPrice != null) ...[
                const SizedBox(width: 8),
                Text('¥${prod.originalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 8),
                TagChip('省 ¥${save.toStringAsFixed(0)}',
                    color: Colors.red.shade50, textColor: Colors.red),
              ],
            ]),
            const SizedBox(height: 4),
            Text('库存：${prod.stock} 件',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            const Text('商品简介',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(prod.description),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('加入购物车'),
                onPressed: () {
                  context.read<CartStore>().add(CartItem(
                      id: prod.id,
                      name: prod.name,
                      image: prod.image,
                      price: price,
                      originalPrice: prod.originalPrice,
                      stock: prod.stock));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已加入购物车')));
                },
              ),
            ),
          ]),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('用户评价 (${stats.total})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (stats.total > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Text(stats.avg.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Stars(value: stats.avg.round()),
                  const SizedBox(width: 8),
                  Text('${stats.total} 条评价',
                      style: const TextStyle(color: Colors.grey)),
                ]),
              ),
            if (msg.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(msg),
              ),
            if (!auth.isLoggedIn)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  onTap: () =>
                      context.push('/auth?from=/products/${widget.id}'),
                  child: const Text.rich(TextSpan(children: [
                    TextSpan(
                        text: '登录',
                        style: TextStyle(color: Color(0xFF5B7C5D))),
                    TextSpan(text: ' 后可以写评价'),
                  ])),
                ),
              )
            else if (!showForm && msg.isEmpty)
              OutlinedButton(
                  onPressed: () => setState(() {
                        showForm = true;
                        msg = '';
                      }),
                  child: const Text('写评价')),
            if (showForm) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Text('评分：'),
                ...List.generate(
                    5,
                    (i) => IconButton(
                        icon: Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFC9A86A)),
                        onPressed: () => setState(() => rating = i + 1))),
              ]),
              TextField(
                controller: contentCtl,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                    hintText: '说说你对这个商品的使用感受...'),
              ),
              if (images.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: images
                      .asMap()
                      .entries
                      .map((e) => Stack(children: [
                            Image.network(e.value,
                                width: 72, height: 72, fit: BoxFit.cover),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => images.removeAt(e.key)),
                                child: const Icon(Icons.cancel,
                                    size: 18, color: Colors.red),
                              ),
                            ),
                          ]))
                      .toList(),
                ),
              TextButton.icon(
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(uploading
                    ? '上传中...'
                    : '上传图片 (${images.length}/6)'),
                onPressed: uploading ? null : _pickImages,
              ),
              Row(children: [
                FilledButton(
                  onPressed: submitting ? null : _submitReview,
                  child: Text(submitting ? '提交中...' : '提交评价'),
                ),
                const SizedBox(width: 12),
                TextButton(
                    onPressed: () => setState(() {
                          showForm = false;
                          msg = '';
                        }),
                    child: const Text('取消')),
              ]),
            ],
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('暂无评价，快来抢沙发吧',
                        style: TextStyle(color: Colors.grey))),
              ),
            ...reviews.map((r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 16,
                              child: Text((r.nickname.isNotEmpty
                                      ? r.nickname
                                      : r.username)
                                  .characters
                                  .first),
                            ),
                            const SizedBox(width: 8),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.nickname.isNotEmpty
                                      ? r.nickname
                                      : r.username),
                                  Stars(value: r.rating, size: 14),
                                ]),
                            const Spacer(),
                            Text(r.createdAt.substring(0, 10),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ]),
                          const SizedBox(height: 8),
                          Text(r.content),
                          if (r.images.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 6,
                                children: r.images
                                    .map((img) => Image.network(img,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover))
                                    .toList(),
                              ),
                            ),
                          if (r.reply != null)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF0EBE3),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('商家回复：${r.reply}',
                                  style: const TextStyle(fontSize: 13)),
                            ),
                        ]),
                  ),
                )),
          ]),
        ),
      ],
    );
  }
}
