import '../data/home_catalog.dart';
import '../models/models.dart';
import '../state/app_state.dart';

/// Read Home availability from the existing shared order/history state.
/// No independent wallet, repair, OTP or quote state is introduced here.
class HomeFeedRepository {
  HomeFeedRepository(this.state, {List<HomeRequest>? requests, DateTime? now})
      : requests = List.unmodifiable(requests ??
            (state.demoEnabled
                ? demoHomeRequests(now ?? DateTime.now())
                : <HomeRequest>[]));
  final AppState state;
  final List<HomeRequest> requests;

  HomeRequestStatus statusOf(HomeRequest request, {DateTime? now}) {
    if (state.history.any((o) => o.orderId == request.offer.orderId)) {
      final history =
          state.history.firstWhere((o) => o.orderId == request.offer.orderId);
      return history.status == OrderStatus.completed
          ? HomeRequestStatus.completed
          : HomeRequestStatus.cancelled;
    }
    if (state.activeOrder?.orderId == request.offer.orderId) {
      return HomeRequestStatus.active;
    }
    if (state.transactions
        .any((t) => t.isCredit && t.orderCode == request.offer.orderId)) {
      return HomeRequestStatus.completed;
    }
    if (request.status == HomeRequestStatus.active) {
      return HomeRequestStatus.assignedElsewhere;
    }
    if (request.status != HomeRequestStatus.waiting) return request.status;
    if (!(now ?? DateTime.now()).isBefore(request.availableUntil)) {
      return HomeRequestStatus.expired;
    }
    return HomeRequestStatus.waiting;
  }

  bool serviceEnabled(String serviceId) {
    final matches = homeServices.where((s) => s.id == serviceId);
    if (matches.isEmpty) return false;
    final index = matches.first.dispatchIndex;
    return index != null && state.services[index].enabled;
  }

  bool canOffer(HomeRequest request, {DateTime? now}) =>
      requests.contains(request) &&
      state.demoEnabled &&
      state.sessionActive &&
      state.isOnline &&
      state.networkAvailable &&
      state.gpsEnabled &&
      state.activeOrder == null &&
      serviceEnabled(request.serviceId) &&
      statusOf(request, now: now) == HomeRequestStatus.waiting;

  /// Action text shared by Home and the full nearby-jobs screen.
  String actionLabel(HomeRequest r, {DateTime? now}) =>
      switch (statusOf(r, now: now)) {
        HomeRequestStatus.active => 'Tiếp tục',
        HomeRequestStatus.completed =>
          state.history.any((o) => o.orderId == r.offer.orderId)
              ? 'Xem chi tiết'
              : 'Đã hoàn thành',
        HomeRequestStatus.cancelled => 'Đã hủy',
        HomeRequestStatus.expired => 'Đã hết hạn',
        HomeRequestStatus.assignedElsewhere => 'Đã có thợ nhận',
        HomeRequestStatus.waiting => state.activeOrder != null
            ? 'Đang có đơn'
            : !state.isOnline
                ? 'Đang ngoại tuyến'
                : !serviceEnabled(r.serviceId)
                    ? 'Dịch vụ đã tắt'
                    : 'Nhận đơn',
      };

  List<HomeRequest> search(
      {String query = '',
      String serviceId = 'all',
      double radiusKm = 10,
      bool newestFirst = false,
      DateTime? now}) {
    final key = homeSearchKey(query);
    final result = requests
        .where((r) =>
            (serviceId == 'all' || r.serviceId == serviceId) &&
            r.offer.distanceKm <= radiusKm &&
            homeSearchKey(
                    '${r.title} ${r.offer.code} ${r.offer.issue} ${r.offer.address} ${r.offer.vehicle}')
                .contains(key))
        .toList();
    result.sort((a, b) => newestFirst
        ? b.requestedAt.compareTo(a.requestedAt)
        : a.offer.distanceKm.compareTo(b.offer.distanceKm));
    return result;
  }

  /// Previewing a card does not accept/create an active order. The existing
  /// incoming-order popup owns the final confirmation through AppState.
  OrderOffer proposalFor(HomeRequest request, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    if (!canOffer(request, now: clock)) {
      throw StateError('Yêu cầu không còn khả dụng để nhận.');
    }
    final o = request.offer;
    final window = clock.add(const Duration(seconds: 30));
    return OrderOffer(
        code: o.code,
        issue: o.issue,
        description: o.description,
        vehicle: o.vehicle,
        plate: o.plate,
        customerName: o.customerName,
        customerPhone: o.customerPhone,
        customerEmail: o.customerEmail,
        customerRating: o.customerRating,
        customerRatingCount: o.customerRatingCount,
        customerVerified: o.customerVerified,
        address: o.address,
        distanceKm: o.distanceKm,
        etaMinutes: o.etaMinutes,
        price: o.price,
        platformFee: o.platformFee,
        verificationCode: o.verificationCode,
        expiresAt: window.isBefore(request.availableUntil)
            ? window
            : request.availableUntil);
  }
}
