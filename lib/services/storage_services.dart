// ignore_for_file: non_constant_identifier_names

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kreengate/helper/global_var.dart';

/// Pengganti SecurePreferences(context, Config.PASSPREF, Config.DATAPREF).
///
/// Isinya di-cache di memory (seperti SharedPreferences di Android) supaya
/// getter bisa dipanggil sinkron di initState, sama seperti di onCreate.
class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static final Map<String, String> _cache = {};

  static Future<void> init() async {
    _cache
      ..clear()
      ..addAll(await _storage.readAll());
  }

  static String getString(String key, [String def = ""]) {
    return _cache[key] ?? def;
  }

  static void putString(String key, String value) {
    _cache[key] = value;
    _storage.write(key: key, value: value);
  }

  static bool getBool(String key, [bool def = false]) {
    final value = _cache[key];
    if (value == null) return def;
    return value == 'true';
  }

  static void putBool(String key, bool value) {
    _cache[key] = value.toString();
    _storage.write(key: key, value: value.toString());
  }

  // -----------------------------------------------------------------------------

  static void setPrintTypeSdk(String type) => putString(printTypeSdkSp, type);
  static String getPrintTypeSdk() => getString(printTypeSdkSp, "");

  static bool getLoginStatus() => getBool(statusLoginSp, false);

  static String getIdEvent() => getString(idEventSp, "");
  static String getTitleEvent() => getString(titleEventSp, "");

  static String getLanguage() => getString(languageSp, "");
  static void setLanguage(String code) => putString(languageSp, code);

  static void setEvent({
    required String idEvent,
    required String title,
    required String topic,
    required String typeEvent,
    required String bannerTopList,
    required String bannerDownList,
  }) {
    putString(idEventSp, idEvent);
    putString(titleEventSp, title);
    putString(topicEventSp, topic);
    putString(typeEventSp, typeEvent);
    putString(bannerTopListSp, bannerTopList);
    putString(bannerDownListSp, bannerDownList);
    putBool(statusLoginSp, true);
  }

  static void clearEvent() {
    putString(idEventSp, "");
    putString(titleEventSp, "");
    putString(topicEventSp, "");
    putString(typeEventSp, "");
    putString(bannerTopListSp, "");
    putString(bannerDownListSp, "");
    putBool(statusLoginSp, false);
  }
}
