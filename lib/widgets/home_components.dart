import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/home_catalog.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class HomePalette {
  HomePalette._();
  static const background = Color(0xFFF7F9FC);
  static const card = Colors.white;
  static const border = Color(0xFFE3EAF3);
  static const text = Color(0xFF152438);
  static const secondary = Color(0xFF71839E);
  static const online = Color(0xFF00B66A);
  static const heroAccent = Color(0xFF7ABBE7);
  // Retained for callers using the earlier icon presentation.
  static const serviceIcon = Color(0xFF111111);
}

class HomeServiceTile extends StatelessWidget {
  const HomeServiceTile(
      {super.key,
      required this.service,
      required this.selected,
      required this.onTap,
      required this.imageHeight,
      this.badge,
      this.badgeActive = false});
  final HomeService service;

  /// Optional small status pill on the photo (All services screen only).
  final String? badge;
  final bool badgeActive;
  final bool selected;
  final VoidCallback onTap;
  final double imageHeight;
  static String title(HomeService service) =>
      service.id == 'all' ? 'Tất cả dịch vụ' : service.label;
  static String description(HomeService service) => service.id == 'all'
      ? 'Khám phá $homeServiceCount dịch vụ'
      : service.description;

  /// Image height as a fraction of the card width (2-column Home grid).
  static const imageRatio = .4;
  static double heightFor(
      HomeService service, double width, TextScaler scaler) {
    double measure(String value, TextStyle style, double maxWidth) {
      final painter = TextPainter(
          text: TextSpan(text: value, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler)
        ..layout(maxWidth: maxWidth);
      return painter.height;
    }

    return width * imageRatio +
        14 +
        math.max(
            13,
            measure(
                title(service),
                appText(11, weight: FontWeight.w600, height: 1.2),
                width - 30)) +
        3 +
        measure(description(service), appText(8.5, height: 1.25), width - 14);
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x07172638),
                    blurRadius: 5,
                    offset: Offset(0, 2))
              ]),
          child: Material(
            color: Colors.white,
            textStyle: appText(14, letterSpacing: 0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
                side: const BorderSide(color: HomePalette.border, width: .7)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: onTap,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                          height: imageHeight,
                          child: Stack(fit: StackFit.expand, children: [
                            service.image != null
                                ? Image.asset(service.image!,
                                    fit: BoxFit.cover,
                                    alignment: switch (service.id) {
                                      'battery' => const Alignment(.45, .35),
                                      // Portrait photo: keep bottle mouth + oil stream.
                                      'maintenance' => const Alignment(0, -.4),
                                      // Square photo: keep the nozzle and hands.
                                      'fuel' => const Alignment(0, .35),
                                      _ => Alignment.center,
                                    },
                                    excludeFromSemantics: true)
                                : ColoredBox(
                                    color: AppColors.surfaceSoft,
                                    child: Center(
                                        child: service.id == 'all'
                                            ? const HomeServiceGridIcon()
                                            : Icon(service.icon,
                                                size: 29,
                                                color: AppColors.primary))),
                            if (badge != null)
                              Positioned(
                                  left: 6,
                                  top: 6,
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: badgeActive
                                              ? AppColors.primary
                                              : const Color(0xB3172638),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Text(badge!,
                                          style: appText(8,
                                              weight: FontWeight.w500,
                                              color: Colors.white,
                                              height: 1.2)))),
                          ])),
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 6, 7),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                          child: Text(title(service),
                                              style: appText(11,
                                                  weight: FontWeight.w600,
                                                  color: HomePalette.text,
                                                  height: 1.2))),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.chevron_right_rounded,
                                          size: 13, color: HomePalette.text),
                                    ]),
                                    const SizedBox(height: 3),
                                    Text(description(service),
                                        style: appText(8.5,
                                            color: HomePalette.secondary,
                                            height: 1.25)),
                                  ]))),
                    ])),
          ),
        ),
      );
}

class HomeServiceGridIcon extends StatelessWidget {
  const HomeServiceGridIcon({super.key, this.color = AppColors.primary});
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 29,
      height: 29,
      child: CustomPaint(painter: _ServiceGridPainter(color)));
}

