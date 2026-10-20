import 'package:flutter/material.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/storage_services.dart';

/// nav/HomeFragment
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? idEvent;
  String? titleEvent;

  // teks layout (diambil saat inflate, tidak berubah sampai fragment dibuat ulang)
  final String kreen = LangService.getString('kreen');
  final String scanYourTicket = LangService.getString('scan_your_ticket_qr_code_first_or_enter_the_ticket_code');

  @override
  void initState() {
    super.initState();
    idEvent = StorageService.getIdEvent();
    titleEvent = StorageService.getTitleEvent();
  }

  @override
  Widget build(BuildContext context) {
    return AWindow(
      statusBarColor: colorPrimary,
      background: white,
      edgeToEdge: edgeToEdge,
      child: Column(
        children: [
          // mainToolbar
          AToolbar(
            background: colorPrimary,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: dsdp(10)),
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: dsdp(16)),
                child: SizedBox(
                  width: double.infinity,
                  child: AText(kreen, font: AFont.bold, bold: true, size: dssp(20), color: white),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: dsdp(20)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: dsdp(15)),
                            child: SizedBox(
                              width: double.infinity,
                              child: AText(titleEvent ?? '',
                                  font: AFont.bold,
                                  bold: true,
                                  size: dssp(16),
                                  color: colorTextPrimary,
                                  align: TextAlign.center),
                            ),
                          ),
                          Image.asset('assets/images/kiosk_phone.png', width: dsdp(120), height: dsdp(120)),
                          Padding(
                            padding: EdgeInsets.only(top: dsdp(20), left: dsdp(50), right: dsdp(50)),
                            child: SizedBox(
                              width: double.infinity,
                              child: AText(scanYourTicket,
                                  font: AFont.medium,
                                  size: dssp(14),
                                  color: colorTextSecondary,
                                  align: TextAlign.center),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
