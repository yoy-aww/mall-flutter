import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../services/auth_store.dart';

const _statusLabels = {
  'pending': ('待付款', Color(0xFF999999)),
  'paid': ('已付款', Color(0xFF1677FF)),
  'shipped': ('已发货', Color(0xFF13C2C2)),
  'delivered': ('已签收', Color(0xFF52C41A)),
  'completed': ('已完成', Color(0xFF52C41A)),
  'cancelled': ('已取消', Color(0xFFFF4D4F)),
};

class ProfileScreen extends StatefulWidget {
  final String? tab;
  const ProfileScreen({super.key, this.tab});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String tab;

  @override
  void initState() {
    super.initState();
    tab = widget.tab ?? 'info';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    if (!auth.isLoggedIn) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('请先登录'),
          FilledButton(
              onPressed: () => context.push('/auth?from=/profile'),
              child: const Text('去登录')),
        ]),
      );
    }
    final user = auth.user!;

    return Column(children: [
      Container(
        color: const Color(0xFF5B7C5D),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Text(
                (user.nickname.isNotEmpty ? user.nickname : user.username)
                    .characters
                    .first,
                style: const TextStyle(fontSize: 24, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.nickname.isNotEmpty ? user.nickname : user.username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(
                  '${user.username} · ${user.phone.isEmpty ? "未绑定手机" : user.phone} · ${user.role == 'admin' ? '管理员' : '普通会员'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          TextButton(
              onPressed: () {
                auth.logout();
                context.go('/');
              },
              child:
                  const Text('退出', style: TextStyle(color: Colors.white))),
        ]),
      ),
      SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final (key, label) in [
            ('info', '个人信息'),
            ('orders', '我的订单'),
            ('addresses', '收货地址'),
            ('aftersales', '售后'),
            ('notifications', '消息'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: ChoiceChip(
                label: Text(label),
                selected: tab == key,
                onSelected: (_) => setState(() => tab = key),
                selectedColor: const Color(0xFF5B7C5D),
                labelStyle: TextStyle(
                    color: tab == key ? Colors.white : Colors.black87),
              ),
            ),
        ]),
      ),
      Expanded(child: _tabBody()),
    ]);
  }

  Widget _tabBody() {
    switch (tab) {
      case 'orders':
        return const OrdersTab();
      case 'addresses':
        return const AddressesTab();
      case 'aftersales':
        return const AfterSalesTab();
      case 'notifications':
        return const NotificationsTab();
      default:
        return const InfoTab();
    }
  }
}

class InfoTab extends StatefulWidget {
  const InfoTab({super.key});
  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {
  late TextEditingController nickCtl;
  late TextEditingController phoneCtl;
  String msg = '';

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthStore>().user!;
    nickCtl = TextEditingController(text: u.nickname);
    phoneCtl = TextEditingController(text: u.phone);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
          controller: nickCtl,
          decoration: const InputDecoration(labelText: '昵称')),
      const SizedBox(height: 12),
      TextField(
          controller: phoneCtl,
          decoration: const InputDecoration(labelText: '手机号'),
          keyboardType: TextInputType.phone),
      if (msg.isNotEmpty)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(msg)),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () async {
          try {
            await context.read<Api>().updateMe(
                nickname: nickCtl.text.trim(), phone: phoneCtl.text.trim());
            setState(() => msg = '保存成功');
          } catch (e) {
            setState(() => msg = e.toString());
          }
        },
        child: const Text('保存'),
      ),
    ]);
  }
}

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});
  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<Order> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      orders = await context.read<Api>().myOrders();
    } catch (_) {
      orders = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _action(String id, String action, String label) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('确定$label此订单？'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('确定')),
              ],
            ));
    if (ok != true) return;
    try {
      await context.read<Api>().orderAction(id, action,
          reason: action == 'cancel' ? '用户取消' : null);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📦', style: TextStyle(fontSize: 48)),
          const Text('还没有订单'),
          FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('去逛逛')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final o = orders[i];
          final (label, color) =
              _statusLabels[o.status] ?? (o.status, Colors.grey);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                      child: Text('订单号：${o.id}',
                          style: const TextStyle(fontSize: 12))),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(label,
                        style: TextStyle(color: color, fontSize: 12)),
                  ),
                ]),
                const Divider(),
                ...o.items.map((it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        if (it.productImage.isNotEmpty)
                          Image.network(it.productImage,
                              width: 48, height: 48, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 48, height: 48)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(it.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        Text(
                            '¥${it.price.toStringAsFixed(2)} × ${it.quantity}'),
                      ]),
                    )),
                const Divider(),
                Text('📍 ${o.receiverName} ${o.receiverPhone}',
                    style: const TextStyle(fontSize: 12)),
                Text(o.shippingAddress,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(children: [
                  const Text('合计'),
                  const Spacer(),
                  Text('¥${o.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                ]),
                if (o.status == 'pending')
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                        onPressed: () => _action(o.id, 'cancel', '取消'),
                        child: const Text('取消订单')),
                    FilledButton(
                        onPressed: () => context.push('/pay/${o.id}'),
                        child: const Text('去支付')),
                  ]),
                if (o.status == 'shipped')
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                        onPressed: () => _action(o.id, 'deliver', '签收'),
                        child: const Text('确认签收')),
                  ),
                if (o.status == 'delivered')
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                        onPressed: () => _action(o.id, 'confirm', '完成'),
                        child: const Text('确认完成')),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class AddressesTab extends StatefulWidget {
  const AddressesTab({super.key});
  @override
  State<AddressesTab> createState() => _AddressesTabState();
}