class _ServiceGridPainter extends CustomPainter {
  const _ServiceGridPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 29, size.height / 29);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final x in [3.0, 16.0]) {
      for (final y in [3.0, 16.0]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, 9.5, 9.5), const Radius.circular(1.5)),
            pen);
      }
    }
  }

  @override
  bool shouldRepaint(_ServiceGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel(
      {super.key,
      required this.onReceive,
      required this.onSchedule,
      required this.onServices,
      required this.onOrders,
      required this.hasActive,
      required this.canReceive});
  final VoidCallback onReceive, onSchedule, onServices, onOrders;
  final bool hasActive, canReceive;
  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  static const _count = 3;
  // The PageView is virtually endless so arrows, swipes and dots all wrap
  // naturally; the visible slide is always `raw % _count`.
  static const _origin = _count * 1000;
  final _pages = PageController(initialPage: _origin);
  int _page = 0;
  bool _animating = false;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  int get _raw =>
      _pages.hasClients ? (_pages.page ?? _origin.toDouble()).round() : _origin;

  Future<void> _goTo(int raw) async {
    if (_animating || !_pages.hasClients) return;
    _animating = true;
    try {
      await _pages.animateToPage(raw,
          duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
    } finally {
      _animating = false;
    }
  }

  void _step(int delta) => _goTo(_raw + delta);

  /// Shortest wrapped distance to [index], so dots never spin through slides.
  void _jumpToDot(int index) {
    var delta = (index - _page) % _count;
    if (delta > _count ~/ 2) delta -= _count;
    if (delta != 0) _goTo(_raw + delta);
  }

  Widget _arrow({required bool left}) => Positioned(
      left: left ? 2 : null,
      right: left ? null : 2,
      top: 0,
      bottom: 0,
      child: Center(
          child: IconButton(
              key: ValueKey(left ? 'hero-prev' : 'hero-next'),
              tooltip: left ? 'Banner trước' : 'Banner tiếp theo',
              style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  fixedSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () => _step(left ? -1 : 1),
              icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x8C172638),
                      border: Border.all(color: const Color(0x33FFFFFF))),
                  child: Icon(
                      left
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: 22,
                      color: Colors.white)))));

  Widget _button(
      String label, IconData icon, VoidCallback? action, double height,
      {bool outline = false}) {
    final text = Text(label,
        maxLines: 2,
        textAlign: TextAlign.center,
        style: appText(11, color: Colors.white, weight: FontWeight.w600));
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    return SizedBox(
        height: height,
        child: outline
            ? OutlinedButton.icon(
                onPressed: action,
                icon: Icon(icon, size: 16),
                label: text,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: .8),
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    shape: shape))
            : FilledButton.icon(
                onPressed: action,
                icon: Icon(icon, size: 16),
                label: text,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFF47657A),
                    disabledForegroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    shape: shape)));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final scale = scaler.scale(1);
        final height =
            math.max(178.0, box.maxWidth / 2.22) + math.max(0, scale - 1) * 210;
        final wrapLabels = scale > 1.2 && box.maxWidth < 380;
        final buttonHeight =
            math.max(36.0, scaler.scale(11) * 1.4 * (wrapLabels ? 2 : 1) + 16);
        final headline = math.min(22.0, (box.maxWidth - 32) / 15.2);
        final buttonWidth =
            math.min(box.maxWidth - 64, scale > 1.25 ? 310.0 : 240.0);
        final slides = <Widget>[
          _slide(
              image: 'assets/images/revo_hero_engine.jpg',
              first: 'Cứu hộ nhanh',
              second: 'có mặt kịp thời',
              description:
                  'Đồng hành mọi hành trình tại TP.HCM và các khu vực lân cận',
              headline: headline,
              buttonWidth: buttonWidth,
              buttons: [
                _button(
                    widget.hasActive ? 'Tiếp tục' : 'Nhận đơn',
                    Icons.bolt_rounded,
                    widget.hasActive || widget.canReceive
                        ? widget.onReceive
                        : null,
                    buttonHeight),
                _button('Xem lịch', Icons.calendar_month_outlined,
                    widget.onSchedule, buttonHeight,
                    outline: true),
              ]),
          _slide(
              image: 'assets/images/revo_hero_tools.jpg',
              alignment: const Alignment(.35, -.1),
              first: 'Chủ động công việc',
              second: 'cùng REVO mỗi ngày',
              description: 'Xem đơn đang làm và lịch sử công việc.',
              headline: headline,
              buttonWidth: math.min(buttonWidth + 44, box.maxWidth - 64),
              dim: .22,
              buttons: [
                _button('Lịch công việc', Icons.calendar_month_outlined,
                    widget.onSchedule, buttonHeight),
                _button('Đơn hàng', Icons.assignment_outlined, widget.onOrders,
                    buttonHeight,
                    outline: true),
              ]),
          _slide(
              image: 'assets/images/revo_hero_teamwork.jpg',
              alignment: const Alignment(0, -.6),
              first: 'Sẵn sàng cứu hộ',
              second: 'đúng dịch vụ của bạn',
              description: 'Cập nhật dịch vụ để nhận đơn phù hợp.',
              headline: headline,
              buttonWidth: buttonWidth,
              buttons: [
                _button('Dịch vụ', Icons.build_outlined, widget.onServices,
                    buttonHeight),
                _button('Đơn hàng', Icons.assignment_outlined, widget.onOrders,
                    buttonHeight,
                    outline: true),
              ]),
        ];
        return Column(children: [
          SizedBox(
              height: height,
              child: Stack(children: [
                Positioned.fill(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: PageView.builder(
                            key: const ValueKey('hero-pages'),
                            controller: _pages,
                            onPageChanged: (v) =>
                                setState(() => _page = v % _count),
                            itemBuilder: (_, i) => slides[i % _count]))),
                _arrow(left: true),
                _arrow(left: false),
              ])),
          SizedBox(
              height: 18,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 3; i++)
                  Semantics(
                      selected: _page == i,
                      child: Tooltip(
                          message: 'Banner ${i + 1}',
                          child: InkWell(
                              onTap: () => _jumpToDot(i),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3, vertical: 5),
                                  child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _page == i
                                              ? AppColors.primary
                                              : const Color(0xFFD2DDE9))))))),
              ])),
        ]);
      });
  Widget _slide(
          {required String image,
          Alignment alignment = const Alignment(.7, .05),
          required String first,
          required String second,
          required String description,
          required double headline,
          required double buttonWidth,
          double dim = 0,
          required List<Widget> buttons}) =>
      Stack(fit: StackFit.expand, children: [
        Image.asset(image,
            fit: BoxFit.cover,
            alignment: alignment,
            excludeFromSemantics: true),
        if (dim > 0)
          ColoredBox(color: const Color(0xFF172638).withValues(alpha: dim)),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
          Color(0xFF172638),
          Color(0xE6172638),
          Color(0x32172638),
          Color(0x07172638)
        ], stops: [
          0,
          .28,
          .69,
          1
        ]))),
        Padding(
            padding: const EdgeInsets.fromLTRB(48, 14, 16, 14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(first,
                      style: appText(headline,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15)),
                  Text(second,
                      style: appText(headline,
                          weight: FontWeight.w700,
                          color: HomePalette.heroAccent,
                          height: 1.15)),
                  const SizedBox(height: 6),
                  SizedBox(
                      width: buttonWidth * .91,
                      child: Text(description,
                          style:
                              appText(10.2, color: Colors.white, height: 1.3))),
                  const SizedBox(height: 12),
                  SizedBox(
                      width: buttonWidth,
                      child: Row(children: [
                        for (var i = 0; i < buttons.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: buttons[i]),
                        ],
                      ])),
                ])),
      ]);
}

