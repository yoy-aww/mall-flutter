import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/cart_store.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final sum = cart.summary;

    if (cart.items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🛒', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          const Text('购物车还是空的'),
          const Text('去挑点道地好草本吧',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('逛逛首页')),
        ]),
      );
    }

    return Column(children: [
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: cart.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final item = cart.items[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  Image.network(item.image,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: const Color(0xFFF0EBE3))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('¥${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          Text('库存 ${item.stock}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ]),
                  ),
                  Column(children: [
                    Row(children: [
                      IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () =>
                              cart.setQuantity(item.id, item.quantity - 1)),
                      Text('${item.quantity}'),
                      IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () =>
                              cart.setQuantity(item.id, item.quantity + 1)),
                    ]),
                    TextButton(
                        onPressed: () => cart.remove(item.id),
                        child: const Text('删除',
                            style: TextStyle(color: Colors.red))),
                  ]),
                ]),
              ),
            );
          },
        ),
      ),
      SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE8E2D9)))),
          child: Row(children: [
            Expanded(
              child: Text('合计 ¥${sum.total.toStringAsFixed(2)}（${sum.count} 件）',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            TextButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                            title: const Text('清空购物车？'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('取消')),
                              FilledButton(
                                  onPressed: () {
                                    cart.clear();
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('确定')),
                            ],
                          ));
                },
                child: const Text('清空')),
            FilledButton(
                onPressed: () => context.push('/checkout'),
                child: const Text('去结算')),
          ]),
        ),
      ),
    ]);
  }
}
