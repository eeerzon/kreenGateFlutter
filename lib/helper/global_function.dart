import 'dart:convert';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

// =====================================================================================
// Ukuran (com.intuit.sdp / ssp)
// =====================================================================================

/// Bucket values-swXXXdp dari library sdp: 300, 330, ..., 1080 (di bawah 300 pakai nilai default).
double _sdpFactor = 1.0;

double _dpr = 1.0;

void initSdp(BuildContext context) {
  _dpr = MediaQuery.devicePixelRatioOf(context);
  final sw = MediaQuery.sizeOf(context).shortestSide;
  int bucket = 300;
  for (int b = 300; b <= 1080; b += 30) {
    if (sw >= b) bucket = b;
  }
  _sdpFactor = bucket / 300.0;
}

/// @dimen/_Nsdp (dp, ikut lebar layar). Dibulatkan 2 desimal seperti di dimens.xml library.
double sdp(num n) => double.parse((n * _sdpFactor).toStringAsFixed(2));

/// @dimen/_Nssp (sp, ikut lebar layar + skala font sistem).
double ssp(num n) => sdp(n);

// dimens.xml proyek: alias "__N" -> "_M" (catatan: __Nssp aslinya menunjuk ke _Msdp, jadi dp)
const Map<int, int> _sdpAlias = {
  2: 1, 3: 2, 4: 3, 5: 4, 7: 5, 8: 6, 10: 7, 12: 9, 13: 10, 14: 10, 15: 11, 16: 12, 18: 13,
  20: 15, 24: 18, 25: 19, 28: 21, 30: 23, 32: 24, 36: 27, 40: 30, 48: 37, 50: 38, 60: 46,
  70: 54, 80: 62, 100: 77, 110: 84, 120: 92, 140: 107, 130: 100, 150: 115, 160: 123, 170: 130,
  180: 138, 190: 146, 200: 154, 210: 161, 220: 169, 230: 176, 250: 192, 300: 230, 320: 246,
  350: 269,
};
const Map<int, int> _sspAlias = {
  2: 1, 8: 6, 10: 7, 11: 8, 12: 9, 14: 10, 15: 11, 16: 12, 18: 13, 20: 15, 24: 18, 25: 19,
  28: 21, 30: 23, 32: 24, 34: 26, 36: 27, 40: 30, 48: 37, 50: 38, 55: 42, 60: 46, 70: 54,
  80: 62,
};

/// android:textSize dibaca TextView lewat getDimensionPixelSize(): dibulatkan ke pixel bulat.
double textSizeDp(double size) => (size * _dpr).roundToDouble() / _dpr;

/// @dimen/__Nsdp
double dsdp(int n) => sdp(_sdpAlias[n]!);

/// @dimen/__Nssp (-> _Msdp, ukuran dp, tidak ikut skala font sistem)
double dssp(int n) => sdp(_sspAlias[n]!);

// =====================================================================================
// Utility.kt
// =====================================================================================

/// Utility.setStatusBarColorAndAppearance(window, color, isLight)
void setStatusBarColorAndAppearance(Color statusBarColor, bool isLight) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: statusBarColor,
    statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
    statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
  ));
}

/// Utility.lightStatusBar(window, isLight) -> selalu isAppearanceLightStatusBars = true
void lightStatusBar(bool? isLight) {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
}

String ucwords(String input) {
  final words = input.split(" ");
  for (int i = 0; i < words.length; i++) {
    final word = words[i];
    if (word.isNotEmpty) {
      words[i] = word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase();
    }
  }
  return words.join(" ");
}

String ucFirstWord(String sentence) {
  final sentence1 = sentence.toLowerCase();
  return sentence1[0].toUpperCase() + sentence1.substring(1);
}

/// Utility.random(jml, isi_string, tbh)
String random(int jml, String isiString, String tbh) {
  final chars1 = isiString.split('');
  final sb1 = StringBuffer();
  final random1 = Random();
  for (int i = 0; i < jml; i++) {
    sb1.write(chars1[random1.nextInt(chars1.length)]);
  }
  return tbh + sb1.toString();
}