class NearbyRequestCard extends StatelessWidget {
  const NearbyRequestCard(
      {super.key,
      required this.request,
      required this.status,
      required this.actionLabel,
      required this.onAction,
      this.secondary = false});
  final HomeRequest request;
  final HomeRequestStatus status;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool secondary;
  String get _title =>
      homeServices.where((s) => s.id == request.serviceId).firstOrNull?.label ??
      request.title;
  String get _statusLabel => switch (status) {
        HomeRequestStatus.waiting => 'Đang chờ',
        HomeRequestStatus.active => 'Đang làm',
        HomeRequestStatus.expired => 'Hết hạn',
        HomeRequestStatus.assignedElsewhere => 'Đã có thợ',
        HomeRequestStatus.completed => 'Hoàn thành',
        HomeRequestStatus.cancelled => 'Đã hủy',
      };
  static double imageHeight(double width, TextScaler scaler) => math.max(
      width / 3.2, scaler.scale(1) > 1.25 ? scaler.scale(8) * 2.4 + 32 : 0);

  static double heightFor(HomeRequest request, double width, TextScaler scaler,
      {String? footer}) {
    TextPainter measure(String value, TextStyle style, double maxWidth) =>
        TextPainter(
            text: TextSpan(text: value, style: style),
            textDirection: TextDirection.ltr,
            textScaler: scaler)
          ..layout(maxWidth: maxWidth);
    final label = homeServices
            .where((s) => s.id == request.serviceId)
            .firstOrNull
            ?.label ??
        request.title;
    final amount = measure(
        formatVnd(request.offer.price - request.offer.platformFee),
        appText(11.5, weight: FontWeight.w600, height: 1.3),
        double.infinity);
    final stacked = scaler.scale(1) > 1.25;
    final title = measure(
        label,
        appText(11, weight: FontWeight.w600, height: 1.3),
        stacked ? width - 18 : math.max(1, width - 21 - amount.width));
    final heading = stacked
        ? title.height + 2 + amount.height
        : math.max(title.height, amount.height);
    final address =
        measure(request.offer.address, appText(9.5, height: 1.35), width - 34);
    final time = measure(
        footer ?? 'Dự kiến nhận: ${request.offer.etaMinutes} phút',
        appText(9.5, height: 1.3),
        width - 34);
    return imageHeight(width, scaler) +
        14 +
        heading +
        4 +
        address.height +
        11 +
        math.max(16, time.height) +
        4;
  }

