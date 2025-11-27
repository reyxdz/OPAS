class ProductCategory {
  final int id;
  final String slug;
  final String name;
  final int? parentId;
  final String? description;
  final bool active;
  final List<ProductCategory>? children;

  ProductCategory({
    required this.id,
    required this.slug,
    required this.name,
    this.parentId,
    this.description,
    required this.active,
    this.children,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      slug: json['slug'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as int?,
      description: json['description'] as String?,
      active: json['active'] as bool? ?? true,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((child) => ProductCategory.fromJson(child as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'parent_id': parentId,
      'description': description,
      'active': active,
      'children': children?.map((child) => child.toJson()).toList(),
    };
  }

  /// Get all children categories (flat list)
  List<ProductCategory> get allChildren {
    if (children == null || children!.isEmpty) return [];
    return children!;
  }

  /// Check if category has children
  bool get hasChildren => children != null && children!.isNotEmpty;
}