String? _formatDate(String date, String from, String to) {
  try {
    return DateFormat(to, 'en_US').format(DateFormat(from, 'en_US').parseStrict(date));
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

String? formatDate1(String date) => _formatDate(date, "yyyy-MM-dd", "dd MMMM yyyy");
String? formatDate2(String date) => _formatDate(date, "yyyy-MM-dd", "EEE, dd MMMM yyyy");
String? formatDate3(String date) => _formatDate(date, "yyyy-MM-dd HH:mm:ss", "EEE, dd MMMM yyyy, HH:mm");
String? formatDate4(String date) => _formatDate(date, "yyyy-MM-dd", "EEE, dd MMM yyyy");
String? formatDate5(String date) => _formatDate(date, "yyyy-MM-dd", "dd MMM yyyy");
String? formatDate6(String date) => _formatDate(date, "yyyy-MM-dd", "dd MMM yyyy");
String? formatDate7(String date) => _formatDate(date, "yyyy-MM-dd", "dd MMM yy");

String? formatDateCustom(String date, String fromDateFormat, String toDateFormat) =>
    _formatDate(date, fromDateFormat, toDateFormat);

String getCurrentDate(String dateFormat) => DateFormat(dateFormat).format(DateTime.now());

int konvStrInt(String s) => int.parse(s.replaceAll(RegExp(r'[\D]'), ''));
int konvStrIntOri(String s) => int.parse(s);
String konvIntStr(int i) => i.toString();
String konvDoubleStr(double d) => d.toString();
int konvDoubleInt(double? d) => d!.round();
double konvStringDouble(String s) => double.parse(s);
int konvStringLong(String s) => int.parse(s);

String currencyFormat(String amount) => NumberFormat("###,###").format(double.parse(amount));

// =====================================================================================
// normalizeAnswer.kt (juga dipakai ParticipantDetail2/3.normalizeAnswer)
// =====================================================================================

String normalizeAnswer(String? raw) {
  if (raw == null || raw.trim().isEmpty || raw == "null") return "";

  final trimmed = raw.trim();

  try {
    if (trimmed.startsWith("[")) {
      // Bentuk array: [...]
      final arr = json.decode(trimmed) as List;
      return arr.map(_optString).join(", ");
    } else if (trimmed.startsWith("\"") && trimmed.endsWith("\"")) {
      // Bentuk string ber-quote ganda: "\"xxx\""
      final match = RegExp(r'^"(?:[^"\\]|\\.)*"').firstMatch(trimmed)!;
      return json.decode(match.group(0)!) as String;
    } else {
      // String biasa
      return trimmed;
    }
  } catch (e) {
    // fallback kalau parsing gagal, buang quote manual saja
    return _trimChar(trimmed, '"');
  }
}

/// JSONArray.optString(index)
String _optString(dynamic v) {
  if (v == null) return "";
  if (v is Map || v is List) return json.encode(v);
  return v.toString();
}

/// Kotlin String.trim(char)
String _trimChar(String s, String ch) {
  int start = 0;
  int end = s.length;
  while (start < end && s[start] == ch) {
    start++;
  }
  while (end > start && s[end - 1] == ch) {
    end--;
  }
  return s.substring(start, end);
}

// =====================================================================================
// Parsing response (perilaku Gson + data class Kotlin)
// =====================================================================================

class GsonConversionException implements Exception {
  final String message;
  const GsonConversionException(this.message);
  @override
  String toString() => 'JsonSyntaxException: $message';
}

String? gStr(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is num || v is bool) return v.toString();
  throw const GsonConversionException('Expected a string');
}

bool gBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  if (v is num) {
    if (v != v.truncate()) throw const GsonConversionException('Expected an int');
    return v != 0;
  }
  throw const GsonConversionException('Expected a boolean');
}

int gInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) {
    if (v != v.truncate()) throw const GsonConversionException('Expected an int');
    return v.toInt();
  }
  if (v is String) {
    final i = int.tryParse(v) ?? (double.tryParse(v)?.let((d) => d == d.truncate() ? d.toInt() : null));
    if (i == null) throw const GsonConversionException('Expected an int');
    return i;
  }
  throw const GsonConversionException('Expected an int');
}

int? gLongOrNull(dynamic v) => v == null ? null : gInt(v);