  Widget _heading(bool stacked) {
    final title = Text(_title,
        style: appText(11,
            weight: FontWeight.w600, color: HomePalette.text, height: 1.3));
    final amount = Text(
        formatVnd(request.offer.price - request.offer.platformFee),
        style: appText(11.5,
            weight: FontWeight.w600, color: AppColors.primary, height: 1.3));
    return stacked
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 2), amount])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: title),
            const SizedBox(width: 3),
            amount
          ]);
  }

  @override
  Widget build(BuildContext context) {
    final o = request.offer;
    final scaler = MediaQuery.textScalerOf(context);
    final stacked = scaler.scale(1) > 1.25;
    final available = onAction != null && status == HomeRequestStatus.waiting;
    final footer =
        available ? 'Dự kiến nhận: ${o.etaMinutes} phút' : actionLabel;
    return Semantics(
      button: onAction != null,
      label: '${request.title}, ${o.code}, $actionLabel',
      child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x07172638),
                    blurRadius: 5,
                    offset: Offset(0, 2))
              ]),
          child: Material(
            key: ValueKey('nearby-${o.orderId}'),
            color: Colors.white,
            textStyle: appText(14, letterSpacing: 0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: HomePalette.border, width: .7)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: onAction,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                          builder: (context, box) => SizedBox(
                              height: imageHeight(box.maxWidth, scaler),
                              child: Stack(fit: StackFit.expand, children: [
                                Image.asset(request.image,
                                    fit: BoxFit.cover,
                                    excludeFromSemantics: true),
                                Positioned(
                                    left: 7,
                                    top: 6,
                                    child: _badge(
                                        _statusLabel, AppColors.primary)),
                                Positioned(
                                    right: 7,
                                    top: stacked ? null : 6,
                                    bottom: stacked ? 6 : null,
                                    child: _badge(
                                        '${o.distanceKm.toStringAsFixed(1)} km',
                                        Colors.black.withValues(alpha: .7),
                                        icon: Icons.location_on_rounded)),
                              ]))),
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _heading(stacked),
                                    const SizedBox(height: 4),
                                    Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.location_on_rounded,
                                              size: 12,
                                              color: HomePalette.secondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                              child: Text(o.address,
                                                  style: appText(9.5,
                                                      color:
                                                          HomePalette.secondary,
                                                      height: 1.35))),
                                        ]),
                                    const Spacer(),
                                    const Padding(
                                        padding:
                                            EdgeInsets.only(top: 5, bottom: 5),
                                        child:
                                            Divider(color: HomePalette.border)),
                                    Row(children: [
                                      Expanded(
                                          child: Text(footer,
                                              style: appText(9.5,
                                                  color: HomePalette.secondary,
                                                  height: 1.3))),
                                      const Icon(Icons.chevron_right_rounded,
                                          size: 16, color: HomePalette.text)
                                    ]),
                                  ]))),
                    ])),
          )),
    );
  }

  Widget _badge(String label, Color color, {IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 2)
        ],
        Text(label,
            style: appText(8,
                weight: FontWeight.w500, color: Colors.white, height: 1.2)),
      ]));
}

class HomeCommitments extends StatelessWidget {
  const HomeCommitments({super.key});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
          color: HomePalette.card,
          border: Border(
              top: BorderSide(color: HomePalette.border),
              bottom: BorderSide(color: HomePalette.border))),
      child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const VerticalDivider(width: 1, color: HomePalette.border),
          Expanded(
              child: Column(children: [
            Icon(
                [
                  Icons.shield_outlined,
                  Icons.location_on_rounded,
                  Icons.receipt_long_rounded,
                  Icons.headset_mic_outlined
                ][i],
                color: AppColors.primary,
                size: 23),
            const SizedBox(height: 6),
            Text(['Uy tín', 'Theo dõi', 'Minh bạch', 'Hỗ trợ nhanh'][i],
                textAlign: TextAlign.center,
                style: appText(9, weight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(
                [
                  'Thông tin rõ ràng',
                  'Tiến trình đơn',
                  'Thu nhập rõ ràng',
                  'Hướng dẫn trong app'
                ][i],
                textAlign: TextAlign.center,
                style: appText(7.5, color: AppColors.textSub, height: 1.4)),
          ])),
        ],
      ])));
}
