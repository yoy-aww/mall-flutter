# mallflutter 学习文档

> 一个 Flutter 电商 App（"道地本草"）的快速入门笔记。
> 把 "mallflutter" 与另一个名为 `mallflutter_android`（Android native 端）配对阅读。

---

## 1. 项目概览

`mallflutter` 是一个 Flutter 跨平台商城应用。它与后端（REST API）对接，共享一套数据模型。

| 层级 | 目录 | 职责 |
|------|------|------|
| 入口 | `lib/main.dart` | 启动 + 依赖注入 + 路由表 |
| 模型 | `lib/models/models.dart` | 所有数据结构，与后端一一对应 |
| 服务 | `lib/services/` | 网络 API / 状态管理 / 本地缓存 |
| 页面 | `lib/screens/` | 每一个路由页面 |
| 组件 | `lib/widgets/` | 可复用 UI |
| 主题 | `lib/utils/theme.dart` | 颜色 / 字体 / 风格 |

依赖栈 (`pubspec.yaml`)：Flutter SDK + `provider`（状态管理） + `go_router`（路由） + `http`（网络） + `shared_preferences`（本地存储） + `image_picker`（图片）.

## 2. 架构与数据流

```
┌─────────────┐   读取/订阅   ┌──────────────┐
│   UI  Widget │  (context.read / Consumer) │ Services │
│  StatelessWidget |Stateful    │  Api / Stor  │
└──────┬──────┘              └──────┬───────┘
       │  依赖注入 (MultiProvider)  │
       │                            ▼
┌──────┴──────┐              ┌──────────────┐
│   main.dart  │◄──────注入────│ Api / AuthStore / CartStore │
│ GoRouter     │              │   (ChangeNotifier) │
└─────────────┘              └──────┬───────┘
                                       │  网络/缓存
                                       ▼
                              ┌────────────────┐
                              │ 后端 REST API   │
                              │ 43.153.148.187 │
                              └────────────────┘
```

- **UI 是无状态/有状态视图层**：只读 + 订阅。
- **Store（AuthStore / CartStore）**：继承 `ChangeNotifier`，是状态+逻辑层。
- **Api**：纯网络封装层，调用 `AuthStore` 拿 `token` 携带鉴权。
- **数据流**：UI → `context.read<Api>()` / `Consumer<Store>` → Store → 本地/远程 → 回写 Store → 通知 UI。

## 3. 路由设计 (main.dart)

```dart
GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/auth',         builder: (_, __) => AuthScreen()),       // 登录/注册
    GoRoute(path: '/pay/:orderId', builder: (_, s)  => PayScreen(orderId: ...)),
    ShellRoute(
      builder: (_, __, child) => Shell(child: child),  // 含顶栏+底栏
      routes: [
        GoRoute(path: '/',            builder: (_, __) => HomeScreen()),
        GoRoute(path: '/products',    builder: (_, s)  => ProductListScreen(category: s.uri.queryParameters['cat'])),
        GoRoute(path: '/products/:id',builder: (_, s)  => ProductDetailScreen(id: s.pathParameters['id']!)),
        GoRoute(path: '/search',      builder: (_, s)  => SearchScreen(q: s.uri.queryParameters['q'] ?? '')),
        GoRoute(path: '/cart',        builder: (_, __) => CartScreen()),
        GoRoute(path: '/checkout',    builder: (_, __) => CheckoutScreen()),
        GoRoute(path: '/profile',     builder: (_, s)  => ProfileScreen(tab: s.uri.queryParameters['tab'])),
      ],
    ),
  ],
)
```

- **ShellRoute**：嵌套路由，底部导航栏 + 搜索图标在 `Shell` 中共享。`child` 是匹配的子路由页面。
- **路径参数**：`/products/:id` → `s.pathParameters['id']`。
- **查询参数**：`/products?cat=...` → `s.uri.queryParameters['cat']`。

