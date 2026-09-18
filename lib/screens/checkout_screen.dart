import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../services/auth_store.dart';
import '../services/cart_store.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Address> addresses = [];
  Address? selAddr;
  String shipMethod = 'standard';
  OrderPreview? quote;
  bool loading = false;
  bool done = false;
  String orderId = '';
  OrderCreateResult? result;

  final nameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final provinceCtl = TextEditingController();
  final cityCtl = TextEditingController();
  final addressCtl = TextEditingController();
  final noteCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _refreshQuote();
  }

  Future<void> _loadAddresses() async {
    final auth = context.read<AuthStore>();
    if (!auth.isLoggedIn) return;
    try {
      final list = await context.read<Api>().addresses();
      setState(() {
        addresses = list;
        final def = list.where((a) => a.isDefault == 1).firstOrNull ??
            list.firstOrNull;
        if (def != null) _pick(def);
      });
    } catch (_) {}
  }

  void _pick(Address a) {
    selAddr = a;
    nameCtl.text = a.receiverName;
    phoneCtl.text = a.receiverPhone;
    provinceCtl.text = a.province;
    cityCtl.text = a.city;
    addressCtl.text = a.address;
  }

  Future<void> _refreshQuote() async {
    final cart = context.read<CartStore>();
    if (cart.items.isEmpty) return;
    try {
      final q = await context
          .read<Api>()
          .previewOrder(cart.items, shipMethod);
      setState(() => quote = q);
    } catch (_) {}
  }

  Future<void> _submit() async {
    final auth = context.read<AuthStore>();
    final cart = context.read<CartStore>();
    if (!auth.isLoggedIn) {
      context.push('/auth?from=/checkout');
      return;
    }
    if (nameCtl.text.isEmpty || phoneCtl.text.isEmpty || addressCtl.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请补全收货人/手机/地址')));
      return;
    }
    if (quote == null) return;

    setState(() => loading = true);
    try {
      final res = await context.read<Api>().createOrder(
            items: cart.items,
            shippingAddress:
                '${provinceCtl.text} ${cityCtl.text} ${addressCtl.text}'.trim(),
            receiverName: nameCtl.text,
            receiverPhone: phoneCtl.text,
            remark: noteCtl.text,
            shippingMethod: shipMethod,
          );
      setState(() {
        done = true;
        orderId = res.id;
        result = res;
      });
      cart.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();

    if (done) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 72),
          const Text('下单成功',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('订单号：$orderId',
              style: const TextStyle(color: Colors.grey)),
          if (result != null)
            Text('应付 ¥${result!.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => context.go('/profile?tab=orders'),
              child: const Text('查看订单')),
          TextButton(
              onPressed: () => context.go('/'),
              child: const Text('继续逛逛')),
        ]),
      );
    }

    if (cart.items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📦', style: TextStyle(fontSize: 64)),
          const Text('购物车没有商品'),
          FilledButton(
              onPressed: () => context.go('/'), child: const Text('去挑选')),
        ]),
      );
    }

    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('收货信息',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (addresses.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...addresses.map((a) => RadioListTile<String>(
                    value: a.id,
                    groupValue: selAddr?.id,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (_) => _pick(a),
                    title: Text('${a.label}  ${a.receiverName} ${a.receiverPhone}'),
                    subtitle: Text('${a.province} ${a.city} ${a.address}'),
                  )),
              const Divider(),
            ],
            TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: '收货人姓名')),
            TextField(
                controller: phoneCtl,
                decoration: const InputDecoration(labelText: '手机号'),
                keyboardType: TextInputType.phone),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: provinceCtl,
                      decoration:
                          const InputDecoration(labelText: '省'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: cityCtl,
                      decoration: const InputDecoration(labelText: '市'))),
            ]),
            TextField(
                controller: addressCtl,
                decoration:
                    const InputDecoration(labelText: '详细地址（街道/小区/门牌）')),
            TextField(
                controller: noteCtl,
                decoration: const InputDecoration(labelText: '备注（选填）')),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('配送方式',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            RadioListTile<String>(
              value: 'standard',
              groupValue: shipMethod,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('标准快递 · ¥8（满 ¥199 免邮）'),
              onChanged: (v) {
                setState(() => shipMethod = v!);
                _refreshQuote();
              },
            ),
            RadioListTile<String>(
              value: 'sfx',
              groupValue: shipMethod,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('顺丰特快 · ¥15'),
              onChanged: (v) {
                setState(() => shipMethod = v!);
                _refreshQuote();
              },
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('商品清单',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...cart.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(child: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('×${it.quantity}'),
                    const SizedBox(width: 12),
                    Text('¥${(it.price * it.quantity).toStringAsFixed(2)}'),
                  ]),
                )),
            const Divider(),
            _row('商品小计', quote == null ? '计算中...' : '¥${quote!.subtotal.toStringAsFixed(2)}'),
            _row('运费', quote == null ? '计算中...' : quote!.free ? '免邮' : '¥${quote!.shippingFee.toStringAsFixed(2)}'),
            _row('应付', quote == null ? '—' : '¥${quote!.total.toStringAsFixed(2)}',
                big: true),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: loading || quote == null ? null : _submit,
          child: Text(loading ? '提交中...' : '提交订单'),
        ),
      ),
    ]);
  }

  Widget _row(String label, String value, {bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(fontSize: big ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  fontSize: big ? 18 : 14,
                  fontWeight: big ? FontWeight.bold : FontWeight.normal,
                  color: big ? Colors.red : null)),
        ]),
      );
}