Map<String, dynamic>? gObj(dynamic v) {
  if (v == null) return null;
  if (v is Map) return Map<String, dynamic>.from(v);
  throw const GsonConversionException('Expected BEGIN_OBJECT');
}

List<T>? gList<T>(dynamic v, T Function(dynamic item) item) {
  if (v == null) return null;
  if (v is List) return v.map(item).toList();
  throw const GsonConversionException('Expected BEGIN_ARRAY');
}

extension _Let<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}

/// BannerImg(id, img)
Map<String, dynamic> parseBannerImg(dynamic v) {
  final m = gObj(v);
  if (m == null) return {'id': null, 'img': null};
  return {'id': gStr(m['id']), 'img': gStr(m['img'])};
}

/// `List<BannerImg>.toString()` versi Kotlin: "[BannerImg(id=1, img=a.png), ...]" (null -> "null")
String kotlinBannerListToString(List<Map<String, dynamic>>? list) {
  if (list == null) return "null";
  return '[${list.map((b) => 'BannerImg(id=${b['id']}, img=${b['img']})').join(', ')}]';
}

/// CheckEventResponse
Map<String, dynamic> parseCheckEventResponse(Map<String, dynamic> body) {
  final d = gObj(body['data']);
  return {
    'rc': gInt(body['rc']),
    'success': gBool(body['success']),
    'message': gStr(body['message']),
    'data': d == null
        ? null
        : {
            'idEvent': gStr(d['id_event']),
            'title': gStr(d['title']),
            'topic': gStr(d['topic']),
            'typeEvent': gStr(d['type_event']),
            'bannerKioskTop': gStr(d['banner_kiosk_top']),
            'bannerKioskBottom': gStr(d['banner_kiosk_bottom']),
            'logoList': gList(d['logo_list'], parseBannerImg),
            'bannerTopList': gList(d['banner_top_list'], parseBannerImg),
            'bannerBottomList': gList(d['banner_bottom_list'], parseBannerImg),
          },
  };
}

/// CheckServerResponse
Map<String, dynamic> parseCheckServerResponse(Map<String, dynamic> body) {
  final d = gObj(body['data']);
  Map<String, dynamic>? u;
  if (d != null) {
    final up = gObj(d['update_app']);
    if (up != null) {
      u = {
        'mandatory': gStr(up['mandatory']),
        'message': gStr(up['message']),
        'messageUpdate': gStr(up['message_update']),
        'statusUpdate': gStr(up['status_update']),
        'update': gStr(up['update']),
        'versionCode': gStr(up['version_code']),
        'versionName': gStr(up['version_name']),
      };
    }
  }
  return {
    'result': d == null
        ? null
        : {
            'descServer': gStr(d['desc_server']),
            'messageServer': gStr(d['message_server']),
            'otp': gStr(d['otp']),
            'server': gStr(d['server']),
            'updateApp': u,
          },
    'message': gStr(body['message']),
    'status': gStr(body['status']),
    'statusCode': gInt(body['status_code']),
    'success': gBool(body['success']),
  };
}

/// BookingRedeemResponse
Map<String, dynamic> parseBookingRedeemResponse(Map<String, dynamic> body) {
  final d = gObj(body['data']);
  return {
    'result': d == null
        ? null
        : {
            'answer': gStr(d['answer']),
            'companyName': gStr(d['company_name']),
            'email': gStr(d['email']),
            'phone': gStr(d['phone']),
            'eventBuyer': gInt(d['event_buyer']),
            'fullName': gStr(d['full_name']),
            'idTicket': gStr(d['id_ticket']),
            'jobTitle': gStr(d['job_title']),
          },
    'message': gStr(body['message']),
    'success': gBool(body['success']),
  };
}

/// OrderFormModel
Map<String, dynamic> parseOrderFormModel(dynamic v) {
  final m = gObj(v);
  if (m == null) {
    return {'id': null, 'answer': null, 'idEvent': null, 'idOrderDetail': null, 'idQuestion': null,
        'idQuestionDetail': null, 'question': null};
  }
  return {
    'id': gStr(m['id']),
    'answer': gStr(m['answer']),
    'idEvent': gStr(m['id_event']),
    'idOrderDetail': gLongOrNull(m['id_order_detail']),
    'idQuestion': gStr(m['id_question']),
    'idQuestionDetail': gStr(m['id_question_detail']),
    'question': gStr(m['question']),
  };
}

