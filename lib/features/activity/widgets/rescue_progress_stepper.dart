import 'package:flutter/material.dart';

import '../models/order_details.dart';
import '../theme/order_details_theme.dart';

class RescueProgressStepper extends StatelessWidget {
  const RescueProgressStepper({super.key, required this.steps});
  final List<RescueProgressStep> steps;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < steps.length; i++)
        Expanded(
          child: Semantics(
            label:
                '${steps[i].label}, ${switch (steps[i].state) {
                  RescueProgressState.done => 'đã xong',
                  RescueProgressState.active => 'đang diễn ra',
                  RescueProgressState.upcoming => 'chưa bắt đầu',
                }}, ${steps[i].time}',
            child: ExcludeSemantics(
              child: Column(
                children: [
                  SizedBox(
                    height: 38,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 2.5,
                                color: i == 0
                                    ? Colors.transparent
                                    : steps[i].state ==
                                          RescueProgressState.upcoming
                                    ? OrderDetailsTheme.line
                                    : OrderDetailsTheme.text,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2.5,
                                color: i == steps.length - 1
                                    ? Colors.transparent
                                    : steps[i + 1].state ==
                                          RescueProgressState.upcoming
                                    ? OrderDetailsTheme.line
                                    : OrderDetailsTheme.text,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          key: ValueKey('order-progress-$i'),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: switch (steps[i].state) {
                              RescueProgressState.active ||
                              RescueProgressState.done => Colors.white,
                              RescueProgressState.upcoming =>
                                OrderDetailsTheme.line,
                            },
                          ),
                          child: Icon(
                            steps[i].state == RescueProgressState.upcoming
                                ? Icons.circle
                                : Icons.check_circle,
                            size: steps[i].state == RescueProgressState.upcoming
                                ? 7
                                : 34,
                            color:
                                steps[i].state == RescueProgressState.upcoming
                                ? OrderDetailsTheme.muted
                                : OrderDetailsTheme.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      steps[i].label,
                      textAlign: TextAlign.center,
                      style: CustomerOrderTheme.text(
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: steps[i].state == RescueProgressState.active
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: steps[i].state == RescueProgressState.upcoming
                            ? OrderDetailsTheme.muted
                            : OrderDetailsTheme.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    steps[i].time,
                    style: CustomerOrderTheme.text(
                      fontSize: 10,
                      color: OrderDetailsTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
