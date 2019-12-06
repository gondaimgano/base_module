import 'dart:async';
import 'dart:io';

import 'package:base_module/ChatMain.dart';
import 'package:base_module/badge_delegate.dart';
import 'package:base_module/inputDialog.dart';
import 'package:base_module/listDialog.dart';
import 'package:base_module/messageDialog.dart';
import 'package:base_module/photo_picker/delegate/checkbox_builder_delegate.dart';
import 'package:base_module/photo_picker/delegate/sort_delegate.dart';
import 'package:base_module/photo_picker/photo.dart';
import 'package:base_module/photo_picker/provider/i18n_provider.dart';
import 'package:base_module/progressDialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:country_pickers/country_picker_dialog.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_pickers/CorpConfig.dart';
import 'package:image_pickers/UIConfig.dart';
import 'package:image_pickers/image_pickers.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_text_view/smart_text_view.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'NotificationHandler.dart';
import 'assets.dart';
import 'basemodel.dart';


inputView(title, hint,
    {TextEditingController controller,
    onTextChanged,
    String value,
    String btnValue,
    String btnHint,
    bool amPassword = false,
    bool passVisible = false,
    bool btnAlone = false,
    bool btnWith = false,
    bool showTitle = true,
    bool useValue = false,
    bool canClick = true,
    imgAsset,
    bool withIcon = false,
    bool isAsset = false,
    onPassChanged,
    TextInputType keyboard = TextInputType.text,
    int maxLine = 1,
    onBtnClicked}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (showTitle)
        Text(
          title,
          style: textStyle(false, 14, black.withOpacity(.7)),
        ),
      if (showTitle) addSpace(10),
      if (btnAlone)
        Container(
          //width: 100,
          color: light_grey,
          child: FlatButton(
              onPressed: canClick ? onBtnClicked : null,
              padding: EdgeInsets.all(12),
              child: Center(
                child: Row(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    if (withIcon && isAsset)
                      Image.asset(
                        imgAsset,
                        height: 18,
                        width: 18,
                        color: black.withOpacity(.4),
                      )
                    else if (withIcon && !isAsset)
                      Icon(
                        imgAsset,
                        color: black.withOpacity(.4),
                      )
                    else
                      Icon(
                        Icons.arrow_drop_down,
                        color: black.withOpacity(.4),
                      ),
                    addSpaceWidth(10),
                    Text(
                      value ?? hint,
                      style: textStyle(
                          false, 14, black.withOpacity(null != value ? 1 : .6)),
                    ),
                  ],
                ),
              )),
        )
      else
        Row(
          children: <Widget>[
            if (btnWith) ...[
              Container(
                //width: 100,
                color: light_grey,
                child: FlatButton(
                    onPressed: canClick ? onBtnClicked : null,
                    padding: EdgeInsets.all(10),
                    child: Center(
                      child: Row(
                        //mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.arrow_drop_down),
                          addSpaceWidth(2),
                          Text(
                            btnValue ?? btnHint,
                            style: textStyle(false, 14,
                                black.withOpacity(null != value ? 1 : .6)),
                          ),
                        ],
                      ),
                    )),
              ),
              addSpaceWidth(10),
            ],
            Flexible(
              child: TextFormField(
                controller: controller,
                keyboardType: keyboard,
                onChanged: onTextChanged,
                maxLines: maxLine,
                //inputFormatters: [UpperCaseTextFormatter()],
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: black.withOpacity(.1), width: .7)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: black.withOpacity(.1), width: .7)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: black.withOpacity(.1), width: .7)),
                    hintText: hint,
                    fillColor: white,
                    filled: true,
                    prefixIcon: Container(
                      height: 15,
                      width: 15,
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(14),
                      child: (withIcon && isAsset)
                          ? Image.asset(
                              imgAsset,
                              color: black.withOpacity(.4),
                            )
                          : (withIcon && !isAsset) ? Icon(imgAsset) : null,
                    ),
                    suffixIcon: amPassword
                        ? IconButton(
                            icon: Icon(
                              passVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: black.withOpacity(.5),
                            ),
                            onPressed: onPassChanged)
                        : null,
                    contentPadding: btnWith ? EdgeInsets.all(15) : null),
              ),
            ),
          ],
        )
    ],
  );
}

SizedBox addSpace(double size) {
  return SizedBox(
    height: size,
  );
}

addSpaceWidth(double size) {
  return SizedBox(
    width: size,
  );
}

int getSeconds(String time) {
  List parts = time.split(":");
  int mins = int.parse(parts[0]) * 60;
  int secs = int.parse(parts[1]);
  return mins + secs;
}

String getTimerText(int seconds, {bool three = false}) {
  int hour = seconds ~/ Duration.secondsPerHour;
  int min = (seconds ~/ 60) % 60;
  int sec = seconds % 60;

  String h = hour.toString();
  String m = min.toString();
  String s = sec.toString();

  String hs = h.length == 1 ? "0$h" : h;
  String ms = m.length == 1 ? "0$m" : m;
  String ss = s.length == 1 ? "0$s" : s;

  return three ? "$hs:$ms:$ss" : "$ms:$ss";
}

Container addLine(
    double size, color, double left, double top, double right, double bottom) {
  return Container(
    height: size,
    width: double.infinity,
    color: color,
    margin: EdgeInsets.fromLTRB(left, top, right, bottom),
  );
}

Container bigButton(double height, double width, String text, textColor,
    buttonColor, onPressed) {
  return Container(
    height: height,
    width: width,
    child: RaisedButton(
      onPressed: onPressed,
      color: buttonColor,
      textColor: white,
      child: Text(
        text,
        style: TextStyle(
            fontSize: 20,
            fontFamily: "NirmalaB",
            fontWeight: FontWeight.normal,
            color: textColor),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    ),
  );
}

textStyle(bool bold, double size, color, {underlined = false}) {
  return TextStyle(
      color: color,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontFamily: bold ? "NirmalaB" : "Nirmala",
      fontSize: size,
      decoration: underlined ? TextDecoration.underline : TextDecoration.none);
}

ThemeData darkTheme() {
  final ThemeData base = ThemeData();
  return base.copyWith(hintColor: white);
}

placeHolder(double height,
    {double width = 200, Color color = blue0, double opacity = .1}) {
  return new Container(
    height: height,
    width: width,
    color: color.withOpacity(opacity),
    child: Center(
        child: Opacity(
            opacity: .3,
            child: Image.asset(
              ic_launcher,
              width: 20,
              height: 20,
            ))),
  );
}

tipBox(color, text, textColor) {
  return Container(
    //width: double.infinity,
    color: color,
    child: Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        //mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            Icons.info,
            size: 14,
            color: white,
          ),
          addSpaceWidth(10),
          Flexible(
            flex: 1,
            child: Text(
              text,
              style: textStyle(false, 15, textColor),
            ),
          )
        ],
      ),
    ),
  );
}

toast(scaffoldKey, text, {Color color = null}) {
  return scaffoldKey.currentState.showSnackBar(new SnackBar(
    content: Padding(
      padding: const EdgeInsets.all(0.0),
      child: Text(
        text,
        style: textStyle(false, 15, white),
      ),
    ),
    backgroundColor: color,
    duration: Duration(seconds: 2),
  ));
}

gradientCheckBox(Widget child, double padding,
    {bool active = false, double boxSize = 20}) {
  return Container(
    height: boxSize,
    width: boxSize,
    decoration: active
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0XFFe46514),
                Color(0XFFf79836),
              ],
            ),
            shape: BoxShape.circle,
          )
        : BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey),
            shape: BoxShape.circle,
          ),
    padding: EdgeInsets.all(padding ?? 20),
    alignment: Alignment.center,
    child: child,
  );
}

textBox(title, icon, mainText, tap) {
  return new Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: textStyle(false, 14, white.withOpacity(.5)),
      ),
      addSpace(10),
      new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Image.asset(
            icon,
            width: 14,
            height: 14,
            color: white,
          ),
          addSpaceWidth(15),
          Flexible(
            flex: 1,
            child: Column(
              children: <Widget>[
                new Container(
                  width: double.infinity,
                  child: InkWell(
                      onTap: tap,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: Text(
                          mainText,
                          style: textStyle(false, 17, white),
                        ),
                      )),
                ),
                addLine(2, white, 0, 0, 0, 0),
              ],
            ),
          )
        ],
      ),
    ],
  );
}

Widget transition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return FadeTransition(
    opacity: animation,
    child: child,
  );
}

/*selectCurrency(context, result) {
  List<String> images = List();
  List<String> titlesMain = List.from(currenciesText);
  List<String> titles = List.from(currenciesText);

  titles.sort((s1, s2) => s1.compareTo(s2));

  for (String s in titles) {
    images.add(currencies[titlesMain.indexOf(s)]);
  }

  pushAndResult(
      context,
      listDialog(
        titles,
        title: "Choose Currency",
        images: images,
      ), result: (_) {
    String title = _;
    result(title);
  });
}*/

loadingLayout({Color color = white, Color load = light_grey}) {
  return new Container(
    color: color,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Center(
          child: Opacity(
            opacity: .3,
            child: Image.asset(
              ic_launcher,
              width: 20,
              height: 20,
            ),
          ),
        ),
        Center(
          child: CircularProgressIndicator(
            //value: 20,
            valueColor: AlwaysStoppedAnimation<Color>(load),
            strokeWidth: 2,
          ),
        ),
      ],
    ),
  );
}

errorDialog(retry, cancel, {String text}) {
  return Stack(
    fit: StackFit.expand,
    children: <Widget>[
      Container(
        color: black.withOpacity(.8),
      ),
      Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: red0,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Text(
                        "!",
                        style: textStyle(true, 30, white),
                      ))),
                  addSpace(10),
                  Text(
                    "Error",
                    style: textStyle(false, 14, red0),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              text == null ? "An unexpected error occurred, try again" : text,
              style: textStyle(false, 14, white.withOpacity(.5)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      )),
      Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: new Container(),
            flex: 1,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: FlatButton(
                      onPressed: retry,
                      child: Text(
                        "RETRY",
                        style: textStyle(true, 15, white),
                      )),
                ),
                addSpace(15),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: FlatButton(
                      onPressed: cancel,
                      child: Text(
                        "CANCEL",
                        style: textStyle(true, 15, white),
                      )),
                ),
              ],
            ),
          )
        ],
      ),
    ],
  );
}

addExpanded() {
  return Expanded(
    child: new Container(),
    flex: 1,
  );
}

addFlexible() {
  return Flexible(
    child: new Container(),
    flex: 1,
  );
}

emptyLayout(icon, String title, String text,
    {click, clickText, bool isIcon = false}) {
  return Container(
    color: white,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new Container(
              width: 50,
              height: 50,
              child: Stack(
                children: <Widget>[
                  new Container(
                    height: 50,
                    width: 50,
                    decoration:
                        BoxDecoration(color: red0, shape: BoxShape.circle),
                  ),
                  new Center(
                      child: isIcon
                          ? Icon(
                              icon,
                              size: 30,
                              color: white,
                            )
                          : Image.asset(
                              icon,
                              height: 30,
                              width: 30,
                              color: white,
                            )),
                  new Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        addExpanded(),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              color: red3,
                              shape: BoxShape.circle,
                              border: Border.all(color: white, width: 1)),
                          child: Center(
                            child: Text(
                              "!",
                              style: textStyle(true, 14, white),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            addSpace(10),
            Text(
              title,
              style: textStyle(true, 16, black),
              textAlign: TextAlign.center,
            ),
            addSpace(5),
            Text(
              text,
              style: textStyle(false, 14, black.withOpacity(.5)),
              textAlign: TextAlign.center,
            ),
            addSpace(10),
            click == null
                ? new Container()
                : FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    color: green_dark,
                    onPressed: click,
                    child: Text(
                      clickText,
                      style: textStyle(true, 14, white),
                    ))
          ],
        ),
      ),
    ),
  );
}

List<String> getFromList(String key, List<BaseModel> models,
    {String sortKey, bool sortWithNumber = true}) {
  List<String> list = new List();
  //List<BaseModel> models = new List();

  if (sortKey != null) {
    models.sort((b1, b2) {
      if (sortWithNumber) {
        int a = b1.getInt(sortKey);
        int b = b2.getInt(sortKey);
        return a.compareTo(b);
      }
      String a = b1.getString(sortKey);
      String b = b2.getString(sortKey);
      return a.compareTo(b);
    });
  }

  for (BaseModel bm in models) {
    list.add(bm.getString(key));
  }

  return list;
}

int memberStatus(List list) {
  for (Map map in list) {
    BaseModel bm = new BaseModel(items: map);
    if (bm.getObjectId() == (userModel.getObjectId())) {
      if (bm.getBoolean(GROUP_ADMIN)) return ADMIN_MEMBER;
      return MEMBER;
    }
  }

  return NOT_MEMBER;
}

pushAndResult(context, item, {result}) {
  Navigator.push(
      context,
      PageRouteBuilder(
          transitionsBuilder: transition,
          opaque: false,
          pageBuilder: (context, _, __) {
            return item;
          })).then((_) {
    if (_ != null) {
      if (result != null) result(_);
    }
  });
}

String getRandomId() {
  var uuid = new Uuid();
  return uuid.v1();
}

double screenW(BuildContext _) {
  return MediaQuery.of(_).size.width;
}

double screenH(BuildContext _) {
  return MediaQuery.of(_).size.height;
}

loadLocalUser(String userId,
    {Source source = Source.cache, bool server = false, noInternet}) async {
  //  var result = await (Connectivity().checkConnectivity());
//  if (result == ConnectivityResult.none) {
//    return;
//  }

  //try {
  if (userId.isNotEmpty) {
    Firestore.instance
        .collection(USER_BASE)
        .document(userId)
        .get(source: source)
        .then((doc) {
      if (doc.exists) {
        userModel = BaseModel(doc: doc);
        amChurch = userModel.getIsChurch();
        trophyCreated = userModel.getBoolean(TROPHY_CREATED);

        if (userModel.getIsChurch()) {
          churchModel = BaseModel(items: userModel.getMap(CHURCH_INFO));
        }

        if (!trophyCreated) {
          print(treeTrophies.length);
          userModel
            ..put(TREE_TROPHIES, treeTrophies)
            ..put(TROPHY_CREATED, true)
            ..updateItems();
          trophyCreated = true;
        }

        isAdmin = userModel.isMaugost() || userModel.getBoolean(IS_ADMIN);
      } else {
        isLoggedIn = false;
        FirebaseAuth.instance.signOut();
      }
    }).catchError((e) {
      if (e.toString().toLowerCase().contains("client is offline")) {
        noInternet(e.details);
        return;
      }

      if (e.toString().toLowerCase().contains("document from cache")) {
        loadLocalUser(userId,
            source: Source.serverAndCache,
            server: true,
            noInternet: noInternet);
        return;
      }
    });
  }

  Firestore.instance
      .collection(APP_SETTINGS_BASE)
      .document(APP_SETTINGS)
      .get(source: source)
      .then((doc) {
    if (doc.exists) {
      appSettingsModel = BaseModel(doc: doc);
    }
  }).catchError((e) {
    if (e.toString().toLowerCase().contains("client is offline")) {
      noInternet(e.details);
      return;
    }

    if (e.toString().toLowerCase().contains("document from cache")) {
      loadLocalUser(userId,
          source: Source.serverAndCache, server: true, noInternet: noInternet);
      return;
    }
  });
}

