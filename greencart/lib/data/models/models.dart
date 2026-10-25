import '../../core/utils/order_status.dart';

enum UserRole { buyer, seller }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.emailOrPhone,
    required this.passwordHashDemo,
    required this.role,
    required this.createdAt,
  });
  final int id;
  final String name;
  final String emailOrPhone;
  final String passwordHashDemo;
  final UserRole role;
  final DateTime createdAt;

  bool get isSeller => role == UserRole.seller;

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
        id: m['id'] as int,
        name: m['name'] as String,
        emailOrPhone: m['email_or_phone'] as String,
        passwordHashDemo: m['password_hash'] as String,
        role: (m['role'] as String) == 'seller' ? UserRole.seller : UserRole.buyer,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}

class Category {
  const Category({required this.id, required this.name, required this.iconKey, required this.sortOrder});
  final int id;
  final String name;
  final String iconKey;
  final int sortOrder;

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as int,
        name: m['name'] as String,
        iconKey: m['icon_key'] as String,
        sortOrder: m['sort_order'] as int,
      );
}

class Product {
  const Product({
    this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.unit,
    required this.stock,
    required this.imageAssetPath,
    required this.sellerId,
    this.sellerName = '',
    this.origin = '',
    this.isActive = true,
  });
  final int? id;
  final String name;
  final int categoryId;
  final String description;
  final int price;
  final String unit;
  final int stock;
  final String imageAssetPath;
  final int sellerId;
  final String sellerName;
  final String origin;
  final bool isActive;

  bool get isAvailable => isActive && stock > 0;

  Product copyWith({
    String? name,
    int? categoryId,
    String? description,
    int? price,
    String? unit,
    int? stock,
    String? imageAssetPath,
    String? origin,
    bool? isActive,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        description: description ?? this.description,
        price: price ?? this.price,
        unit: unit ?? this.unit,
        stock: stock ?? this.stock,
        imageAssetPath: imageAssetPath ?? this.imageAssetPath,
        sellerId: sellerId,
        sellerName: sellerName,
        origin: origin ?? this.origin,
        isActive: isActive ?? this.isActive,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category_id': categoryId,
        'description': description,
        'price': price,
        'unit': unit,
        'stock': stock,
        'image_asset_path': imageAssetPath,
        'seller_id': sellerId,
        'origin': origin,
        'is_active': isActive ? 1 : 0,
      };

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int,
        name: m['name'] as String,
        categoryId: m['category_id'] as int,
        description: m['description'] as String,
        price: m['price'] as int,
        unit: m['unit'] as String,
        stock: m['stock'] as int,
        imageAssetPath: m['image_asset_path'] as String,
        sellerId: m['seller_id'] as int,
        sellerName: (m['seller_name'] as String?) ?? '',
        origin: (m['origin'] as String?) ?? '',
        isActive: (m['is_active'] as int) == 1,
      );
}

class CartItem {
  const CartItem({required this.id, required this.productId, required this.quantity, required this.addedAt});
  final int id;
  final int productId;
  final int quantity;
  final DateTime addedAt;
}

/// Item keranjang beserta produknya. Perhitungan harga ada di sini, bukan di UI.
class CartLine {
  const CartLine({required this.item, required this.product});
  final CartItem item;
  final Product product;

  int get quantity => item.quantity;
  int get subtotal => product.price * item.quantity;
}

class Address {
  const Address({
    this.id,
    required this.userId,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    this.areaNote = '',
    this.isDefault = false,
  });
  final int? id;
  final int userId;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String areaNote;
  final bool isDefault;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'recipient_name': recipientName,
        'phone': phone,
        'address_line': addressLine,
        'area_note': areaNote,
        'is_default': isDefault ? 1 : 0,
      };

  factory Address.fromMap(Map<String, Object?> m) => Address(
        id: m['id'] as int,
        userId: m['user_id'] as int,
        recipientName: m['recipient_name'] as String,
        phone: m['phone'] as String,
        addressLine: m['address_line'] as String,
        areaNote: (m['area_note'] as String?) ?? '',
        isDefault: (m['is_default'] as int) == 1,
      );
}

/// Snapshot item saat pesanan dibuat; tidak ikut berubah bila katalog berubah.
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.sellerId,
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
  });
  final int productId;
  final int sellerId;
  final String name;
  final String unit;
  final int price;
  final int quantity;

  int get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, Object?> m) => OrderItem(
        productId: m['product_id'] as int,
        sellerId: m['seller_id'] as int,
        name: m['name'] as String,
        unit: m['unit'] as String,
        price: m['price'] as int,
        quantity: m['quantity'] as int,
      );
}

class OrderStatusEvent {
  const OrderStatusEvent({required this.status, required this.note, required this.timestamp});
  final OrderStatus status;
  final String note;
  final DateTime timestamp;
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.note,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.events = const [],
  });
  final int id;
  final String orderNumber;
  final int userId;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String note;
  final List<OrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderStatusEvent> events;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.orderId,
  });
  final int id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final int? orderId;

  factory AppNotification.fromMap(Map<String, Object?> m) => AppNotification(
        id: m['id'] as int,
        userId: m['user_id'] as int,
        title: m['title'] as String,
        message: m['message'] as String,
        isRead: (m['is_read'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        orderId: m['order_id'] as int?,
      );
}
