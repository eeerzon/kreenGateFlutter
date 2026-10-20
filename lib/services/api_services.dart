import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/services/lang_service.dart';

/// Hasil panggilan API, padanan `Resource<T>` di app Android.
///
/// status:
///  - "success" -> Resource.Success(data)
///  - "error"   -> Resource.Error(message, desc, errorCode)
///  - "none"    -> tidak ada value yang di-post (body null), observer tidak dipanggil lagi
class ApiService {
  static http.Client? _client;
  static http.Client? _jipremiumClient;

  // ApiModule: connectTimeout 15s, readTimeout 15s
  static const Duration _timeout = Duration(seconds: 15);
  // OkHttpClient default (JipremiumNetworkModule): 10s
  static const Duration _jipremiumTimeout = Duration(seconds: 10);

  static http.Client _main() {
    return _client ??= IOClient(HttpClient()..connectionTimeout = _timeout);
  }

  static Future<http.Client> _jipremium() async {
    if (_jipremiumClient != null) return _jipremiumClient!;
    // network_security_config.xml: jipremium.com -> @raw/gogetssl_intermediate + system
    final context = SecurityContext(withTrustedRoots: true);
    try {
      final cert = await rootBundle.load('assets/certs/gogetssl_intermediate.crt');
      final bytes = cert.buffer.asUint8List();
      // res/raw berisi DER (biner); SecurityContext Dart hanya menerima PEM
      final isPem = utf8.decode(bytes.take(10).toList(), allowMalformed: true).startsWith('-----');
      final pem = isPem
          ? bytes
          : utf8.encode('-----BEGIN CERTIFICATE-----\n'
              '${base64.encode(bytes).replaceAllMapped(RegExp(r'.{1,64}'), (m) => '${m[0]}\n')}'
              '-----END CERTIFICATE-----\n');
      context.setTrustedCertificatesBytes(pem);
    } catch (e) {
      debugPrint('gogetssl_intermediate.crt not loaded: $e');
    }
    final client = HttpClient(context: context)..connectionTimeout = _jipremiumTimeout;
    return _jipremiumClient = IOClient(client);
  }

