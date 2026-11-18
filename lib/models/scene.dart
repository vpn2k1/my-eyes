import '../i18n/copy.dart';

class Scene {
  const Scene(this.id, this.title, this.alt, this.barrier, this.tip);
  final String id;
  final LocalText title, alt, barrier, tip;
  String get asset => 'assets/scenes/$id.png';
}

final scenes = <Scene>[
  Scene(
    'traffic',
    words('Traffic signals', 'Đèn giao thông'),
    words('Three stacked lights above a street', 'Ba đèn xếp dọc bên đường'),
    words(
      'Red and green may look similar.',
      'Đèn đỏ và xanh có thể trông giống nhau.',
    ),
    words(
      'Use position and surrounding cues. Keep the simulation to educational settings.',
      'Dùng vị trí và dấu hiệu xung quanh. Chỉ dùng mô phỏng trong bối cảnh giáo dục.',
    ),
  ),
  Scene(
    'food',
    words('Food and ripeness', 'Thực phẩm và độ chín'),
    words('A plate of red and green tomatoes', 'Một đĩa cà chua đỏ và xanh'),
    words(
      'Ripeness can be difficult to judge by hue alone.',
      'Có thể khó nhận biết độ chín chỉ qua sắc màu.',
    ),
    words(
      'Pair color with labels or other suitable cues.',
      'Kết hợp màu với nhãn hoặc dấu hiệu phù hợp khác.',
    ),
  ),
  Scene(
    'clothing',
    words('Clothing', 'Trang phục'),
    words('Three shirts in different hues', 'Ba áo khác màu'),
    words(
      'Similar hues can be hard to match.',
      'Các màu gần nhau có thể khó phối.',
    ),
    words(
      'Show color names on tags and swatches.',
      'Ghi tên màu trên nhãn và bảng mẫu.',
    ),
  ),
  Scene(
    'nature',
    words('Flowers and foliage', 'Hoa và tán lá'),
    words('Pink flowers among green leaves', 'Hoa hồng xen giữa lá xanh'),
    words(
      'Flowers may blend into the foliage.',
      'Màu hoa có thể hòa lẫn với màu lá.',
    ),
    words(
      'Look for outlines and lightness differences.',
      'Quan sát đường viền và chênh lệch độ sáng.',
    ),
  ),
  Scene(
    'charts',
    words('Charts', 'Biểu đồ'),
    words(
      'Two lines marked with dots on a chart',
      'Biểu đồ có hai đường được đánh dấu bằng chấm',
    ),
    words(
      'Series with similar hues can be hard to track.',
      'Các chuỗi có sắc màu gần nhau có thể khó theo dõi.',
    ),
    words(
      'Label each line directly and vary marker shape or line style.',
      'Gắn nhãn trực tiếp, dùng ký hiệu hoặc nét khác nhau.',
    ),
  ),
  Scene(
    'classroom',
    words('Classroom materials', 'Đồ dùng học tập'),
    words(
      'Six classroom cards with red or green backgrounds',
      'Sáu thẻ học có nền đỏ hoặc xanh',
    ),
    words(
      'Color-only sorting can hide the groups.',
      'Cách phân nhóm chỉ bằng màu có thể khó nhận biết.',
    ),
    words(
      'Pair every group color with a symbol or a word.',
      'Thêm ký hiệu hoặc chữ cho từng nhóm màu.',
    ),
  ),
];
