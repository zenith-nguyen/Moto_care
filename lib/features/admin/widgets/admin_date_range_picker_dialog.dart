import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/admin_tokens.dart';

/// Edits an inclusive calendar range locally and returns it only on Apply.
class AdminDateRangePickerDialog extends StatefulWidget {
  AdminDateRangePickerDialog({
    super.key,
    required DateTime firstDate,
    required DateTime lastDate,
    required DateTime currentDate,
    DateTimeRange? initialDateRange,
  }) : firstDate = DateUtils.dateOnly(firstDate),
       lastDate = DateUtils.dateOnly(lastDate),
       currentDate = DateUtils.dateOnly(currentDate),
       initialDateRange = initialDateRange == null
           ? null
           : DateTimeRange(
               start: DateUtils.dateOnly(initialDateRange.start),
               end: DateUtils.dateOnly(initialDateRange.end),
             ) {
    assert(!this.lastDate.isBefore(this.firstDate));
    assert(
      this.initialDateRange == null ||
          (!this.initialDateRange!.start.isBefore(this.firstDate) &&
              !this.initialDateRange!.end.isAfter(this.lastDate)),
    );
  }

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime currentDate;
  final DateTimeRange? initialDateRange;

  @override
  State<AdminDateRangePickerDialog> createState() =>
      _AdminDateRangePickerDialogState();
}

