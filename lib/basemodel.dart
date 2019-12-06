import 'package:cloud_firestore/cloud_firestore.dart';

import 'AppEngine.dart';
import 'assets.dart';

class BaseModel {
  Map<String, Object> items = new Map();
  Map<String, Object> itemUpdate = new Map();
  Map<String, Map> itemUpdateList = new Map();

  BaseModel({Map items, DocumentSnapshot doc}) {
    if (items != null) {
      Map<String, Object> theItems = Map.from(items);
      this.items = theItems;
    }
    if (doc != null && doc.exists) {
      this.items = doc.data;
      this.items[DOCUMENT_ID] = doc.documentID;
    }
  }

  void put(String key, Object value) {
    items[key] = value;
    itemUpdate[key] = value;
  }

  void putInList(String key, Object value, bool add) {
    List itemsInList = items[key] == null ? List() : List.from(items[key]);
    if (add) {
      if (!itemsInList.contains(value)) itemsInList.add(value);
    } else {
      itemsInList.removeWhere((E) => E == value);
    }
    items[key] = itemsInList;

    Map update = Map();
    update[ADD] = add;
    update[VALUE] = value;

    itemUpdateList[key] = update;
  }

  void remove(String key) {
    items.remove(key);
    itemUpdate[key] = null;
  }

  String getObjectId() {
    Object value = items[DOCUMENT_ID];
    return value == null || !(value is String) ? "" : value.toString();
  }

  List getList(String key) {
    Object value = items[key];
    return value == null || !(value is List) ? new List() : List.from(value);
  }

  List<Object> addToList(String key, Object value, bool add) {
    List<Object> list = items[key];
    list = list == null ? new List<Object>() : list;
    if (add) {
      if (!list.contains(value)) list.add(value);
    } else {
      list.remove(value);
    }
    put(key, list);
    return list;
  }

  /* List<Map<String, Object>> addOnceToMap(
      String mapName, BaseModel bm, bool add) {
    List<Map<String, Object>> maps = items[mapName];
    maps = maps == null ? new List<Map<String, Object>>() : maps;
    bool canAdd = true;
    for (Map<String, Object> theMap in maps) {
      BaseModel model = new BaseModel(items: theMap);
      if (model.getString(OBJECT_ID) == (bm.getString(OBJECT_ID))) {
        canAdd = false;
        if (!add) maps.remove(theMap);
        break;
      }
    }
    if (canAdd && add) {
      maps.add(bm.items);
    }

    put(mapName, maps);
    return maps;
  }

  bool hasMap(String mapName, BaseModel bm) {
    List<Map<String, Object>> maps = items[mapName];
    maps = maps == null ? new List<Map<String, Object>>() : maps;
    for (Map<String, Object> theMap in maps) {
      BaseModel model = new BaseModel(items: theMap);
      if (model.getString(OBJECT_ID) == (bm.getString(OBJECT_ID))) {
        return true;
      }
    }
    return false;
  }*/

  Map getMap(String key) {
    Object value = items[key];
    return value == null || !(value is Map)
        ? new Map<String, String>()
        : Map.from(value);
  }

  Object get(String key) {
    return items[key];
  }

