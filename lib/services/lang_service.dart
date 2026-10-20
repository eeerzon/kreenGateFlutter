import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/services/storage_services.dart';

/// Isi assets/lang/{en,in}.json di-generate dari res/values*/strings.xml.
class LangService {
  static final Map<String, Map<String, dynamic>> _cache = {};

  static Future<void> preload() async {
    for (final code in const ['en', 'in']) {
      final String response = await rootBundle.loadString('assets/lang/$code.json');
      _cache[code] = Map<String, dynamic>.from(json.decode(response)['bahasa']);
    }
  }

  static Future<Map<String, dynamic>> getJsonData(String langCode, String header) async {
    final String response = await rootBundle.loadString("assets/lang/$langCode.json");
    final data = json.decode(response);
    return Map<String, dynamic>.from(data[header]);
  }

  /// Sama seperti getString(R.string.key) dengan konfigurasi bahasa yang sedang aktif.
  static String getString(String key) {
    final code = langNotifier.value == 'in' ? 'in' : 'en';
    return (_cache[code]?[key] ?? _cache['en']?[key] ?? key) as String;
  }

  /// LanguageManager.updateResource(getLang()).
  ///
  /// getLang() mengembalikan "" kalau belum pernah diset -> Locale("") -> resource default (English).
  static void updateResource() {
    final code = StorageService.getLanguage();
    langNotifier.value = code;
    StorageService.setLanguage(code);
  }
}