createBasicListeners(String userId, {bool suspend = false}) async {
  if (suspend) {
    isLoggedIn = false;
    userModel = new BaseModel();
    FirebaseAuth.instance.signOut();
    cartStream?.cancel();
    notifyStream?.cancel();
    usersStream?.cancel();
    appSettingsStream?.cancel();
    return;
  }

  if (userId.isNotEmpty) {
    usersStream = Firestore.instance
        .collection(USER_BASE)
        .document(userId)
        .snapshots()
        .listen((shot) {
      if (shot.exists) {
        userModel = BaseModel(doc: shot);
        amChurch = userModel.getIsChurch();
        trophyCreated = userModel.getBoolean(TROPHY_CREATED);

        if (!trophyCreated) {
          userModel
            ..put(TREE_TROPHIES, treeTrophies)
            ..put(TROPHY_CREATED, true)
            ..updateItems();
          trophyCreated = true;
        }

        if (userModel.getIsChurch()) {
          churchModel = BaseModel(items: userModel.getMap(CHURCH_INFO));
        }
        isAdmin = userModel.isMaugost() || userModel.getBoolean(IS_ADMIN);

        if (!trophyCreated) {
          userModel
            ..put(TREE_TROPHIES, treeTrophies)
            ..updateItems();
        }
      } else {
        isLoggedIn = false;
      }
    });
  }

  appSettingsStream = Firestore.instance
      .collection(APP_SETTINGS_BASE)
      .document(APP_SETTINGS)
      .snapshots()
      //.get(source: Source.server)
      .listen((shot) {
    if (!shot.exists) {
      BaseModel model = BaseModel();
      model.saveItem(APP_SETTINGS_BASE, false, document: APP_SETTINGS);
    }
    if (shot != null) {
      appSettingsModel = BaseModel(doc: shot);
    }
  });
}

String getCountryCode(context) {
  return Localizations.localeOf(context).countryCode;
}

uploadFile(File file, onComplete) {
  final String ref = getRandomId();
  StorageReference storageReference = FirebaseStorage.instance.ref().child(ref);
  StorageUploadTask uploadTask = storageReference.putFile(file);
  uploadTask.onComplete
      /*.timeout(Duration(seconds: 3600), onTimeout: () {
    onComplete(null, "Error, Timeout");
  })*/
      .then((task) {
    if (task != null) {
      task.ref.getDownloadURL().then((_) {
        BaseModel model = new BaseModel();
        model.put(FILE_URL, _.toString());
        model.put(REFERENCE, ref);
        model.saveItem(REFERENCE_BASE, false);
        onComplete(_.toString(), null);
      }, onError: (error) {
        onComplete(null, error);
      });
    }
  }, onError: (error) {
    onComplete(null, error);
  });
}

uploadFiles(List filePaths, {onComplete, onError}) async {
  List fileUrls = List();

  bool connected = await isConnected();

  if (!connected) {
    onError("No internet access. Please check your internet connection");
    return;
  }

  for (int i = 0; i < filePaths.length; i++) {
    BaseModel bm = BaseModel(items: filePaths[i]);
    int type = bm.getType();
    bool isNetwork = bm.getBoolean(IS_NETWORK_IMAGE);
    String err = "";
    print("uploading T $type N $isNetwork....");

    if (isNetwork) {
      fileUrls.add(bm.items);
      if (fileUrls.length == filePaths.length) {
        onComplete(fileUrls);
      }
      continue;
    }

    if (err.isNotEmpty) {
      onError("Error occurred while uploading videos.\n $err");
      break;
    }

    if (type == ASSET_TYPE_VIDEO) {
      File video = File(bm.getString(VIDEO_PATH));
      File thumbnail = File(bm.getString(THUMBNAIL_PATH));
      File gif = File(bm.getString(GIF_PATH));
      print("uploading vidi....");

      uploadFile(video, (url, error) {
        if (error != null) {
          err = error;
          onError("Error occurred while uploading videos.\n $error");
          return;
        }

        print("uploaded $url");
        bm.put(VIDEO_URL, url);
        bm.put(VIDEO_PATH, "");
//        fileUrls.add(bm.items);
//        if (fileUrls.length == filePaths.length) {
//          onComplete(fileUrls);
//        }

        uploadFile(thumbnail, (url, error) {
          if (error != null) {
            err = error;
            onError(
                "Error occurred while uploading videos thumbnail.\n $error");
            return;
          }
          bm.put(THUMBNAIL_URL, url);
          bm.put(THUMBNAIL_PATH, "");
          fileUrls.add(bm.items);
          if (fileUrls.length == filePaths.length) {
            onComplete(fileUrls);
          }
        });
      });
    } else {
      File image = File(bm.getString(IMAGES_PATH));
      print("uploading img....");

      uploadFile(image, (url, error) {
        if (error != null) {
          err = error;
          onError("Error occurred while uploading images.\n $error");
          return;
        }
        bm.put(IMAGE_URL, url);
        bm.put(IMAGES_PATH, "");
        fileUrls.add(bm.items);
        if (fileUrls.length == filePaths.length) {
          onComplete(fileUrls);
        }
      });
    }
  }
}

Future<bool> isConnected() async {
  var result = await (Connectivity().checkConnectivity());
  if (result == ConnectivityResult.none) {
    return Future<bool>.value(false);
  }
  return Future<bool>.value(true);
}

void showProgress(bool show, String progressId, BuildContext context,
    {String msg, bool cancellable = false, double countDown}) {
  if (!show) {
    currentProgress = progressId;
    return;
  }

  currentProgress = "";

  pushAndResult(
      context,
      progressDialog(
        progressId,
        message: msg,
        cancelable: cancellable,
      ));
}

void showMessage(context, icon, iconColor, title, message,
    {int delayInMilli = 0,
    clickYesText = "OK",
    onClicked,
    clickNoText,
    bool cancellable = false,
    double iconPadding,
    bool isIcon = true}) {
  Future.delayed(Duration(milliseconds: delayInMilli), () {
    pushAndResult(
        context,
        messageDialog(
          icon,
          iconColor,
          title,
          message,
          clickYesText,
          noText: clickNoText,
          cancellable: cancellable,
          isIcon: isIcon,
          iconPadding: iconPadding,
        ),
        result: onClicked);
  });
}

void showListDialog(
  context,
  items, {
  images,
  title,
  onClicked,
  useIcon = true,
  usePosition = true,
  useTint = false,
  int delayInMilli = 0,
}) {
  Future.delayed(Duration(milliseconds: delayInMilli), () {
    pushAndResult(
        context,
        listDialog(
          items,
          title: title,
          images: images,
          isIcon: useIcon,
          usePosition: usePosition,
          useTint: useTint,
        ),
        result: onClicked);
  });
}

bool isEmailValid(String email) {
  if (!email.contains("@") || !email.contains(".")) return false;
  return true;
}

getVideoThumbnail(String path) async {
  var appDocDir = await getApplicationDocumentsDirectory();
  final folderPath = appDocDir.path;
//  return Platform.isAndroid
//      ? await Thumbnails.getThumbnail(
//          videoFile: path, imageType: ThumbFormat.PNG, quality: 150)
//      :
  return await VideoThumbnail.thumbnailFile(
    video: path,
    //thumbnailPath: folderPath,
    thumbnailPath: (await getTemporaryDirectory()).path,
    imageFormat: ImageFormat.PNG,
    maxHeightOrWidth: 0, // the original resolution of the video
    quality: 150,
  );
}

gradientLine({double height = 4, bool reverse = false, alpha = .3}) {
  return Container(
    width: double.infinity,
    height: height,
    decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: FractionalOffset.topCenter,
            end: FractionalOffset.bottomCenter,
            colors: reverse
                ? [
                    black.withOpacity(alpha),
                    transparent,
                  ]
                : [transparent, black.withOpacity(alpha)])),
  );
}

openLink(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    print('Could not launch $url');
  }
}

void yesNoDialog(
  context,
  title,
  message,
  clickedYes, {
  bool cancellable = true,
  bool isIcon = true,
}) {
  Navigator.push(
      context,
      PageRouteBuilder(
          transitionsBuilder: transition,
          opaque: false,
          pageBuilder: (context, _, __) {
            return messageDialog(
              Icons.warning,
              red0,
              title,
              message,
              "Yes",
              noText: "No, Cancel",
              cancellable: cancellable,
              isIcon: isIcon,
            );
          })).then((_) {
    if (_ != null) {
      if (_ == true) {
        clickedYes();
      }
    }
  });
}

formatPrice(String price) {
  if (price.contains("000000")) {
    price = price.replaceAll("000000", "");
    price = "${price}M";
  } else if (price.length > 6) {
    double pr = (int.parse(price)) / 1000000;
    return "${pr.toStringAsFixed(1)}M";
  } else if (price.contains("000")) {
    price = price.replaceAll("000", "");
    price = "${price}K";
  } else if (price.length > 3) {
    double pr = (int.parse(price)) / 1000;
    return "${pr.toStringAsFixed(1)}K";
  }

  return price;
}

replyThis(
  context,
  BaseModel comment,
  onEdited,
) {
  pushAndResult(
      context, inputDialog("Reply", hint: "Write a Reply...", okText: "SEND"),
      result: (_) {
//    BaseModel model = new BaseModel();
//    model.put(MESSAGE, _);
//    model.put(ITEM_ID, comment.getString(ITEM_ID));
//    model.put(COMMENT_ID, comment.getObjectId());
//    model.saveItem(COMMENT_BASE, true);
//    Future.delayed(Duration(seconds: 1), () {
//      onEdited();
//
//      createNotification([comment.getUserId()], "replied your comment", comment,
//          ITEM_TYPE_COMMENT,
//          user: userModel, id: "${comment.getObjectId()}");
//    });
  });
}

showCommentOptions(
    context, model, onEdited, onDeleted, bool myPost, bool isReply) {
  List<String> options = List();
  if (isAdmin) options.add(model.getBoolean(HIDDEN) ? "Unhide" : "Hide");
  if (isAdmin || model.myItem()) {
    options.addAll(["Edit", "Copy", "Delete"]);
  } else if (myPost) {
    options.addAll(["Copy", "Delete"]);
  } else {
    options.addAll(["Copy"]);
  }
  pushAndResult(context, listDialog(options), result: (_) {
    if (_ == "Hide") {
      yesNoDialog(context, "Hide Comment?",
          "Are you sure you want to hide this comment?", () {
        model.put(HIDDEN, true);
        onEdited();
      });
    } else if (_ == "Unhide") {
      model.put(HIDDEN, false);
      onEdited();
    } else if (_ == "Reply") {
      replyThis(
        context,
        model,
        onEdited(),
      );
    } else if (_ == "Edit") {
      pushAndResult(
          context,
          inputDialog("Edit Comment",
              message: model.getString(MESSAGE),
              hint: "Comment...",
              okText: "UPDATE"), result: (_) {
        model.put(MESSAGE, _.toString());
        model.updateItems();
        onEdited();
      });
    } else if (_ == "Delete") {
      yesNoDialog(
          context, "Delete?", "Are you sure you want to delete this comment?",
          () {
        model.deleteItem();
        /*commentsList
            .removeWhere((bm) => bm.getObjectId() == model.getObjectId());*/
        onDeleted(model);
      });
    } else if (_ == "Copy") {
      //ClipboardManager.copyToClipBoard(model.getString(MESSAGE));
    }
  });
}

refreshUser(BaseModel model /*, BaseModel theUser*/) {
  if (model == null) return;

  Firestore.instance
      .collection(USER_BASE)
      .document(model.getString(USER_ID))
      .get()
      .then((shot) {
    BaseModel theUser = BaseModel(doc: shot);
    String name = theUser.getString(FULL_NAME);
    String image = theUser.getString(USER_IMAGE);

    if (name != model.getString(FULL_NAME) ||
        image != model.getString(USER_IMAGE)) {
      model.put(FULL_NAME, name);
      model.put(USER_IMAGE, image);
      model.updateItems();
    }
  });
}

String showAllId = "";

/*replyItem(BaseModel comment){
  return new Stack(
    children: <Widget>[
      GestureDetector(
        onLongPress: () {
          //showCommentOptions(context, comment, onEdited, onDeleted, myPost);
        },
        child: Container(
          margin: EdgeInsets.fromLTRB(80, 0, 40, 15),
          decoration: BoxDecoration(
              color: blue09, borderRadius: BorderRadius.circular(25)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      comment.getString(NAME),
                      maxLines: 1,
                      style: textStyle(true, 12, black),
                    ),
                    addSpaceWidth(5),
                    Text(
                      timeAgo.format(
                          DateTime.fromMillisecondsSinceEpoch(
                              comment.getTime()),
                          locale: "en_short"),
                      style: textStyle(false, 12, black.withOpacity(.3)),
                    ),
                  ],
                ),
                addSpace(5),
                Text(
                  comment.getString(MESSAGE),
                  style: textStyle(false, 17, black),
                ),
                isReport ? Container() : addSpace(5),
                isReport
                    ? Container()
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    stars.isEmpty
                        ? Container()
                        : Text(
                      "${stars.length}",
                      style: textStyle(
                          false, 12, blue3.withOpacity(.5)),
                    ),
                    stars.isEmpty ? Container() : addSpaceWidth(5),
                    new GestureDetector(
                      onTap: () {
                        if (starred) {
                          stars.remove(userModel.getObjectId());
                        } else {
                          stars.add(userModel.getObjectId());
                        }
                        comment.put(STARS, stars);
                        comment.updateItem();
                        onEdited();
                      },
                      child: Icon(
                        starred ? Icons.star : Icons.star_border,
                        size: 15,
                        color: starred ? blue0 : blue3.withOpacity(.5),
                      ),
                    ),
                    addSpaceWidth(20),
                    replies.isEmpty
                        ? Container()
                        : Text(
                      "${replies.length}",
                      style: textStyle(
                          false, 12, blue3.withOpacity(.5)),
                    ),
                    replies.isEmpty ? Container() : addSpaceWidth(5),
                    new GestureDetector(
                      onTap: () {},
                      child: Icon(
                        Icons.reply,
                        size: 15,
                        color: red0.withOpacity(.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      new Container(
        decoration: BoxDecoration(
          color: blue0,
          border: Border.all(width: 2, color: white),
          shape: BoxShape.circle,
        ),
        margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
        width: 40,
        height: 40,
        child: Stack(
          children: <Widget>[
            Card(
              margin: EdgeInsets.all(0),
              shape: CircleBorder(),
              clipBehavior: Clip.antiAlias,
              color: transparent,
              elevation: .5,
              child: Stack(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    color: blue0,
                    child: Center(
                        child: Icon(
                          Icons.person,
                          color: white,
                          size: 15,
                        )),
                  ),
                  CachedNetworkImage(
                    width: 40,
                    height: 40,
                    imageUrl: comment.getString(USER_IMAGE),
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ),
            !isOnline
                ? Container()
                : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: white, width: 2),
                color: red0,
              ),
            ),
          ],
        ),
      )
    ],
  );
}*/

