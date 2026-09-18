// 共享 widget：商品卡、星级、价格行、网络图
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';

class ProductCard extends StatelessWidget {
  final Product p;
  const ProductCard({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    final price = p.price;
    final discount = p.discountedPrice != null
        ? (price / p.originalPrice * 10).round()
        : null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/products/${p.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: NetImage(p.image, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: p.tags
                          .take(3)
                          .map((t) => TagChip(t))
                          .toList(),
                    ),
                  const SizedBox(height: 4),
                  Text(p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('¥${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (p.discountedPrice != null) ...[
                        const SizedBox(width: 6),
                        Text('¥${p.originalPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 4),
                        TagChip('$discount折',
                            color: Colors.red.shade50, textColor: Colors.red),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('库存 ${p.stock} 件',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  const TagChip(this.text, {super.key, this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFF0EBE3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: textColor ?? Colors.brown)),
    );
  }
}

class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF0EBE3),
        child: const Center(child: Text('🍵', style: TextStyle(fontSize: 40))),
      );
    }
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(color: const Color(0xFFF0EBE3)),
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF0EBE3),
        child: const Center(child: Text('🍵', style: TextStyle(fontSize: 40))),
      ),
    );
  }
}

class Stars extends StatelessWidget {
  final int value;
  final double size;
  const Stars({super.key, required this.value, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(i < value ? Icons.star : Icons.star_border,
            size: size, color: const Color(0xFFC9A86A)),
      ),
    );
  }
}
