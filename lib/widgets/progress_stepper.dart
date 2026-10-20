import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StepKind { done, current, pending, failed }

class StepperStep {
  const StepperStep(this.label, this.time, this.state);
  final String label;

  /// Already formatted; null renders [emptyTime].
  final String? time;
  final StepKind state;
}

const _line = Color(0xFFDDE6F0);

/// Horizontal stepper shared by the order timeline (4 steps) and the payout
/// timeline (3 steps). It only draws what it is given: it owns no state.
class ProgressStepper extends StatelessWidget {
  const ProgressStepper(
      {super.key, required this.steps, this.emptyTime = 'Chưa có'});
  final List<StepperStep> steps;
  final String emptyTime;

  bool _reached(StepKind s) => s == StepKind.done || s == StepKind.current;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < steps.length; i++) Expanded(child: _column(i)),
    ]);
  }

  Widget _column(int i) {
    final s = steps[i];
    final leftOn = i > 0 && _reached(s.state) && _reached(steps[i - 1].state);
    final rightOn = i < steps.length - 1 &&
        _reached(steps[i + 1].state) &&
        _reached(s.state);
    final failed = s.state == StepKind.failed;
    final labelColor = failed
        ? AppColors.dangerDark
        : s.state == StepKind.current
            ? AppColors.primary
            : s.state == StepKind.pending
                ? AppColors.textSub
                : AppColors.ink;
    return Column(children: [
      SizedBox(
          height: 34,
          child: Row(children: [
            Expanded(child: _segment(i > 0, leftOn)),
            _Dot(s.state),
            Expanded(child: _segment(i < steps.length - 1, rightOn)),
          ])),
      const SizedBox(height: 8),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(s.label,
              textAlign: TextAlign.center,
              style: appText(11.5,
                  weight: s.state == StepKind.pending
                      ? FontWeight.w500
                      : FontWeight.w600,
                  color: labelColor))),
      const SizedBox(height: 4),
      Text(s.time ?? emptyTime,
          textAlign: TextAlign.center,
          style: appText(11, color: AppColors.textSub)),
    ]);
  }

  Widget _segment(bool exists, bool on) => AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 2,
      color: !exists
          ? Colors.transparent
          : on
              ? AppColors.primary
              : _line);
}

class _Dot extends StatelessWidget {
  const _Dot(this.state);
  final StepKind state;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color border;
    final Widget? child;
    switch (state) {
      case StepKind.done:
        fill = AppColors.primary;
        border = AppColors.primary;
        child = const Icon(Icons.check_rounded, size: 18, color: Colors.white);
      case StepKind.current:
        fill = AppColors.primary;
        border = const Color(0xFFD3E5F5);
        child = Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle));
      case StepKind.failed:
        fill = AppColors.dangerDark;
        border = AppColors.dangerDark;
        child = const Icon(Icons.close_rounded, size: 18, color: Colors.white);
      case StepKind.pending:
        fill = Colors.white;
        border = _line;
        child = Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFFC4CFDC), shape: BoxShape.circle));
    }
    final ring = state == StepKind.current ? 4.0 : 1.5;
    return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 30 + (state == StepKind.current ? 4 : 0),
        height: 30 + (state == StepKind.current ? 4 : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(
                color: border,
                width: state == StepKind.done || state == StepKind.failed
                    ? 0
                    : ring)),
        child: child);
  }
}