void uploadItem(StreamController<String> uploadingController,
    String uploadingText, String successText, BaseModel model,
    {BaseModel listExtras, onComplete}) {
  List keysToUpload = model.getList(FILES_TO_UPLOAD);
  if (keysToUpload.isEmpty) {
    model.saveItem(model.getString(DATABASE_NAME), true,
        document: model.getObjectId(), onComplete: () {
      if (successText != null) {
        uploadingController.add(successText);
        Future.delayed(Duration(seconds: 2), () {
          uploadingController.add(null);
        });
      }
      if (onComplete != null) onComplete();
    });
    return;
  }

  if (uploadingText != null) uploadingController.add(uploadingText);

  String key = keysToUpload[0];
  var item = model.get(key);

  if (item is List) {
    uploadItemFiles(item, List(), (res, error) {
      if (error != null) {
        uploadItem(uploadingController, uploadingText, successText, model,
            listExtras: listExtras, onComplete: onComplete);
        return;
      }
      if (listExtras != null) {
        List ext = List.from(listExtras.getList(key));
        //List ext = List.from(extraImages);
        ext.addAll(res);
        model.put(key, ext);
      } else {
        model.put(key, res);
      }
      keysToUpload.removeAt(0);
      model.put(FILES_TO_UPLOAD, keysToUpload);
      uploadItem(uploadingController, uploadingText, successText, model,
          listExtras: listExtras, onComplete: onComplete);
    });
  } else {
    List list = List();
    list.add(item);
    uploadItemFiles(list, List(), (res, error) {
      if (error != null) {
        uploadItem(uploadingController, uploadingText, successText, model,
            listExtras: listExtras, onComplete: onComplete);
        return;
      }
      List urls = res;
      model.put(key, urls[0].toString());
      keysToUpload.removeAt(0);
      model.put(FILES_TO_UPLOAD, keysToUpload);
      uploadItem(uploadingController, uploadingText, successText, model,
          listExtras: listExtras, onComplete: onComplete);
    });
  }
}

uploadItemFiles(List files, List urls, onComplete) {
  if (files.isEmpty) {
    onComplete(urls, null);
    return;
  }
  var item = files[0];
  var file = item is String ? File(item) : item;
  uploadFile(file, (res, error) {
    if (error != null) {
      onComplete(null, error);
      return;
    }

    files.removeAt(0);
    urls.add(res.toString());
    uploadItemFiles(files, urls, onComplete);
  });
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> getLocalFile(String name) async {
  final path = await _localPath;
  return File('$path/$name');
}

Future<File> getDirFile(String name) async {
  final dir = await getExternalStorageDirectory();
  var testDir = await Directory("${dir.path}/Maugost").create(recursive: true);
  return File("${testDir.path}/$name");
}

String formatDuration(Duration position) {
  final ms = position.inMilliseconds;

  int seconds = ms ~/ 1000;
  final int hours = seconds ~/ 3600;
  seconds = seconds % 3600;
  var minutes = seconds ~/ 60;
  seconds = seconds % 60;

  final hoursString = hours >= 10 ? '$hours' : hours == 0 ? '00' : '0$hours';

  final minutesString =
      minutes >= 10 ? '$minutes' : minutes == 0 ? '00' : '0$minutes';

  final secondsString =
      seconds >= 10 ? '$seconds' : seconds == 0 ? '00' : '0$seconds';

  final formattedTime =
      '${hoursString == '00' ? '' : hoursString + ':'}$minutesString:$secondsString';

  return formattedTime;
}

int getPositionForLetter(String text) {
  return az.indexOf(text.toUpperCase());
}

String az = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
String getLetterForPosition(int position) {
  return az.substring(position, position + 1);
}

String convertListToString(String divider, List list) {
  StringBuffer sb = new StringBuffer();
  for (int i = 0; i < list.length; i++) {
    String s = list[i];
    sb.write(s);
    sb.write(" ");
    if (i != list.length - 1) sb.write(divider);
    sb.write(" ");
  }

  return sb.toString().trim();
}

List<String> convertStringToList(String divider, String text) {
  List<String> list = new List();
  var parts = text.split(divider);
  for (String s in parts) {
    list.add(s.trim());
  }
  return list;
}

moreButton(String text, onTapped) {
  return new Container(
    height: 22,
    width: 70,
    child: new FlatButton(
        padding: EdgeInsets.all(0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: black.withOpacity(.1), width: 1)),
        color: blue09,
        onPressed: onTapped,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            //addSpaceWidth(10),
            Text(
              text,
              style: textStyle(true, 10, black.withOpacity(.5)),
              maxLines: 1,
            ),
            //addSpaceWidth(10),
          ],
        )),
  );
}

createReport(context, BaseModel theModel, int type) {
  pushAndResult(
      context,
      inputDialog("Report",
          hint: "Please tell us what's wrong...",
          okText: "REPORT"), result: (_) {
    BaseModel report = BaseModel();
    report.put(MESSAGE, _.toString());
    report.put(THE_MODEL, theModel.items);
    report.put(REPORT_TYPE, type);
    report.put(STATUS, STATUS_UNDONE);
    report.saveItem(REPORT_BASE, true);
    showMessage(
        context,
        Icons.report,
        blue0,
        "Report Sent",
        "Thank you for submitting a report, "
            "we will review this "
            "${type == ITEM_TYPE_POST ? "post" : type == ITEM_TYPE_LIBRARY ? "document" : type == ITEM_TYPE_MARKET ? "advert" : type == ITEM_TYPE_PROFILE ? "user" : type == ITEM_TYPE_GROUP ? "group" : "headline"} and take neccessary actions",
        cancellable: true,
        delayInMilli: 200);
  });
}

bool hasEventEnded(BaseModel model) {
  var end = model.getInt(EVENT_END_DATE);
  return end < DateTime.now().millisecondsSinceEpoch;
}

List<EventType> eventTypes = [
  EventType(
      eventTitle: "Activities",
      eventDescription: "Create an event centered around physical"
          " activities such as working out, hiking, bike riding,"
          " sports, nature walks, etc....",
      eventType: 1,
      useColor: false,
      assetImage: activities),
  EventType(
      eventTitle: "Community Service",
      eventDescription:
          "Create an event focused on serving your local community"
          " such as feeding the homeless, volunteering at a youth"
          " event, cleaning a park, planting a community garden, "
          "volunteering at a senior assisted living home etc....",
      eventType: 2,
      useColor: true,
      assetImage: community_service),
  EventType(
      eventTitle: "Bible Study/Prayer Group",
      eventDescription:
          "Create an event to come together and study the Word of God "
          "or join in prayer on a conference call or video chat, at"
          " a local coffee shop, church, library etc. RESTRICTION: "
          "No in home bible study (events must be at a public place)",
      eventType: 3,
      useColor: false,
      assetImage: bible_study),
  EventType(
      eventTitle: "Hangouts",
      eventDescription:
          "Create an event to hang out with and meet other believers."
          " Includes events you've discovered or created such as open "
          "mic night, movies, restaurants, painting/pottery, sporting "
          "event, concerts, festivals etc...",
      eventType: 4,
      useColor: true,
      assetImage: hangout),
  EventType(
      eventTitle: "Business",
      eventDescription:
          "Are you organizing an event for your business such as a siminar, "
          "workshop, pop up shop, book release, marketing event etc.?"
          " Create that event here",
      eventType: 5,
      useColor: false,
      assetImage: promotion),
  EventType(
      eventTitle: "Conference",
      eventDescription:
          "Are you organizing a conference, retreat, revival or similar event? "
          "Create that event here.",
      eventType: 5,
      useColor: false,
      assetImage: conference),
];

class EventType {
  String eventTitle;
  String eventDescription;
  String assetImage;
  bool useColor;
  int eventType;

  EventType(
      {@required this.eventTitle,
      @required this.eventDescription,
      @required this.assetImage,
      @required this.useColor,
      @required this.eventType});
}

List months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

eventItem(BuildContext context, BaseModel model,
    {onPressed,
    onLongPressed,
    onOptionPressed,
    bool admin = false,
    bool search = false,
    onApproved,
    onDeclined,
    onProfileClicked,
    optionClicked}) {
  List eventData = model.getList(EVENT_DATA);
  var startDate =
      DateTime.fromMillisecondsSinceEpoch(model.getInt(EVENT_START_DATE));
  var startTime =
      DateTime.fromMillisecondsSinceEpoch(model.getInt(EVENT_START_TIME));
  var timeOfEvent = TimeOfDay.fromDateTime(startTime);

  bool myEvent = model.getUId() == userModel.getUId();
  bool isSponsored = model.getBoolean(IS_SPONSORED);
  BaseModel owner = BaseModel(items: model.getOwner());
  String webAddress = model.getString(EVENT_WEB_ADDRESS);

  int status = model.getInt(STATUS);
  final formatter = NumberFormat("#,###");

  String statusText = status == PENDING
      ? "PENDING APPROVAL"
      : status == APPROVED
          ? "ACTIVE"
          : status == REJECTED
              ? "REJECTED"
              : status == INACTIVE
                  ? "INACTIVE"
                  : status == COMPLETED ? "COMPLETED" : "DISAPPROVED";

  return GestureDetector(
    onTap: onPressed,
    onLongPress: () {
      onLongPressed(myEvent);
    },
    child: Container(
      margin: EdgeInsets.all(10),
      decoration:
          BoxDecoration(color: white, border: Border.all(color: light_grey)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!search)
            Stack(
              children: <Widget>[
                CachedNetworkImage(
                  imageUrl: eventData[0][IMAGE_URL],
                  height: 250,
                  width: screenW(context),
                  alignment: Alignment.topCenter,
                  fit: BoxFit.cover,
                  errorWidget: (_, s, o) {
                    return Container(
                      //height: 250,
                      color: APP_COLOR,
                      child: Center(
                          child: Icon(
                        Icons.refresh,
                        color: white,
                        size: 15,
                      )),
                    );
                  },
                  placeholder: (_, s) {
                    return Container(
                      //height: 300,
                      color: APP_COLOR,
                    );
                  },
                ),
                Container(
                  height: 250,
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                            child: Text(
                          model.getString(LOCATION),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle(true, 14, white),
                        )),
                        Container(
                          height: 45,
                          width: 45,
                          padding: EdgeInsets.all(8),
                          child: Image.asset(
                            eventTypes[model.getInt(EVENT_INDEX)].assetImage,
                            height: 15,
                            width: 15,
                            color:
                                eventTypes[model.getInt(EVENT_INDEX)].useColor
                                    ? white
                                    : null,
                            //color: white,
                          ),
                          decoration: BoxDecoration(
                              color: white.withOpacity(.5),
                              shape: BoxShape.circle),
                        ),
                      ],
                    ),
                  ),
                  decoration: BoxDecoration(
                      color: APP_COLOR,
                      //color: Colors.black.withOpacity(0.9),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.9)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        //stops: [0.1, 0.1]
                      )),
                ),
                if (model.getBoolean(IS_SPONSORED))
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: gray_light.withOpacity(.5),
                              borderRadius: BorderRadius.circular(12)),
                          child: new Text(
                            "🔥 Sponsored Event",
                            style: textStyle(false, 12, black),
                          ),
                        )),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: white,
                      ),
                      onPressed: () {
                        optionClicked(model);
                      }),
                ),
              ],
            ),
