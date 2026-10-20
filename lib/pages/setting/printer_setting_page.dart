import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/printer_service.dart';

/// Layout activity_printer_setting.xml (juga activity_printer_setting2 & activity_printer_test_printama2).
class PrinterSettingLayout extends StatelessWidget {
  final String title;
  final String printerInfo;
  final bool showPrinterTest;
  final VoidCallback onPrinterSettings;
  final VoidCallback onPrinterTest;
  final VoidCallback onBack;

  const PrinterSettingLayout({
    super.key,
    required this.title,
    required this.printerInfo,
    required this.showPrinterTest,
    required this.onPrinterSettings,
    required this.onPrinterTest,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final margin = dsdp(8);
    return Scaffold(
      backgroundColor: white,
      body: AWindow(
        statusBarColor: white,
        background: white,
        edgeToEdge: edgeToEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AToolbar(
              background: white,
              child: Padding(
                padding: EdgeInsets.only(top: dsdp(10), bottom: dsdp(10), right: dsdp(16)),
                child: Row(children: [
                  Clickable(
                    onTap: onBack,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: dsdp(10)),
                      child: SvgIcon('ic_arrow_back', width: dsdp(25), height: dsdp(25), tint: colorTextPrimary),
                    ),
                  ),
                  Expanded(child: AText(title, font: AFont.bold, bold: true, size: dssp(16), color: black)),
                ]),
              ),
            ),
            Container(height: dsdp(2), color: colorStroke),
            Padding(
              padding: EdgeInsets.only(top: dsdp(20)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(margin),
                      child: ACard(
                        color: colorPrimary,
                        radius: dsdp(25),
                        onTap: onPrinterSettings,
                        child: SizedBox(
                          height: dsdp(50),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.only(start: dsdp(10)),
                                child: Container(
                                  color: colorPrimary,
                                  padding: EdgeInsets.all(dsdp(10)),
                                  child: const SvgIcon('ic_print', width: 24, height: 24, tint: colorWhite),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  color: colorPrimary,
                                  child: AText(printerInfo, font: AFont.medium, size: dssp(12), color: colorWhite),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.only(end: dsdp(8)),
                                child: Padding(
                                  padding: EdgeInsets.all(dsdp(8)),
                                  child: const SvgIcon('ic_settings', width: 24, height: 24, tint: white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showPrinterTest)
                    Padding(
                      padding: EdgeInsetsDirectional.only(top: margin, end: margin, bottom: margin),
                      child: SizedBox(
                        width: dsdp(50),
                        height: dsdp(50),
                        child: ACard(
                          color: colorPrimary,
                          radius: dsdp(25),
                          onTap: onPrinterTest,
                          child: Center(
                            child: AText(LangService.getString('test'),
                                font: AFont.medium, size: dssp(12), color: colorWhite, align: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ui/main/PrinterSettingActivity (Printama)
class PrinterSettingPage extends StatefulWidget {
  const PrinterSettingPage({super.key});

  @override
  State<PrinterSettingPage> createState() => _PrinterSettingPageState();
}

class _PrinterSettingPageState extends State<PrinterSettingPage> {
  String tvPrinterInfo = LangService.getString('printer_is_not_found');
  bool btnPrinterTestVisible = false;

  @override
  void initState() {
    super.initState();
    setStatusBarColorAndAppearance(white, true);
    checkBluetoothPermissions(() => getSavedPrinter());
  }

  void testPrinter() {
    PrinterService.printamaPrintTest();
  }

  Future<void> getSavedPrinter() async {
    final connectedPrinter = await PrinterService.printamaConnectedPrinterName();
    if (connectedPrinter != null && mounted) {
      setState(() => tvPrinterInfo = "Connected to : $connectedPrinter");
    }
  }

  void showPrinterList() {
    checkBluetoothPermissions(() async {
      final printerName = await PrinterService.printamaShowPrinterList();
      Fluttertoast.showToast(msg: printerName, toastLength: Toast.LENGTH_SHORT);
      if (!mounted) return;
      setState(() {
        tvPrinterInfo = "Connected to : $printerName";
        if (!printerName.contains("failed")) {
          btnPrinterTestVisible = true;
        }
      });
    });
  }

  /// showResult (dipakai printerListLauncher)
  void showResult(String printerName) {
    showToast(printerName);
    setState(() {
      tvPrinterInfo = "Connected to : $printerName";
      if (!printerName.contains("failed")) btnPrinterTestVisible = true;
    });
  }

  void showToast(String message) => Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);

  @override
  Widget build(BuildContext context) {
    return PrinterSettingLayout(
      title: LangService.getString('printer_settings'),
      printerInfo: tvPrinterInfo,
      showPrinterTest: btnPrinterTestVisible,
      onPrinterSettings: showPrinterList,
      onPrinterTest: testPrinter,
      onBack: () => Navigator.of(context).pop(),
    );
  }
}
