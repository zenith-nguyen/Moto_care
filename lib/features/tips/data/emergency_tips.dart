import '../models/emergency_tip.dart';

const emergencyTips = [
  EmergencyTip(
    title: 'Cách xử lý khi xe bị ngập nước chết máy',
    minutes: 2,
    level: 'Dễ',
    kind: TipKind.flood,
    steps: [
      'Chỉ đưa xe ra chỗ khô khi bạn có thể làm việc đó an toàn. Tránh vùng ngập sâu hoặc có dòng nước chảy mạnh.',
      'Tắt khóa điện. Không cố đề lại máy: nước có thể đã vào động cơ.',
      'Đứng ở nơi an toàn và ghi nhận mức nước cùng tình trạng xe để báo cho thợ.',
      'Gọi cứu hộ đưa xe đi kiểm tra động cơ, dầu máy và hệ thống điện trước khi khởi động lại.',
    ],
    sourceLabel: 'Honda Việt Nam • Tư vấn sử dụng xe',
    sourceUrl: 'https://www.honda.com.vn/cau-hoi-thuong-gap?category=thong-tin-ve-cong-ty&category_child=tu-van-su-dung-xe-may&category_tab=su-dung-xe',
  ),
  EmergencyTip(
    title: 'Mẹo dắt xe an toàn khi bị đinh đâm xẹp lốp',
    minutes: 2,
    level: 'Dễ',
    kind: TipKind.flatTire,
    steps: [
      'Nếu đang chạy, giữ chắc tay lái, giảm ga từ từ và giữ hướng thẳng. Tránh phanh gấp.',
      'Khi xe đã chậm, đưa xe vào vị trí an toàn, dừng hẳn rồi tắt máy.',
      'Chỉ dắt xe một đoạn ngắn ở chỗ bằng phẳng, tách khỏi luồng xe. Không tiếp tục chạy với lốp xẹp.',
      'Nếu xe quá nặng hoặc đoạn đường không an toàn, chờ cứu hộ. Báo vị trí và bánh bị xẹp cho thợ.',
    ],
    sourceLabel: 'California DMV • Motorcycle Handbook',
    sourceUrl:
        'https://www.dmv.ca.gov/portal/file/motorcycle-driver-handbook-pdf/',
  ),
  EmergencyTip(
    title: 'Cách xử lý khi xe tay ga bị hết bình ắc quy',
    minutes: 3,
    level: 'Trung bình',
    kind: TipKind.battery,
    steps: [
      'Dừng xe ở chỗ an toàn. Tắt khóa điện và các phụ tải không cần thiết.',
      'Kiểm tra trạng thái công tắc, chân chống và đèn trên bảng đồng hồ theo sách hướng dẫn của xe.',
      'Không đề liên tục hoặc tự nối dây vào bình khác khi chưa có hướng dẫn phù hợp cho mẫu xe.',
      'Liên hệ thợ kiểm tra bình và hệ thống sạc. Với xe tay ga, không cố đẩy xe để nổ máy.',
    ],
    sourceLabel: 'Honda • Sách hướng dẫn SH Mode',
    sourceUrl: 'https://2rom-prd-data.hondamotopub.com/om/HVN/SH%20Mode/2019/SH%20Mode_4FK29A30_0.pdf',
  ),
  EmergencyTip(
    title: 'Kỹ năng dồn số phanh động cơ khi mất phanh',
    minutes: 4,
    level: 'Trung bình',
    kind: TipKind.brakes,
    steps: [
      'Giữ bình tĩnh, nhả ga từ từ, giữ xe ổn định và quan sát khoảng trống phía trước.',
      'Nếu còn một phanh hoạt động, sử dụng nhẹ nhàng để giảm tốc. Tránh thao tác đột ngột.',
      'Chỉ với xe số và người đã được huấn luyện: về số thấp từng cấp phù hợp tốc độ theo hướng dẫn của xe. Không về số quá thấp đột ngột; xe tay ga không áp dụng thao tác này.',
      'Hướng về nơi trống và dừng an toàn. Không tiếp tục chạy xe; gọi cứu hộ kiểm tra hệ thống phanh.',
    ],
    sourceLabel: 'California DMV • Kỹ thuật điều khiển xe máy',
    sourceUrl:
        'https://www.dmv.ca.gov/portal/file/motorcycle-driver-handbook-pdf/',
  ),
];
