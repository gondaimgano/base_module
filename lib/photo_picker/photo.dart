library photo;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:photo_manager/photo_manager.dart';

import 'package:base_module/photo_picker/delegate/badge_delegate.dart';
import 'package:base_module/photo_picker/delegate/checkbox_builder_delegate.dart';
import 'package:base_module/photo_picker/delegate/loading_delegate.dart';
import 'package:base_module/photo_picker/delegate/sort_delegate.dart';
import 'package:base_module/photo_picker/entity/options.dart';
import 'package:base_module/photo_picker/provider/i18n_provider.dart';
import 'package:base_module/photo_picker/ui/dialog/not_permission_dialog.dart';
import 'package:base_module/photo_picker/ui/photo_app.dart';
export 'package:base_module/photo_picker/delegate/checkbox_builder_delegate.dart';
export 'package:base_module/photo_picker/delegate/loading_delegate.dart';
export 'package:base_module/photo_picker/delegate/sort_delegate.dart';
export 'package:base_module/photo_picker/provider/i18n_provider.dart'
    show I18NCustomProvider, I18nProvider, CNProvider, ENProvider;
export 'package:base_module/photo_picker/entity/options.dart' show PickType;
export 'package:base_module/photo_picker/delegate/badge_delegate.dart';

class PhotoPicker {
  static PhotoPicker _instance;

  PhotoPicker._();

  factory PhotoPicker() {
    _instance ??= PhotoPicker._();
    return _instance;
  }

  static const String rootRouteName = "photo_picker_image";

  /// 没有授予权限的时候,会开启一个dialog去帮助用户去应用设置页面开启权限
  /// 确定开启设置页面,取消关闭弹窗,无论选择什么,返回值都是null
  ///
  ///
  /// 当用户给予权限后
  ///
  ///   当用户确定时,返回一个图片[AssetEntity]列表
  ///
  ///   当用户取消时返回一个空数组
  ///
  ///   [photoPathList] 一旦设置 则 [pickType]参数无效
  ///
  /// 关于参数可以查看readme文档介绍
  ///
  /// if user not grand permission, then return null and show a dialog to help user open setting.
  /// sure is open setting cancel ,cancel to dismiss dialog, return null
  ///
  /// when user give permission.
  ///
  ///   when user sure , return a [AssetEntity] of [List]
  ///
  ///   when user cancel selected,result is empty list
  ///
  ///   when [photoPathList] is not null , [pickType] invalid
  ///
  /// params see readme.md
  static Future<List<AssetEntity>> pickAsset({
    @required BuildContext context,
    int rowCount = 4,
    int maxSelected = 9,
    double padding = 0.5,
    double itemRadio = 1.0,
    Color themeColor,
    Color dividerColor,
    Color textColor,
    Color disableColor,
    int thumbSize = 64,
    I18nProvider provider = I18nProvider.chinese,
    SortDelegate sortDelegate,
    CheckBoxBuilderDelegate checkBoxBuilderDelegate,
    LoadingDelegate loadingDelegate,
    PickType pickType = PickType.all,
    BadgeDelegate badgeDelegate = const DefaultBadgeDelegate(),
    List<AssetPathEntity> photoPathList,
  }) {
    assert(provider != null, "provider must be not null");
    assert(context != null, "context must be not null");
    assert(pickType != null, "pickType must be not null");

    themeColor ??= Theme.of(context)?.primaryColor ?? Colors.black;
    dividerColor ??= Theme.of(context)?.dividerColor ?? Colors.grey;
    disableColor ??= Theme.of(context)?.disabledColor ?? Colors.grey;
    textColor ??= Colors.white;

    sortDelegate ??= SortDelegate.common;
    checkBoxBuilderDelegate ??= DefaultCheckBoxBuilderDelegate();

    loadingDelegate ??= DefaultLoadingDelegate();

    var options = Options(
      rowCount: rowCount,
      dividerColor: dividerColor,
      maxSelected: maxSelected,
      itemRadio: itemRadio,
      padding: padding,
      disableColor: disableColor,
      textColor: textColor,
      themeColor: themeColor,
      thumbSize: thumbSize,
      sortDelegate: sortDelegate,
      checkBoxBuilderDelegate: checkBoxBuilderDelegate,
      loadingDelegate: loadingDelegate,
      badgeDelegate: badgeDelegate,
      pickType: pickType,
    );

    return PhotoPicker()._pickAsset(
      context,
      options,
      provider,
      photoPathList,
    );
  }

  Future<List<AssetEntity>> _pickAsset(
    BuildContext context,
    Options options,
    I18nProvider provider,
    List<AssetPathEntity> photoList,
  ) async {
    var requestPermission = await PhotoManager.requestPermission();
    if (requestPermission != true) {
      var result = await showDialog(
        context: context,
        builder: (ctx) => NotPermissionDialog(
          provider.getNotPermissionText(options),
        ),
      );
      if (result == true) {
        PhotoManager.openSetting();
      }
      return null;
    }

    return _openGalleryContentPage(context, options, provider, photoList);
  }

  Future<List<AssetEntity>> _openGalleryContentPage(
    BuildContext context,
    Options options,
    I18nProvider provider,
    List<AssetPathEntity> photoList,
  ) async {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PhotoApp(
          options: options,
          provider: provider,
          photoList: photoList,
        ),
      ),
    );
  }
}
