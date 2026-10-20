// Render halaman yang tidak bisa dibuka lewat UI (butuh tiket valid / tidak ada navigasinya)
// ke PNG dengan ukuran layar 1080x2400 @ 2.625 (sama seperti emulator pembanding).
//
// flutter test test/pages_preview_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/pages/participant/participant_detail2_page.dart';
import 'package:kreengate/pages/participant/participant_detail3_page.dart';
import 'package:kreengate/pages/participant/participant_detail_page.dart';
import 'package:kreengate/pages/printer_test/printer_test_escpos2_page.dart';
import 'package:kreengate/pages/printer_test/printer_test_escpos_page.dart';
import 'package:kreengate/pages/scan/input_manual_ticket_page.dart';
import 'package:kreengate/pages/setting/language_page.dart';
import 'package:kreengate/pages/setting/printer_setting2_page.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/storage_services.dart';

Future<void> _loadFonts() async {
  for (final f in {
    'Poppins': 'assets/fonts/poppins.ttf',
    'PoppinsMedium': 'assets/fonts/poppins_medium.ttf',
    'PoppinsSemiBold': 'assets/fonts/poppins_semibold.ttf',
    'PoppinsBold': 'assets/fonts/poppins_bold.ttf',
  }.entries) {
    await (FontLoader(f.key)..addFont(rootBundle.load(f.value))).load();
  }
  // Roboto (font default Android) untuk teks tanpa fontFamily
  final roboto = File('test/fonts/Roboto.ttf').readAsBytesSync();
  await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(roboto)))).load();
}

const _questionMap = {
  'EMWXGUWFINSDUFGNQ871': 'Visit Day (Hari Kunjungan)',
  'MQYGBYEWDJDPVFYDI664': 'Company Name (Nama Perusahaan)',
  'SMGFIUDIVPQQXIWJM293': 'Job Title (Nama Pekerjaan)',
  'CYEUUMQVOZOUGKOYT158': 'Registration Code (Kode Registrasi)',
};

final Map<String, dynamic> _detail = parseDetailModel({
  'fullname': 'Laksa Ersa',
  'email': 'laksa.ersa@example.com',
  // dikirim server sebagai string ter-escape, seperti yang ditangani OrderFormsTypeAdapter
  'order_forms': '[{"id_question":"EMWXGUWFINSDUFGNQ871","answer":"[\\"Day 1, 3 September 2026\\",\\"Day 2, 4 September 2026\\"]"},'
      '{"id_question":"MQYGBYEWDJDPVFYDI664","answer":"PT Keren Entertainment Indonesia"},'
      '{"id_question":"SMGFIUDIVPQQXIWJM293","answer":"\\"Programmer\\""},'
      '{"id_question":"CYEUUMQVOZOUGKOYT158","answer":"AZ01TA"}]',
})!;

Widget _app(Widget page) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: false, fontFamily: 'Roboto'),
    builder: (context, child) {
      initSdp(context);
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: child!,
      );
    },
    home: page,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // flutter_secure_storage: simpan di memory
    final store = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = (call.arguments as Map?) ?? {};
        switch (call.method) {
          case 'write':
            store[args['key'] as String] = args['value'] as String;
            return null;
          case 'readAll':
            return store;
          default:
            return null;
        }
      },
    );
    await _loadFonts();
    await StorageService.init();
    await LangService.preload();
    LangService.updateResource();
  });

  final pages = <String, Widget Function()>{
    'participant_detail2_buyer': () => ParticipantDetail2Page(
        idEvent: allowedEventId, idTicket: '67719535', showQr: '1', detail: _detail, questionMap: _questionMap),
    'participant_detail3_visitor': () => ParticipantDetail3Page(
        idEvent: 'HJUQPPJEBJGJNSOBH299', idTicket: '67719535', showQr: '0', detail: _detail, questionMap: _questionMap),
    'participant_detail_v1': () => const ParticipantDetailPage(extras: {
          'fullName': 'Laksa Ersa',
          'email': 'laksa.ersa@example.com',
          'phone': '0853*****',
          'idTicket': '67719535',
          'answer': 'AZ01TA',
          'companyName': 'PT Keren Entertainment Indonesia',
          'jobTitle': 'Programmer',
          'eventBuyer': 1,
        }),
    'language': () => const LanguagePage(),
    'printer_setting2': () => const PrinterSetting2Page(),
    'input_manual_ticket_activity': () => const InputManualTicketPage(),
    'printer_test_escpos': () => const PrinterTestEscposPage(),
    'printer_test_escpos2': () => const PrinterTestEscpos2Page(),
  };

  for (final entry in pages.entries) {
    testWidgets(entry.key, (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
      tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
      addTearDown(tester.view.reset);
      debugDisableShadows = false; // render bayangan elevation seperti di device

      await tester.pumpWidget(_app(entry.value()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${entry.key}.png'));
      debugDisableShadows = true;
    });
  }
}
