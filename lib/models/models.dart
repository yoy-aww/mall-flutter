// 数据模型，与后端 API 返回结构一一对应（对齐 mall-web/src/api.ts 与 mallandroid/Models.kt）

// 商城 Banner（改名避免与 Flutter Material Banner 冲突）
class StoreBanner {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String link;
  final int sortOrder;
  final int enabled;
  final String audioUrl;

  StoreBanner({
    this.id = '',
    this.title = '',
    this.subtitle = '',
    this.image = '',
    this.link = '',
    this.sortOrder = 0,
    this.enabled = 0,
    this.audioUrl = '',
  });

  factory StoreBanner.fromJson(Map<String, dynamic> j) => StoreBanner(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        subtitle: j['subtitle'] ?? '',
        image: j['image'] ?? '',
        link: j['link'] ?? '',
        sortOrder: j['sortOrder'] ?? 0,
        enabled: j['enabled'] ?? 0,
        audioUrl: j['audioUrl'] ?? '',
      );
}

class Category {
  final String id;
  final String name;
  final String icon;
  final int productCount;
  final int sortOrder;

  Category({
    this.id = '',
    this.name = '',
    this.icon = '',
    this.productCount = 0,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        icon: j['icon'] ?? '',
        productCount: j['productCount'] ?? 0,
        sortOrder: j['sortOrder'] ?? 0,
      );
}

class Product {
  final String id;
  final String name;
  final String image;
  final double originalPrice;
  final double? discountedPrice;
  final String categoryId;
  final String description;
  final int stock;
  final List<String> tags;

  Product({
    this.id = '',
    this.name = '',
    this.image = '',
    this.originalPrice = 0,
    this.discountedPrice,
    this.categoryId = '',
    this.description = '',
    this.stock = 0,
    this.tags = const [],
  });

