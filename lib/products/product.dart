class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.brand,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.availabilityStatus,
    required this.shippingInformation,
    required this.returnPolicy,
    required this.thumbnail,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      brand: json['brand'] as String?,
      price: (json['price'] as num).toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: json['stock'] as int? ?? 0,
      availabilityStatus: json['availabilityStatus'] as String? ?? '',
      shippingInformation: json['shippingInformation'] as String? ?? '',
      returnPolicy: json['returnPolicy'] as String? ?? '',
      thumbnail: json['thumbnail'] as String,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  static const lowStockThreshold = 10;

  final int id;
  final String title;
  final String description;
  final String category;
  final String? brand;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String availabilityStatus;
  final String shippingInformation;
  final String returnPolicy;
  final String thumbnail;
  final List<String> images;

  bool get hasDiscount => discountPercentage > 0;
  double get discountedPrice => price * (1 - discountPercentage / 100);
  bool get isLowStock => stock > 0 && stock < lowStockThreshold;
}
