class MenuModel {
  final int? id;
  final String name;
  final int price;
  final String category;
  final String imageUrl;
  final String? label;
  final bool isAvailable;

  MenuModel({
    this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.label,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'label': label,
      'is_available': isAvailable ? 1 : 0,
    };
  }

  factory MenuModel.fromMap(Map<String, dynamic> map) {
    return MenuModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: map['price'] as int,
      category: map['category'] as String,
      imageUrl: map['image_url'] as String,
      label: map['label'] as String?,
      isAvailable: (map['is_available'] as int? ?? 1) == 1,
    );
  }
}
