class PaginatedList<T> {
  final List<T> items;
  final PaginationInfo pagination;

  PaginatedList({required this.items, required this.pagination});

  PaginatedList<T> copyWith({List<T>? items, PaginationInfo? pagination}) {
    return PaginatedList<T>(
      items: items ?? this.items,
      pagination: pagination ?? this.pagination,
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int totalItems;
  final int perPage;

  bool get hasMore => currentPage < lastPage;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.totalItems,
    required this.perPage,
  });

  factory PaginationInfo.fromLaravelMeta(Map<String, dynamic> meta) {
    return PaginationInfo(
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      totalItems: meta['total'] ?? 0,
      perPage: meta['per_page'] ?? 20,
    );
  }

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? json['total_pages'] ?? 1,
      totalItems: json['total'] ?? 0,
      perPage: json['per_page'] ?? 20,
    );
  }
}