  String getUserId() {
    Object value = items[USER_ID];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getUserImage() {
    Object value = items[USER_IMAGE];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getImage() {
    Object value = items[IMAGE];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getGroupImage() {
    Object value = items[GROUP_IMAGE];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getGroupName() {
    Object value = items[GROUP_NAME];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getGroupDescription() {
    Object value = items[GROUP_DESCRIPTION];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getUserName() {
    Object value = items[USERNAME];
    String name = value == null || !(value is String) ? "" : value.toString();
    if (name.length > 2) {
      name = name.substring(0, 1).toUpperCase() + name.substring(1);
    }
    return name;
  }

  String getString(String key) {
    Object value = items[key];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getEmail() {
    Object value = items[EMAIL];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getPassword() {
    Object value = items[PASSWORD];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getNotificationTitle() {
    Object value = items[NOTIFICATION_TITLE];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getNotificationSender() {
    Object value = items[NOTIFICATION_SENDER_NAME];
    return value == null || !(value is String) ? "" : value.toString();
  }

  /*int getCreatedAt() {
    Object value = items[CREATED_AT];
    return value == null || !(value is DateTime)
        ? 0
        : (value as DateTime).millisecond;
  }

  DateTime getCreatedAtDate() {
    Object value = items[CREATED_AT];
    return value == null || !(value is DateTime) ? new DateTime.now() : (value);
  }

  DateTime getUpdatedAtDate() {
    Object value = items[UPDATED_AT];
    return value == null || !(value is DateTime) ? new DateTime.now() : (value);
  }

  int getUpdatedAt() {
    Object value = items[UPDATED_AT];
    return value == null || !(value is Timestamp)
        ? 0
        : (value as Timestamp).millisecondsSinceEpoch;
  }*/

  /*bool isRead({String userId}) {
    List<String> readBy = List.from(getList(READ_BY));
    return readBy.contains(userId != null ? userId : userModel.getObjectId());
  }*/

  bool isMuted(String chatId) {
    List<String> readBy = getList(MUTED);
    return readBy.contains(chatId);
  }

  bool isRated(String chatId) {
    List<String> readBy = getList(HAS_RATED);
    return readBy.contains(chatId);
  }

  bool isSilenced() {
    List<String> silence = getList(SILENCED);
    return silence.contains(userModel.getObjectId());
  }

  bool isKicked() {
    List<String> readBy = getList(KICKED_OUT);
    return readBy.contains(userModel.getObjectId());
  }

  bool isMale() {
    return getInt(GENDER) == 0;
  }

  /*void setRead() {
    List<String> readBy = getList(READ_BY);
    if (!readBy.contains(userModel.getObjectId())) {
      readBy.add(userModel.getObjectId());
      put(READ_BY, readBy);
    }
    updateItem();
  }*/

  /*void setUnRead() {
    List<String> readBy = getList(READ_BY);
    readBy.remove(userModel.getObjectId());
    updateItem();
  }*/

  Map getOwner() {
    Object value = items[POST_OWNER];
    return value == null || !(value is Map)
        ? new Map<String, String>()
        : Map.from(value);
  }

  Map getChurchInfo() {
    Object value = items[CHURCH_INFO];
    return value == null || !(value is Map)
        ? new Map<String, String>()
        : Map.from(value);
  }

  Map getRequestError() {
    Object value = items[ERROR];
    return value == null || !(value is Map)
        ? new Map<String, String>()
        : Map.from(value);
  }

  bool myItem() {
    return getUserId() == (userModel.getUserId());
  }

  bool mySentChat() {
    return getBoolean(MY_SENT_CHAT);
  }

  bool isHidden() {
    List<String> readBy = getList(HIDDEN);
    return readBy.contains(userModel.getObjectId());
  }

  int getInt(String key) {
    Object value = items[key];
    return value == null || !(value is int) ? 0 : (value);
  }

  int getType() {
    Object value = items[TYPE];
    return value == null || !(value is int) ? 0 : value;
  }

  double getDouble(String key) {
    Object value = items[key];
    return value == null || !(value is double) ? 0 : value;
  }

  int getTime() {
    Object value = items[TIME];
    return value == null || !(value is int) ? 0 : value;
  }

  /*int getLong(String key) {
    Object value = items[key];
    return value == null || !(value is int) ? 0 : value;
  }*/

  bool getBoolean(String key) {
    Object value = items[key];
    return value == null || !(value is bool) ? false : value;
  }

  bool isAdminItem() {
    return getBoolean(IS_ADMIN);
  }

  bool isJohn() {
    return getEmail() == ("johnebere58@gmail.com");
  }

  bool isMaugost() {
    return getEmail() == ("ammaugost@gmail.com");
  }

  bool getIsChurch() {
    Object value = items[IS_CHURCH];
    return value == null || !(value is bool) ? false : value;
  }

  String getUId() {
    Object value = items[USER_ID];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getOwnerId() {
    Object value = items[OWNER_ID];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getFullName() {
    bool isChurch = getIsChurch();
    Object value = items[isChurch ? CHURCH_NAME : FULL_NAME];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getTitle() {
    Object value = items[TITLE];
    return value == null || !(value is String) ? "NONE" : value.toString();
  }

  String getCity() {
    Object value = items[CITY];
    return value == null || !(value is String) ? "NONE" : value.toString();
  }

  String getChurchName() {
    Object value = items[CHURCH_NAME];
    return value == null || !(value is String) ? "NONE" : value.toString();
  }

  String getRelationshipStatus() {
    Object value = items[RELATIONSHIP_STATUS];
    return value == null || !(value is String) ? "NONE" : value.toString();
  }

  String getChurchDenomination() {
    Object value = items[CHURCH_DENOMINATION];
    return value == null || !(value is String) ? "NONE" : value.toString();
  }

  String getChurchAddress() {
    Object value = items[CHURCH_ADDRESS];
    return value == null || !(value is String) ? "NONE" : value.toString();
  }

  String getBusinessAddress() {
    Object value = items[BUSINESS_ADDRESS];
    return value == null || !(value is String) || value.toString().isEmpty
        ? "NONE"
        : value.toString();
  }

  String getChurchWebsite() {
    Object value = items[CHURCH_WEBSITE];
    return value == null || !(value is String) ? "NONE" : value.toString();
  }

  String getToken() {
    Object value = items[TOKEN_ID];
    return value == null || !(value is String) ? "" : value.toString();
  }

  int getAssetType() {
    Object value = items[ASSET_TYPE];
    return value == null || !(value is int) ? 0 : (value);
  }

  String getGifUrl() {
    Object value = items[GIF_URL];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getAboutUser() {
    Object value = items[ABOUT_ME];
    return value == null || !(value is String) ? "NONE" : value.toString();
  }

  String getAssetFile() {
    Object value = items[ASSET_FILE];
    return value == null || !(value is String) ? "NONE" : value.toString();
  }

  String getThumbnailFile() {
    Object value = items[THUMBNAIL_PATH];
    return value == null || !(value is String) ? "NONE" : value.toString();
  }

  int getIsOnline() {
    Object value = items[IS_ONLINE];
    return value == null || !(value is int) ? 0 : (value);
  }

  bool getRequestHasError() {
    return items.isNotEmpty;
  }

  bool getIsHidden() {
    Object value = items[IS_HIDDEN];
    return value == null || !(value is bool) ? false : value;
  }

  bool getIsPostReported() {
    return getReports().contains(userModel.getUId());
  }

  bool getIsPostBlocked() {
    return getBlocks().contains(userModel.getUId());
  }

  List getReports() {
    Object value = items[REPORTS];
    return value == null || !(value is List) ? new List() : List.from(value);
  }

  List getChatData() {
    Object value = items[CHAT_DATA];
    return value == null || !(value is List) ? new List() : List.from(value);
  }

  List getConnections() {
    Object value = items[CONNECTIONS];
    return value == null || !(value is List) ? new List() : List.from(value);
  }

  List getShares() {
    Object value = items[SHARES];
    return value == null || !(value is List) ? new List() : List.from(value);
  }

  List getAchievements() {
    Object value = items[ACHIEVEMENTS];
    return value == null || !(value is List) ? new List() : List.from(value);
  }

  List getSentRequests() {
    Object value = items[SENT_REQUESTS];
    return value == null || !(value is List) ? new List() : List.from(value);
  }

  List getReceivedRequests() {
    Object value = items[RECEIVED_REQUESTS];
    return value == null || !(value is List) ? new List() : List.from(value);
  }

  List getBlocks() {
    Object value = items[BLOCKED];
    return value == null || !(value is List) ? new List() : List.from(value);
  }

  bool getCanShowDate() {
    Object value = items[SHOW_DATE];
    return value == null || !(value is bool) ? false : value;
  }

  bool getIsUploadingData() {
    Object value = items[UPLOADING_DATA];
    return value == null || !(value is bool) ? false : value;
  }

  bool getIsChurchUpdated() {
    Object value = items[IS_CHURCH_UPDATED];
    return value == null || !(value is bool) ? false : value;
  }

  bool getIsPersonalUpdated() {
    Object value = items[IS_PERSONAL_UPDATED];
    return value == null || !(value is bool) ? false : value;
  }

  bool getUserBlocked() {
    Object value = items[IS_BLOCKED];
    return value == null || !(value is bool) ? false : value;
  }

  bool getIsVerified() {
    Object value = items[IS_VERIFIED];
    return value == null || !(value is bool) ? false : value;
  }

  bool getIsBlocked() {
    Object value = items[IS_CHURCH];
    return value == null || !(value is bool) ? false : value;
  }

  bool getIsNetwork() {
    Object value = items[IS_NETWORK_IMAGE];
    return value == null || !(value is bool) ? false : value;
  }

  String getMessage() {
    Object value = items[MESSAGE];
    return value == null || !(value is String) ? "" : value.toString();
  }

  int getStatus() {
    Object value = items[NOTIFICATION_STATUS];
    return value == null || !(value is int) ? 0 : (value);
  }

  int getNotificationType() {
    Object value = items[NOTIFICATION_TYPE];
    return value == null || !(value is int) ? 0 : (value);
  }

  /*void updateItems({onComplete, bool updateTime = true}) {
    String dName = items[DATABASE_NAME];
    //if(dName==null ||dName.isEmpty())return;

    String id = items[OBJECT_ID];

    if (updateTime) {
      items[UPDATED_AT] = FieldValue.serverTimestamp();
      items[TIME_UPDATED] = DateTime.now().millisecondsSinceEpoch;
    }

    Firestore db = Firestore.instance;
    db.collection(dName).document(id).setData(items).whenComplete(onComplete);
  }*/

  /*void updateItems({bool updateTime = true}) async {
    String dName = items[DATABASE_NAME];
    String id = items[OBJECT_ID];

    Firestore.instance.runTransaction((tran) async {
      DocumentReference ref = Firestore.instance.collection(dName).document(id);
      DocumentSnapshot doc = await tran.get(ref);
      if (doc == null) return;
      if (!doc.exists) return;

      Map data = doc.data;
      for (String k in itemUpdate.keys) {
        data[k] = itemUpdate[k];
      }
      for (String k in itemUpdateList.keys) {
        Map update = itemUpdateList[k];
        bool add = update[ADD];
        var value = update[VALUE];

        List dataList = data[k] == null ? List() : List.from(data[k]);
        if (add) {
          if (!dataList.contains(value)) dataList.add(value);
        } else {
          dataList.removeWhere((E) => E == value);
        }
        data[k] = dataList;
      }

      if (updateTime) {
        data[UPDATED_AT] = FieldValue.serverTimestamp();
        data[TIME_UPDATED] = DateTime.now().millisecondsSinceEpoch;
      }
      await tran.update(ref, data);
    });
  }*/

  void updateItems({bool updateTime = true, int delaySeconds = 0}) async {
    Future.delayed(Duration(seconds: delaySeconds), () async {
      bool connected = await isConnected();
      if (!connected) {
        delaySeconds = delaySeconds + 10;
        delaySeconds = delaySeconds >= 60 ? 0 : delaySeconds;
        print("not connected retrying in $delaySeconds seconds");
        updateItems(updateTime: updateTime, delaySeconds: delaySeconds);
        return;
      }

      String dName = items[DATABASE_NAME];
      String id = items[OBJECT_ID];

      DocumentSnapshot doc = await Firestore.instance
          .collection(dName)
          .document(id)
          .get(source: Source.server)
          .catchError((error) {
        delaySeconds = delaySeconds + 10;
        delaySeconds = delaySeconds >= 60 ? 0 : delaySeconds;
        print("$error... retrying in $delaySeconds seconds");
        updateItems(updateTime: updateTime, delaySeconds: delaySeconds);
        return;
      });
      if (doc == null) return;
      if (!doc.exists) return;

      Map data = doc.data;
      for (String k in itemUpdate.keys) {
        data[k] = itemUpdate[k];
      }
      for (String k in itemUpdateList.keys) {
        Map update = itemUpdateList[k];
        bool add = update[ADD];
        var value = update[VALUE];

        List dataList = data[k] == null ? List() : List.from(data[k]);
        if (add) {
          if (!dataList.contains(value)) dataList.add(value);
        } else {
          dataList.removeWhere((E) => E == value);
        }
        data[k] = dataList;
      }

      if (updateTime) {
        data[UPDATED_AT] = FieldValue.serverTimestamp();
        data[TIME_UPDATED] = DateTime.now().millisecondsSinceEpoch;
      }

      doc.reference.setData(data);
    });
  }

  void updateCountItem(String key, bool increase,
      {bool updateTime = true, int delaySeconds = 0}) async {
    Future.delayed(Duration(seconds: 1), () async {
      bool connected = await isConnected();
      if (!connected) {
        delaySeconds = delaySeconds + 10;
        delaySeconds = delaySeconds >= 60 ? 0 : delaySeconds;
        updateCountItem(key, increase,
            updateTime: updateTime, delaySeconds: delaySeconds);
        return;
      }

      String dName = items[DATABASE_NAME];
      String id = items[OBJECT_ID];

      DocumentSnapshot doc = await Firestore.instance
          .collection(dName)
          .document(id)
          .get(source: Source.server)
          .catchError((error) {
        delaySeconds = delaySeconds + 10;
        delaySeconds = delaySeconds >= 60 ? 0 : delaySeconds;
        updateCountItem(key, increase,
            updateTime: updateTime, delaySeconds: delaySeconds);
        return;
      });
      if (doc == null) return;
      if (!doc.exists) return;

      Map data = doc.data;
      var item = data[key] ?? 0;
      if (increase) {
        item = item + 1;
      } else {
        item = item - 1;
      }
      data[key] = item;

      if (updateTime) {
        data[UPDATED_AT] = FieldValue.serverTimestamp();
        data[TIME_UPDATED] = DateTime.now().millisecondsSinceEpoch;
      }

      doc.reference.setData(data);
    });
  }

  void deleteItem() {
    String dName = items[DATABASE_NAME];
    String id = items[OBJECT_ID];

    Firestore db = Firestore.instance;
    db.collection(dName).document(id).delete();
  }

  processSave(String name, bool addMyInfo) {
    items[VISIBILITY] = PUBLIC;
    items[DATABASE_NAME] = name;
    items[UPDATED_AT] = FieldValue.serverTimestamp();
    items[CREATED_AT] = FieldValue.serverTimestamp();
    items[TIME] = DateTime.now().millisecondsSinceEpoch;
    items[TIME_UPDATED] = DateTime.now().millisecondsSinceEpoch;
    if (name != (USER_BASE) &&
        name != (APP_SETTINGS_BASE) &&
        name != (NOTIFY_BASE)) {
      if (addMyInfo) addMyDetails();
    }
//    if (name == VOICE_BASE || name == POSTS_BASE) {
//      items[FOLLOWERS] = userModel.getList(FOLLOWERS);
//    }
  }

  void addMyDetails() {
    items[OWNER_ID] = userModel.getUserId();
    items[USER_ID] = userModel.getUserId();
    items[USER_IMAGE] = userModel.getString(USER_IMAGE);
    items[IMAGE] = userModel.getImage();
    items[USERNAME] = userModel.getUserName();
    items[FULL_NAME] = userModel.getString(FULL_NAME);
    items[BY_ADMIN] = userModel.isAdminItem();
    items[GENDER] = userModel.getInt(GENDER);
    items[COUNTRY] = userModel.getString(COUNTRY);
    items[EMAIL] = userModel.getString(EMAIL);
    items[PHONE_NO] = userModel.getString(PHONE_NO);
    items[TOKEN_ID] = userModel.getToken();
  }

  void saveItem(String name, bool addMyInfo, {document, onComplete}) {
    processSave(name, addMyInfo);
    if (document == null) {
      Firestore.instance
              .collection(name)
              .add(items) /*.whenComplete((){
        onComplete();
      })*/
          ;
    } else {
      items[OBJECT_ID] = document;
      Firestore.instance
          .collection(name)
          .document(document)
          .setData(items)
          .whenComplete(() {
        onComplete();
      });
    }
  }

  /*void saveItemManually(String name, String document, bool addMyInfo,
      onComplete, bool isUpdating) {
    if (!isUpdating) {
      processSave(name, addMyInfo);
    } else {
      items[UPDATED_AT] = FieldValue.serverTimestamp();
      items[TIME_UPDATED] = DateTime.now().millisecondsSinceEpoch;
    }

    bool hasError = false;

    Firestore.instance
        .collection(name)
        .document(document)
        .setData(items)
        .timeout(Duration(seconds: 15), onTimeout: () {
      onComplete(null, "Error, Timeout");
      hasError = true;
    }).then((void _) {
      if (!hasError) onComplete(_, null);
    }, onError: (error) {
      onComplete(null, error);
    });
  }*/
}