  double get price => discountedPrice ?? originalPrice;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        image: j['image'] ?? '',
        originalPrice: (j['originalPrice'] ?? 0).toDouble(),
        discountedPrice: j['discountedPrice'] == null
            ? null
            : (j['discountedPrice'] as num).toDouble(),
        categoryId: j['categoryId'] ?? '',
        description: j['description'] ?? '',
        stock: j['stock'] ?? 0,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class Review {
  final String id;
  final String productId;
  final String userId;
  final String username;
  final String nickname;
  final int rating;
  final String content;
  final List<String> images;
  final String? reply;
  final String? replyAt;
  final String createdAt;

  Review({
    this.id = '',
    this.productId = '',
    this.userId = '',
    this.username = '',
    this.nickname = '',
    this.rating = 0,
    this.content = '',
    this.images = const [],
    this.reply,
    this.replyAt,
    this.createdAt = '',
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] ?? '',
        productId: j['productId'] ?? '',
        userId: j['userId'] ?? '',
        username: j['username'] ?? '',
        nickname: j['nickname'] ?? '',
        rating: j['rating'] ?? 0,
        content: j['content'] ?? '',
        images: (j['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
        reply: j['reply'],
        replyAt: j['replyAt'],
        createdAt: j['createdAt'] ?? '',
      );
}

class ReviewStats {
  final double avg;
  final int total;
  final List<int> dist;

  ReviewStats({this.avg = 0, this.total = 0, this.dist = const [0, 0, 0, 0, 0]});

  factory ReviewStats.fromJson(Map<String, dynamic> j) => ReviewStats(
        avg: (j['avg'] ?? 0).toDouble(),
        total: j['total'] ?? 0,
        dist: (j['dist'] as List?)?.map((e) => (e as num).toInt()).toList() ??
            const [0, 0, 0, 0, 0],
      );
}

class Address {
  final String id;
  final String userId;
  final String label;
  final String receiverName;
  final String receiverPhone;
  final String province;
  final String city;
  final String address;
  final int isDefault;

  Address({
    this.id = '',
    this.userId = '',
    this.label = '',
    this.receiverName = '',
    this.receiverPhone = '',
    this.province = '',
    this.city = '',
    this.address = '',
    this.isDefault = 0,
  });

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        label: j['label'] ?? '',
        receiverName: j['receiverName'] ?? '',
        receiverPhone: j['receiverPhone'] ?? '',
        province: j['province'] ?? '',
        city: j['city'] ?? '',
        address: j['address'] ?? '',
        isDefault: j['isDefault'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'province': province,
        'city': city,
        'address': address,
      };
}

class User {
  final String id;
  final String username;
  final String nickname;
  final String role;
  final String phone;

  User({
    this.id = '',
    this.username = '',
    this.nickname = '',
    this.role = '',
    this.phone = '',
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] ?? '',
        username: j['username'] ?? '',
        nickname: j['nickname'] ?? '',
        role: j['role'] ?? '',
        phone: j['phone'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nickname': nickname,
        'role': role,
        'phone': phone,
      };
}

class OrderPreview {
  final double subtotal;
  final double shippingFee;
  final double total;
  final bool free;
  final String shippingMethod;

  OrderPreview({
    this.subtotal = 0,
    this.shippingFee = 0,
    this.total = 0,
    this.free = false,
    this.shippingMethod = 'standard',
  });

  factory OrderPreview.fromJson(Map<String, dynamic> j) => OrderPreview(
        subtotal: (j['subtotal'] ?? 0).toDouble(),
        shippingFee: (j['shippingFee'] ?? 0).toDouble(),
        total: (j['total'] ?? 0).toDouble(),
        free: j['free'] ?? false,
        shippingMethod: j['shippingMethod'] ?? 'standard',
      );
}

class OrderCreateResult {
  final String id;
  final double subtotal;
  final double shippingFee;
  final double total;
  final bool free;

  OrderCreateResult({
    this.id = '',
    this.subtotal = 0,
    this.shippingFee = 0,
    this.total = 0,
    this.free = false,
  });

  factory OrderCreateResult.fromJson(Map<String, dynamic> j) =>
      OrderCreateResult(
        id: j['id'] ?? '',
        subtotal: (j['subtotal'] ?? 0).toDouble(),
        shippingFee: (j['shippingFee'] ?? 0).toDouble(),
        total: (j['total'] ?? 0).toDouble(),
        free: j['free'] ?? false,
      );
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;

  OrderItem({
    this.productId = '',
    this.productName = '',
    this.productImage = '',
    this.price = 0,
    this.quantity = 0,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productId: j['productId'] ?? '',
        productName: j['productName'] ?? '',
        productImage: j['productImage'] ?? '',
        price: (j['price'] ?? 0).toDouble(),
        quantity: j['quantity'] ?? 0,
      );
}

class Order {
  final String id;
  final String status;
  final List<OrderItem> items;
  final double totalAmount;
  final double subtotal;
  final double shippingFee;
  final String shippingMethod;
  final String shippingAddress;
  final String receiverName;
  final String receiverPhone;
  final String? remark;
  final String? shipTracking;
  final String? cancelledReason;
  final String createdAt;
  final String? paidAt;
  final String? shippedAt;
  final String? completedAt;

  Order({
    this.id = '',
    this.status = '',
    this.items = const [],
    this.totalAmount = 0,
    this.subtotal = 0,
    this.shippingFee = 0,
    this.shippingMethod = '',
    this.shippingAddress = '',
    this.receiverName = '',
    this.receiverPhone = '',
    this.remark,
    this.shipTracking,
    this.cancelledReason,
    this.createdAt = '',
    this.paidAt,
    this.shippedAt,
    this.completedAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] ?? '',
        status: j['status'] ?? '',
        items: (j['items'] as List?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        totalAmount: (j['totalAmount'] ?? 0).toDouble(),
        subtotal: (j['subtotal'] ?? 0).toDouble(),
        shippingFee: (j['shippingFee'] ?? 0).toDouble(),
        shippingMethod: j['shippingMethod'] ?? '',
        shippingAddress: j['shippingAddress'] ?? '',
        receiverName: j['receiverName'] ?? '',
        receiverPhone: j['receiverPhone'] ?? '',
        remark: j['remark'],
        shipTracking: j['shipTracking'] ?? j['tracking'],
        cancelledReason: j['cancelledReason'],
        createdAt: j['createdAt'] ?? '',
        paidAt: j['paidAt'],
        shippedAt: j['shippedAt'],
        completedAt: j['completedAt'],
      );
}

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String content;
  final String? relatedId;
  final int read;
  final String createdAt;

  AppNotification({
    this.id = '',
    this.userId = '',
    this.type = '',
    this.title = '',
    this.content = '',
    this.relatedId,
    this.read = 0,
    this.createdAt = '',
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        type: j['type'] ?? '',
        title: j['title'] ?? '',
        content: j['content'] ?? '',
        relatedId: j['relatedId'],
        read: j['read'] ?? 0,
        createdAt: j['createdAt'] ?? '',
      );
}

class NotificationResponse {
  final List<AppNotification> list;
  final int unread;

  NotificationResponse({this.list = const [], this.unread = 0});

  factory NotificationResponse.fromJson(Map<String, dynamic> j) =>
      NotificationResponse(
        list: (j['list'] as List?)
                ?.map((e) =>
                    AppNotification.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        unread: j['unread'] ?? 0,
      );
}

class AfterSale {
  final String id;
  final String orderId;
  final String orderStatus;
  final List<Map<String, dynamic>> items;
  final String reason;
  final String description;
  final String status;
  final String? handleReason;
  final String createdAt;

  AfterSale({
    this.id = '',
    this.orderId = '',
    this.orderStatus = '',
    this.items = const [],
    this.reason = '',
    this.description = '',
    this.status = '',
    this.handleReason,
    this.createdAt = '',
  });

  factory AfterSale.fromJson(Map<String, dynamic> j) => AfterSale(
        id: j['id'] ?? '',
        orderId: j['orderId'] ?? '',
        orderStatus: j['orderStatus'] ?? '',
        items: (j['items'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        reason: j['reason'] ?? '',
        description: j['description'] ?? '',
        status: j['status'] ?? '',
        handleReason: j['handleReason'],
        createdAt: j['createdAt'] ?? '',
      );
}
