import 'package:flutter/material.dart';

import '../models/home_destination.dart';
import '../models/home_user.dart';
import 'home_screen.dart';

/// Compatibility entry point for the existing Vietnamese route.
class TrangChu extends StatelessWidget {
  const TrangChu({super.key, this.user, this.onDestinationSelected});
  final HomeUser? user;
  final ValueChanged<HomeDestination>? onDestinationSelected;

  @override
  Widget build(BuildContext context) =>
      HomeScreen(user: user, onDestinationSelected: onDestinationSelected);
}
