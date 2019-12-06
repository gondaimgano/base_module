import 'dart:async';
import 'dart:typed_data';

import 'package:base_module/AppEngine.dart';

import 'package:base_module/assets.dart';

import 'package:flutter/material.dart';
import 'package:base_module/photo_picker/delegate/badge_delegate.dart';
import 'package:base_module/photo_picker/delegate/loading_delegate.dart';
import 'package:base_module/photo_picker/engine/lru_cache.dart';
import 'package:base_module/photo_picker/engine/throttle.dart';
import 'package:base_module/photo_picker/entity/options.dart';
import 'package:base_module/photo_picker/provider/asset_provider.dart';
import 'package:base_module/photo_picker/provider/config_provider.dart';
import 'package:base_module/photo_picker/provider/gallery_list_provider.dart';
import 'package:base_module/photo_picker/provider/i18n_provider.dart';
import 'package:base_module/photo_picker/provider/selected_provider.dart';
import 'package:base_module/photo_picker/ui/dialog/change_gallery_dialog.dart';
import 'package:base_module/photo_picker/ui/page/photo_preview_page.dart';
import 'package:photo_manager/photo_manager.dart';

part './main/bottom_widget.dart';
part './main/image_item.dart';

class PhotoMainPage extends StatefulWidget {
  final ValueChanged<List<AssetEntity>> onClose;
  final Options options;
  final List<AssetPathEntity> photoList;

  const PhotoMainPage({
    Key key,
    this.onClose,
    this.options,
    this.photoList,
  }) : super(key: key);

  @override
  _PhotoMainPageState createState() => _PhotoMainPageState();
}

