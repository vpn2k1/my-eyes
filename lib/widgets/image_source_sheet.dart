import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../i18n/copy.dart';
import 'app_icon.dart';

/// Lets the user pick between camera and gallery before `_openPhoto` loads
/// the result, matching the sheet pattern used by [showSettingsSheet].
Future<XFile?> showImageSourceSheet(BuildContext context) =>
    showModalBottomSheet<XFile?>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const AppIcon(AppIcons.camera),
              title: Text(context.t('Take photo', 'Chụp ảnh')),
              onTap: () async {
                final file = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  requestFullMetadata: false,
                );
                if (context.mounted) Navigator.of(context).pop(file);
              },
            ),
            ListTile(
              leading: const AppIcon(AppIcons.photo),
              title: Text(context.t('Choose from gallery', 'Chọn từ thư viện')),
              onTap: () async {
                final file = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  requestFullMetadata: false,
                );
                if (context.mounted) Navigator.of(context).pop(file);
              },
            ),
          ],
        ),
      ),
    );
