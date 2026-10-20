import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/pages/setting/printer_setting_page.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/printer_service.dart';

/// printer/printama/PrinterTestPrintama2Activity (layout = activity_printer_setting dengan judul literal)
class PrinterTestPrintama2Page extends StatefulWidget {
  const PrinterTestPrintama2Page({super.key});

  @override
  State<PrinterTestPrintama2Page> createState() => _PrinterTestPrintama2PageState();
}

class _PrinterTestPrintama2PageState extends State<PrinterTestPrintama2Page> {
  String tvPrinterInfo = LangService.getString('printer_is_not_found');
  bool btnPrinterTestVisible = false;

  @override
  void initState() {
    super.initState();
    setStatusBarColorAndAppearance(white, true);
    checkBluetoothPermissionsBatch(() => getSavedPrinter());
  }

  void printTextCenter() {
    final ops = PrintamaOps()
      ..printText("Test Print", PrinterService.printamaCenter)
      ..close();
    debugPrint("BluetoothError: Print command sent");
    PrinterService.printamaConnect(ops, withOnFailed: false);
  }

  Future<void> getSavedPrinter() async {
    final connectedPrinter = await PrinterService.printamaConnectedPrinterName();
    if (connectedPrinter != null && mounted) {
      setState(() => tvPrinterInfo = "Connected to : $connectedPrinter");
    }
  }

  void showPrinterList() {
    checkBluetoothPermissionsBatch(() async {
      final printerName = await PrinterService.printamaShowPrinterList();
      Fluttertoast.showToast(msg: printerName, toastLength: Toast.LENGTH_SHORT);
      if (!mounted) return;
      setState(() {
        tvPrinterInfo = "Connected to : $printerName";
        if (!printerName.contains("failed")) btnPrinterTestVisible = true;
      });
    });
  }

  void showResult(String printerName) {
    Fluttertoast.showToast(msg: printerName, toastLength: Toast.LENGTH_SHORT);
    setState(() {
      tvPrinterInfo = "Connected to : $printerName";
      if (!printerName.contains("failed")) btnPrinterTestVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrinterSettingLayout(
      title: "printer_settings",
      printerInfo: tvPrinterInfo,
      showPrinterTest: btnPrinterTestVisible,
      onPrinterSettings: showPrinterList,
      onPrinterTest: printTextCenter,
      onBack: () => Navigator.of(context).pop(),
    );
  }
}
