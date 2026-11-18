import 'package:flutter/widgets.dart';

import '../i18n/copy.dart';
import 'filters.dart';
import 'vision.dart';

String modeName(BuildContext context, VisionMode mode) => switch (mode) {
  VisionMode.normal => context.t('Typical vision', 'Thị giác thông thường'),
  VisionMode.protan => context.t('Red color blindness', 'Mù màu đỏ'),
  VisionMode.deutan => context.t('Green color blindness', 'Mù màu xanh lá'),
  VisionMode.tritan => context.t(
    'Blue–yellow color blindness',
    'Mù màu xanh dương – vàng',
  ),
  VisionMode.blueCone => context.t(
    'Blue cone only',
    'Chỉ còn tế bào hình nón xanh dương',
  ),
  VisionMode.grayscale => context.t(
    'Total color blindness',
    'Mù màu toàn phần',
  ),
};

LocalText modeNote(VisionMode mode) => switch (mode) {
  VisionMode.normal => words(
    'Displays the original colors.',
    'Hiển thị màu gốc.',
  ),
  VisionMode.protan => words(
    'Some red and green shades are harder to distinguish. Reds may appear darker.',
    'Một số sắc đỏ và xanh lá khó phân biệt hơn. Màu đỏ có thể trông tối hơn.',
  ),
  VisionMode.deutan => words(
    'Some red, green and nearby shades are harder to tell apart.',
    'Một số sắc đỏ, xanh lá và các màu gần nhau trở nên khó phân biệt hơn.',
  ),
  VisionMode.tritan => words(
    'Some blue, green and yellow shades are harder to distinguish.',
    'Một số sắc xanh dương, xanh lá và vàng khó phân biệt hơn.',
  ),
  VisionMode.blueCone => words(
    'Only the blue cone works, so the image is near-monochrome with a faint blue–yellow trace.',
    'Chỉ tế bào hình nón xanh dương còn hoạt động, ảnh gần như đơn sắc với chút dấu vết xanh dương – vàng.',
  ),
  VisionMode.grayscale => words(
    'Approximates the absence of color using luminance. Light sensitivity and visual acuity are outside this model.',
    'Dùng độ chói để minh họa việc không cảm nhận màu. Mô hình không mô phỏng độ nhạy sáng và thị lực.',
  ),
};

/// Name for one picker entry. Entries of the same [VisionMode] differ only in
/// preset strength or direction, so the clinical term is the name itself.
String filterName(BuildContext context, VisionFilter filter) =>
    switch (filter.id) {
      'deuteranopia' => context.t(
        'Deuteranopia',
        'Deuteranopia – mù màu xanh lá',
      ),
      'deuteranomaly' => context.t(
        'Deuteranomaly',
        'Deuteranomaly – giảm sắc xanh lá',
      ),
      'protanopia' => context.t('Protanopia', 'Protanopia – mù màu đỏ'),
      'protanomaly' => context.t('Protanomaly', 'Protanomaly – giảm sắc đỏ'),
      'tritanopia' => context.t(
        'Tritanopia',
        'Tritanopia – mù màu xanh dương',
      ),
      'tritanomaly' => context.t(
        'Tritanomaly',
        'Tritanomaly – giảm sắc xanh dương',
      ),
      'achromatopsia' => context.t(
        'Achromatopsia',
        'Achromatopsia – mù màu toàn phần',
      ),
      'achromatomaly' => context.t(
        'Achromatomaly',
        'Achromatomaly – mù màu một phần',
      ),
      'blueConeMonochromacy' => context.t(
        'Blue cone monochromacy',
        'Đơn sắc tế bào hình nón xanh dương',
      ),
      'correctDeutan' => context.t(
        'Boost red – green (green-weak)',
        'Tăng phân biệt đỏ – xanh lá (yếu xanh lá)',
      ),
      'correctProtan' => context.t(
        'Boost red – green (red-weak)',
        'Tăng phân biệt đỏ – xanh lá (yếu đỏ)',
      ),
      'correctTritan' => context.t(
        'Boost blue – yellow',
        'Tăng phân biệt xanh dương – vàng',
      ),
      'notchRedGreen' => context.t(
        'Narrow-notch red-green filter',
        'Kính lọc notch hẹp đỏ – xanh lá',
      ),
      'broadTintRedGreen' => context.t(
        'Broad-tint red-green filter',
        'Kính nhuộm màu rộng đỏ – xanh lá',
      ),
      'monocularRedTint' => context.t(
        'Single-eye red tint',
        'Kính nhuộm đỏ một mắt',
      ),
      'tritanTint' => context.t(
        'Blue-yellow support tint',
        'Kính hỗ trợ xanh dương – vàng',
      ),
      'cataract' => context.t('Cataract', 'Đục thủy tinh thể'),
      'glaucoma' => context.t('Glaucoma', 'Glaucoma – tăng nhãn áp'),
      'macularDegeneration' => context.t(
        'Macular degeneration',
        'Thoái hóa điểm vàng',
      ),
      'nightBlindness' => context.t('Night blindness', 'Mù đêm – quáng gà'),
      'myopia' => context.t('Myopia (near-sighted)', 'Cận thị'),
      'hyperopia' => context.t('Hyperopia (far-sighted)', 'Viễn thị'),
      'astigmatism' => context.t('Astigmatism', 'Loạn thị'),
      _ => modeName(context, filter.mode),
    };

