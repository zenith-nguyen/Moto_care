import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/revo_brand.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../../notifications/application/notification_inbox_controller.dart';
import '../application/provider_location_tracking_controller.dart';
import '../application/provider_work_controller.dart';
import '../domain/provider_models.dart';
import 'provider_formatters.dart';

const _ink = Color(0xFF152438);
const _secondary = Color(0xFF71839E);
const _heroAccent = Color(0xFF7ABBE7);
const _cardBorder = Color(0xFFE3EAF3);

TextStyle _t(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = _ink,
  double height = 1.4,
}) => TextStyle(
  fontFamily: 'Montserrat',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: -0.3,
);

String _vnd(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${buffer.toString()} đ';
}

/// Provider (Thợ) home, job-board style ported from the REVO prototype:
/// availability header over a sky photo, weather + search, a photo hero
/// carousel, popular service photo tiles and a "Đơn gần bạn" feed. The mechanic
/// receives/accepts jobs here; they never book services like a customer.
class ProviderHomeTab extends ConsumerStatefulWidget {
  const ProviderHomeTab({super.key});

  @override
  ConsumerState<ProviderHomeTab> createState() => _ProviderHomeTabState();
}

class _ProviderHomeTabState extends ConsumerState<ProviderHomeTab> {
  String _service = 'all';

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return ColoredBox(
      color: const Color(0xFFF7F9FC),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360 + topInset,
            child: Image.asset(
              'assets/images/provider-sky.png',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFFBFE2F6)),
            ),
          ),
          RefreshIndicator(
            onRefresh: () =>
                ref.read(providerWorkControllerProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 20),
              children: [
                const _Header(),
                const SizedBox(height: 14),
                const _WeatherCard(),
                const SizedBox(height: 16),
                const _HeroCarousel(),
                const SizedBox(height: 22),
                _PopularServices(
                  selected: _service,
                  onSelected: (id) => setState(() => _service = id),
                ),
                const SizedBox(height: 22),
                _NearbyJobs(service: _service),
                const SizedBox(height: 8),
                const _Commitments(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final name = session is SessionSignedIn ? session.session.user.name : 'Thợ';
    final location = ref.watch(providerLocationTrackingControllerProvider);
    final online = location.asData?.value.isTracking ?? false;
    final busy = location.asData?.value.isBusy ?? false;
    final unread =
        ref.watch(notificationInboxControllerProvider).value?.unreadCount ?? 0;

    void toggle(bool value) {
      if (busy) return;
      final controller = ref.read(
        providerLocationTrackingControllerProvider.notifier,
      );
      value ? controller.goOnline() : controller.goOffline();
    }

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(name),
                style: _t(15, weight: FontWeight.w800, color: _ink),
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: online ? RevoBrandColors.success : _secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => toggle(!online),
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 32,
                      height: 20,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: online ? RevoBrandColors.success : _secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 180),
                        alignment: online
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        online ? 'Sẵn sàng nhận đơn' : 'Tạm dừng nhận đơn',
                        style: _t(12, weight: FontWeight.w500, color: _ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: Color(0xFF234560),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF202421),
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Quận 1, TP.HCM',
                          style: _t(
                            10,
                            weight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: const Color(0xEFFFFFFF),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.push('/provider/notifications'),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                    color: Color(0xFF172638),
                  ),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF008BDE),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF91C8EF), Color(0xFF80B3E6)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10557891),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '32°',
                      style: _t(
                        36,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Nắng nóng · Dễ nổ lốp',
                      style: _t(
                        11,
                        weight: FontWeight.w500,
                        color: const Color(0xFF354F65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(painter: _SunnyCloudPainter()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: _secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tìm đơn cứu hộ, dịch vụ',
                    style: _t(13, color: _secondary),
                  ),
                ),
                const Icon(Icons.tune_rounded, color: RevoBrandColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SunnyCloudPainter extends CustomPainter {
  const _SunnyCloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 76, size.height / 76);
    const sun = Offset(50, 27);
    final ray = Paint()
      ..color = const Color(0xFFFFD75C)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = math.pi * i / 4;
      canvas.drawLine(
        sun + Offset(math.cos(angle), math.sin(angle)) * 21,
        sun + Offset(math.cos(angle), math.sin(angle)) * 26,
        ray,
      );
    }
    canvas.drawCircle(
      sun,
      17,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.5),
          colors: [Color(0xFFFFE16D), Color(0xFFFFB500)],
        ).createShader(Rect.fromCircle(center: sun, radius: 17)),
    );
    final cloud = Path()
      ..moveTo(16, 64)
      ..cubicTo(-1, 64, -2, 42, 14, 40)
      ..cubicTo(16, 22, 43, 20, 48, 38)
      ..cubicTo(69, 33, 77, 62, 55, 64)
      ..close();
    canvas.drawShadow(cloud, const Color(0x55345F7D), 6, true);
    canvas.drawPath(
      cloud,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE3F1FC)],
        ).createShader(const Rect.fromLTWH(0, 24, 70, 42)),
    );
  }

  @override
  bool shouldRepaint(_SunnyCloudPainter oldDelegate) => false;
}