class _PhotoMainPageState extends State<PhotoMainPage>
    with SelectedProvider, GalleryListProvider {
  Options get options => widget.options;

  I18nProvider get i18nProvider => PhotoPickerProvider.of(context).provider;
  AssetProvider get assetProvider =>
      PhotoPickerProvider.of(context).assetProvider;

  List<AssetEntity> get list => assetProvider.data;

  Color get themeColor => options.themeColor;

  AssetPathEntity _currentPath;

  bool _isInit = false;

  AssetPathEntity get currentPath {
    if (_currentPath == null) {
      return null;
    }
    return _currentPath;
  }

  set currentPath(AssetPathEntity value) {
    _currentPath = value;
  }

  String get currentGalleryName {
    if (currentPath?.isAll == true) {
      return i18nProvider.getAllGalleryText(options);
    }
    return currentPath?.name ?? "All";
  }

  GlobalKey scaffoldKey;
  ScrollController scrollController;

  bool isPushed = false;

  bool get useAlbum => widget.photoList == null || widget.photoList.isEmpty;

  Throttle _changeThrottle;

  @override
  void initState() {
    super.initState();
    _refreshList();
    scaffoldKey = GlobalKey();
    scrollController = ScrollController();
    _changeThrottle = Throttle(onCall: _onAssetChange);
    PhotoManager.addChangeCallback(_changeThrottle.call);
    PhotoManager.startChangeNotify();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_changeThrottle.call);
    PhotoManager.stopChangeNotify();
    _changeThrottle.dispose();
    scaffoldKey = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: black,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          options.pickType == PickType.onlyImage
              ? "Choose Photos"
              : "Choose Video",
          style: textStyle(true, 17, black),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FlatButton(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                color: APP_COLOR,
                onPressed: selectedCount == 0 ? null : sure,
                child: Text(
                  "OK",
                  style: textStyle(true, 14, white),
                )),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _BottomWidget(
        key: scaffoldKey,
        provider: i18nProvider,
        options: options,
        galleryName: currentGalleryName,
        onGalleryChange: _onGalleryChange,
        onTapPreview: selectedList.isEmpty ? null : _onTapPreview,
        selectedProvider: this,
        galleryListProvider: this,
      ),
    );
  }

  void _cancel() {
    selectedList.clear();
    widget.onClose(selectedList);
  }

  @override
  bool isUpperLimit() {
    var result = selectedCount == options.maxSelected;
    if (result) _showTip(i18nProvider.getMaxTipText(options));
    return result;
  }

  void sure() {
    widget.onClose?.call(selectedList);
  }

  void _showTip(String msg) {
    if (isPushed) {
      return;
    }
    Scaffold.of(scaffoldKey.currentContext).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: options.textColor,
            fontSize: 14.0,
          ),
        ),
        duration: Duration(milliseconds: 1500),
        backgroundColor: themeColor.withOpacity(0.7),
      ),
    );
  }

  void _refreshList() {
    if (!useAlbum) {
      _refreshListFromWidget();
      return;
    }

    _refreshListFromGallery();
  }

  Future<void> _refreshListFromWidget() async {
    galleryPathList.clear();
    galleryPathList.addAll(widget.photoList);
    this.list.clear();
    var assetList = await galleryPathList[0].assetList;
    _sortAssetList(assetList);
    this.list.addAll(assetList);
    this.list.sort((a, b) {
      return b.createDtSecond.compareTo(a.createDtSecond);
    });
    setState(() {
      _isInit = true;
    });
  }

  Future<void> _refreshListFromGallery() async {
    List<AssetPathEntity> pathList;
    switch (options.pickType) {
      case PickType.onlyImage:
        pathList = await PhotoManager.getImageAsset();
        break;
      case PickType.onlyVideo:
        pathList = await PhotoManager.getVideoAsset();
        break;
      default:
        pathList = await PhotoManager.getAssetPathList();
    }

    if (pathList == null) {
      return;
    }

    options.sortDelegate.sort(pathList);

    galleryPathList.clear();
    galleryPathList.addAll(pathList);

    if (pathList.isNotEmpty) {
      assetProvider.current = pathList[0];
      await assetProvider.loadMore();
    }

    for (var path in pathList) {
      if (path.isAll) {
        path.name = i18nProvider.getAllGalleryText(options);
      }
    }

    setState(() {
      _isInit = true;
    });
  }

  void _sortAssetList(List<AssetEntity> assetList) {
    options?.sortDelegate?.assetDelegate?.sort(assetList);
  }

  Widget _buildBody() {
    if (!_isInit) {
      return _buildLoading();
    }

    final noMore = assetProvider.noMore;

    final count = assetProvider.count + (noMore ? 0 : 1);

    return Container(
      color: options.dividerColor,
      child: GridView.builder(
        controller: scrollController,
        padding: EdgeInsets.all(0),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: options.rowCount,
          childAspectRatio: options.itemRadio,
          crossAxisSpacing: options.padding,
          mainAxisSpacing: options.padding,
        ),
        itemBuilder: _buildItem,
        itemCount: count,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final noMore = assetProvider.noMore;
    if (!noMore && index == assetProvider.count) {
      _loadMore();
      return _buildLoading();
    }

    var data = list[index];
    var currentSelected = containsEntity(data);

    return RepaintBoundary(
      child: GestureDetector(
        //onTap: () => _onItemClick(data, index),
        onTap: () {
          if (options.pickType == PickType.onlyVideo ||
              options.maxSelected == 1) {
            addSelectEntity(data);
            sure();
            return;
          }

          changeCheck(!currentSelected, data);
        },
        child: Stack(
          children: <Widget>[
            ImageItem(
              entity: data,
              themeColor: themeColor,
              size: options.thumbSize,
              loadingDelegate: options.loadingDelegate,
              badgeDelegate: options.badgeDelegate,
            ),
            options.pickType == PickType.onlyVideo
                ? Container(
                    color: black.withOpacity(.2),
                    child: Center(
                        child: Icon(
                      Icons.play_circle_filled,
                      size: 20,
                      color: white,
                    )),
                  )
                : _buildMask(containsEntity(data)),
            options.pickType == PickType.onlyVideo || options.maxSelected == 1
                ? Container()
                : _buildSelected(data),
          ],
        ),
      ),
    );
  }

  _loadMore() async {
    await assetProvider.loadMore();
    setState(() {});
  }

  _buildMask(bool showMask) {
    return IgnorePointer(
      child: AnimatedContainer(
        color: showMask ? Colors.black.withOpacity(0.5) : Colors.transparent,
        duration: Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildSelected(AssetEntity entity) {
    var currentSelected = containsEntity(entity);
    return Positioned(
      right: 0.0,
      width: 36.0,
      height: 36.0,
      child: GestureDetector(
        onTap: () {
          changeCheck(!currentSelected, entity);
        },
        behavior: HitTestBehavior.translucent,
        child: _buildText(entity),
      ),
    );
  }

  Widget _buildText(AssetEntity entity) {
    var isSelected = containsEntity(entity);
    Widget child;
    BoxDecoration decoration;
    if (isSelected) {
      child = Text(
        (indexOfSelected(entity) + 1).toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.0,
          color: options.textColor,
        ),
      );
      decoration = BoxDecoration(color: themeColor);
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(1.0),
        border: Border.all(
          color: themeColor,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: decoration,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  void changeCheck(bool value, AssetEntity entity) {
    if (value) {
      addSelectEntity(entity);
    } else {
      removeSelectEntity(entity);
    }
    setState(() {});
  }

  void _onGalleryChange(AssetPathEntity assetPathEntity) async {
    // _currentPath = assetPathEntity;

    // _currentPath.assetList.then((v) async {
    //   _sortAssetList(v);
    //   list.clear();
    //   list.addAll(v);
    //   scrollController.jumpTo(0.0);
    //   await checkPickImageEntity();
    //   setState(() {});
    // });

//    if (assetPathEntity != assetProvider.current) {
//      assetProvider.current = assetPathEntity;
//      await assetProvider.loadMore();
//      setState(() {});
//    }
    _currentPath = assetPathEntity;

    _currentPath.assetList.then((v) async {
      _sortAssetList(v);
      list.clear();
      list.addAll(v);
      list.sort((a, b) {
        return b.createDtSecond.compareTo(a.createDtSecond);
      });
      scrollController.jumpTo(0.0);
      await checkPickImageEntity();
      setState(() {});
    });
  }

  void _onItemClick(AssetEntity data, int index) {
    var result = new PhotoPreviewResult();
    isPushed = true;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) {
          return PhotoPickerProvider(
            provider: PhotoPickerProvider.of(context).provider,
            options: options,
            child: PhotoPreviewPage(
              selectedProvider: this,
              list: List.of(list),
              initIndex: index,
              changeProviderOnCheckChange: true,
              result: result,
              isPreview: false,
              assetProvider: assetProvider,
            ),
          );
        },
      ),
    ).then((v) {
      if (handlePreviewResult(v)) {
        Navigator.pop(context, v);
        return;
      }
      isPushed = false;
      setState(() {});
    });
  }

  void _onTapPreview() async {
    var result = new PhotoPreviewResult();
    isPushed = true;
    var v = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PhotoPickerProvider(
          provider: PhotoPickerProvider.of(context).provider,
          options: options,
          child: PhotoPreviewPage(
            selectedProvider: this,
            list: List.of(selectedList),
            changeProviderOnCheckChange: false,
            result: result,
            isPreview: true,
            assetProvider: assetProvider,
          ),
        ),
      ),
    );
    if (handlePreviewResult(v)) {
      // print(v);
      Navigator.pop(context, v);
      return;
    }
    isPushed = false;
    compareAndRemoveEntities(result.previewSelectedList);
  }

  bool handlePreviewResult(List<AssetEntity> v) {
    if (v == null) {
      return false;
    }
    if (v is List<AssetEntity>) {
      return true;
    }
    return false;
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        children: <Widget>[
          Container(
            width: 40.0,
            height: 40.0,
            padding: const EdgeInsets.all(5.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(themeColor),
              strokeWidth: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              i18nProvider.loadingText(),
              style: const TextStyle(
                fontSize: 12.0,
              ),
            ),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _onAssetChange() {
    if (useAlbum) {
      _onPhotoRefresh();
    }
  }

  void _onPhotoRefresh() async {
    List<AssetPathEntity> pathList;
    switch (options.pickType) {
      case PickType.onlyImage:
        pathList = await PhotoManager.getImageAsset();
        break;
      case PickType.onlyVideo:
        pathList = await PhotoManager.getVideoAsset();
        break;
      default:
        pathList = await PhotoManager.getAssetPathList();
    }

    if (pathList == null) {
      return;
    }

    this.galleryPathList.clear();
    this.galleryPathList.addAll(pathList);

    if (!this.galleryPathList.contains(this.currentPath)) {
      // current path is deleted , 当前的相册被删除, 应该提示刷新
      if (this.galleryPathList.length > 0) {
        _onGalleryChange(this.galleryPathList[0]);
      }
      return;
    }
    // Not deleted
    _onGalleryChange(this.currentPath);
  }
}