import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/pages/setting/printer_setting_page.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/printer_service.dart';

/// ui/main/PrinterSetting2Activity (ESC/POS)
class PrinterSetting2Page extends StatefulWidget {
  const PrinterSetting2Page({super.key});

  @override
  State<PrinterSetting2Page> createState() => _PrinterSetting2PageState();
}

class _PrinterSetting2PageState extends State<PrinterSetting2Page> {
  String tvPrinterInfo = LangService.getString('printer_is_not_found');
  bool btnPrinterTestVisible = false;

  int? selectedDevice;

  @override
  void initState() {
    super.initState();
    // Activity ini tidak mengatur status bar -> window default tema (putih, ikon terang)
    setStatusBarColorAndAppearance(const Color(0xFFFFFFFF), false);
  }

  // ===============================================================================
  // BLUETOOTH PART
  // ===============================================================================

  void browseBluetoothDevice() {
    checkBluetoothPermissions(() async {
      final selected = await PrinterService.escposBrowseBluetoothDevice();
      if (!mounted) return;
      final index = selected['index'] as int;
      setState(() {
        selectedDevice = index == -1 ? null : index;
        tvPrinterInfo = selected['label'] as String? ?? 'null';
        btnPrinterTestVisible = true;
      });
    });
  }

  // myAdd
  void printBluetooth() {
    checkBluetoothPermissions(() async {
      final result = await PrinterService.escposPrintBluetooth(
        deviceIndex: selectedDevice,
        printerDpi: 203,
        printerWidthMM: 80,
        printerNbrCharactersPerLine: 32,
        textsToPrint: [getAsyncEscPosPrinterText("123456")],
      );
      debugPrint(result['event'] == 'success'
          ? "Async.OnPrintFinished: AsyncEscPosPrint.OnPrintFinished : Print is finished !"
          : "Async.OnPrintFinished: AsyncEscPosPrint.OnPrintFinished : An error occurred !");
    });
  }

  // ===============================================================================
  // ESC/POS PRINTER PART
  // ===============================================================================

  String getAsyncEscPosPrinterText(String idTicket) {
    // ignore: unused_local_variable
    final format = DateFormat("'on' yyyy-MM-dd 'at' HH:mm:ss");
    return "[C]TEST PRINT\n"
        "[C]\n"
        "[C]<qrcode size='20'>$idTicket</qrcode>\n"
        "[C]TEST PRINT\n";
  }

  @override
  Widget build(BuildContext context) {
    return PrinterSettingLayout(
      title: LangService.getString('printer_settings'),
      printerInfo: tvPrinterInfo,
      showPrinterTest: btnPrinterTestVisible,
      onPrinterSettings: browseBluetoothDevice,
      onPrinterTest: printBluetooth,
      onBack: () => Navigator.of(context).pop(),
    );
  }
}