LocalText filterNote(VisionFilter filter) => switch (filter.id) {
  'deuteranomaly' => words(
    'The partial form, by far the most common. Reds and greens are muted rather than lost.',
    'Dạng một phần, phổ biến nhất. Màu đỏ và xanh lá bị nhạt đi chứ không mất hẳn.',
  ),
  'protanomaly' => words(
    'The partial form. Reds look duller and darker than they are.',
    'Dạng một phần. Màu đỏ trông nhạt và tối hơn thực tế.',
  ),
  'tritanomaly' => words(
    'The partial form. Blues and greens drift together.',
    'Dạng một phần. Xanh dương và xanh lá dần lẫn vào nhau.',
  ),
  'achromatomaly' => words(
    'Colors are washed out but not gone.',
    'Màu bị bạc đi nhưng chưa mất hẳn.',
  ),
  'correctDeutan' || 'correctProtan' || 'correctTritan' => words(
    'Shifts confusable colors apart instead of simulating the loss. Helpful on charts and maps, not a cure.',
    'Dịch các màu dễ lẫn ra xa nhau thay vì mô phỏng khiếm khuyết. Hữu ích với biểu đồ và bản đồ, không phải cách chữa.',
  ),
  'notchRedGreen' => words(
    'Approximates a narrow-band filter over the red/green overlap wavelengths, from published filter specs - not an exact manufacturer formula.',
    'Xấp xỉ một kính lọc dải hẹp ở vùng sóng đỏ/xanh lá chồng lấp, dựa trên thông số công khai - không phải công thức chính xác của nhà sản xuất.',
  ),
  'broadTintRedGreen' => words(
    'Approximates a wider, less selective tint than a narrow-notch filter, from published filter specs.',
    'Xấp xỉ một kính nhuộm màu rộng, ít chọn lọc hơn kính lọc notch hẹp, dựa trên thông số công khai.',
  ),
  'monocularRedTint' => words(
    'Real single-eye designs rely on the brain comparing two different images, one per eye - a single screen viewed with both eyes cannot reproduce that. This only shows the color change for the covered eye.',
    'Thiết kế kính một mắt thật dựa vào việc não so sánh hai ảnh khác nhau ở mỗi mắt - một màn hình xem bằng cả hai mắt không thể tái hiện điều đó. Đây chỉ minh họa phần thay đổi màu ở mắt bị che.',
  ),
  'tritanTint' => words(
    'The least documented of this set - far fewer public sources describe blue-yellow correction filters than red-green ones.',
    'Loại ít tài liệu nhất trong nhóm này - có rất ít nguồn công khai mô tả kính hỗ trợ xanh dương – vàng so với kính đỏ – xanh lá.',
  ),
  'cataract' => words(
    'A clouded lens scatters light: everything softens and takes on a yellow cast.',
    'Thủy tinh thể đục làm tán xạ ánh sáng: mọi thứ mờ đi và ngả vàng.',
  ),
  'glaucoma' => words(
    'Peripheral vision narrows first, often long before anyone notices.',
    'Thị trường ngoại vi hẹp lại trước, thường rất lâu trước khi người bệnh nhận ra.',
  ),
  'macularDegeneration' => words(
    'The center of the field fades, so faces and text are hit hardest.',
    'Vùng trung tâm mờ dần, nên khuôn mặt và chữ bị ảnh hưởng nặng nhất.',
  ),
  'nightBlindness' => words(
    'Dim light gives almost nothing to work with, even where others still see.',
    'Trong ánh sáng yếu gần như không thấy gì, dù người khác vẫn nhìn được.',
  ),
  'myopia' => words(
    'Distant objects blur while close ones stay sharp.',
    'Vật ở xa bị mờ, vật ở gần vẫn thấy rõ.',
  ),
  'hyperopia' => words(
    'Close objects blur while distant ones stay sharp.',
    'Vật ở gần bị mờ, vật ở xa vẫn thấy rõ.',
  ),
  'astigmatism' => words(
    'An uneven cornea blurs and stretches the image at every distance.',
    'Giác mạc không đều làm hình ảnh mờ và méo ở mọi khoảng cách.',
  ),
  _ => modeNote(filter.mode),
};

