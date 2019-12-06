import 'package:flutter/material.dart';

import 'package:photo_manager/photo_manager.dart';

import 'package:base_module/photo_picker/entity/options.dart';
import 'package:base_module/photo_picker/provider/config_provider.dart';
import 'package:base_module/photo_picker/provider/i18n_provider.dart';
import 'package:base_module/photo_picker/ui/page/photo_main_page.dart';

class PhotoApp extends StatelessWidget {
  final Options options;
  final I18nProvider provider;
  final List<AssetPathEntity> photoList;
  const PhotoApp({
    Key key,
    this.options,
    this.provider,
    this.photoList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PhotoPickerProvider(
      provider: provider,
      options: options,
      child: PhotoMainPage(
        onClose: (List<AssetEntity> value) {
          Navigator.pop(context, value);
        },
        options: options,
        photoList: photoList,
      ),
    );
  }
}