class _AdminDateRangePickerDialogState
    extends State<AdminDateRangePickerDialog> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _start = widget.initialDateRange?.start;
    _end = widget.initialDateRange?.end;
    final initial = _start ?? widget.currentDate;
    final visible = initial.isBefore(widget.firstDate)
        ? widget.firstDate
        : initial.isAfter(widget.lastDate)
        ? widget.lastDate
        : initial;
    _month = DateTime(visible.year, visible.month);
  }

  String get _rangeLabel {
    final start = _start;
    final end = _end;
    if (start == null) return 'Ngày bắt đầu – Ngày kết thúc';
    final showYear = end != null && start.year != end.year;
    String label(DateTime date) =>
        '${date.day} thg ${date.month}${showYear ? ', ${date.year}' : ''}';
    return '${label(start)} – ${end == null ? 'Ngày kết thúc' : label(end)}';
  }

  bool _canChangeMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    return !next.isBefore(
          DateTime(widget.firstDate.year, widget.firstDate.month),
        ) &&
        !next.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  void _changeMonth(int delta) {
    if (!_canChangeMonth(delta)) return;
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _onSwipeEnd(DragEndDetails details) {
    final distance = _dragDistance;
    _dragDistance = 0;
    final velocity = details.primaryVelocity ?? 0;
    if (distance.abs() < 24 && velocity.abs() < 200) return;
    final direction = distance.abs() >= 24 ? distance : velocity;
    // The requested gesture is left = previous, right = next.
    _changeMonth(direction < 0 ? -1 : 1);
  }

  void _selectDay(DateTime date) => setState(() {
    if (_start == null || _end != null) {
      _start = date;
      _end = null;
    } else if (date.isBefore(_start!)) {
      _end = _start;
      _start = date;
    } else {
      _end = date;
    }
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AdminTokens.surface,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: DefaultTextStyle(
      style: GoogleFonts.montserrat(color: AdminTokens.text, fontSize: 14),
      child: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Đóng',
                    icon: const Icon(Icons.close, color: AdminTokens.text),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Chọn khoảng ngày',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AdminTokens.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _start == null || _end == null
                        ? null
                        : () => Navigator.of(context)
                              .pop(DateTimeRange(start: _start!, end: _end!)),
                    style: TextButton.styleFrom(
                      foregroundColor: AdminTokens.primaryBlue,
                      textStyle: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _rangeLabel,
                        key: const ValueKey('admin-date-range-label'),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            liveRegion: true,
                            child: Text(
                              'Tháng ${_month.month}, ${_month.year}',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AdminTokens.text,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tháng trước',
                          onPressed: _canChangeMonth(-1)
                              ? () => _changeMonth(-1)
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        IconButton(
                          tooltip: 'Tháng sau',
                          onPressed: _canChangeMonth(1)
                              ? () => _changeMonth(1)
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final day in [
                          'T2',
                          'T3',
                          'T4',
                          'T5',
                          'T6',
                          'T7',
                          'CN',
                        ])
                          Expanded(
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: const Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      key: const ValueKey('admin-date-calendar'),
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) => _dragDistance = 0,
                      onHorizontalDragUpdate: (details) =>
                          _dragDistance += details.delta.dx,
                      onHorizontalDragEnd: _onSwipeEnd,
                      onHorizontalDragCancel: () => _dragDistance = 0,
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: _CalendarMonth(
                          key: ValueKey(
                            'admin-calendar-${_month.year}-${_month.month}',
                          ),
                          month: _month,
                          firstDate: widget.firstDate,
                          lastDate: widget.lastDate,
                          today: widget.currentDate,
                          start: _start,
                          end: _end,
                          onSelected: _selectDay,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CalendarMonth extends StatelessWidget {
  const _CalendarMonth({
    super.key,
    required this.month,
    required this.firstDate,
    required this.lastDate,
    required this.today,
    required this.start,
    required this.end,
    required this.onSelected,
  });

  final DateTime month;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime today;
  final DateTime? start;
  final DateTime? end;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final leading = month.weekday - DateTime.monday;
      final days = DateUtils.getDaysInMonth(month.year, month.month);
      final width = constraints.maxWidth / 7;
      final height = math.max(48.0, MediaQuery.textScalerOf(context).scale(36));
      return GridView.builder(
        primary: false,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisExtent: height,
        ),
        itemCount: 42,
        itemBuilder: (context, index) {
          final day = index - leading + 1;
          if (day < 1 || day > days) return const SizedBox.shrink();
          final date = DateTime(month.year, month.month, day);
          return _CalendarDay(
            date: date,
            enabled: !date.isBefore(firstDate) && !date.isAfter(lastDate),
            today: DateUtils.isSameDay(date, today),
            isStart: date == start,
            isEnd: date == end,
            inRange:
                start != null &&
                end != null &&
                !date.isBefore(start!) &&
                !date.isAfter(end!),
            width: width,
            height: height,
            onSelected: () => onSelected(date),
          );
        },
      );
    },
  );
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.enabled,
    required this.today,
    required this.isStart,
    required this.isEnd,
    required this.inRange,
    required this.width,
    required this.height,
    required this.onSelected,
  });

  final DateTime date;
  final bool enabled;
  final bool today;
  final bool isStart;
  final bool isEnd;
  final bool inRange;
  final double width;
  final double height;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final endpoint = isStart || isEnd;
    final diameter = math.min(40.0, width - 4);
    final color = endpoint
        ? Colors.white
        : !enabled
        ? const Color(0xFFC7C7CC)
        : inRange
        ? AdminTokens.primaryBlue
        : AdminTokens.text;
    return Semantics(
      key: ValueKey('admin-date-${date.year}-${date.month}-${date.day}'),
      label:
          '${MaterialLocalizations.of(context).formatFullDate(date)}'
          '${today ? ', hôm nay' : ''}',
      button: true,
      enabled: enabled,
      selected: endpoint || inRange,
      excludeSemantics: true,
      onTap: enabled ? onSelected : null,
      child: InkWell(
        onTap: enabled ? onSelected : null,
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (inRange && !(isStart && isEnd))
              Positioned(
                left: isStart ? width / 2 : 0,
                right: isEnd ? width / 2 : 0,
                top: (height - diameter) / 2,
                height: diameter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AdminTokens.activePill,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(
                        date.weekday == DateTime.monday || date.day == 1
                            ? 6
                            : 0,
                      ),
                      right: Radius.circular(
                        date.weekday == DateTime.sunday ||
                                date.day ==
                                    DateUtils.getDaysInMonth(
                                      date.year,
                                      date.month,
                                    )
                            ? 6
                            : 0,
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: endpoint ? AdminTokens.primaryBlue : null,
                border: today && !endpoint
                    ? Border.all(
                        color: AdminTokens.primaryBlue.withValues(alpha: .2),
                      )
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: endpoint ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  if (today)
                    Positioned(
                      bottom: 3,
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