class _AddressesTabState extends State<AddressesTab> {
  List<Address> list = [];
  bool loading = true;
  String? editId;
  final labelCtl = TextEditingController();
  final nameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final provinceCtl = TextEditingController();
  final cityCtl = TextEditingController();
  final addressCtl = TextEditingController();
  bool showForm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      list = await context.read<Api>().addresses();
    } catch (_) {
      list = [];
    }
    if (mounted) setState(() => loading = false);
  }

  void _openAdd() {
    editId = null;
    for (final c in [labelCtl, nameCtl, phoneCtl, provinceCtl, cityCtl, addressCtl]) {
      c.clear();
    }
    setState(() => showForm = true);
  }

  void _openEdit(Address a) {
    editId = a.id;
    labelCtl.text = a.label;
    nameCtl.text = a.receiverName;
    phoneCtl.text = a.receiverPhone;
    provinceCtl.text = a.province;
    cityCtl.text = a.city;
    addressCtl.text = a.address;
    setState(() => showForm = true);
  }

  Future<void> _submit() async {
    if (nameCtl.text.isEmpty || phoneCtl.text.isEmpty || addressCtl.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('姓名/手机/地址为必填')));
      return;
    }
    final a = Address(
      label: labelCtl.text.isEmpty ? '默认' : labelCtl.text,
      receiverName: nameCtl.text,
      receiverPhone: phoneCtl.text,
      province: provinceCtl.text,
      city: cityCtl.text,
      address: addressCtl.text,
    );
    try {
      final api = context.read<Api>();
      if (editId != null) {
        await api.updateAddress(editId!, a);
      } else {
        await api.createAddress(a);
      }
      setState(() => showForm = false);
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [
        const Text('收货地址',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Spacer(),
        FilledButton.icon(
            onPressed: _openAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新建')),
      ]),
      if (loading) const Center(child: CircularProgressIndicator()),
      if (!loading && list.isEmpty)
        const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text('暂无收货地址'))),
      ...list.map((a) => Card(
            margin: const EdgeInsets.only(top: 8),
            child: ListTile(
              title: Text('${a.label}  ${a.receiverName} ${a.receiverPhone}'),
              subtitle: Text('${a.province} ${a.city} ${a.address}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _openEdit(a)),
                IconButton(
                    icon: const Icon(Icons.delete,
                        size: 20, color: Colors.red),
                    onPressed: () async {
                      await context.read<Api>().deleteAddress(a.id);
                      _load();
                    }),
              ]),
            ),
          )),
      if (showForm)
        Card(
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              TextField(
                  controller: labelCtl,
                  decoration:
                      const InputDecoration(labelText: '标签（家/公司）')),
              TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: '收件人')),
              TextField(
                  controller: phoneCtl,
                  decoration: const InputDecoration(labelText: '手机号')),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: provinceCtl,
                        decoration: const InputDecoration(labelText: '省'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: cityCtl,
                        decoration: const InputDecoration(labelText: '市'))),
              ]),
              TextField(
                  controller: addressCtl,
                  decoration: const InputDecoration(labelText: '详细地址')),
              const SizedBox(height: 12),
              Row(children: [
                FilledButton(
                    onPressed: _submit,
                    child: Text(editId != null ? '保存修改' : '添加地址')),
                const SizedBox(width: 12),
                TextButton(
                    onPressed: () => setState(() => showForm = false),
                    child: const Text('取消')),
              ]),
            ]),
          ),
        ),
    ]);
  }
}

class AfterSalesTab extends StatefulWidget {
  const AfterSalesTab({super.key});
  @override
  State<AfterSalesTab> createState() => _AfterSalesTabState();
}

class _AfterSalesTabState extends State<AfterSalesTab> {
  List<AfterSale> list = [];
  bool loading = true;

  static const _labels = {
    'pending': ('待审核', Colors.orange),
    'approved': ('已同意', Colors.green),
    'rejected': ('已拒绝', Colors.red),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      list = await context.read<Api>().aftersales();
    } catch (_) {
      list = [];
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) {
      return const Center(child: Text('暂无售后记录'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final a = list[i];
        final (label, color) =
            _labels[a.status] ?? (a.status, Colors.grey);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('订单 ${a.orderId} · ${a.reason}'),
            subtitle: Text(a.description),
            trailing: Text(label, style: TextStyle(color: color)),
          ),
        );
      },
    );
  }
}

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});
  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<AppNotification> list = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final r = await context.read<Api>().notifications();
      list = r.list;
    } catch (_) {
      list = [];
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) return const Center(child: Text('暂无消息'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final n = list[i];
        return Card(
          color: n.read == 0 ? const Color(0xFFFFF8EC) : null,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(n.title,
                style: TextStyle(
                    fontWeight:
                        n.read == 0 ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(n.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Text(n.createdAt.substring(0, 10),
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            onTap: () async {
              if (n.read == 0) {
                await context.read<Api>().markRead(n.id);
                _load();
              }
            },
          ),
        );
      },
    );
  }
}