//          RaisedButton(
//            onPressed: () {},
//            color: red0,
//            child: Row(
//              mainAxisAlignment: MainAxisAlignment.spaceBetween,
//              children: <Widget>[
//                Text(
//                  "LEARN MORE",
//                  style: textStyle(false, 14, white),
//                ),
//                Icon(
//                  Icons.navigate_next,
//                  color: white,
//                )
//              ],
//            ),
//          ),
//          if (myEvent)
//          Container(
//            //height: 40,
//            padding: EdgeInsets.all(10),
//            alignment: Alignment.centerLeft,
//            child: Text(
//              "${model.getIsVerified() ? "Event has been approved and is active" : "Event is penidng approval"}",
//              style: textStyle(true, 12, white),
//            ),
//            color: model.getIsVerified() ? green_dark : red,
//          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                Container(
                  height: 50,
                  width: 50,
                  padding: EdgeInsets.all(5),
                  decoration:
                      BoxDecoration(color: light_grey, shape: BoxShape.circle),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        months[startDate.month - 1],
                        style: textStyle(true, 16, APP_COLOR),
                      ),
                      Text(
                        '${startDate.day}',
                        style: textStyle(true, 14, black),
                      )
                    ],
                  ),
                ),
                addSpaceWidth(10),
                Flexible(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '(${timeOfEvent.format(context)}) ${model.getString(EVENT_TITLE)}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: textStyle(true, 16, black),
                    ),
                    addSpace(5),
                    Text(
                      model.getString(EVENT_DETAILS),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: textStyle(false, 14, black.withOpacity(.7)),
                    ),
                  ],
                ))
              ],
            ),
          ),
          if (admin) ...[
            performanceItem(context, model, admin),
            addLine(0.5, light_grey, 0, 0, 0, 8),
            if (webAddress.isNotEmpty)
              Container(
                height: 40,
                padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.vpn_lock,
                      color: APP_COLOR,
                    ),
                    addSpaceWidth(5),
                    Flexible(
                      child: SmartText(
                        text: webAddress,
                      ),
                    ),
                  ],
                ),
              ),
            InkWell(
              onTap: () {
                onProfileClicked(owner);
              },
              child: Container(
                padding: EdgeInsets.only(left: 15, right: 15),
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    imageHolder(30, owner.getImage()),
                    addSpaceWidth(10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            owner.getFullName(),
                            style: textStyle(true, 13, black),
                          ),
                          addSpace(3),
                          Text(
                            owner.getEmail(),
                            style: textStyle(false, 12, black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            addLine(0.5, light_grey, 0, 8, 0, 0),
            Row(
              children: <Widget>[
                Flexible(
                  child: RaisedButton(
                    onPressed: onApproved,
                    child: Center(
                      child: Text(
                        "APPROVE",
                        style: textStyle(false, 14, white),
                      ),
                    ),
                    color: APP_COLOR,
                  ),
                ),
                Flexible(
                  child: RaisedButton(
                    onPressed: onDeclined,
                    child: Center(
                      child: Text(
                        "DECLINE",
                        style: textStyle(false, 14, white),
                      ),
                    ),
                    color: warm_grey,
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    ),
  );
}

performanceItem(BuildContext context, BaseModel model, bool admin) {
  int status = model.getInt(STATUS);
  bool paid = model.getBoolean(HAS_PAID);
  final formatter = NumberFormat("#,###");

  String statusText = status == PENDING
      ? "PENDING APPROVAL"
      : status == APPROVED
          ? "ACTIVE"
          : status == REJECTED
              ? "REJECTED"
              : status == INACTIVE
                  ? "INACTIVE"
                  : status == COMPLETED ? "COMPLETED" : "DISAPPROVED";

  return new Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
        child: Text(
          "PERFORMANCE",
          style: textStyle(false, 12, black.withOpacity(.5)),
        ),
      ),
      addLine(.5, black.withOpacity(.1), 0, 0, 0, 0),
      new Container(
        height: 40,
        padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Reach ${!admin ? "" : "Max (${model.getDouble(SPONSOR_MAX_REACH)}) Budget(${model.getDouble(SPONSOR_FEE)})"}",
              style: textStyle(false, 16, black),
            ),
            addSpaceWidth(10),
            GestureDetector(
              onTap: () {
                showMessage(context, Icons.info, blue0, "Reach",
                    "This is the number of people who saw your ad at least once. Reach is different from impressions, which may include multiple views of your ads by the same people");
              },
              child: Icon(
                Icons.info,
                size: 18,
                color: black.withOpacity(.5),
              ),
            ),
            Flexible(
              flex: 1,
              child: Container(),
            ),
            Text(
              formatter.format(model.getList(SHOWN).length),
              style: textStyle(true, 13, black),
            )
          ],
        ),
      ),
      addLine(.5, black.withOpacity(.1), 0, 0, 0, 0),
      new Container(
        height: 40,
        padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Impressions",
              style: textStyle(false, 16, black),
            ),
            addSpaceWidth(10),
            GestureDetector(
              onTap: () {
                showMessage(context, Icons.info, blue0, "Impressions",
                    "This is the total number of times your ad has been viewed by people");
              },
              child: Icon(
                Icons.info,
                size: 18,
                color: black.withOpacity(.5),
              ),
            ),
            Flexible(
              flex: 1,
              child: Container(),
            ),
            Text(
              formatter.format(model.getInt(IMPRESSIONS)),
              style: textStyle(true, 13, black),
            )
          ],
        ),
      ),
      addLine(.5, black.withOpacity(.1), 0, 0, 0, 0),
      new Container(
        height: 40,
        padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Clicks",
              style: textStyle(false, 16, black),
            ),
            /*addSpaceWidth(10),
                                      GestureDetector(
                                        onTap: (){
                                          showMessage(context, Icons.info, blue0, "Clicks", "This is the total number of times your ad has been viewed by a user");
                                        },
                                        child: Icon(
                                          Icons.info,
                                          size: 18,
                                          color: black.withOpacity(.5),
                                        ),
                                      ),*/
            Flexible(
              flex: 1,
              child: Container(),
            ),
            Text(
              formatter.format(model.getList(CLICKS).length),
              style: textStyle(true, 13, black),
            )
          ],
        ),
      ),
      addLine(.5, black.withOpacity(.1), 0, 0, 0, 0),
      new Container(
        height: 40,
        padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Status",
              style: textStyle(false, 16, black),
            ),
            Flexible(
              flex: 1,
              child: Container(),
            ),
            Text(
              statusText,
              style: textStyle(true, 13, status == PENDING ? blue0 : red0),
            )
          ],
        ),
      ),
      addLine(.5, black.withOpacity(.1), 0, 0, 0, 0),
      new Container(
        height: 40,
        padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Paid",
              style: textStyle(false, 16, black),
            ),
            Flexible(
              flex: 1,
              child: Container(),
            ),
            Text(
              "$paid".toUpperCase(),
              style: textStyle(true, 13, paid ? blue0 : red0),
            )
          ],
        ),
      ),
      addLine(20, black.withOpacity(.1), 0, 0, 0, 0),
    ],
  );
}

userItem(BaseModel user,
    {bool showAbt = false,
    bool showBtn = false,
    String acceptTxt = "ACCEPT",
    String declineTxt = "REMOVE",
    onProfileClicked,
    handleAccepted,
    handleDeclined}) {
  bool thisIsChurch = user.getIsChurch();
  return InkWell(
    onTap: onProfileClicked,
    child: Container(
      padding: EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          imageHolder(60, user.getImage(), strokeColor: black.withOpacity(.02)),
          addSpaceWidth(15),
          Flexible(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        thisIsChurch
                            ? user.getChurchName()
                            : user.getFullName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (thisIsChurch)
                        imageHolder(25, church_icon,
                            local: true,
                            localPadding: 4,
                            strokeColor: APP_COLOR),
                    ],
                  ),
                  addSpace(5),
                  if (showAbt) ...[
                    addSpace(5),
                    new Text(
                      user.getAboutUser().isEmpty
                          ? "Hey there! i am using Tree"
                          : user.getAboutUser(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle(false, 13, black.withOpacity(.5)),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            "Denomination",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold),
                          ),
                          addSpaceWidth(5),
                          Text(
                            thisIsChurch
                                ? user.getChurchDenomination()
                                : BaseModel(items: user.getChurchInfo())
                                    .getChurchDenomination(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withOpacity(.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    addSpace(5),
                    if (!thisIsChurch) ...[
                      addSpace(5),
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Image.asset(
                              church_icon,
                              height: 12,
                              width: 12,
                              color: Colors.black.withOpacity(.5),
                            ),
                            addSpaceWidth(5),
                            Text(
                              BaseModel(items: user.getChurchInfo())
                                  .getChurchName(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        //mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.black.withOpacity(.5),
                          ),
                          addSpaceWidth(5),
                          Flexible(
                            child: Text(
                              user.getChurchAddress(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showBtn) addSpace(5),
                    if (showBtn)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Flexible(
                            child: RaisedButton(
                              color: APP_COLOR,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              onPressed: handleAccepted,
                              child: Center(
                                child: Text(
                                  acceptTxt,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            child: RaisedButton(
                              //color: Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              onPressed: handleDeclined,
                              child: Center(
                                child: Text(
                                  declineTxt,
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

generalMessageItem(
    context, bool single, bool last, BaseModel model, onRemoved) {
  //String name = model.getString(NAME);
  return new Container(
    width: single ? double.infinity : 265,
    child: GestureDetector(
      onLongPress: () {
        if (isAdmin) {
          yesNoDialog(context, "Delete?",
              "Are you sure you want to delete this message?", () {
            model.deleteItem();
            onRemoved();
          });
        }
      },
      child: new Card(
          color: red03,
          elevation: .5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          margin: EdgeInsets.fromLTRB(12, 0, last ? 12 : 0, 0),
          child: Stack(
            children: <Widget>[
              new Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.new_releases,
                          size: 14,
                          color: white,
                        ),
                        addSpaceWidth(5),
                        GestureDetector(
                          onTap: () {
                            if (model.getBoolean(BY_ADMIN)) return;
//                            pushAndResult(
//                                context, ProfileMain(model.getString(USER_ID)));
                          },
                          child: Text(
                            //"General Message",
                            model.getBoolean(BY_ADMIN)
                                ? "General Message"
                                : model.getString(FULL_NAME),
                            style: textStyle(true, 12, white.withOpacity(.5)),
                          ),
                        ),
                        addSpaceWidth(5),
                        Flexible(
                          child: Text(
                            timeAgo.format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  model.getTime(),
                                ),
                                locale: "en_short"),
//                          maxLines: 1,
//                          overflow: TextOverflow.ellipsis,
                            style: textStyle(false, 12, white.withOpacity(.5)),
                          ),
                        ),
                        addSpace(15),
                      ],
                    ),
                    addSpace(5),
                    single
                        ? Text(
                            model.getString(MESSAGE),
                            style: textStyle(false, 16, white),
                          )
                        : Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showMessage(
                                    context,
                                    Icons.new_releases,
                                    blue0,
                                    "General Message",
                                    model.getString(MESSAGE));
                              },
                              child: Text(
                                model.getString(MESSAGE),
                                style: textStyle(false, 16, white),
                                overflow: TextOverflow.ellipsis,
                                maxLines: model.getString(ACTION_TEXT).isEmpty
                                    ? 3
                                    : 2,
                              ),
                            ),
                          ),
                    model.getString(ACTION_TEXT).isEmpty
                        ? Container()
                        : GestureDetector(
                            onTap: () {
                              openLink(model.getString(ACTION_LINK));
                            },
                            child: Container(
                              margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                              decoration: BoxDecoration(
                                  color: white,
                                  borderRadius: BorderRadius.circular(3)),
                              child: Text(
                                model.getString(ACTION_TEXT),
                                style: textStyle(true, 9, blue0),
                              ),
                            )),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () {
                    List readItems = userModel.getList(READ_ITEMS);
                    readItems.add(model.getObjectId());
                    userModel.put(READ_ITEMS, readItems);
                    userModel.updateItems();
                    onRemoved();
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    child: Center(
                        child: Icon(
                      Icons.close,
                      color: white.withOpacity(.5),
                      size: 14,
                    )),
                  ),
                ),
              )
            ],
          )),
    ),
  );
}

tipMessageItem(String title, String message, {Color color = red03}) {
  return Container(
    //width: 300,
    //height: 300,
    child: new Card(
        color: color,
        elevation: .5,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: new Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.info,
                    size: 14,
                    color: white,
                  ),
                  addSpaceWidth(5),
                  Text(
                    title,
                    style: textStyle(true, 12, white.withOpacity(.5)),
                  ),
                ],
              ),
              addSpace(5),
              Text(
                message,
                style: textStyle(false, 16, white),
                //overflow: TextOverflow.ellipsis,
              ),
              /*Container(
                margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                decoration: BoxDecoration(
                    color: white, borderRadius: BorderRadius.circular(3)),
                child: Text(
                  "APPLY",
                  style: textStyle(true, 9, black),
                ),
              ),*/
            ],
          ),
        )),
  );
}

niceButton(double width, text, click, image,
    {bool isIcon = false, bool selected = false}) {
  return new Container(
    width: width,
    child: new FlatButton(
        padding: EdgeInsets.all(0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: blue0, width: 1),
            borderRadius: BorderRadius.circular(25)),
        color: selected ? blue0 : transparent,
        onPressed: click,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            addSpaceWidth(15),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Text(
                text,
                style: textStyle(true, 12, selected ? white : blue0),
                maxLines: 1,
              ),
            ),
            addSpaceWidth(10),
            new Container(
                margin: EdgeInsets.fromLTRB(0, 0, 15, 0),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                    color: selected ? white : blue0, shape: BoxShape.circle),
                child: Center(
                    child: !isIcon
                        ? Image.asset(
                            image,
                            width: 12,
                            height: 12,
                            color: selected ? blue0 : white,
                          )
                        : Icon(
                            image,
                            color: selected ? blue0 : white,
                            size: 12,
                          ))),
          ],
        )),
  );
}

clickOnAd(context, BaseModel model) {
  List<String> clicks = List.from(model.getList(CLICKS));

  String action = model.getString(ACTION_TEXT);
  if (action != CONTACT_US) {
    model.putInList(CLICKS, userModel.getObjectId(), true);
    model.updateItems();

    openLink(model.getString(ACTION_LINK));

    /*if (!clicks.contains(userModel.getObjectId())) {
      clicks.add(userModel.getObjectId());
      model.put(CLICKS, clicks);
      model.updateListWithMyId(CLICKS, true);
    }*/
  } else {
    List<String> options = List();
    List optionsIcons = List();
    String phone = model.getString(CONTACT_PHONE);
    String email = model.getString(CONTACT_EMAIL);
    String whats = model.getString(CONTACT_WHATS);
    whats = whats.replaceAll("+", "");

    if (phone.isNotEmpty) {
      options.add("Call Now");
      optionsIcons.add(Icons.call);
    }
    if (email.isNotEmpty) {
      options.add("Send Email");
      optionsIcons.add(Icons.email);
    }
    if (whats.isNotEmpty) {
      options.add("Chat on Whatsapp");
      optionsIcons.add(Icons.chat_bubble);
    }

    pushAndResult(
        context,
        listDialog(
          options,
          images: optionsIcons,
          isIcon: true,
          title: "Contact Us",
        ), result: (_) {
      if (_ == "Call Now") {
        openLink("tel://$phone");
      }
      if (_ == "Send Email") {
        openLink(
            "mailto:$email?subject=${model.getString(ITEM_NAME)}&body=${"Hi, i am interested in your ad i saw on Maugost App"}");
      }
      if (_ == "Chat on Whatsapp") {
        openLink(
            "https://wa.me/$whats?text=${"Hi, i am interested in your ad \"${model.getString(ITEM_NAME)}\" i saw on Maugost App"}");
      }

      model.putInList(CLICKS, userModel.getObjectId(), true);
      model.updateItems();
      /*if (!clicks.contains(userModel.getObjectId())) {
        clicks.add(userModel.getObjectId());
        model.put(CLICKS, clicks);
        model.updateListWithMyId(CLICKS, true);
      }*/
    });
  }
}

placeCall(String phone) {
  openLink("tel://$phone");
}

sendEmail(String email, {String subject = ""}) {
  openLink("mailto:$email?subject=$subject");
}

//List<BaseModel> levelList = List();

