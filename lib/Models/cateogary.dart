class CategoryModel {
  final String id;
  final String name;
  final String? icon; // can be emoji, asset, or url

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      icon: map['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
    };
  }
}