  static Future<bool> hasInternetConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.ethernet);
  }

  static Map<String, dynamic> _error(String message, String? desc, int errorCode) {
    return {"status": "error", "message": message, "desc": desc, "errorCode": errorCode};
  }

  static Map<String, dynamic> _success(Map<String, dynamic> data) {
    return {"status": "success", "data": data};
  }

  static const Map<String, dynamic> _none = {"status": "none"};

  static void _log(http.BaseRequest request, http.Response response) {
    // HttpLoggingInterceptor.Level.BODY
    debugPrint('--> ${request.method} ${request.url}');
    debugPrint('<-- ${response.statusCode} ${response.reasonPhrase ?? ''} ${request.url}');
    debugPrint(response.body);
  }

  /// Pola umum di BookingViewModel: cek internet -> request -> isSuccessful -> body -> success.
  static Future<Map<String, dynamic>> _call(
    Future<http.Response> Function() request, {
    required Map<String, dynamic> Function(Map<String, dynamic> body) parse,
    bool checkSuccessField = true,
    String serverErrorDesc = 'failed_to_connect_to_server',
  }) async {
    try {
      if (!await hasInternetConnection()) {
        return _error(
          LangService.getString('no_internet_connection'),
          LangService.getString('please_check_you_internet_connection_and_try_again'),
          httpErrInternetDisconnected,
        );
      }

      final response = await request();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Retrofit tidak memanggil converter untuk 204/205 -> body() == null -> tidak ada post
        if (response.statusCode == 204 || response.statusCode == 205) return _none;

        final dynamic decoded = json.decode(response.body); // FormatException ~ MalformedJson/EOF (IOException)
        if (decoded == null) return _none;
        if (decoded is! Map) throw const GsonConversionException('expected BEGIN_OBJECT');
        final body = parse(Map<String, dynamic>.from(decoded));

        if (!checkSuccessField || body['success'] == true) {
          return _success(body);
        }
        // Resource.Error(message: String) -> message null akan NPE -> masuk catch "else"
        final message = body['message'];
        if (message == null) throw const GsonConversionException('message null');
        return _error(message as String, LangService.getString(serverErrorDesc), httpInternalServerError);
      } else {
        return _error(
          response.reasonPhrase ?? '',
          serverErrorDesc.isEmpty ? '' : LangService.getString(serverErrorDesc),
          httpInternalServerError,
        );
      }
    } catch (ex) {
      debugPrint('API EXCEPTION: ${ex.runtimeType} - $ex');
      if (ex is IOException || ex is TimeoutException || ex is FormatException || ex is http.ClientException) {
        return _error(
          LangService.getString('network_failure'),
          LangService.getString('please_check_you_internet_connection_and_try_again'),
          httpBadRequest,
        );
      }
      return _error(
        LangService.getString('conversion_error'),
        LangService.getString('error_in_data_conversion'),
        httpBadRequest,
      );
    }
  }

  static Future<http.Response> _postForm(
    String url,
    Map<String, String> fields, {
    Map<String, String>? headers,
  }) async {
    final request = http.Request('POST', Uri.parse(url))
      ..bodyFields = fields; // application/x-www-form-urlencoded; charset=utf-8
    if (headers != null) request.headers.addAll(headers);
    final streamed = await _main().send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamed).timeout(_timeout);
    _log(request, response);
    return response;
  }

  // ===============================================================================
  // ApiService.kt
  // ===============================================================================

  /// checkServerInfo (CheckServerViewModel.getCheckServer)
  static Future<Map<String, dynamic>> getCheckServer(String vCode, String typeApp, String platform) {
    return _call(
      () async {
        final request = http.Request('POST', Uri.parse('${baseUrl}check-server-info'))
          ..headers['Content-Type'] = 'application/json'
          ..body = json.encode({"platform": platform, "type_app": typeApp, "v_code": vCode});
        final response = await http.Response.fromStream(await _main().send(request).timeout(_timeout));
        _log(request, response);
        return response;
      },
      parse: parseCheckServerResponse,
      checkSuccessField: false,
      serverErrorDesc: '',
    );
  }

  /// checkEvent (BookingRepository.getCheckEvent_1) - JSON body
  static Future<Map<String, dynamic>> getCheckEvent1(String idEvent) {
    return _call(
      () async {
        final request = http.Request('POST', Uri.parse('${baseUrl}check_event'))
          ..headers['Content-Type'] = 'application/json; charset=UTF-8'
          ..body = json.encode({"id_event": idEvent});
        final response = await http.Response.fromStream(await _main().send(request).timeout(_timeout));
        _log(request, response);
        return response;
      },
      parse: parseCheckEventResponse,
    );
  }

  /// checkEvent3 (BookingRepository.getCheckEvent__) - form ke check-server-info
  static Future<Map<String, dynamic>> getCheckEvent3(String idEvent) {
    return _call(
      () => _postForm('${baseUrl}check-server-info', {"id_event": idEvent},
          headers: {'Content-Type': 'application/x-www-form-urlencoded'}),
      parse: parseCheckEventResponse,
    );
  }

  /// checkEvent5 (BookingRepository.getCheckEvent) - dipakai LoginEventActivity
  static Future<Map<String, dynamic>> getCheckEvent(String idEvent) {
    return _call(
      () => _postForm('${baseUrl}kiosk-check-event', {"id_event": idEvent}),
      parse: parseCheckEventResponse,
    );
  }

  /// booking_redeem2_coex
  static Future<Map<String, dynamic>> bookingRedeem(String idRedeem, String idTicket, String idEvent) {
    return _call(
      () => _postForm('${baseUrl}booking_redeem2_coex',
          {"id_redeem": idRedeem, "id_ticket": idTicket, "id_event": idEvent}),
      parse: parseBookingRedeemResponse,
    );
  }

  /// booking_redeem3_coex_kiosk - dipakai ScanActivity
  static Future<Map<String, dynamic>> bookingRedeem2(String idRedeem, String idTicket, String idEvent) {
    return _call(
      () => _postForm('${baseUrl}booking_redeem3_coex_kiosk',
          {"id_redeem": idRedeem, "id_ticket": idTicket, "id_event": idEvent}),
      parse: parseDataDetailResponse,
    );
  }

  /// listQuestionOrderForm (URL absolut + header API-Secret-Key)
  static Future<Map<String, dynamic>> listQuestionOrderForm(String secretKey, String idEvent) {
    return _call(
      () => _postForm('https://kreenconnect.com/kreenapi/event/listQuestionOrderForm', {"id_event": idEvent},
          headers: {'API-Secret-Key': secretKey}),
      parse: parseListQuestionOrderFormResponse,
    );
  }

  // ===============================================================================
  // ApiServiceJipremium.kt
  // ===============================================================================

  /// order/check-qrcode (BookingViewModel.checkBooking)
  static Future<Map<String, dynamic>> checkBooking(String idTicket, String idEvent) async {
    debugPrint('id_order: $idTicket');
    final result = await _call(
      () async {
        debugPrint('CHECK_BOOKING: BEFORE API');
        final request = http.Request('POST', Uri.parse('${baseUrlJipremium}order/check-qrcode'))
          ..headers['API-Secret-Key'] = jipremiumSecretKey
          ..bodyFields = {"id_order": idTicket, "id_event": idEvent};
        final client = await _jipremium();
        final response =
            await http.Response.fromStream(await client.send(request).timeout(_jipremiumTimeout));
        debugPrint('CHECK_BOOKING: AFTER API');
        _log(request, response);
        return response;
      },
      parse: parseDataDetailResponse,
    );
    return result;
  }
}
