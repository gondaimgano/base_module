import 'package:flutter/material.dart';
import 'package:base_module/photo_picker/entity/options.dart';
import 'package:base_module/photo_picker/provider/asset_provider.dart';
import 'package:base_module/photo_picker/provider/i18n_provider.dart';

class PhotoPickerProvider extends InheritedWidget {
  final Options options;
  final I18nProvider provider;
  final AssetProvider assetProvider = AssetProvider();

  PhotoPickerProvider({
    @required this.options,
    @required this.provider,
    @required Widget child,
    Key key,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }

  static PhotoPickerProvider of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(PhotoPickerProvider);

  static AssetProvider assetProviderOf(BuildContext context) =>
      of(context).assetProvider;
}
