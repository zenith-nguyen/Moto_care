import '../models/price_group.dart';

const List<PriceGroup> demoPriceGroups = [
  (
    'Cứu hộ cơ bản',
    PriceCategory.rescue,
    [('Vá xe', '30k - 50k'), ('Cứu hộ hết xăng', '40k'), ('Kích bình', '50k')],
  ),
  (
    'Săm & Lốp xe',
    PriceCategory.tire,
    [('Ruột xe số', '90k'), ('Lốp tay ga không ruột', '350k - 450k')],
  ),
  (
    'Bình Ắc quy & Điện',
    PriceCategory.battery,
    [('Thay bình ắc quy GS', '380k')],
  ),
];