## 4. 状态管理 (services)

### 4.1 AuthStore — 认证
```dart
class AuthStore extends ChangeNotifier {
  String? token;
  User? user;
  static const _storageKey = 'mall_auth';
  // 构造函数时从 shared_preferences 异步加载
  // setLogin(token, user) -> _save() -> notifyListeners()
  bool get isLoggedIn => token != null;
}
```
- 登录/注册后调用 `auth.setLogin(...)` 保存 token+user 到本地。
- 退出：token/user 置空，自动清除本地存储。

### 4.2 CartStore — 购物车
```dart
class CartStore extends ChangeNotifier {
  final AuthStore auth;              // 监听登录状态
  List<CartItem> items = [];
  ({double total, int count}) get summary => ...; // 合计与数量
  void add(CartItem item, [int n = 1]);            // 增/更新
  void setQuantity(String id, int qty);            // 调整数量
  void remove(String id);
  void clear();
}
```
游客 vs 登录态逻辑（值得关注）：
- **游客**：存到 `shared_preferences` key `guyibu_cart_guest`.
- **登录**：迁移 key `guyibu_cart_<userId>`。
- **登录成功后**：`_onAuthChanged` 触发 —— 把游客 cart `_mergeGuestInto(userId)` 合并到账号 cart。
- **历史迁移**：旧 key `guyibu_cart` 一次性迁移到新 key。

### 4.3 Api — 网络层
- 所有接口复用 `_request<T>(path, parse, method, body)` 泛型封装。
- 成功约定 `json['success'] == true`，否则抛 `ApiException(json['error'])`.
- 鉴权：`_headers` 自动加 `Authorization: Bearer ${auth.token}`.
- 主要分组：Banners/Categories/Products、Auth、Addresses、Orders、Reviews。

## 5. 页面速览 (screens)

| 文件 | 功能 | 关键状态 |
|------|------|------|
| `home_screen.dart` | 轮播 + 分类 + 热卖 | `banners`, `categories`, `popular`；`PageController` + `Timer.periodic` 自动轮播 |
| `product_list_screen.dart` | 商品列表 · 分类筛选 | `products`, `categories`; 点击分类滚动 |
| `product_detail_screen.dart` | 商品详情 | 图片轮播，Sku 选择，评价 |
| `cart_screen.dart` | 购物车 | 全选、数量、去结算 |
| `checkout_screen.dart` | 结算 | 地址选/增、预览价格、提交订单 |
| `auth_screen.dart` | 登录/注册 | 双模式切切，`isLogin` |
| `profile_screen.dart` | 个人中心 | 订单列表 / 收藏 / 设置 |
| `search_screen.dart` | 搜索 | 根据 `q` 查产品 |
| `pay_screen.dart` | 订单支付 | 调出支付、标记付款 |
| `shell.dart` | 壳：顶栏搜索+购物车徽标 + 底导航栏 | `_indexFor` 地图路径 ↔ 页签 |

典型页面模板：
```dart
class FooScreen extends StatefulWidget { ... }
class _FooScreenState extends State<FooScreen> {
  bool loading = true;
  late ...;  // state

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final data = await context.read<Api>().xxx();
      setState(() { ...; loading = false; });
    } catch(e) { /* 降级为 [] */ }
  }
  @override Widget build(...) {
    if (loading) return Loading();
    return ...;
  }
}
```

## 6. 可复用组件 (widgets/common.dart)

- `ProductCard`：商品卡 — 图片 + 名称 + 价格（原价/折扣）+ TagChip。
- `TagChip`：气泡标签。
- `NetImage`：网络图 + 占位图（🍵） + 错误图。

## 7. 主题 (utils/theme.dart)

- 品牌色：primary `0xFF5B7C5D`（茶绿）, accent `0xFFC9A86A`（杏金），背景米白。
- Material 3: `ColorScheme.fromSeed(seedColor: primary)`.
- 统一 `cardTheme` / `filledButtonTheme` / `inputDecorationTheme`.

