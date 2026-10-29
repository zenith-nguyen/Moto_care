import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_tip.dart';
import '../data/emergency_tips.dart';

final emergencyTipsProvider = Provider<List<EmergencyTip>>(
  (ref) => emergencyTips,
);