smallButton(icon, text, clicked) {
  return new Container(
    height: 40,
    child: new FlatButton(
        padding: EdgeInsets.all(0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        color: blue09,
        onPressed: clicked,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            addSpaceWidth(10),
            Center(
                child: Icon(
              icon,
              color: blue0,
              size: 14,
            )),
            addSpaceWidth(5),
            Text(
              text,
              style: textStyle(true, 12, blue0),
              maxLines: 1,
            ),
            addSpaceWidth(12),
          ],
        )),
  );
}

pickCountry(context, onPicked) {
  showDialog(
      context: context,
      builder: (c) {
        return CountryPickerDialog(
          title:
              /*Text(
                                      "Select Country",textAlign: ,
                                      style: textStyle(true, 15, black),
                                    )*/
              Container(),
          contentPadding: EdgeInsets.all(0),
          titlePadding: EdgeInsets.all(0),
          searchCursorColor: blue0,
          isSearchable: true,
          searchInputDecoration: InputDecoration(
              hintText: "Search country",
              hintStyle: textStyle(false, 17, black.withOpacity(.3))),
          onValuePicked: (country) {
            onPicked(country);
          },
          itemBuilder: (country) {
            return Container(
                child: Row(children: [
              CountryPickerUtils.getDefaultFlagImage(country),
              addSpaceWidth(8),
              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: Text(country.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle(false, 16, black)),
              ),
              addSpaceWidth(8),
              Container(
                padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                decoration: BoxDecoration(
                    color: blue09,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: black.withOpacity(.1), width: 1)),
                child: Text(
                  "+${country.phoneCode}",
                  style: textStyle(true, 10, black.withOpacity(.5)),
                ),
              )
            ]));
          },
        );
      });
}

List<String> getSearchString(String text) {
  text = text.toLowerCase().trim();
  if (text.isEmpty) return List();

  List<String> list = List();
  list.add(text);
  var parts = text.split(" ");
  for (String s in parts) {
    if (s.isNotEmpty) list.add(s);
    for (int i = 0; i < s.length; i++) {
      String sub = s.substring(0, i);
      if (sub.isNotEmpty) list.add(sub);
    }
  }
  for (int i = 0; i < text.length; i++) {
    String sub = text.substring(0, i);
    if (sub.isNotEmpty) list.add(sub.trim());
  }
  return list;
}

filterItem(
    bool selected, image, double iconSize, String text, onTapped, onRemoved,
    {bool isIcon = false, bool useTint = true}) {
  return Container(
    height: 30,
    color: selected ? white : blue2,
    child: InkWell(
      onTap: onTapped,
      child: Container(
        height: 30,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            addSpaceWidth(10),
            isIcon
                ? Icon(
                    image,
                    size: iconSize,
                    color: !useTint ? null : selected ? blue1 : white,
                  )
                : Image.asset(
                    image,
                    color: !useTint ? null : selected ? blue1 : white,
                    width: iconSize,
                    height: iconSize,
                  ),
            addSpaceWidth(5),
            Text(
              text,
              style: textStyle(false, 14, selected ? blue1 : white),
            ),
            addSpaceWidth(10),
            !selected
                ? Container()
                : InkWell(
                    onTap: onRemoved,
                    child: Container(
                      width: 30,
                      height: 30,
                      //margin: EdgeInsets.fromLTRB(6, 0, 0, 0),
                      color: blue09,
                      child: Center(
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: black.withOpacity(.5),
                        ),
                      ),
                    ),
                  )
          ],
        ),
      ),
    ),
  );
}

rateApp() {
  String packageName = appSettingsModel.getString(PACKAGE_NAME);
  if (packageName.isEmpty) return;

  userModel.put(HAS_RATED, true);
  userModel.updateItems();
  String link = "http://play.google.com/store/apps/details?id=$packageName";
  openLink(link);
}

var schoolOptions = [
  "Change Type",
  "Approve School",
  "Delete School",
  "Update Name",
  "Update Phone",
  "Update Email",
  "Update Location",
  "Update Abbr"
];

label(icon, String text, double iconSize,
    {bool isIcon = true, bool showLine = true}) {
  if (text.isEmpty) return Container();
  return Container(
    //height: 30,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: blue09,
                  shape: BoxShape.circle,
                  border: Border.all(color: black.withOpacity(.1), width: .5)),
              child: Center(
                child: isIcon
                    ? Icon(icon, size: iconSize, color: black.withOpacity(.5))
                    : Image.asset(
                        icon,
                        width: iconSize,
                        height: iconSize,
                        color: black.withOpacity(.5),
                      ),
              ),
            ),
            addSpaceWidth(5),
            Flexible(
              child: Text(
                text,
                style: textStyle(false, 12, black.withOpacity(.4)),
              ),
            )
          ],
        ),
        !showLine
            ? Container()
            : addLine(.5, black.withOpacity(.1), 25, 0, 0, 0),
      ],
    ),
  );
}

clickChat(context, BaseModel theUser, bool isGroup) {
  String chatID = chatExists(theUser, isGroup);

  print(chatID);
  //return;
  if (chatID != null) {
    /*popUpWidgetAndDisposeCurrent(
      context,
      ChatMain(
        chatID,
        isGroup: isGroup,
      ),
    );*/
  } else {
    createChat(context, theUser, isGroup);
  }
}

BaseModel createChatModel(String chatId, BaseModel model, bool isGroup) {
  BaseModel myModel = new BaseModel();
  myModel.put(OBJECT_ID, chatId);
  myModel.put(CHAT_ID, chatId);
  myModel.put(USER_ID, model.getObjectId());
  myModel.put(IMAGE, model.getImage());
  if (isGroup) {
    myModel.put(GROUP_NAME, model.getString(GROUP_NAME));
    myModel.put(GROUP_IMAGE, model.getString(GROUP_IMAGE));
    myModel.put(GROUP_MEMBERS, model.getList(GROUP_MEMBERS));
    myModel.put(IS_CONVERSATION, model.getBoolean(IS_CONVERSATION));
    myModel.put(IS_ROOM, model.getBoolean(IS_ROOM));
    myModel.put(IS_GROUP, model.getBoolean(IS_GROUP));
    myModel.put(IS_TREE, model.getBoolean(IS_TREE));
  } else {
    myModel.put(FULL_NAME, model.getString(FULL_NAME));
    myModel.put(USER_IMAGE, model.getString(USER_IMAGE));
  }
  return myModel;
}

BaseModel createGroupModel(BaseModel theUser, bool isAdmin) {
  BaseModel bm = new BaseModel();
  bm.put(OBJECT_ID, theUser.getObjectId());
  bm.put(USER_ID, theUser.getUId());
  bm.put(GROUP_ADMIN, isAdmin);
  bm.put(FULL_NAME, theUser.getFullName());
  bm.put(IMAGE, theUser.getImage());
  bm.put(TOKEN_ID, theUser.getToken());
  return bm;
}

String chatExists(BaseModel theUser, bool isGroup) {
  int existing = 0;
  String theId;
  String theUserId = theUser.getObjectId();
  List<Map> myChats = List.from(userModel.getList(MY_CHATS));
  List<Map> hisChat = List.from(theUser.getList(MY_CHATS));

  for (Map chat in myChats) {
    BaseModel bm = new BaseModel(items: chat);
    String chatId = bm.getString(CHAT_ID);
    if (chatId.contains(theUserId)) {
      existing++;
      theId = chatId;
      break;
    }
  }
  if (isGroup) {
    return existing != 1 ? null : theId;
  }

  for (Map chat in hisChat) {
    BaseModel bm = new BaseModel(items: chat);
    String chatId = bm.getString(CHAT_ID);
    if (chatId.contains(userModel.getUserId())) {
      existing++;
      theId = chatId;
      break;
    }
  }
  return existing != 2 ? null : theId;
}

createChat(context, BaseModel theUser, bool isGroup) {
  String chatId = "";
  if (isGroup) {
    chatId = theUser.getObjectId();
  } else {
    List<String> ids = [theUser.getUserId(), userModel.getUserId()];
    ids.sort((s1, s2) => s1.compareTo(s2));
    chatId = "${ids[0]}${ids[1]}";
  }

  BaseModel myModel = createChatModel(chatId, theUser, isGroup);
  List<Map> myChats = List.from(userModel.getList(MY_CHATS));
  myChats.add(myModel.items);
  userModel.put(MY_CHATS, myChats);
  userModel.updateItems();

  if (!isGroup) {
    BaseModel hisModel = createChatModel(chatId, userModel, isGroup);
    List<Map> hisChat = List.from(theUser.getList(MY_CHATS));
    hisChat.add(hisModel.items);
    theUser.put(MY_CHATS, hisChat);
    theUser.updateItems(updateTime: false);
  }

  /*popUpWidgetAndDisposeCurrent(
    context,
    ChatMain(
      chatId,
      isGroup: isGroup,
    ),
  );*/
}

bool isSameDay(int time1, int time2) {
  DateTime date1 = DateTime.fromMillisecondsSinceEpoch(time1);

  DateTime date2 = DateTime.fromMillisecondsSinceEpoch(time2);

  return (date1.day == date2.day) &&
      (date1.month == date2.month) &&
      (date1.year == date2.year);
}

incomingChatDeleted(context, BaseModel chat) {
  if (chat.getList(HIDDEN).contains(userModel.getObjectId())) {
    return Container();
  }
  return new Stack(
    children: <Widget>[
      GestureDetector(
        onLongPress: () {
          showChatOptions(context, chat, deletedChat: true);
        },
        child: new Opacity(
          opacity: .4,
          child: new Container(
            margin: EdgeInsets.fromLTRB(40, 0, 60, 15),
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            decoration: BoxDecoration(
                color: default_white, borderRadius: BorderRadius.circular(25)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Message Deleted",
                      style: textStyle(false, 15, black),
                    ),
                    addSpaceWidth(5),
                    Icon(
                      Icons.info,
                      color: red0,
                      size: 17,
                    )
                  ],
                ),
                addSpace(3),
                Text(
                  /*timeAgo.format(
                        DateTime.fromMillisecondsSinceEpoch(
                            chat.getTime()),
                        locale: "en_short")*/
                  getChatTime(chat.getInt(TIME)),
                  style: textStyle(false, 12, black.withOpacity(.3)),
                ),
              ],
            ),
          ),
        ),
      ),
      userImageItem(context, chat)
    ],
  );
}

String getExtImage(String fileExtension) {
  if (fileExtension == null) return "";
  fileExtension = fileExtension.toLowerCase().trim();
  if (fileExtension.contains("doc")) {
    return icon_file_doc;
  } else if (fileExtension.contains("pdf")) {
    return icon_file_pdf;
  } else if (fileExtension.contains("xls")) {
    return icon_file_xls;
  } else if (fileExtension.contains("ppt")) {
    return icon_file_ppt;
  } else if (fileExtension.contains("txt")) {
    return icon_file_text;
  } else if (fileExtension.contains("zip")) {
    return icon_file_zip;
  } else if (fileExtension.contains("xml")) {
    return icon_file_xml;
  } else if (fileExtension.contains("png") ||
      fileExtension.contains("jpg") ||
      fileExtension.contains("jpeg")) {
    return icon_file_photo;
  } else if (fileExtension.contains("mp4") ||
      fileExtension.contains("3gp") ||
      fileExtension.contains("mpeg") ||
      fileExtension.contains("avi")) {
    return icon_file_video;
  } else if (fileExtension.contains("mp3") ||
      fileExtension.contains("m4a") ||
      fileExtension.contains("m4p")) {
    return icon_file_audio;
  }

  return icon_file_unknown;
}