/// Heading above each top-level offering in the picker.
LocalText categoryTitle(FilterCategory category) => switch (category) {
  FilterCategory.experience => words(
    'EXPERIENCE A VISION DIFFERENCE',
    'TRẢI NGHIỆM SẮC GIÁC KHÁC BIỆT',
  ),
  FilterCategory.correction => words(
    'HELP SEE TRUE COLORS',
    'HỖ TRỢ NHÌN ĐÚNG MÀU',
  ),
};

LocalText? categoryNote(FilterCategory category) => switch (category) {
  FilterCategory.experience => words(
    'See the world the way color blindness or another common eye condition would show it.',
    'Xem thế giới qua mắt mù màu hoặc một bệnh lý mắt thường gặp khác.',
  ),
  FilterCategory.correction => null,
};

/// Heading above each run of entries in the picker.
LocalText groupTitle(FilterGroup group) => switch (group) {
  FilterGroup.redGreen => words(
    'RED – GREEN DEFICIENCY',
    'RỐI LOẠN ĐỎ – XANH LÁ',
  ),
  FilterGroup.blueYellow => words(
    'BLUE – YELLOW DEFICIENCY',
    'RỐI LOẠN XANH DƯƠNG – VÀNG',
  ),
  FilterGroup.noColor => words('NO COLOR VISION', 'KHÔNG THẤY MÀU'),
  FilterGroup.correction => words(
    'HELP TELL COLORS APART',
    'HỖ TRỢ PHÂN BIỆT MÀU',
  ),
  FilterGroup.realGlasses => words(
    'REAL GLASSES SIMULATION',
    'MÔ PHỎNG KÍNH MÙ MÀU THẬT',
  ),
  FilterGroup.condition => words('OTHER EYE CONDITIONS', 'BỆNH LÝ MẮT KHÁC'),
};

LocalText? groupNote(FilterGroup group) => switch (group) {
  FilterGroup.redGreen => words(
    'The most common form, about 8% of men',
    'Phổ biến nhất, khoảng 8% nam giới',
  ),
  FilterGroup.blueYellow => words('Rare', 'Rất hiếm gặp'),
  FilterGroup.noColor => null,
  FilterGroup.correction => words(
    'These help you see differences, not lose them',
    'Các chế độ này giúp thấy rõ khác biệt, không phải mô phỏng khiếm khuyết',
  ),
  FilterGroup.realGlasses => words(
    'Approximates published optical specs for real products, not the exact manufacturer formula',
    'Xấp xỉ theo thông số quang học công khai của sản phẩm thật, không phải công thức chính xác của nhà sản xuất',
  ),
  FilterGroup.condition => words(
    'Rough illustrations of field and clarity loss, not an optical model',
    'Minh họa thô về mất thị trường và độ nét, không phải mô hình quang học',
  ),
};

final simulationNotice = words(
  'This educational simulation is an approximation. It cannot diagnose color vision or reproduce anyone’s individual experience.',
  'Đây là mô phỏng gần đúng dùng cho giáo dục. Ứng dụng không chẩn đoán sắc giác hay tái hiện trải nghiệm của từng người.',
);

final screeningNotice = words(
  'This is an indicative screening, not a medical diagnosis. Screen colors and room lighting affect the result. See an eye care professional for a proper test.',
  'Đây là sàng lọc tham khảo, không phải chẩn đoán y tế. Màu màn hình và ánh sáng phòng đều ảnh hưởng kết quả. Hãy gặp bác sĩ mắt để kiểm tra chính thức.',
);