class _HeroSlide {
  const _HeroSlide({
    required this.image,
    required this.first,
    required this.second,
    required this.description,
    required this.alignment,
  });
  final String image;
  final String first;
  final String second;
  final String description;
  final Alignment alignment;
}

const _heroSlides = <_HeroSlide>[
  _HeroSlide(
    image: 'assets/images/revo_hero_engine.jpg',
    first: 'Cứu hộ nhanh',
    second: 'có mặt kịp thời',
    description: 'Đồng hành mọi hành trình tại TP.HCM và các khu vực lân cận',
    alignment: Alignment(.7, .05),
  ),
  _HeroSlide(
    image: 'assets/images/revo_hero_tools.jpg',
    first: 'Chủ động công việc',
    second: 'cùng REVO mỗi ngày',
    description: 'Xem đơn đang làm và lịch sử công việc.',
    alignment: Alignment(.35, -.1),
  ),
  _HeroSlide(
    image: 'assets/images/revo_hero_teamwork.jpg',
    first: 'Sẵn sàng cứu hộ',
    second: 'đúng dịch vụ của bạn',
    description: 'Cập nhật dịch vụ để nhận đơn phù hợp.',
    alignment: Alignment(0, -.6),
  ),
];

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  static const _count = 3;
  static const _origin = _count * 1000;
  final _pages = PageController(initialPage: _origin);
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _step(int delta) {
    if (!_pages.hasClients) return;
    final raw = (_pages.page ?? _origin.toDouble()).round() + delta;
    _pages.animateToPage(
      raw,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final height = math.max(178.0, box.maxWidth / 2.22);
        return Column(
          children: [
            SizedBox(
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: PageView.builder(
                        controller: _pages,
                        onPageChanged: (v) =>
                            setState(() => _page = v % _count),
                        itemBuilder: (_, i) =>
                            _Slide(slide: _heroSlides[i % _count]),
                      ),
                    ),
                  ),
                  _arrow(left: true),
                  _arrow(left: false),
                ],
              ),
            ),
            SizedBox(
              height: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _count; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _page == i
                              ? RevoBrandColors.primary
                              : const Color(0xFFD2DDE9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _arrow({required bool left}) => Positioned(
    left: left ? 2 : null,
    right: left ? null : 2,
    top: 0,
    bottom: 0,
    child: Center(
      child: IconButton(
        tooltip: left ? 'Banner trước' : 'Banner tiếp theo',
        onPressed: () => _step(left ? -1 : 1),
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x8C172638),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Icon(
            left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide});
  final _HeroSlide slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          slide.image,
          fit: BoxFit.cover,
          alignment: slide.alignment,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => const ColoredBox(color: _ink),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF172638),
                Color(0xE6172638),
                Color(0x32172638),
                Color(0x07172638),
              ],
              stops: [0, .28, .69, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slide.first,
                style: _t(
                  20,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              Text(
                slide.second,
                style: _t(
                  20,
                  weight: FontWeight.w700,
                  color: _heroAccent,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 220,
                child: Text(
                  slide.description,
                  style: _t(10.2, color: Colors.white, height: 1.3),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: RevoBrandColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(
                      'Nhận đơn',
                      style: _t(
                        11,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: .8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month_outlined, size: 16),
                    label: Text(
                      'Xem lịch',
                      style: _t(
                        11,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceCat {
  const _ServiceCat(this.id, this.label, this.description, this.image);
  final String id;
  final String label;
  final String description;
  final String? image;
}

const _serviceCats = <_ServiceCat>[
  _ServiceCat(
    'battery',
    'Kích bình',
    'Xe không đề được?',
    'assets/images/home_battery_car.png',
  ),
  _ServiceCat(
    'tire',
    'Thay lốp',
    'Lốp xẹp, thủng?',
    'assets/images/home_tire_suv.png',
  ),
  _ServiceCat(
    'repair',
    'Sửa xe',
    'Sự cố trên đường?',
    'assets/images/home_service_repair.png',
  ),
  _ServiceCat('all', 'Tất cả dịch vụ', 'Khám phá 7 dịch vụ', null),
];

class _PopularServices extends StatelessWidget {
  const _PopularServices({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dịch vụ phổ biến', style: _t(18, weight: FontWeight.w800)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.42,
          children: [
            for (final cat in _serviceCats)
              _ServiceTile(
                cat: cat,
                active: selected == cat.id,
                onTap: () => onSelected(cat.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.cat,
    required this.active,
    required this.onTap,
  });

  final _ServiceCat cat;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: active ? RevoBrandColors.primary : _cardBorder,
          width: active ? 1.3 : .7,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: cat.image != null
                  ? Image.asset(
                      cat.image!,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: RevoBrandColors.surfaceSoft),
                    )
                  : const ColoredBox(
                      color: RevoBrandColors.surfaceSoft,
                      child: Icon(
                        Icons.grid_view_rounded,
                        color: RevoBrandColors.primary,
                        size: 28,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cat.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(11, weight: FontWeight.w600),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: _ink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cat.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(8.5, color: _secondary, height: 1.25),
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

class _NearbyJob {
  const _NearbyJob({
    required this.service,
    required this.catId,
    required this.vehicle,
    required this.distanceKm,
    required this.price,
    required this.address,
    required this.minutesAgo,
    required this.image,
  });
  final String service;
  final String catId;
  final String vehicle;
  final double distanceKm;
  final int price;
  final String address;
  final int minutesAgo;
  final String image;
}

const _demoJobs = <_NearbyJob>[
  _NearbyJob(
    service: 'Kích bình',
    catId: 'battery',
    vehicle: 'Toyota Vios',
    distanceKm: 1.2,
    price: 150000,
    address: 'Nguyễn Thị Minh Khai, Q.1',
    minutesAgo: 12,
    image: 'assets/images/home_battery_car.png',
  ),
  _NearbyJob(
    service: 'Kéo xe',
    catId: 'tow',
    vehicle: 'Toyota Fortuner',
    distanceKm: 3.6,
    price: 350000,
    address: '321 Lê Hồng Phong, Q.10',
    minutesAgo: 20,
    image: 'assets/images/home_service_tow.png',
  ),
  _NearbyJob(
    service: 'Thay lốp',
    catId: 'tire',
    vehicle: 'Toyota Fortuner',
    distanceKm: 2.8,
    price: 200000,
    address: 'Võ Văn Kiệt, Q.1',
    minutesAgo: 18,
    image: 'assets/images/home_tire_suv.png',
  ),
];

class _NearbyJobs extends ConsumerWidget {
  const _NearbyJobs({required this.service});

  final String service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final work = ref.watch(providerWorkControllerProvider);
    final offers = work.asData?.value.pendingOffers ?? const <PendingOffer>[];
    final busy = work.asData?.value.isBusy ?? false;
    // Real dispatched offers take priority; demo jobs fill the feed only when
    // there are none (offline demo / show) so the job-board never looks empty.
    final demoJobs = service == 'all'
        ? _demoJobs
        : _demoJobs.where((j) => j.catId == service).toList();
    final count = offers.isNotEmpty ? offers.length : demoJobs.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Đơn gần bạn',
                style: _t(18, weight: FontWeight.w800),
              ),
            ),
            Text(
              '$count đơn',
              style: _t(13, weight: FontWeight.w600, color: _secondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (offers.isNotEmpty)
          for (final offer in offers) ...[
            _OfferJobCard(offer: offer, busy: busy),
            const SizedBox(height: 12),
          ]
        else if (demoJobs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.inbox_rounded, size: 40, color: _secondary),
                const SizedBox(height: 10),
                Text(
                  'Chưa có đơn phù hợp quanh đây.',
                  style: _t(13, color: _secondary),
                ),
              ],
            ),
          )
        else
          for (final job in demoJobs) ...[
            _NearbyJobCard(job: job),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _NearbyJobCard extends StatelessWidget {
  const _NearbyJobCard({required this.job});

  final _NearbyJob job;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _cardBorder, width: .7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 128,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    job.image,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: RevoBrandColors.surfaceSoft),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _badge('Chờ nhận', RevoBrandColors.primary),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _badge(
                      '${job.distanceKm.toStringAsFixed(1)} km',
                      Colors.black.withValues(alpha: .7),
                      icon: Icons.location_on_rounded,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${job.service} • ${job.vehicle}',
                    style: _t(13, weight: FontWeight.w700, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _vnd(job.price),
                    style: _t(
                      17,
                      weight: FontWeight.w800,
                      color: RevoBrandColors.primary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: _secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job.address,
                          style: _t(11, color: _secondary, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${job.minutesAgo} phút trước',
                        style: _t(
                          10,
                          weight: FontWeight.w500,
                          color: _secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Nhận đơn ngay',
                        style: _t(
                          14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  Widget _badge(String label, Color color, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: _t(10, weight: FontWeight.w600, color: Colors.white),
        ),
      ],
    ),
  );
}

/// A real dispatched offer rendered as a job-board card.
class _OfferJobCard extends ConsumerWidget {
  const _OfferJobCard({required this.offer, required this.busy});

  final PendingOffer offer;
  final bool busy;

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    await ref.read(providerWorkControllerProvider.notifier).acceptOffer(offer);
    final state = ref.read(providerWorkControllerProvider).value;
    if (!context.mounted || state?.selectedOrder?.id != offer.orderId) return;
    await ref
        .read(providerLocationTrackingControllerProvider.notifier)
        .trackOrder(offer.orderId);
    if (context.mounted) context.push('/provider/orders/${offer.orderId}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disabled = busy || offer.isExpired;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: .7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.order.incidentType.name,
                  style: _t(15, weight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: RevoBrandColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  offer.order.code,
                  style: _t(
                    12,
                    weight: FontWeight.w700,
                    color: RevoBrandColors.primaryDeep,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: _cardBorder),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thu nhập dự kiến', style: _t(11, color: _secondary)),
                    Text(
                      formatProviderMoney(offer.order.estimatedPrice),
                      style: _t(
                        17,
                        weight: FontWeight.w800,
                        color: RevoBrandColors.primaryDeep,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: disabled ? null : () => _accept(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Nhận đơn',
                  style: _t(14, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Commitments extends StatelessWidget {
  const _Commitments();

  static const _items = [
    (Icons.shield_outlined, 'Uy tín', 'Thông tin rõ ràng'),
    (Icons.location_on_rounded, 'Theo dõi', 'Tiến trình đơn'),
    (Icons.receipt_long_rounded, 'Minh bạch', 'Thu nhập rõ ràng'),
    (Icons.headset_mic_outlined, 'Hỗ trợ nhanh', 'Hướng dẫn trong app'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _cardBorder),
          bottom: BorderSide(color: _cardBorder),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1, color: _cardBorder),
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      _items[i].$1,
                      color: RevoBrandColors.primary,
                      size: 23,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _items[i].$2,
                      textAlign: TextAlign.center,
                      style: _t(9, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _items[i].$3,
                      textAlign: TextAlign.center,
                      style: _t(7.5, color: _secondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
