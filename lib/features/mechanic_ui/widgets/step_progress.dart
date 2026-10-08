import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Thanh tiến độ ngang nhiều bước, có connector line.
/// Bước xong: xanh + check. Bước hiện tại: đỏ. Chưa tới: xám.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current, required this.labels});

  final int current; // chỉ số bước hiện tại (0-based)
  final List<String> labels;

  bool _isDone(int i) =>
      i < current || (i == current && i == labels.length - 1);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: _StepCell(
              index: i,
              label: labels[i],
              isFirst: i == 0,
              isLast: i == labels.length - 1,
              done: _isDone(i),
              active: i == current && !_isDone(i),
              leftDone: i <= current, // đoạn nối (i-1 -> i)
              rightDone: i < current, // đoạn nối (i -> i+1)
            ),
          ),
      ],
    );
  }
}

class _StepCell extends StatelessWidget {
  const _StepCell({
    required this.index,
    required this.label,
    required this.isFirst,
    required this.isLast,
    required this.done,
    required this.active,
    required this.leftDone,
    required this.rightDone,
  });

  final int index;
  final String label;
  final bool isFirst;
  final bool isLast;
  final bool done;
  final bool active;
  final bool leftDone;
  final bool rightDone;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = done
        ? AppColors.ink
        : (active ? AppColors.primaryDark : AppColors.textSub);

    return Column(
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: [
              Expanded(
                child: isFirst
                    ? const SizedBox.shrink()
                    : _Connector(done: leftDone),
              ),
              _Dot(number: index + 1, done: done, active: active),
              Expanded(
                child: isLast
                    ? const SizedBox.shrink()
                    : _Connector(done: rightDone),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: appText(
              10.5,
              weight: active ? FontWeight.w700 : FontWeight.w600,
              color: labelColor,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      height: 3,
      decoration: BoxDecoration(
        color: done ? AppColors.success : AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.number, required this.done, required this.active});

  final int number;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color bg = done
        ? AppColors.success
        : (active ? AppColors.primary : AppColors.border);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primary.op(0.28),
                  spreadRadius: 3,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: done
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text(
              '$number',
              style: appText(
                12,
                weight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textSub,
              ),
            ),
    );
  }
}
