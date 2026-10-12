import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:intl/intl.dart';

import '../../activity/models/rescue_order.dart';
import '../data/service_rating_tags.dart';
import '../models/service_rating.dart';

final serviceRatingServiceProvider = Provider<ServiceRatingService>(
  (ref) => ServiceRatingService(),
);

/// Override with the real review API when available. Default storage is session-only.
final serviceRatingSubmitterProvider =
    Provider<Future<void> Function(ServiceRating)>((ref) => (_) async {});

class ServiceRatingService {
  ServiceRatingService({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;

  ServiceRating create(
    RescueOrder? order, {
    required int stars,
    required Set<String> tagIds,
    required String comment,
    Uint8List? photo,
  }) {
    if (order == null || order.status != RescueOrderStatus.completed) {
      throw StateError('Chỉ có thể đánh giá đơn đã hoàn thành.');
    }
    if (stars < 1 || stars > 5) {
      throw StateError('Vui lòng chọn từ 1 đến 5 sao.');
    }
    if (!tagIds.every((id) => serviceRatingTags.any((tag) => tag.id == id))) {
      throw StateError('Nhãn đánh giá không hợp lệ.');
    }
    if (comment.trim().characters.length > 1000) {
      throw StateError('Nhận xét tối đa 1.000 ký tự.');
    }
    if (photo != null && photo.length > 5 * 1024 * 1024) {
      throw StateError('Vui lòng chọn ảnh nhỏ hơn 5 MB.');
    }
    return ServiceRating(
      orderId: order.id,
      stars: stars,
      tagIds: tagIds,
      comment: comment.trim(),
      photo: photo,
      createdAt: _clock(),
    );
  }

  ServiceRatingSummary summary(RescueOrder order) {
    final name = order.providerName?.trim();
    final words = (name ?? '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final service = order.items.isNotEmpty
        ? order.items
              .map(
                (item) =>
                    '${item.name}${item.quantity > 1 ? ' × ${item.quantity}' : ''}',
              )
              .join(', ')
        : order.serviceOption.isNotEmpty
        ? order.serviceOption
        : order.serviceType.label;
    return ServiceRatingSummary(
      mechanicName: name?.isNotEmpty == true ? name! : 'Chưa có thông tin thợ',
      shopName: order.partnerName?.trim().isNotEmpty == true
          ? order.partnerName!.trim()
          : 'Chưa có thông tin tiệm',
      initials: words.isEmpty
          ? '?'
          : words
                .skip(words.length > 1 ? words.length - 2 : 0)
                .map((word) => word.substring(0, 1))
                .join()
                .toUpperCase(),
      serviceAndPrice:
          '$service • ${NumberFormat.decimalPattern('vi').format(order.totalPrice)}đ',
    );
  }
}