userImageItem(context, BaseModel model) {
  return new GestureDetector(
    onTap: () {
      //pushAndResult(context, ProfileMain(model.getString(USER_ID)));
    },
    child: new Container(
      decoration: BoxDecoration(
        color: blue0,
        border: Border.all(width: 2, color: white),
        shape: BoxShape.circle,
      ),
      margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
      width: 40,
      height: 40,
      child: Stack(
        children: <Widget>[
          Card(
            margin: EdgeInsets.all(0),
            shape: CircleBorder(),
            clipBehavior: Clip.antiAlias,
            color: transparent,
            elevation: .5,
            child: Stack(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  color: blue0,
                  child: Center(
                      child: Icon(
                    Icons.person,
                    color: white,
                    size: 15,
                  )),
                ),
                CachedNetworkImage(
                  width: 40,
                  height: 40,
                  imageUrl: model.getImage(),
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
          /*!isOnline
                        ? Container()
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: white, width: 2),
                              color: red0,
                            ),
                          ),*/
        ],
      ),
    ),
  );
}

String getChatDate(int milli) {
  final formatter = DateFormat("MMM d 'AT' h:mm a");
  DateTime date = DateTime.fromMillisecondsSinceEpoch(milli);
  return formatter.format(date);
}

String getChatTime(int milli) {
  final formatter = DateFormat("h:mm a");
  DateTime date = DateTime.fromMillisecondsSinceEpoch(milli);
  return formatter.format(date);
}

String getTimeAgo(int milli) {
  return timeAgo.format(DateTime.fromMillisecondsSinceEpoch(milli));
}

saveChatFile(BaseModel model, String pathKey, String urlKey, onSaved) {
  upOrDown.add(model.getObjectId());
  String path = model.getString(pathKey);
  uploadFile(File(path), (_, error) {
    upOrDown.removeWhere((s) => s == model.getObjectId());
    if (error != null) {
      return;
    }
    model.put(urlKey, _);
    model.updateItems();
    onSaved();
  });
}

saveChatVideo(BaseModel model, onSaved) {
  String thumb = model.getString(THUMBNAIL_PATH);
  String videoPath = model.getString(VIDEO_PATH);
  String thumbUrl = model.getString(THUMBNAIL_URL);
  String videoUrl = model.getString(VIDEO_URL);

  bool uploadingThumb = thumbUrl.isEmpty;

  if (videoUrl.isNotEmpty) {
    onSaved();
    return;
  }

  upOrDown.add(model.getObjectId());

  uploadFile(File(uploadingThumb ? thumb : videoPath), (_, error) {
    upOrDown.removeWhere((s) => s == model.getObjectId());
    if (error != null) {
      return;
    }
    model.put(uploadingThumb ? THUMBNAIL_URL : VIDEO_URL, _);
    model.updateItems();
    saveChatVideo(model, onSaved);
  });
}

downloadChatFile(BaseModel model, onComplete) async {
  String fileName = "${model.getObjectId()}.${model.getString(FILE_EXTENSION)}";
  File file = await getDirFile(fileName);
  //upOrDown.add(model.getObjectId());
  onComplete();

  QuerySnapshot shots = await Firestore.instance
      .collection(REFERENCE_BASE)
      .where(FILE_URL, isEqualTo: model.getString(FILE_URL))
      .limit(1)
      .getDocuments();
  if (shots.documents.isEmpty) {
    //upOrDown.removeWhere((s) => s == model.getObjectId());
    onComplete();
  } else {
    for (DocumentSnapshot doc in shots.documents) {
      if (!doc.exists || doc.data.isEmpty) continue;
      BaseModel model = BaseModel(doc: doc);
      String ref = model.getString(REFERENCE);
      StorageReference storageReference =
          FirebaseStorage.instance.ref().child(ref);
      storageReference.writeToFile(file).future.then((_) {
        //toastInAndroid("Download Complete");
        //upOrDown.removeWhere((s) => s == model.getObjectId());
        onComplete();
      }, onError: (error) {
        //upOrDown.removeWhere((s) => s == model.getObjectId());
        onComplete();
      }).catchError((error) {
        //upOrDown.removeWhere((s) => s == model.getObjectId());
        onComplete();
      });

      break;
    }
  }
}

showChatOptions(context, BaseModel chat, {bool deletedChat = false}) {
  int type = chat.getInt(TYPE);
  pushAndResult(
      context,
      listDialog(type == CHAT_TYPE_TEXT && !deletedChat
          ? ["Copy", "Delete"]
          : ["Delete"]), result: (_) {
    if (_ == "Copy") {
      Clipboard.setData(new ClipboardData(text: chat.getString(MESSAGE)));
    }
    if (_ == "Delete") {
      if (chat.myItem()) {
        chat.put(DELETED, true);
        chat.updateItems();
      } else {
        List hidden = List.from(chat.getList(HIDDEN));
        hidden.add(userModel.getObjectId());
        chat.put(HIDDEN, hidden);
        chat.updateItems();
      }
    }
  });
}

tabIndicator(int tabCount, int currentPosition, {margin}) {
  return Container(
    padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
    margin: margin,
    decoration: BoxDecoration(
        color: black.withOpacity(.7), borderRadius: BorderRadius.circular(25)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: getTabs(tabCount, currentPosition),
    ),
  );
}

getTabs(int count, int cp) {
  List<Widget> items = List();
  for (int i = 0; i < count; i++) {
    bool selected = i == cp;
    items.add(Container(
      width: selected ? 10 : 8,
      height: selected ? 10 : 8,
      //margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
      decoration: BoxDecoration(
          color: white.withOpacity(selected ? 1 : (.5)),
          shape: BoxShape.circle),
    ));
    if (i != count - 1) items.add(addSpaceWidth(5));
  }

  return items;
}

stackImagesHolder(List<BaseModel> members,
    {leftPadding = 5,
    double holderSize = 30,
    double boxSize = 40,
    int max = 3}) {
  return Container(
    height: boxSize,
    width: boxSize,
    child: Stack(
      children:
          List.generate(members.length > max ? 3 : members.length, (int i) {
        BaseModel model = members[i];
        double padding =
            i == 1 ? 0 : (leftPadding + i * leftPadding).roundToDouble();
        if (model.myItem()) return Container();
        return Padding(
          //padding: EdgeInsets.only(left: padding),
          padding: EdgeInsets.only(left: leftPadding + (i * 4.0)),
          child: imageHolder(
            holderSize,
            model.getImage(),
            strokeColor: orang1,
            stroke: i == 1 ? 0 : .5,
          ),
        );
      }),
    ),
  );
}

imageHolder(
  double size,
  imageUrl, {
  double stroke = 0,
  strokeColor = orang1,
  localColor = white,
  margin,
  bool local = false,
  iconHolder = Icons.person,
  double iconHolderSize = 14,
  double localPadding = 0,
  bool round = true,
  bool borderCurve = false,
  onImageTap,
}) {
  return GestureDetector(
    onTap: onImageTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderCurve ? 20 : 0),
      child: AnimatedContainer(
        curve: Curves.ease,
        margin: margin,
        alignment: Alignment.center,
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(stroke),
        decoration: BoxDecoration(
          color: strokeColor,
          //borderRadius: BorderRadius.circular(borderCurve ? 15 : 0),
          //border: Border.all(width: 2, color: white),
          shape: round ? BoxShape.circle : BoxShape.rectangle,
        ),
        width: size,
        height: size,
        child: Stack(
          children: <Widget>[
            new Card(
              margin: EdgeInsets.all(0),
              shape: round
                  ? CircleBorder()
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
              clipBehavior: Clip.antiAlias,
              color: transparent,
              elevation: .5,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: size,
                    height: size,
                    child: Center(
                        child: Icon(
                      iconHolder,
                      color: white,
                      size: iconHolderSize,
                    )),
                  ),
                  imageUrl is File
                      ? (Image.file(imageUrl))
                      : local
                          ? Padding(
                              padding: EdgeInsets.all(localPadding),
                              child: Image.asset(
                                imageUrl,
                                width: size,
                                height: size,
                                color: localColor,
                                fit: BoxFit.cover,
                              ),
                            )
                          : CachedNetworkImage(
                              width: size,
                              height: size,
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                            ),
                ],
              ),
            ),
            /*!isOnline
                              ? Container()
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: white, width: 2),
                                    color: red0,
                                  ),
                                ),*/
          ],
        ),
      ),
    ),
  );
}

String getExtToUse(String fileExtension) {
  if (fileExtension == null) return "";
  fileExtension = fileExtension.toLowerCase().trim();
  if (fileExtension.contains("doc")) {
    return "doc";
  } else if (fileExtension.contains("xls")) {
    return "xls";
  } else if (fileExtension.contains("ppt")) {
    return "ppt";
  }

  return fileExtension;
}

class RaisedGradientButton extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double width;
  final double height;
  final Function onPressed;
  final bool round;
  final bool addShadow;

  const RaisedGradientButton(
      {Key key,
      @required this.child,
      this.gradient,
      this.width = double.infinity,
      this.height = 50.0,
      this.onPressed,
      this.addShadow = true,
      this.round = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 50.0,
      decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: round ? null : BorderRadius.circular(25),
          boxShadow: !addShadow
              ? null
              : [
                  BoxShadow(
                    color: Colors.grey[500],
                    offset: Offset(0.0, 1.5),
                    blurRadius: 1.5,
                  ),
                ],
          shape: round ? BoxShape.circle : BoxShape.rectangle),
      child: Material(
        color: Colors.transparent,
        child: FlatButton(
            shape: round
                ? CircleBorder()
                : RoundedRectangleBorder(
                    borderRadius: round ? null : BorderRadius.circular(25),
                  ),
            color: Colors.transparent,
            onPressed: onPressed,
            child: Center(
              child: child,
            )),
      ),
    );
  }
}

flutToast(msg, {Color color = black}) {
//  Fluttertoast.showToast(
//      msg: msg,
//      toastLength: Toast.LENGTH_SHORT,
//      gravity: ToastGravity.BOTTOM,
//      timeInSecForIos: 1,
//      backgroundColor: color,
//      textColor: Colors.white,
//      fontSize: 16.0);
}

peopleItem1(context, BaseModel model,
    {onRemoved,
    bool showStudy = true,
    double width = 100,
    double height = 100}) {
  //BaseModel model = peopleList[position];
  return GestureDetector(
    onTap: () {
      //pushAndResult(context, ProfileMain(model.getObjectId()));
    },
    child: Container(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CachedNetworkImage(
                  imageUrl: model.getString(USER_IMAGE),
                  fit: BoxFit.cover,
                ),
                gradientLine(alpha: .7),
                new Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    //mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                      Text(
                        model.getString(FULL_NAME),
                        style: textStyle(
                          false,
                          12,
                          white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                      //addSpace(3),
                      if (showStudy)
                        Text(
                          model.getString(CHURCH_NAME),
                          style: textStyle(
                            false,
                            10,
                            white.withOpacity(.5),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      addSpace(3),
                      /*if (onFollowed != null)
                        new Container(
                          width: 60,
                          //margin: EdgeInsets.fromLTRB(5, 0, 5, 5),
                          height: 22,
                          child: FlatButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: white, width: .5)),
                            padding: EdgeInsets.all(0),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onPressed: onFollowed,
                            child: Text(
                              userModel
                                      .getList(FOLLOWING)
                                      .contains(model.getObjectId)
                                  ? "Unfollow"
                                  : "Follow",
                              style: textStyle(true, 10, white),
                            ),
                            color: black.withOpacity(.7),
                          ),
                        )*/
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onRemoved != null)
            Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    userModel.putInList(SHOWN, model.getObjectId(), true);
                    userModel.updateItems();
                    onRemoved();
                  },
                  child: new Container(
                      width: 40,
                      height: 40,
                      color: transparent,
                      //padding: EdgeInsets.all(5),
                      child: Center(
                        child: Icon(
                          Icons.cancel,
                          size: 25,
                          color: black.withOpacity(.6),
                        ),
                      )),
                )),
        ],
      ),
    ),
  );
}

peopleItem2(context, BaseModel user, {double size = 80}) {
  bool male = user.isMale();
  String image = user.getString(USER_IMAGE);

  int now = DateTime.now().millisecondsSinceEpoch;
  int lastUpdated = user.getInt(TIME_UPDATED);
  bool notOnline =
      ((now - lastUpdated) > (Duration.millisecondsPerMinute * 10));
  bool isOnline = user.getBoolean(IS_ONLINE) && (!notOnline);
  return Stack(
    children: <Widget>[
      GestureDetector(
        onTap: () {
          //pushAndResult(context, ProfileMain(user.getUserId()));
        },
        child: new Center(
          child: Card(
            elevation: 1,
            shape: CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[],
                )
              ],
            ),
          ),
        ),
      ),
      !isOnline
          ? Container()
          : Container(
              margin: EdgeInsets.fromLTRB(8, 8, 0, 0),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: white, width: 1),
                color: red0,
              ),
            ),
    ],
  );
}

smallTitle(String text,
    {buttonIcon = Icons.search, String buttonText, onButtonClicked}) {
  return Container(
    margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
    child: Row(
      children: <Widget>[
        Flexible(
          flex: 1,
          fit: FlexFit.tight,
          child: Text(
            text,
            style: textStyle(true, 14, black.withOpacity(.5)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        buttonText == null
            ? Container()
            : new Container(
                //width: 50,
                //margin: EdgeInsets.fromLTRB(5, 0, 5, 5),
                height: 25,
                child: FlatButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side:
                          BorderSide(color: black.withOpacity(.1), width: .5)),
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: onButtonClicked,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        buttonIcon,
                        size: 12,
                        color: black.withOpacity(.4),
                      ),
                      addSpaceWidth(2),
                      Text(
                        buttonText,
                        style: textStyle(true, 10, black.withOpacity(.4)),
                      ),
                    ],
                  ),
                  color: blue09,
                ),
              )
      ],
    ),
  );
}

addPeopleSection(context, List people, String title,
    {showStudy = true, onRemoved}) {
  return people.isEmpty
      ? Container()
      : new Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              addSpace(15),
              smallTitle(title),
              addSpace(5),
              new Container(
                height: 100,
                child: AnimatedList(
                  itemBuilder: (c, p, anim) {
                    return peopleItem1(context, people[p],
                        showStudy: showStudy, onRemoved: onRemoved);
                  },
                  initialItemCount: people.length,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.all(0),
                  shrinkWrap: true,
                ),
              ),
            ],
          ),
        );
}

avatarItem(String title, String image, onChanged) {
  return Column(
    children: <Widget>[
      GestureDetector(
        onTap: onChanged,
        child: image.isEmpty
            ? Container(
                height: 90,
                width: 90,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey.withOpacity(.4)),
                    shape: BoxShape.circle),
              )
            : Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    image: DecorationImage(image: FileImage(File(image))),
                    border: Border.all(color: Colors.grey.withOpacity(.4)),
                    shape: BoxShape.circle),
              ),
      ),
      addSpace(10),
      Text(
        title,
        style: textStyle(true, 12, black.withOpacity(.4)),
      ),
    ],
  );
}

inputItem(
  String title,
  //String text,
  TextEditingController controller,
  icon,
  onChanged, {
  inputType = TextInputType.text,
  bool isPass = false,
  bool isAsset = false,
  bool autofocus = false,
  String hint = "",
  int maxLines = 1,
}) {
  //TextEditingController controller = TextEditingController(text: text);
  return new Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: textStyle(true, 12, black.withOpacity(.4)),
      ),
      //addSpace(10),
      Row(
        crossAxisAlignment: maxLines != 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.fromLTRB(0, maxLines == 1 ? 0 : 15, 0, 0),
            child: isAsset
                ? Image.asset(
                    icon,
                    height: 18,
                    width: 18,
                    color: black.withOpacity(.4),
                  )
                : Icon(
                    icon,
                    size: 23,
                    color: black.withOpacity(.4),
                  ),
          ),
          addSpaceWidth(10),
          Flexible(
            child: new TextField(
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
              autofocus: autofocus,
              //maxLength: 20,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: textStyle(false, 17, black.withOpacity(.2))),
              style: textStyle(false, 20, black),
              cursorColor: black,
              cursorWidth: 1,
              maxLines: maxLines,
              keyboardType: inputType,
              //onChanged: onChanged,
              obscureText: isPass, controller: controller,
            ),
          ),
        ],
      ),
      //addSpace(10),
      addLine(1, black.withOpacity(.1), 0, 0, 0, 20)
    ],
  );
}

dropDownV(hint, value, items, onChanged, icon, {bool isAsset = false}) {
  return Container(
    padding: EdgeInsets.all(4),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            addSpaceWidth(5),
            if (isAsset)
              Image.asset(
                icon,
                height: 20,
                width: 20,
                color: Colors.black.withOpacity(.4),
              )
            else
              Icon(
                icon,
                size: 20,
                color: Colors.black.withOpacity(.4),
              ),
            addSpaceWidth(10),
            Flexible(
              child: DropdownButton(
                value: value,
                isExpanded: true,
                style: textStyle(false, 20, black),
                items: items,
                onChanged: onChanged,
                hint: Text(
                  hint,
                  style: textStyle(false, 17, black.withOpacity(.2)),
                ),
                underline: Container(),
              ),
            ),
          ],
        ),
        addLine(.5, black.withOpacity(.1), 0, 0, 0, 20)
      ],
    ),
  );
}

