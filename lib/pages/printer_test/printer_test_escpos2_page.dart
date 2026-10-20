import 'package:flutter/material.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/pages/printer_test/printer_test_escpos_page.dart';
import 'package:kreengate/services/printer_service.dart';

/// printer/escpos/PrinterTestEscpos2Activity
class PrinterTestEscpos2Page extends StatefulWidget {
  const PrinterTestEscpos2Page({super.key});

  @override
  State<PrinterTestEscpos2Page> createState() => _PrinterTestEscpos2PageState();
}

class _PrinterTestEscpos2PageState extends State<PrinterTestEscpos2Page> {
  int? selectedDevice;
  String btnBluetoothBrowseText = "Default printer";

  @override
  void initState() {
    super.initState();
    setStatusBarColorAndAppearance(white, false);
  }

  void browseBluetoothDevice() {
    checkBluetoothPermissions(() async {
      final selected = await PrinterService.escposBrowseBluetoothDevice();
      if (!mounted) return;
      final index = selected['index'] as int;
      setState(() {
        selectedDevice = index == -1 ? null : index;
        btnBluetoothBrowseText = selected['label'] as String? ?? 'null';
      });
    });
  }

  // myAdd
  void printBluetooth2() {
    checkBluetoothPermissions(() async {
      final result = await PrinterService.escposPrintBluetooth(
        deviceIndex: selectedDevice,
        printerDpi: 150,
        printerWidthMM: 80,
        printerNbrCharactersPerLine: 10,
        textsToPrint: [getAsyncEscPosPrinter3Text("123456")],
      );
      debugPrint(result['event'] == 'success'
          ? "Async.OnPrintFinished: AsyncEscPosPrint.OnPrintFinished : Print is finished !"
          : "Async.OnPrintFinished: AsyncEscPosPrint.OnPrintFinished : An error occurred !");
    });
  }

  String getAsyncEscPosPrinter3Text(String idTicket) {
    return "[C]budiman\n"
        "[C]Programmer\n"
        "[C]PT Indonesia Berkarya\n"
        "[L]\n"
        "[C]<qrcode size='20'>$idTicket</qrcode>\n";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: AWindow(
        statusBarColor: white,
        background: white,
        edgeToEdge: edgeToEdge,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.only(bottom: 20), child: escposTestText("Click to print !")),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: escposTestButton(btnBluetoothBrowseText, browseBluetoothDevice),
                  ),
                  escposTestButton("Print by bluetooth !", printBluetooth2),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

