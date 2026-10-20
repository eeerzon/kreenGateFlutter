import 'package:flutter/material.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/pages/auth/login_event_page.dart';
import 'package:kreengate/pages/setting/language_page.dart';
import 'package:kreengate/pages/setting/printer_setting2_page.dart';
import 'package:kreengate/pages/setting/printer_setting_page.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/storage_services.dart';

/// nav/SettingFragment
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String? printTypeSDK;

  final String setting = LangService.getString('setting');
  final String printerSettings = LangService.getString('printer_settings');
  final String details = LangService.getString('details');
  final String eventDetail = LangService.getString('event_detail');
  final String language = LangService.getString('language');
  final String logoutText = LangService.getString('logout');

  @override
  void initState() {
    super.initState();
    printTypeSDK = StorageService.getPrintTypeSdk();
    debugPrint("ikann = $printTypeSDK");
  }

  void onPrinterSettingClick() {
    final Widget? page = switch (printTypeSDK) {
      printTypeEscpos => const PrinterSetting2Page(),
      printTypePrintama => const PrinterSettingPage(),
      _ => null,
    };
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  void onLanguageClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguagePage()));
  }

  void logout() {
    StorageService.clearEvent();
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LoginEventPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  Widget _row(String title, {required VoidCallback onTap, bool showDetails = true}) {
    return Clickable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: dsdp(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AText(title, font: AFont.medium, size: dssp(16), color: colorTextPrimary),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showDetails) AText(details, font: AFont.medium, size: dssp(14), color: colorTextSecondary),
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: dsdp(5)),
                      child: SvgIcon('ic_chevron_right',
                          width: dsdp(20), height: dsdp(20), tint: colorTextPrimary, fit: BoxFit.cover),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: dsdp(15)),
              child: Container(height: dsdp(2), color: colorStroke),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AWindow(
      statusBarColor: white,
      background: colorBg,
      edgeToEdge: edgeToEdge,
      child: Column(
        children: [
          AToolbar(
            background: white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: dsdp(10)),
              child: SizedBox(
                width: double.infinity,
                child: AText(setting, font: AFont.bold, bold: true, size: dssp(16), color: black),
              ),
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const NoOverscroll(),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(height: dsdp(2), color: colorStroke),
                    Container(
                      color: white,
                      padding: EdgeInsets.only(left: dsdp(16), right: dsdp(16), top: dsdp(10)),
                      child: Padding(
                        padding: EdgeInsets.only(top: dsdp(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _row(printerSettings, onTap: onPrinterSettingClick),
                            // layEventDetail & layLanguage: android:visibility="gone"
                            Offstage(child: _row(eventDetail, onTap: () {})),
                            Offstage(child: _row(language, onTap: onLanguageClick, showDetails: false)),
                          ],
                        ),
                      ),
                    ),
                    Container(height: dsdp(10), color: colorBg),
                    Padding(
                      padding: EdgeInsets.only(left: dsdp(16), right: dsdp(16), top: dsdp(50)),
                      child: MButton(
                        text: logoutText,
                        height: dsdp(60),
                        cornerRadius: dsdp(20),
                        textSize: dssp(16),
                        onPressed: logout,
                      ),
                    ),
                    SizedBox(height: dsdp(60)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
