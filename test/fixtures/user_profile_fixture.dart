import 'package:moto_care/features/profile/models/user_profile.dart';

const profileFixture = UserProfile(
  id: 'member-001',
  fullName: 'Nguyễn Văn An',
  phoneNumber: '0900000001',
  email: 'an@example.com',
  memberTier: 'Thành viên Vàng',
  rewardPoints: 350,
  emergencyContactName: 'Người thân',
  emergencyContactPhone: '0900000002',
  medicalNote: 'Dị ứng penicillin',
  defaultVehicle: ProfileVehicle(
    type: 'Xe tay ga • Honda Vision',
    plate: '59-X1 123.45',
    tireType: 'Lốp không săm',
  ),
  defaultAddress: 'Quận 3, TP. Hồ Chí Minh',
  workAddress: 'Quận 1, TP. Hồ Chí Minh',
);
