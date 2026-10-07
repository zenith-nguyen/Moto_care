import 'package:flutter/foundation.dart';

/// Account information supplied by the authentication flow.
@immutable
class HomeUser {
  const HomeUser({
    required this.displayName,
    this.memberId,
    this.membershipLabel = 'Chưa có hạng',
    this.rewardPoints = 0,
  });

  final String displayName;
  final String? memberId;
  final String membershipLabel;
  final int rewardPoints;
}
