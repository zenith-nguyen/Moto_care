enum AppNotificationType {
  offerCreated('OFFER_CREATED'),
  offerExpired('OFFER_EXPIRED'),
  orderStatusChanged('ORDER_STATUS_CHANGED'),
  providerNearby('PROVIDER_NEARBY'),
  messageCreated('MESSAGE_CREATED'),
  system('SYSTEM');

  const AppNotificationType(this.wireValue);
  final String wireValue;

  static AppNotificationType parse(Object? value) {
    return values.firstWhere(
      (type) => type.wireValue == value,
      orElse: () => throw const FormatException('Unknown notification type.'),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  final int id;
  final AppNotificationType type;
  final String title;
  final String body;
  final Map<String, String> data;
  final DateTime? readAt;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (json['id'] is! int ||
        json['title'] is! String ||
        json['body'] is! String ||
        rawData is! Map) {
      throw const FormatException('Invalid notification response.');
    }
    final data = <String, String>{};
    for (final entry in rawData.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const FormatException('Invalid notification data.');
      }
      data[entry.key as String] = entry.value as String;
    }
    return AppNotification(
      id: json['id'] as int,
      type: AppNotificationType.parse(json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      data: Map.unmodifiable(data),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.nextCursor,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final int? nextCursor;
  final int unreadCount;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List || json['unreadCount'] is! int) {
      throw const FormatException('Invalid notification page.');
    }
    return NotificationPage(
      items: rawItems
          .map((item) {
            if (item is! Map) {
              throw const FormatException('Invalid notification item.');
            }
            return AppNotification.fromJson(Map<String, dynamic>.from(item));
          })
          .toList(growable: false),
      nextCursor: json['nextCursor'] as int?,
      unreadCount: json['unreadCount'] as int,
    );
  }
}