buttonItem(text, onPressed, {color = green_dark}) {
  return Container(
    height: 50,
    width: double.infinity,
    child: RaisedButton(
      onPressed: onPressed,
      color: color ?? APP_COLOR,
      textColor: white,
      child: Text(
        text,
        style: textStyle(true, 22, white),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    ),
  );
}

inputItemTv(String title, String text, icon, onTap, String hint,
    {isAsset = false, showSearch = false}) {
  return new Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: textStyle(false, 12, black.withOpacity(.4)),
      ),
      //addSpace(10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (isAsset)
            Image.asset(
              icon,
              height: 20,
              width: 20,
              color: Colors.black.withOpacity(.4),
            ),
          if (!isAsset)
            Icon(
              icon,
              size: 25,
              color: black.withOpacity(.4),
            ),
          addSpaceWidth(10),
          Flexible(
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 50,
                width: double.infinity,
                child: Row(
                  children: <Widget>[
                    Flexible(
                      flex: 1,
                      fit: FlexFit.tight,
                      child: Text(
                        text.isEmpty ? hint : text,
                        style: textStyle(false, 17,
                            black.withOpacity(text.isEmpty ? (.2) : 1)),
                      ),
                    ),
                    addSpaceWidth(10),
                  ],
                ),
              ),
            ),
          ),
          addSpaceWidth(10),
          if (showSearch)
            Icon(
              Icons.search,
              size: 25,
              color: black.withOpacity(.4),
            ),
        ],
      ),
      //addSpace(10),
      addLine(1, black.withOpacity(.1), 0, 0, 0, 20)
    ],
  );
}

checkBoxItemTv(bool active, onTap, String hint,
    {bool showLine = false, bool circle = true}) {
  return new Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 25,
            width: 25,
            padding: EdgeInsets.all(5),
            child: Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? APP_COLOR : Colors.transparent,
                  border: Border.all(
                      color: active ? APP_COLOR : Colors.transparent)),
            ),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                    width: 2, color: active ? APP_COLOR : Colors.grey)),
          ),
          addSpaceWidth(10),
          Flexible(
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 50,
                width: double.infinity,
                child: Row(
                  children: <Widget>[
                    Flexible(
                      flex: 1,
                      fit: FlexFit.tight,
                      child: Text(
                        hint,
                        style: TextStyle(
                            fontSize: 17,
                            color: black.withOpacity(active ? 1 : .2)),
                      ),
                    ),
                    addSpaceWidth(10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      //addSpace(10),
      if (showLine)
        addLine(1, black.withOpacity(.1), 0, 0, 0, 20)
    ],
  );
}

expandedContainer(child, {show = false}) {
  return AnimatedContainer(
    duration: Duration(milliseconds: 5),
    child: show ? child : null,
    curve: Curves.easeOut,
    //padding: EdgeInsets.all(show ? 5 : 0),
//      decoration: BoxDecoration(
//          border: Border.all(width: 0.5, color: Colors.black.withOpacity(.1)),
//          color: Colors.grey.withOpacity(.05)
//      ),
  );
}

dropDownItem(String text) {
  return DropdownMenuItem(
    child: Text(
      text,
      style: textStyle(false, 18, black),
    ),
    value: text,
  );
}

List generateSearchArray(BaseModel model) {
  String churchName = "";
  String churchAddress = "";
  String churchVicinity = "";
  String denomination = "";
  String fullName = "";
  String relationShipStatus = "";
  String city = "";
  String businessAddress = "";
  String eventTitle = "";
  String eventVenue = "";

  if (!model.getIsChurch()) {
    BaseModel m = BaseModel(items: model.getMap(CHURCH_INFO));
    churchName = m.getString(CHURCH_NAME);
    denomination = m.getString(CHURCH_DENOMINATION);
    churchAddress = m.getString(CHURCH_ADDRESS);
    churchVicinity = m.getString(CHURCH_VICINITY);
    city = model.getString(CITY);
    businessAddress = model.getString(BUSINESS_ADDRESS);
    relationShipStatus = model.getString(RELATIONSHIP_STATUS);
  }

  if (model.getIsChurch()) {
    churchName = model.getString(CHURCH_NAME);
    churchAddress = model.getString(CHURCH_ADDRESS);
    denomination = model.getString(CHURCH_DENOMINATION);
    churchVicinity = model.getString(CHURCH_VICINITY);
  }

  if (model.getType() == POST_TYPE_ADS) {
    eventTitle = model.getString(EVENT_TITLE);
    eventVenue = model.getString(LOCATION);
  }

  fullName = model.getString(FULL_NAME);

  String searchData = "$churchName $denomination $fullName "
      "$relationShipStatus $churchAddress $churchVicinity "
      "$city $businessAddress $eventTitle $eventVenue";

  List searchArray = getSearchString(searchData);
  return searchArray;
}

bool isDomainEmailValid(String email) {
  if (email.contains("aol") ||
      email.contains("gmail") ||
      email.contains("yahoo") ||
      email.contains("hotmail")) return false;
  return true;
}

getDayOfWeekInt(int d) {
  if (d == DateTime.monday) return Day.Monday;
  if (d == DateTime.tuesday) return Day.Tuesday;
  if (d == DateTime.wednesday) return Day.Wednesday;
  if (d == DateTime.thursday) return Day.Thursday;
  if (d == DateTime.friday) return Day.Friday;
  if (d == DateTime.saturday) return Day.Saturday;
  return Day.Saturday;
}

getDayOfWeek(String d) {
  if (d == "Mon") return Day.Monday;
  if (d == "Tue") return Day.Tuesday;
  if (d == "Wed") return Day.Wednesday;
  if (d == "Thur") return Day.Thursday;
  if (d == "Fri") return Day.Friday;
  if (d == "Sat") return Day.Saturday;
  return Day.Saturday;
}

bool weAreConnected(String userId) {
  List friendsMap = userModel.getConnections();
  for (var id in friendsMap) {
    //String id = map[USER_ID];
    if (userId == id) return true;
  }

  return false;
}

//Future<File> cropImage(File imageFile,
//    {bool useCircle = false, String title = "Crop Photo"}) async {
//  File croppedFile = await ImageCropper.cropImage(
//    sourcePath: imageFile.path,
//    cropStyle: useCircle ? CropStyle.circle : CropStyle.rectangle,
//    //iosUiSettings: IOSUiSettings(),
//  );
//  return croppedFile;
//}

Future<ImageInfo> getImageInfo(File imageFile) async {
  final Completer completer = Completer<ImageInfo>();
  final ImageStream stream =
      FileImage(imageFile).resolve(const ImageConfiguration());
  final listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
    if (!completer.isCompleted) {
      completer.complete(info);
    }

    print("W ${info.image.width} H ${info.image.height}");
  });
  stream.addListener(listener);

  completer.future.then((_) {
    stream.removeListener(listener);
  });
  return await completer.future;
}

Future getImagePicker(ImageSource imageSource) async {
  var image = await ImagePicker.pickImage(source: imageSource);

  return image;
}

Future getVideoPicker(ImageSource imageSource) async {
  var image = await ImagePicker.pickVideo(source: imageSource);
  return image;
}

Future<List> pickMultiImage(BuildContext context, PickType type,
    {int max = 8}) async {
  List<AssetEntity> imgList = await PhotoPicker.pickAsset(
      context: context,
      themeColor: APP_COLOR,
      padding: 3.0,
      dividerColor: Colors.grey,
      disableColor: Colors.grey.shade300,
      itemRadio: 0.9,
      maxSelected: max,
      provider: I18nProvider.english,
      rowCount: 3,
      textColor: Colors.white,
      thumbSize: 150,
      sortDelegate: SortDelegate.common,
      checkBoxBuilderDelegate: DefaultCheckBoxBuilderDelegate(
        activeColor: Colors.white,
        unselectedColor: Colors.white,
      ),
      //badgeDelegate: const DurationBadgeDelegate(),
      pickType: type);
  return imgList;
}

addUpdatePicture(BuildContext context, BaseModel profileInfo,
    {bool isGroup = false, onStarted, onComplete}) async {
  File cropped = File(await getSingleCroppedImage());
  if (cropped == null) return;
  onStarted();
  uploadFile(cropped, (url, error) async {
    if (error != null) {
      onComplete();
      return;
    }
    profileInfo.put(IMAGE, url);
    profileInfo.updateItems();
    await updatePostRecords(isGroup: isGroup);
    onComplete();
  });
  return;
}

Future<String> getSingleCroppedImage() async {
  var media = await ImagePickers.pickerPaths(
      galleryMode: GalleryMode.image,
      selectCount: 1,
      showCamera: true,
      compressSize: 300,
      //uiConfig: UIConfig(UITheme.white),
      corpConfig: CorpConfig(enableCrop: true, width: 10, height: 10));
  return media[0].path;
}

updatePostRecords({bool isGroup = false, BaseModel groupInfo}) async {
  if (isGroup) {
    await Firestore.instance
        .collection(POST_BASE)
        .where(POST_ID, isEqualTo: groupInfo.getObjectId())
        .getDocuments()
        .then((query) {
      for (var doc in query.documents) {
        BaseModel model = BaseModel(doc: doc);
        model.put(IMAGE, userModel.getImage());
        model.put(FULL_NAME, userModel.getFullName());
        model.updateItems();
      }
    });

    await Firestore.instance
        .collection(COMMENTS_BASE)
        .where(POST_ID, isEqualTo: groupInfo.getObjectId())
        .getDocuments()
        .then((query) {
      for (var doc in query.documents) {
        BaseModel model = BaseModel(doc: doc);
        model.put(IMAGE, userModel.getImage());
        model.put(FULL_NAME, userModel.getFullName());
        model.updateItems();
      }
    });

    await Firestore.instance
        .collection(REPLIES_BASE)
        .where(POST_ID, isEqualTo: groupInfo.getObjectId())
        .getDocuments()
        .then((query) {
      for (var doc in query.documents) {
        BaseModel model = BaseModel(doc: doc);
        model.put(IMAGE, userModel.getImage());
        model.put(FULL_NAME, userModel.getFullName());
        model.updateItems();
      }
    });

    return;
  }

  await Firestore.instance
      .collection(POST_BASE)
      .where(OWNER_ID, isEqualTo: userModel.getUId())
      .getDocuments()
      .then((query) {
    for (var doc in query.documents) {
      BaseModel model = BaseModel(doc: doc);
      model.put(IMAGE, userModel.getImage());
      model.put(FULL_NAME, userModel.getFullName());
      model.updateItems();
    }
  });

  await Firestore.instance
      .collection(COMMENTS_BASE)
      .where(OWNER_ID, isEqualTo: userModel.getUId())
      .getDocuments()
      .then((query) {
    for (var doc in query.documents) {
      BaseModel model = BaseModel(doc: doc);
      model.put(IMAGE, userModel.getImage());
      model.put(FULL_NAME, userModel.getFullName());
      model.updateItems();
    }
  });

  await Firestore.instance
      .collection(REPLIES_BASE)
      .where(OWNER_ID, isEqualTo: userModel.getUId())
      .getDocuments()
      .then((query) {
    for (var doc in query.documents) {
      BaseModel model = BaseModel(doc: doc);
      model.put(IMAGE, userModel.getImage());
      model.put(FULL_NAME, userModel.getFullName());
      model.updateItems();
    }
  });

  await Firestore.instance
      .collection(EVENT_BASE)
      .where(OWNER_ID, isEqualTo: userModel.getUId())
      .getDocuments()
      .then((query) {
    for (var doc in query.documents) {
      BaseModel model = BaseModel(doc: doc);
      model.put(IMAGE, userModel.getImage());
      model.put(FULL_NAME, userModel.getFullName());
      model.updateItems();
    }
  });
}

deleteGroup(BaseModel groupDetails, {onComplete}) async {
  //GOTO CHAT HISTORY
  var chatShots = await Firestore.instance
      .collection(CHAT_BASE)
      .where(CHAT_ID, isEqualTo: groupDetails.getObjectId())
      .getDocuments();

  //GOTO POST HISTORY
  var postShots = await Firestore.instance
      .collection(POST_BASE)
      .where(POST_ID, isEqualTo: groupDetails.getObjectId())
      .getDocuments();

  //WIPE CHAT HISTORY
  for (var doc in chatShots.documents) {
    BaseModel model = BaseModel(doc: doc);
    model.deleteItem();
  }

  //WIPE POST HISTORY
  for (var doc in postShots.documents) {
    BaseModel model = BaseModel(doc: doc);
    model.deleteItem();
  }

  //DELETE GROUP
  groupDetails.deleteItem();
  onComplete();
}

addUser(BaseModel me, BaseModel user) async {
  Firestore.instance
      .collection(USER_BASE)
      .document(me.getUId())
      .get()
      .then((shot) {
    BaseModel bm = BaseModel(doc: shot);
    bm.putInList(RECEIVED_REQUESTS, user.getUId(), false);
    bm.putInList(SENT_REQUESTS, user.getUId(), false);
    bm.putInList(CONNECTIONS, user.getUId(), true);
    bm.updateItems();
  });

  Firestore.instance
      .collection(USER_BASE)
      .document(user.getUId())
      .get()
      .then((shot) {
    BaseModel bm = BaseModel(doc: shot);
    bm.putInList(RECEIVED_REQUESTS, me.getUId(), false);
    bm.putInList(SENT_REQUESTS, me.getUId(), false);
    bm.putInList(CONNECTIONS, me.getUId(), true);
    bm.updateItems();
  });
}

updateShareCount(String uid) {
  Firestore.instance.collection(USER_BASE).document(uid).get().then((shot) {
    BaseModel bm = BaseModel(doc: shot);
    bm.putInList(SHARES, userModel.getUId(), true);
    bm.updateItems();
  });
}

