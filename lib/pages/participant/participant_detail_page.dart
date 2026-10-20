import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/pages/participant/detail_adapter.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/printer_service.dart';

/// ui/main/ParticipantDetailActivity (versi lama, data dari booking_redeem2_coex)
class ParticipantDetailPage extends StatefulWidget {
  /// Intent extras: fullName, email, phone, idTicket, answer, companyName, jobTitle (String), eventBuyer (Int)
  final Map<String, dynamic>? extras;

  const ParticipantDetailPage({super.key, this.extras});

  @override
  State<ParticipantDetailPage> createState() => _ParticipantDetailPageState();
}

class _ParticipantDetailPageState extends State<ParticipantDetailPage> {
  String fullName = "";
  String email = "";
  String phone = "";
  String idTicket = "";
  String answer = "";
  String companyName = "";
  String jobTitle = "";
  int eventBuyer = 0;

  @override
  void initState() {
    super.initState();
    setStatusBarColorAndAppearance(white, true);

    final extras = widget.extras;
    if (extras != null) {
      // extras.getString("x").toString() -> "null" kalau tidak ada
      String s(String key) => extras[key]?.toString() ?? "null";
      fullName = s("fullName");
      email = s("email");
      phone = s("phone");
      idTicket = s("idTicket");
      answer = s("answer");
      companyName = s("companyName");
      jobTitle = s("jobTitle");
      eventBuyer = extras["eventBuyer"] is int ? extras["eventBuyer"] as int : 0;
    }
  }

  void finish() {
    if (mounted) Navigator.of(context).pop();
  }

  void onPrintClick() {
    checkBluetoothPermissions(() async {
      await getSavedPrinter();
      printTickerOnly();
    });
  }

  Future<void> getSavedPrinter() async {
    final connectedPrinter = await PrinterService.printamaConnectedPrinterName();
    if (connectedPrinter == null) showPrinterList();
  }

  void showPrinterList() {
    checkBluetoothPermissions(() {
      PrinterService.printamaShowPrinterList().then((printerName) {
        Fluttertoast.showToast(msg: printerName, toastLength: Toast.LENGTH_SHORT);
      });
    });
  }

  void showToast(String message) => Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);

  ({String title, String subtitle, String job}) _titles() {
    if (eventBuyer > 0) return (title: fullName, subtitle: companyName, job: jobTitle);
    return (title: fullName, subtitle: "", job: "");
  }

  void _connect(PrintamaOps printama) {
    PrinterService.printamaConnect(printama).then((result) {
      if (result['event'] == 'failed') showToast(result['message'] as String);
    });
    finish();
  }

  PrintamaImage _giftOrBlank() => answer != "" && answer != "-"
      ? PrintamaImage.fromVector('icon_gift')
      : PrintamaImage.fromVector('ic_checked_blank');

  void printTicker() {
    final t = _titles();
    final printama = PrintamaOps();
    final text = [t.subtitle, t.title, t.job, email, phone].where((it) => it.isNotEmpty).join("\n");
    printama.printText(text, PrinterService.printamaCenter);
    printama.printImage(_giftOrBlank(), 50, PrinterService.printamaRight);
    printama.setNormalText();
    printama.printText("QR Code", PrinterService.printamaRight);
    printama.printImage(PrintamaImage.qrCode(idTicket, 200), 200, PrinterService.printamaRight);
    printama.addNewLine(1);
    printama.close();
    _connect(printama);
  }

  void printTicker2() {
    final t = _titles();
    final printama = PrintamaOps();
    final text = [t.subtitle, t.title, t.job, phone, email, answer].where((it) => it.isNotEmpty).join("\n");
    printama.printText(text, PrinterService.printamaLeft);
    printama.printImage(_giftOrBlank(), 50, PrinterService.printamaLeft);
    printama.setNormalText();
    printama.printText("QR Code", PrinterService.printamaRight);
    printama.printImage(PrintamaImage.qrCode(idTicket, 200), 200, PrinterService.printamaRight);
    printama.addNewLine(1);
    printama.close();
    _connect(printama);
  }

  void printTicker3() {
    final t = _titles();
    final printama = PrintamaOps();
    final text = [t.subtitle, t.title, t.job, phone, email, answer].where((it) => it.isNotEmpty).join("\n");
    printama.printText(text, PrinterService.printamaLeft);
    printama.addNewLine(1);
    final leftBitmap = answer.isNotEmpty && answer != "-"
        ? PrintamaImage.fromVector('icon_gift')
        : PrintamaImage.fromVector('ic_checked_blank');
    final qrCodeBitmap = PrintamaImage.qrCode(idTicket, 200, emptyOnError: true);
    // printImage(rowBitmap, rowBitmap.width, LEFT): width -1 = lebar bitmap gabungan (dihitung native)
    printama.call('printImage', [PrintamaImage.row(leftBitmap, qrCodeBitmap), -100, PrinterService.printamaLeft]);
    printama.addNewLine(1);
    printama.close();
    _connect(printama);
  }

  void printTicker4() {
    final t = _titles();
    final printama = PrintamaOps();
    final text = [t.subtitle, t.title, t.job, phone, email, answer].where((it) => it.isNotEmpty).join("\n");
    printama.printText(text, PrinterService.printamaRight);
    printama.addNewLine(1);
    printama.printImage(PrintamaImage.qrCode(idTicket, 200), 200, PrinterService.printamaRight);
    printama.addNewLine(1);
    printama.close();
    _connect(printama);
  }

  void printTickerOnly() {
    final t = _titles();
    final printama = PrintamaOps();
    final text = [t.subtitle, t.title, t.job, phone, email, answer].where((it) => it.isNotEmpty).join("\n");
    printama.printText(text, PrinterService.printamaLeft);
    printama.addNewLine(1);
    printama.setNormalText();
    printama.printText("QR Code", PrinterService.printamaRight);
    printama.addNewLine(1);
    printama.close();
    _connect(printama);
  }

  Widget _field(String label, String value, {double marginTop = 0, int? maxLines, bool center = false}) {
    return Padding(
      padding: EdgeInsets.only(top: marginTop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AText(label, font: AFont.poppins, size: dssp(12), color: colorTextPrimary,
              align: center ? TextAlign.center : TextAlign.start),
          AText(value, font: AFont.bold, bold: true, size: dssp(14), color: colorTextPrimary,
              maxLines: maxLines, align: center ? TextAlign.center : TextAlign.start),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final full = eventBuyer > 0;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (full)
          Container(
            color: colorStrokeBg,
            padding: EdgeInsets.all(dsdp(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(LangService.getString('full_name'), fullName),
                _field(LangService.getString('company_name'), companyName, marginTop: dsdp(10), maxLines: 2),
                _field(LangService.getString('city'), jobTitle, marginTop: dsdp(10), maxLines: 2),
                if (phone.isNotEmpty) _field(LangService.getString('phone'), phone, marginTop: dsdp(10), maxLines: 2),
                if (email.isNotEmpty) _field(LangService.getString('email'), email, marginTop: dsdp(10), maxLines: 2),
                if (answer.isNotEmpty) _field(LangService.getString('code'), answer, marginTop: dsdp(10), maxLines: 2),
              ],
            ),
          )
        else
          Padding(
            padding: EdgeInsets.all(dsdp(15)),
            child: _field(LangService.getString('full_name'), fullName, center: true),
          ),
      ],
    );
    return ParticipantDetailLayout(
      content: content,
      printText: LangService.getString('print'),
      onPrint: onPrintClick,
      onBack: finish,
      onClose: finish,
    );
  }
}