## 8. 后端约定（关键约定）

- 接口前缀统一 `Api.baseUrl = http://43.153.148.187:3000/api`.
- 响应体统一 `{ success: bool, data: ..., error?: string }`.
- `data` 可能是对象或数组 —— 解析时注意类型 `(json['data'] as List?)`。
- 订单状态机字段 `status`（如 `pending/payment/shipped/done`），见 `Order.status`；`orderAction(id, action)` 执行 `payment / cancel / receive` 等。
- 轮播 `link` 是后端写死的字符串，`_bannerLink` 用正则解析出路由 —— 注意前端路由与banner约定的耦合。

## 9. 快速开始

```bash
flutter pub get          # 安装依赖
flutter run -d chrome     # web 跑起来
flutter run -d <device>   # 移动设备
```

> 接口服务需要部署在 `43.153.148.187:3000`，开发前请确保网络可达。

## 10. 扩展阅读 / 对应 native 端

- `mallflutter_android/` 是 Android native 端，共享同后端 API，对应 `mall-web` 的 TS 模型。
- 数据模型 `models.dart` 头部注释说："与后端 API 返回结构一一对应（对齐 mall-web/src/api.ts 与 mallandroid/Models.kt）"—— 可对照 native 端 DTOs 学习类型映射。

## 11. 平台与工程目录说明

Flutter 把不同平台的原生宿主工程放到根目录下，`flutter create` 时自动生成。

| 目录 | 作用 |
|------|------|
| **android/** | Android 原生宿主工程（Gradle、`AndroidManifest.xml`、Kotlin/Java Activity） |
| **ios/** | iOS 原生宿主工程（Xcode 工程、`Runner` app） |
| **web/** | Web 端（`index.html` + `main.dart.js` 编译目标） |
| **linux/** | 桌面 Linux 宿主（CMake + GTK） |
| **macos/** | 桌面 macOS 宿主（Xcode + Cocoa） |
| **windows/** | 桌面 Windows 宿主（MSVC + Win32） |

> **你的业务逻辑只写在 `lib/`**。这 6 个平台目录是原生层，正常开发时不用手动改动。

### 构建与打包

对应目录生效于构建命令，开发时按需使用：

```bash
flutter build apk            # 产物在 android/ 下
flutter build ios            # ios/ 下
flutter build web            # web/ 下
flutter build macos          # macos/ 下
flutter build windows        # windows/ 下
flutter build linux          # linux/ 下
```

### 非业务目录一览

| 目录/文件 | 类型 | 是否入库 |
|-----------|------|----------|
| `test/` | 单元/Widget 测试 | ✅ |
| `build/` | 编译产物（APK/AAB 等） | ❌ `.gitignore` 忽略 |
| `.dart_tool/` | Dart 工具缓存（package 解析等） | ❌ | 
| `.idea/` | IntelliJ/Android Studio 配置 | ❌ |
| `pubspec.yaml` | 依赖声明 | ✅ | 
| `pubspec.lock` | 依赖版本锁定 | ✅ (推荐提交) |
| `analysis_options.yaml` | lint 规则 | ✅ |
| `mallflutter.iml` | IDE 模块描述 | ✅ |
| `.gitignore` | 忽略文件清单 | ✅ |

### 关键提醒

- **`build/`、`.dart_tool/`、`.idea/`** 都是**生成物**，不要手动修改，也不该提交到 Git。
- `android/` 是 **Flutter 的 Android 宿主**，和同项目旁的 `mallflutter_android/`（**独立 Android native 端**）不是一回事，后者对应 `mall-web` 的 native 版。

---

*写完一个小提醒：`profile_screen.dart` 很大 (600+ 行)。后续学习时推荐先看它的 `tab` 查询参数 + 各 Tab 的 `if` 分支布局。*
