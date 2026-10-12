import '../models/station_model.dart';
import '../models/service_catalog_model.dart';

// Sample profile metadata until a station profile API is connected.
final stationProfiles = Map<String, StationProfile>.unmodifiable({
  'station-mobile': StationProfile(
    description:
        'Đội ngũ chuyên sửa chữa xe tay ga, xe số và cứu hộ lưu động. '
        'Hỗ trợ xe chết máy, thủng lốp, hết bình và kéo xe sự cố, '
        'với chi phí rõ ràng trước khi thực hiện.',
    mechanicCount: 12,
    warrantyLabel: 'Bảo hành',
    serviceDetails: {
      'tire-tubeless': ServiceCatalogDetails(
        description: 'Vá dùi/nấm chuyên dụng • Khoảng 10 phút',
        procedureSteps: [
          'Kiểm tra áp suất và xác định vị trí thủng trên lốp không ruột.',
          'Vệ sinh điểm thủng và xác nhận phương án vá phù hợp với tình trạng lốp.',
          'Thực hiện vá, bơm đúng áp suất và kiểm tra độ kín trước khi bàn giao.',
        ],
        materialsCommitment: 'Sử dụng miếng vá, keo vá và dụng cụ chuyên dụng. Thợ xác nhận vật tư với bạn trước khi thực hiện.',
        warranty: 'Bảo hành miếng vá 30 ngày tại vị trí đã vá.',
      ),
      'battery-jump': ServiceCatalogDetails(
        description: 'Bộ kích bình chuyên dụng • Khoảng 10–15 phút',
        procedureSteps: [
          'Kiểm tra điện áp ắc quy, đầu cọc và tình trạng khởi động của xe.',
          'Kết nối bộ kích bình chuyên dụng và hỗ trợ khởi động đúng kỹ thuật.',
          'Kiểm tra khả năng khởi động và tư vấn tình trạng ắc quy sau khi kích.',
        ],
        materialsCommitment: 'Thiết bị kích bình có bảo vệ. Không thay mới ắc quy khi chưa có xác nhận của bạn.',
        warranty: 'Dịch vụ kích bình không bao gồm bảo hành ắc quy mới. Điều kiện hỗ trợ kiểm tra lại được trạm xác nhận trước khi thực hiện.',
      ),
      'towing': ServiceCatalogDetails(
        description: 'Xe chuyên dụng & dây chằng • Theo quãng đường',
        procedureSteps: [
          'Tiếp nhận vị trí, ghi nhận hiện trạng xe và thống nhất tiệm tiếp nhận.',
          'Cố định xe bằng dụng cụ chằng buộc phù hợp trước khi di chuyển.',
          'Vận chuyển đến tiệm đã thống nhất và bàn giao hiện trạng xe.',
        ],
        materialsCommitment: 'Dùng dụng cụ chằng buộc chuyên dụng và ghi nhận hiện trạng xe trước khi vận chuyển.',
        warranty: 'Cam kết bàn giao đúng hiện trạng đã ghi nhận. Dịch vụ vận chuyển không bao gồm bảo hành sửa chữa tại tiệm.',
      ),
    },
  ),
  'station-tuan': StationProfile(
    description:
        'Hỗ trợ cứu hộ lưu động, xử lý sự cố lốp, ắc quy và kéo xe '
        'về tiệm. Phục vụ xe tay ga và xe số suốt ngày đêm.',
  ),
  'station-dealer': StationProfile(
    description:
        'Kiểm tra, sửa chữa và bảo dưỡng xe tay ga, xe số và xe phân '
        'khối lớn. Cung cấp dịch vụ cứu hộ và thay thế phụ tùng.',
  ),
  'station-thanh': StationProfile(
    description:
        'Tiệm sửa chữa xe máy, hỗ trợ vá lốp, kiểm tra ắc quy '
        'và xử lý các sự cố thường gặp của xe tay ga, xe số.',
  ),
});

final defaultStationProfile = StationProfile(
  description:
      'Liên hệ trạm để được tư vấn dịch vụ cứu hộ phù hợp với xe của bạn.',
);
