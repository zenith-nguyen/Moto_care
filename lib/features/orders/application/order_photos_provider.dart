import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../domain/order_photo.dart';

/// Incident photo metadata for an order (both participants may read it).
final orderIncidentPhotosProvider = FutureProvider.autoDispose
    .family<List<OrderPhoto>, int>((ref, orderId) async {
      return ref.read(orderPhotosRepositoryProvider).list(orderId);
    });

typedef IncidentPhotoKey = ({int orderId, int photoId});

/// Raw bytes for one protected incident photo, fetched on demand.
final orderIncidentPhotoBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, IncidentPhotoKey>((ref, key) async {
      return ref
          .read(orderPhotosRepositoryProvider)
          .loadImage(orderId: key.orderId, photoId: key.photoId);
    });
