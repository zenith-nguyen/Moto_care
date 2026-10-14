import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

final profileDeviceServiceProvider = Provider<ProfileDeviceService>(
  (ref) => NativeProfileDeviceService(),
);

abstract class ProfileDeviceService {
  Future<Uint8List?> pickAvatar();
  Future<Uint8List?> recoverAvatar();
  Future<bool> authenticate();
}

class ProfileDeviceException implements Exception {
  const ProfileDeviceException(this.message);
  final String message;
}

class NativeProfileDeviceService implements ProfileDeviceService {
  final _picker = ImagePicker();
  final _auth = LocalAuthentication();

  Future<Uint8List> _readImage(XFile file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const ProfileDeviceException('Vui lòng chọn ảnh nhỏ hơn 5 MB.');
    }
    return file.readAsBytes();
  }

  @override
  Future<Uint8List?> pickAvatar() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      return file == null ? null : await _readImage(file);
    } on PlatformException {
      throw const ProfileDeviceException(
        'Không thể mở thư viện ảnh. Hãy kiểm tra quyền truy cập ảnh.',
      );
    }
  }

  @override
  Future<Uint8List?> recoverAvatar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final lost = await _picker.retrieveLostData();
    if (lost.exception != null) {
      throw const ProfileDeviceException(
        'Không thể khôi phục ảnh đã chọn. Vui lòng chọn lại.',
      );
    }
    final files = lost.files;
    return files == null || files.isEmpty
        ? null
        : await _readImage(files.first);
  }

  @override
  Future<bool> authenticate() async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform)) {
      throw const ProfileDeviceException(
        'Thiết bị này chưa hỗ trợ FaceID / vân tay.',
      );
    }
    try {
      if (!await _auth.canCheckBiometrics ||
          (await _auth.getAvailableBiometrics()).isEmpty) {
        throw const ProfileDeviceException(
          'Hãy thiết lập FaceID hoặc vân tay trong cài đặt thiết bị trước.',
        );
      }
      return await _auth.authenticate(
        localizedReason: 'Xác thực để bảo vệ thông tin cá nhân MotoCare',
        biometricOnly: true,
      );
    } on LocalAuthException {
      throw const ProfileDeviceException(
        'Không thể xác thực sinh trắc học lúc này. Vui lòng thử lại.',
      );
    } on PlatformException {
      throw const ProfileDeviceException(
        'Thiết bị này chưa hỗ trợ FaceID / vân tay.',
      );
    }
  }
}
