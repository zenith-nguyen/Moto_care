import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/ui.dart';

void main() {
  setUp(() => appState.profile = MockData.profile());

  test('Only the name and the avatar source changed in the demo profile', () {
    final p = MockData.profile();
    expect(p.name, 'Võ Thành Đạt');
    expect(p.avatarAsset, 'assets/images/mechanic_vo_thanh_dat.png');
    // Everything else is untouched.
    expect(p.tierName, 'Bạc');
    expect(p.tierOrders, 18);
    expect(p.rating, 4.9);
    expect(p.ratingCount, 132);
    expect(p.area, 'Quận 1, TP.HCM');
    expect(p.specialty, 'Sửa chữa xe máy tại chỗ');
    expect(p.verificationStatus.name, 'verified');
    expect(p.skills.length, 3);
    expect(p.documents.length, 2);
  });

  Future<void> host(WidgetTester t) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: MechanicAccountScreen())));
    await t.pumpAndSettle();
  }

  testWidgets('Account shows the new name in Montserrat Bold navy', (t) async {
    await host(t);
    expect(find.text('Võ Thành Đạt'), findsOneWidget);
    expect(find.text('Nguyễn Văn Hùng'), findsNothing);
    final name = t.widget<Text>(find.text('Võ Thành Đạt'));
    expect(name.style!.fontFamily, 'Montserrat');
    expect(find.text('Thợ cứu hộ REVO'), findsOneWidget);
    expect(find.text('4.9 (132)'), findsOneWidget);
    expect(find.text('Quận 1, TP.HCM'), findsOneWidget);
    expect(find.text('Sửa hồ sơ'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('The account avatar is the provided photo and loads fine',
      (t) async {
    await host(t);
    final avatar = t.widget<AvatarCircle>(find.byType(AvatarCircle).first);
    expect(avatar.imageAsset, 'assets/images/mechanic_vo_thanh_dat.png');
    final img = t.widget<Image>(find.descendant(
        of: find.byType(AvatarCircle).first, matching: find.byType(Image)));
    expect((img.image as AssetImage).assetName,
        'assets/images/mechanic_vo_thanh_dat.png');
    expect(img.fit, BoxFit.cover);
    expect(find.byIcon(Icons.broken_image), findsNothing);
    expect(
        File('assets/images/mechanic_vo_thanh_dat.png').existsSync(), isTrue);
    expect(t.getSize(find.byType(AvatarCircle).first), const Size(76, 76));
    expect(t.takeException(), isNull);
  });

  testWidgets('A present asset is shown round, cover-fitted and unfiltered',
      (t) async {
    await t.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: AvatarCircle(
                initials: 'VĐ',
                size: 64,
                imageAsset: 'assets/images/revo_hero_tools.jpg'))));
    await t.pumpAndSettle();
    final img = t.widget<Image>(find.byType(Image));
    expect(img.fit, BoxFit.cover);
    expect(img.colorBlendMode, isNull);
    expect(img.color, isNull);
    expect(find.byType(ClipOval), findsOneWidget);
    expect(t.getSize(find.byType(AvatarCircle)), const Size(64, 64));
  });
}
