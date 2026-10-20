import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/pages/printer_test/printer_test_escpos2_page.dart';
import 'package:kreengate/services/printer_service.dart';

/// Tombol android.widget.Button di layout test (MaterialComponents -> MaterialButton, textAllCaps)
Widget escposTestButton(String text, VoidCallback onTap) {
  return IntrinsicWidth(
    child: MButton(
      text: text,
      height: 48,
      cornerRadius: 4,
      font: AFont.robotoMedium,
      textSize: 14 * systemTextScale,
      bold: false,
      allCaps: true,
      onPressed: onTap,
    ),
  );
}

/// TextView default (TextAppearance.Small: 14sp, textColorSecondary)
Widget escposTestText(String text) =>
    AText(text, size: 14 * systemTextScale, color: const Color(0x8A000000));

/// printer/escpos/PrinterTestEscposActivity
class PrinterTestEscposPage extends StatefulWidget {
  const PrinterTestEscposPage({super.key});

  @override
  State<PrinterTestEscposPage> createState() => _PrinterTestEscposPageState();
}

class _PrinterTestEscposPageState extends State<PrinterTestEscposPage> {
  int? selectedDevice;
  String btnBluetoothBrowseText = "Default printer";

  final TextEditingController ipAddress = TextEditingController();
  final TextEditingController portAddress = TextEditingController();

  @override
  void initState() {
    super.initState();
    setStatusBarColorAndAppearance(white, false);
  }

  @override
  void dispose() {
    ipAddress.dispose();
    portAddress.dispose();
    super.dispose();
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

  void _logResult(Map<String, dynamic> result) {
    debugPrint(result['event'] == 'success'
        ? "Async.OnPrintFinished: AsyncEscPosPrint.OnPrintFinished : Print is finished !"
        : "Async.OnPrintFinished: AsyncEscPosPrint.OnPrintFinished : An error occurred !");
  }

  void printBluetooth() {
    checkBluetoothPermissions(() async {
      _logResult(await PrinterService.escposPrintBluetooth(
        deviceIndex: selectedDevice,
        printerDpi: 203,
        printerWidthMM: 48,
        printerNbrCharactersPerLine: 32,
        textsToPrint: [getAsyncEscPosPrinterText()],
      ));
    });
  }

  // myAdd
  void printBluetooth2() {
    checkBluetoothPermissions(() async {
      _logResult(await PrinterService.escposPrintBluetooth(
        deviceIndex: selectedDevice,
        printerDpi: 150,
        printerWidthMM: 80,
        printerNbrCharactersPerLine: 10,
        textsToPrint: [getAsyncEscPosPrinter2Text()],
      ));
    });
  }

  // USB PART
  void printUsb() {
    PrinterService.escposPrintUsb(
      printerDpi: 203,
      printerWidthMM: 48,
      printerNbrCharactersPerLine: 32,
      textsToPrint: [getAsyncEscPosPrinterText()],
    );
  }

  // TCP PART
  Future<void> printTcp() async {
    // Kotlin String.toInt(): tanpa spasi, boleh tanda +/-
    final portText = portAddress.text;
    final port = RegExp(r'^[+-]?\d+$').hasMatch(portText) ? int.tryParse(portText) : null;
    if (port == null || port > 2147483647 || port < -2147483648) {
      PrinterService.showNativeAlert("Invalid TCP port address", "Port field must be an integer.");
      return;
    }
    _logResult(await PrinterService.escposPrintTcp(
      ipAddress: ipAddress.text,
      port: port,
      printerDpi: 203,
      printerWidthMM: 48,
      printerNbrCharactersPerLine: 32,
      textsToPrint: [getAsyncEscPosPrinterText()],
    ));
  }

  // ESC/POS PRINTER PART
  String getAsyncEscPosPrinterText() {
    final format = DateFormat("'on' yyyy-MM-dd 'at' HH:mm:ss");
    return "[C]<img>{{IMG_HEX:logo}}</img>\n"
        "[L]\n"
        "[C]<u><font size='big'>ORDER N°045</font></u>\n"
        "[L]\n"
        "[C]<u type='double'>${format.format(DateTime.now())}</u>\n"
        "[C]\n"
        "[C]================================\n"
        "[L]\n"
        "[L]<b>BEAUTIFUL SHIRT</b>[R]9.99€\n"
        "[L]  + Size : S\n"
        "[L]\n"
        "[L]<b>AWESOME HAT</b>[R]24.99€\n"
        "[L]  + Size : 57/58\n"
        "[L]\n"
        "[C]--------------------------------\n"
        "[R]TOTAL PRICE :[R]34.98€\n"
        "[R]TAX :[R]4.23€\n"
        "[L]\n"
        "[C]================================\n"
        "[L]\n"
        "[L]<u><font color='bg-black' size='tall'>Customer :</font></u>\n"
        "[L]Raymond DUPONT\n"
        "[L]5 rue des girafes\n"
        "[L]31547 PERPETES\n"
        "[L]Tel : +33801201456\n"
        "\n"
        "[C]<barcode type='ean13' height='10'>831254784551</barcode>\n"
        "[L]\n"
        "[C]<qrcode size='20'>https://dantsu.com/</qrcode>\n";
  }

  String getAsyncEscPosPrinter2Text() {
    return "[C]IKAN[C]\n"
        "[C]<barcode type='ean13' height='10'>831254784551</barcode>\n"
        "[C]IKAN\n"
        "[C]<barcode type='ean13' height='10'>831254784551</barcode>\n";
  }

  Widget _field(TextEditingController c, double width, {bool ipDigits = false}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        cursorColor: colorPrimaryLight,
        inputFormatters: ipDigits ? [FilteringTextInputFormatterDigitsDot()] : null,
        decoration: const InputDecoration(
          isDense: true,
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0x8A000000))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorPrimaryLight, width: 2)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      resizeToAvoidBottomInset: !edgeToEdge,
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
              Padding(padding: const EdgeInsets.only(bottom: 20), child: escposTestButton("Print by USB !", printUsb)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Padding(padding: const EdgeInsets.only(right: 5), child: escposTestText("IP :")),
                _field(ipAddress, 170, ipDigits: true),
                Padding(padding: const EdgeInsets.only(left: 20, right: 5), child: escposTestText("Port :")),
                _field(portAddress, 80),
              ]),
              Padding(padding: const EdgeInsets.only(bottom: 20), child: escposTestButton("Print by TCP !", printTcp)),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: escposTestButton("NEXT", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterTestEscpos2Page()));
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// android:digits="0123456789."
class FilteringTextInputFormatterDigitsDot extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return RegExp(r'^[0-9.]*$').hasMatch(newValue.text) ? newValue : oldValue;
  }
}
