import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Run from the repository root: dart run tool/generate_splash.dart
Future<void> main() async {
  final jpgSource = File('assets/images/logo-motocare.jpg');
  final sourceFile = jpgSource.existsSync()
      ? jpgSource
      : File('assets/images/Logo_motocare.png');
  if (!sourceFile.existsSync()) {
    throw StateError(
      'Add assets/images/logo-motocare.jpg or assets/images/Logo_motocare.png '
      'before generating the splash.',
    );
  }
  final source = img.decodeImage(sourceFile.readAsBytesSync());
  if (source == null) {
    throw StateError('Cannot decode ${sourceFile.path}');
  }
  stdout.writeln('Splash source: ${sourceFile.path}');

  final cropped = _trimWhiteBorder(source);
  final splash = img.copyResize(
    cropped,
    width: 768,
    interpolation: img.Interpolation.average,
  );
  File('assets/images/logo-motocare-splash.png')
      .writeAsBytesSync(img.encodePng(splash));

  // Android 12 masks a 1152px image to a circle with a 768px diameter.
  // Fit the entire crop inside that circle, with 16px of space on each side.
  final diagonal = math.sqrt(
    cropped.width * cropped.width + cropped.height * cropped.height,
  );
  final androidLogo = img.copyResize(
    cropped,
    width: (cropped.width * 736 / diagonal).floor(),
    interpolation: img.Interpolation.average,
  );
  final androidSplash = img.Image(width: 1152, height: 1152);
  img.fill(androidSplash, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(
    androidSplash,
    androidLogo,
    dstX: (androidSplash.width - androidLogo.width) ~/ 2,
    dstY: (androidSplash.height - androidLogo.height) ~/ 2,
  );
  File('assets/images/logo-motocare-splash-android12.png')
      .writeAsBytesSync(img.encodePng(androidSplash));
  stdout.writeln(
    'Cropped ${source.width}x${source.height} to '
    '${cropped.width}x${cropped.height}; generated splash PNGs.',
  );

  final generator = await Process.start(Platform.resolvedExecutable, [
    'run',
    'flutter_native_splash:create',
  ], mode: ProcessStartMode.inheritStdio);
  exitCode = await generator.exitCode;
}

img.Image _trimWhiteBorder(img.Image source) {
  var left = source.width;
  var top = source.height;
  var right = -1;
  var bottom = -1;

  // Ignore near-white JPEG compression noise when locating the logo.
  for (final pixel in source) {
    if (pixel.r >= 240 && pixel.g >= 240 && pixel.b >= 240) continue;
    left = math.min(left, pixel.x);
    top = math.min(top, pixel.y);
    right = math.max(right, pixel.x);
    bottom = math.max(bottom, pixel.y);
  }
  if (right < left || bottom < top) {
    throw StateError('The source image contains no visible logo.');
  }

  final padding = (math.max(right - left + 1, bottom - top + 1) * 0.02).ceil();
  left = math.max(0, left - padding);
  top = math.max(0, top - padding);
  right = math.min(source.width - 1, right + padding);
  bottom = math.min(source.height - 1, bottom + padding);
  return img.copyCrop(
    source,
    x: left,
    y: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );
}
