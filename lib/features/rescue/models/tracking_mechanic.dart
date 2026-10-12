class TrackingMechanic {
  const TrackingMechanic({
    this.name = 'Nguyễn Minh Tuấn',
    this.shop = 'Tiệm sửa xe Siêu Tốc',
    this.plate = '59-X1 123.45',
    this.vehicle = 'Honda Wave',
    this.rating = 4.9,
    this.phoneNumber,
    this.avatarUrl,
  });
  final String name, shop, plate, vehicle;
  final double rating;
  final String? phoneNumber, avatarUrl;

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    return words
        .skip(words.length > 1 ? words.length - 2 : 0)
        .map((word) => word.substring(0, 1))
        .join()
        .toUpperCase();
  }
}