addFriend(BuildContext context, BaseModel user, bool add,
    {bool requestAccepted = false, refreshFeed}) async {
  List sIds = [user.getUId(), userModel.getUId()];
  String sentId = "${sIds[0]}${sIds[1]}";
  String sentId2 = "${sIds[1]}${sIds[0]}";

  BaseModel model = createRequestMap(userModel, user);

  if (requestAccepted) {
    addUser(userModel, user);

    deleteRequest(sentId, sentId2, onError: (e) {
      showMessage(
          context,
          Icons.network_check,
          Colors.red,
          "Network Error",
          "We experienced difficulties connecting to our server. "
              "Please check your internet connection and try again",
          clickYesText: "Try Again",
          isIcon: true,
          cancellable: true,
          onClicked: (_) async {});
    }, onDeleted: () {
      createNotification(
          context,
          "Request accepted",
          "accepted your friend request",
          user,
          NotificationType.requestAccepted,
          useID: userModel.getUId(),
          fcmToken: model.getToken());

      addUser(userModel, user);

      refreshFeed();
    });
    return;
  }

  if (!add) {
    print("Here....");

    user.putInList(RECEIVED_REQUESTS, userModel.getUId(), false);
    userModel.putInList(SENT_REQUESTS, user.getUId(), false);

    userModel.putInList(RECEIVED_REQUESTS, user.getUId(), false);
    user.putInList(SENT_REQUESTS, userModel.getUId(), false);

    userModel.updateItems();
    user.updateItems();

    deleteRequest(sentId, sentId2, onError: (e) {
      print(e);
      showMessage(
          context,
          Icons.network_check,
          Colors.red,
          "Network Error",
          "We experienced difficulties connecting to our server. "
              "Please check your internet connection and try again",
          clickYesText: "Try Again",
          isIcon: true,
          cancellable: true,
          onClicked: (_) async {});
    }, onDeleted: () {
      print("Deleted");

      user.putInList(RECEIVED_REQUESTS, userModel.getUId(), false);
      userModel.putInList(SENT_REQUESTS, user.getUId(), false);

      userModel.putInList(RECEIVED_REQUESTS, user.getUId(), false);
      user.putInList(SENT_REQUESTS, userModel.getUId(), false);

      userModel.updateItems();
      user.updateItems();
      refreshFeed();
    });
  } else {
    //sentList.add(userId);
    model.saveItem(REQUEST_BASE, true, document: sentId, onComplete: () {
      model.put(USER_ID, user.getUId());
      createNotification(context, "Friend request", "sent you a friend request",
          model, NotificationType.requestSent,
          fcmToken: user.getToken());

      user.putInList(RECEIVED_REQUESTS, userModel.getUId(), add);
      userModel.putInList(SENT_REQUESTS, user.getUId(), add);
      userModel.updateItems();
      user.updateItems();
      print("Sent!!!...");
      refreshFeed();
    });
  }
}

BaseModel createRequestMap(BaseModel me, BaseModel user) {
  BaseModel model = BaseModel();
  model.put(DOCUMENT_ID, me.getUId());
  model.put(PERSON_ID, user.getUId());
  model.put(USER_ID, me.getUId());
  model.put(IMAGE, me.getImage());
  model.put(IS_CHURCH, me.getIsChurch());
  model.put(PUSH_NOTIFICATION_TOKEN, user.getToken());
  model.put(TIME, DateTime.now().millisecondsSinceEpoch);
  if (me.getIsChurch()) {
    model.put(CHURCH_DENOMINATION, me.getChurchDenomination());
    model.put(CHURCH_NAME, me.getChurchName());
    model.put(CHURCH_ADDRESS, me.getChurchAddress());
  } else {
    BaseModel church = BaseModel(items: me.getChurchInfo());
    BaseModel churchInfo = BaseModel();
    churchInfo.put(CHURCH_DENOMINATION, church.getChurchDenomination());
    churchInfo.put(CHURCH_NAME, church.getChurchName());
    churchInfo.put(CHURCH_ADDRESS, church.getChurchAddress());
    model.put(FULL_NAME, me.getFullName());
    model.put(CITY, me.getCity());
    model.put(CHURCH_INFO, churchInfo.items);
  }
  return model;
}

BaseModel createEventMap(BaseModel bm) {
  BaseModel model = BaseModel();
  model.put(TYPE, bm.getType());
  model.put(DOCUMENT_ID, bm.getObjectId());
  model.put(EVENT_TITLE, bm.get(EVENT_TITLE));
  model.put(EVENT_START_DATE, bm.get(EVENT_START_DATE));
  model.put(EVENT_START_TIME, bm.get(EVENT_START_TIME));
  model.put(EVENT_END_TIME, bm.get(EVENT_END_TIME));
  model.put(EVENT_END_DATE, bm.get(EVENT_END_DATE));
  model.put(EVENT_DETAILS, bm.get(EVENT_DETAILS));
  model.put(CLICKS, bm.get(CLICKS));
  model.put(EVENT_DATA, bm.get(EVENT_DATA));
  model.put(EVENT_INDEX, bm.get(EVENT_INDEX));
  model.put(LOCATION, bm.get(LOCATION));
  model.put(IS_SPONSORED, bm.get(IS_SPONSORED));

  return model;
}

BaseModel createUserMap(BaseModel bm) {
  BaseModel model = BaseModel();
  model.put(TYPE, POST_TYPE_USER);
  model.put(DOCUMENT_ID, bm.getUId());
  model.put(PERSON_ID, bm.getUId());
  model.put(USER_ID, bm.getUId());
  model.put(IMAGE, bm.getImage());
  model.put(IS_CHURCH, bm.getIsChurch());
  model.put(PUSH_NOTIFICATION_TOKEN, bm.getToken());
  model.put(TIME, DateTime.now().millisecondsSinceEpoch);
  if (bm.getIsChurch()) {
    model.put(CHURCH_DENOMINATION, bm.getChurchDenomination());
    model.put(CHURCH_NAME, bm.getChurchName());
    model.put(CHURCH_ADDRESS, bm.getChurchAddress());
  } else {
    BaseModel church = BaseModel(items: bm.getChurchInfo());
    BaseModel churchInfo = BaseModel();
    churchInfo.put(CHURCH_DENOMINATION, church.getChurchDenomination());
    churchInfo.put(CHURCH_NAME, church.getChurchName());
    churchInfo.put(CHURCH_ADDRESS, church.getChurchAddress());
    model.put(FULL_NAME, bm.getFullName());
    model.put(CITY, bm.getCity());
    model.put(CHURCH_INFO, churchInfo.items);
  }
  return model;
}

deleteRequest(String sentId1, String sentId2,
    {bool useTwo = false, onDeleted, onError}) async {
  bool connected = await isConnected();
  String id = useTwo ? sentId2 : sentId1;
  DocumentSnapshot doc = await Firestore.instance
      .collection(REQUEST_BASE)
      .document(id)
      .get(source: Source.server)
      .catchError((error) {
    onError("No Network");
    return;
  });

  print("DocID $id 2nd $useTwo");

  if (doc == null) {
    print("Null False....");
    return;
  }
  if (!doc.exists && !useTwo) {
    deleteRequest(sentId1, sentId2,
        useTwo: true, onError: onError, onDeleted: onDeleted);
    print("False....");
    return;
  }

  doc.reference.delete();
  onDeleted();
}

createNotification(BuildContext context, String title, String msg,
    BaseModel model, NotificationType notificationType,
    {String useID, String fcmToken}) {
  print("My Item ${model.myItem()}");
  if (model.myItem()) return;

  try {
    //Handle the notification
    BaseModel bm = BaseModel();
    bm.put(TITLE, title);
    bm.put(DOCUMENT_ID, getRandomId());
    bm.put(POST_ID, useID ?? model.getObjectId());
    bm.put(FULL_NAME, userModel.getFullName());
    bm.put(NOTIFICATION_BODY, msg);
    bm.put(IMAGE, userModel.getImage());
    bm.put(OWNER_ID, model.getUId());
    bm.put(MESSAGE, "${userModel.getFullName()} $msg");
    bm.put(TOKEN_ID, fcmToken);
    //print("CREATING... ${bm.items}");
    NotificationHandler(context, bm, HandlerType.outgoingNotification,
        notificationType: notificationType);
  } on PlatformException catch (e) {
    print("EEE $e");
  }
}

acceptFriendRequest(BuildContext context, BaseModel model, bool accepted,
    {onComplete}) {
  if (accepted) {
    BaseModel bm = BaseModel();
    bm.put(TITLE, "Request Accepted");
    bm.put(MESSAGE, "${userModel.getFullName()} accepted your friend request");
    bm.put(USER_ID, userModel.getUId());
    bm.put(TOKEN_ID, model.getToken());
    NotificationHandler(context, bm, HandlerType.outgoingNotification,
        notificationType: NotificationType.requestAccepted);

    userModel.putInList(CONNECTIONS, model.getUId(), true);
    model.putInList(CONNECTIONS, userModel.getUId(), true);

    userModel.updateItems();
    model.updateItems();
  }
  userModel.putInList(RECEIVED_REQUESTS, model.getUId(), false);
  model.putInList(SENT_REQUESTS, userModel.getUId(), false);
  model.updateItems();
  userModel.updateItems();
  Firestore.instance
      .collection(REQUEST_BASE)
      .document(model.getString(REQUEST_ID))
      .get()
      .then((doc) {
    if (doc.exists) {
      doc.reference.delete();
    }
  });
  onComplete(model);
}

sendFriendRequest(BuildContext context, BaseModel model, bool add,
    {onComplete}) {
  List sIds = [model.getUId(), userModel.getUId()];
  String sentId = "${sIds[0]}${sIds[1]}";

  if (!add) {
    userModel.putInList(SENT_REQUESTS, model.getUId(), false);
    model.putInList(RECEIVED_REQUESTS, userModel.getUId(), false);

    userModel.putInList(RECEIVED_REQUESTS, model.getUId(), false);
    model.putInList(SENT_REQUESTS, userModel.getUId(), false);
    model.updateItems();
    userModel.updateItems();
    Firestore.instance.collection(REQUEST_BASE).document(sentId).delete();
    onComplete(model);
    return;
  }

  BaseModel bm = BaseModel();
  bm.put(TITLE, "Friend Request");
  bm.put(MESSAGE, "${model.getFullName()} sent you a friend request");
  bm.put(USER_ID, model.getUId());
  bm.put(TOKEN_ID, model.getToken());
  NotificationHandler(context, bm, HandlerType.outgoingNotification,
      notificationType: NotificationType.requestSent);

  userModel.putInList(RECEIVED_REQUESTS, model.getUId(), true);
  model.putInList(SENT_REQUESTS, userModel.getUId(), true);

  userModel.updateItems();
  model.updateItems();

  BaseModel request = BaseModel();
  request.put(PERSON_ID, model.getUId());
  request.saveItem(REQUEST_BASE, true, document: sentId);
}

scrollUpDownView(scrollFeedTotalTop, scrollFeedTotalDown) {
  return Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.only(right: 10, bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          RaisedButton(
            onPressed: scrollFeedTotalTop,
            padding: EdgeInsets.all(12),
            color: Colors.green[700],
            child: Icon(
              Icons.arrow_upward,
              color: Colors.white,
            ),
            shape: CircleBorder(),
          ),
          addSpace(10),
          RaisedButton(
            onPressed: scrollFeedTotalDown,
            padding: EdgeInsets.all(12),
            color: Colors.green[700],
            child: Icon(
              Icons.arrow_downward,
              color: Colors.white,
            ),
            shape: CircleBorder(),
          )
        ],
      ),
    ),
  );
}

pinnedMessageBox({
  String title,
  int time,
  String message,
  String btnTitle,
  Function onClicked,
  Function onClose,
  bool showUpdate = false,
  bool isProfile = false,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Container(
      margin: EdgeInsets.all(isProfile ? 0 : 10),
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: Colors.blue, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          addSpace(10),
          Row(
            children: <Widget>[
              Icon(
                Icons.info,
                color: Colors.white,
              ),
              addSpaceWidth(10),
              Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(.7)),
              ),
              addSpaceWidth(10),
              if (!isProfile)
                Text(
                  getChatTime(time),
                  style: TextStyle(color: Colors.white.withOpacity(.7)),
                ),
              addExpanded(),
              InkWell(
                onTap: onClose,
                child: Icon(
                  Icons.clear,
                  //size: 18,
                  color: Colors.white.withOpacity(0.7),
                ),
              )
            ],
          ),
          addSpace(10),
          Text(
            message,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          addSpace(10),
          if (showUpdate)
            RaisedButton(
              onPressed: onClicked,
              color: Colors.white,
              padding: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.white.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(
                  btnTitle,
                  style:
                      TextStyle(color: APP_COLOR, fontWeight: FontWeight.bold),
                ),
              ),
            )
        ],
      ),
    ),
  );
}

infoBox() {
  return Container(
    margin: EdgeInsets.all(10),
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
        //color: Colors.red,
        color: Colors.red,
        borderRadius: BorderRadius.circular(10)),
    child: Row(
      children: <Widget>[
        Icon(
          Icons.warning,
          color: Colors.white,
        ),
        addSpaceWidth(10),
        Flexible(
          child:
              Text.rich(TextSpan(style: textStyle(false, 14, white), children: [
            TextSpan(
              text:
                  "Please note this profile type is for Churches that want to create an account with Tree.\n",
            ),
            TextSpan(
                style: textStyle(true, 14, white),
                text: "This is not the profile type for individuals.."),
          ])
                  //,
                  ),
        ),
      ],
    ),
  );
}

disclaimerBox() {
  return Container(
    margin: EdgeInsets.all(10),
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
        //color: Colors.red,
        color: Colors.red,
        borderRadius: BorderRadius.circular(10)),
    child: Row(
      children: <Widget>[
        Icon(
          Icons.warning,
          color: Colors.white,
        ),
        addSpaceWidth(10),
        Flexible(
          child:
              Text.rich(TextSpan(style: textStyle(false, 14, white), children: [
            TextSpan(
              text: "Please note: If you don't have a church name type ",
            ),
            TextSpan(style: textStyle(false, 14, white), text: "NONE"),
            TextSpan(
              text: " instead of leaving it blank.",
            ),
          ])
                  //,
                  ),
        ),
      ],
    ),
  );
}

disclaimerBox1() {
  return Container(
    margin: EdgeInsets.all(10),
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
        //color: Colors.red,
        color: Colors.blue,
        borderRadius: BorderRadius.circular(10)),
    child: Row(
      children: <Widget>[
        Icon(
          Icons.warning,
          color: Colors.white,
        ),
        addSpaceWidth(10),
        Flexible(
          child:
              Text.rich(TextSpan(style: textStyle(false, 14, white), children: [
            TextSpan(
              text:
                  "If you do not know the Church ID please visit your church and ask for their  ",
            ),
            TextSpan(style: textStyle(false, 14, white), text: "Tree ID."),
            TextSpan(
              text: " In the meantime click here to move forward without the ",
            ),
            TextSpan(style: textStyle(false, 14, white), text: "Church ID."),
          ])
                  //,
                  ),
        ),
      ],
    ),
  );
}

openMap(double latitude, double longitude) async {
  String googleUrl =
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  if (await canLaunch(googleUrl)) {
    await launch(googleUrl);
  } else {
    throw 'Could not open the map.';
  }
}
