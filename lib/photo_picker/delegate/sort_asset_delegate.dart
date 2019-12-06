part of './sort_delegate.dart';

abstract class SortAssetDelegate {
  const SortAssetDelegate();

  void sort(List<AssetEntity> list);
}

class DefaultAssetDelegate extends SortAssetDelegate {
  const DefaultAssetDelegate();

  @override
  void sort(List<AssetEntity> list) {
    list.sort((entity1, entity2) {
      //entity1.createDtSecond
      return entity2.createDtSecond.compareTo(entity1.createDtSecond);
    });
  }
}
