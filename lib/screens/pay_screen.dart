import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api.dart';

class PayScreen extends StatefulWidget {
  final String orderId;
  const PayScreen({super.key, required this.orderId});
  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  Order? order;
  bool loading = true;
  bool paying = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      order = await context.read<Api>().orderById(widget.orderId);
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _pay() async {
    setState(() => paying = true);
    try {
      await context.read<Api>().orderAction(widget.orderId, 'payment');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('支付成功')));
        context.go('/profile?tab=orders');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订单支付')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('订单号：${order!.id}',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      Text('¥${order!.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                      const SizedBox(height: 24),
                      const Text('（演示环境：点击即模拟支付）',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: paying ? null : _pay,
                          child: Text(paying ? '支付中...' : '立即支付'),
                        ),
                      ),
                    ]),
                  ),
                ),
    );
  }
}