/// OrderFormsTypeAdapter: "order_forms" bisa array, string ter-escape, atau null.
List<Map<String, dynamic>>? parseOrderForms(dynamic v) {
  if (v == null) return null;
  if (v is List) return v.map(parseOrderFormModel).toList();
  if (v is String) {
    if (v.trim().isEmpty) return [];
    try {
      final inner = json.decode(v);
      if (inner == null) return [];
      return gList(inner, parseOrderFormModel) ?? [];
    } catch (e) {
      return [];
    }
  }
  return [];
}

/// DetailModel(fullname, email, orderForms)
Map<String, dynamic>? parseDetailModel(dynamic v) {
  final m = gObj(v);
  if (m == null) return null;
  return {
    'fullname': gStr(m['fullname']),
    'email': gStr(m['email']),
    'orderForms': parseOrderForms(m['order_forms']),
  };
}

/// BookingRedeem2Response / CheckBookingResponse: data { detail, id, show_qr }
Map<String, dynamic> parseDataDetailResponse(Map<String, dynamic> body) {
  final d = gObj(body['data']);
  return {
    'result': d == null
        ? null
        : {
            'detail': parseDetailModel(d['detail']),
            'id': gStr(d['id']),
            'showQr': gStr(d['show_qr']),
          },
    'message': gStr(body['message']),
    'success': gBool(body['success']),
  };
}

/// ListQuestionOrderFormResponse
Map<String, dynamic> parseListQuestionOrderFormResponse(Map<String, dynamic> body) {
  return {
    'success': gBool(body['success']),
    'message': gStr(body['message']),
    'data': gList(body['data'], (item) {
      final m = gObj(item);
      return {
        'idQuestion': m == null ? null : gStr(m['id_order_form_master']),
        'question': m == null ? null : gStr(m['question']),
      };
    }),
  };
}

// =====================================================================================
// Permission (checkBluetoothPermissions di tiap Activity)
// =====================================================================================

Future<int> androidSdkInt() async {
  final info = await DeviceInfoPlugin().androidInfo;
  return info.version.sdkInt;
}

/// Urutan sama dengan checkBluetoothPermissions(): BLUETOOTH, BLUETOOTH_ADMIN (< S),
/// BLUETOOTH_CONNECT, BLUETOOTH_SCAN (>= S). Kalau izin di-grant, cek ulang dari awal;
/// kalau ditolak, berhenti tanpa memanggil callback.
Future<void> checkBluetoothPermissions(VoidCallback? onPermissionsGranted) async {
  final sdk = await androidSdkInt();
  if (sdk >= 31) {
    for (final permission in [Permission.bluetoothConnect, Permission.bluetoothScan]) {
      if (!await permission.isGranted) {
        final status = await permission.request();
        if (status.isGranted) {
          return checkBluetoothPermissions(onPermissionsGranted);
        }
        return;
      }
    }
  }
  // BLUETOOTH & BLUETOOTH_ADMIN (< S) adalah izin normal, selalu granted saat install.
  onPermissionsGranted!();
}

/// Varian PrinterTestPrintama2Activity: semua izin yang kurang diminta sekaligus,
/// lalu hanya hasil izin pertama yang dicek.
Future<void> checkBluetoothPermissionsBatch(VoidCallback? onPermissionsGranted) async {
  final sdk = await androidSdkInt();
  final permissions = <Permission>[];
  if (sdk >= 31) {
    if (!await Permission.bluetoothConnect.isGranted) permissions.add(Permission.bluetoothConnect);
    if (!await Permission.bluetoothScan.isGranted) permissions.add(Permission.bluetoothScan);
  }
  if (permissions.isNotEmpty) {
    final result = await permissions.request();
    if (result[permissions.first]?.isGranted == true) {
      return checkBluetoothPermissionsBatch(onPermissionsGranted);
    }
  } else {
    onPermissionsGranted?.call();
  }
}
