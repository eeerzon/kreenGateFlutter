import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/pages/participant/detail_adapter.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/printer_service.dart';

/// ui/main/ParticipantDetail2Activity (printer Printama)
class ParticipantDetail2Page extends StatefulWidget {
  final String? idEvent;
  final String? idTicket;
  final String? showQr;
  final Map<String, dynamic>? detail;
  final Map<String, String> questionMap;

  const ParticipantDetail2Page({
    super.key,
    this.idEvent,
    this.idTicket,
    this.showQr,
    this.detail,
    this.questionMap = const {},
  });

  @override
  State<ParticipantDetail2Page> createState() => _ParticipantDetail2PageState();
}

class _ParticipantDetail2PageState extends State<ParticipantDetail2Page> {
  String idEvent = "";
  String idTicket = "";
  String showQr = "";
  Map<String, dynamic>? detail;
  Map<String, String> questionMap = {};

  late final bool canPrint;

  @override
  void initState() {
    super.initState();
    setStatusBarColorAndAppearance(white, true);

    idEvent = widget.idEvent ?? "";
    idTicket = widget.idTicket ?? "";
    showQr = widget.showQr ?? "";
    detail = widget.detail;
    questionMap = Map.of(widget.questionMap);

    canPrint = idEvent == allowedEventId;
  }

  void finish() {
    if (mounted) Navigator.of(context).pop();
  }

  void onPrintClick() {
    if (canPrint) {
      checkBluetoothPermissions(() async {
        await getSavedPrinter();
        printTicker4();
      });
    } else {
      finish();
    }
  }

  Future<void> getSavedPrinter() async {
    final connectedPrinter = await PrinterService.printamaConnectedPrinterName();
    if (connectedPrinter != null) {
      /* val connectedTo = findViewById<TextView>(R.id.tv_printer_info) ... */
    } else {
      showPrinterList();
    }
  }

  void showPrinterList() {
    checkBluetoothPermissions(() {
      PrinterService.printamaShowPrinterList().then((printerName) {
        Fluttertoast.showToast(msg: printerName, toastLength: Toast.LENGTH_SHORT);
      });
    });
  }

  void showToast(String message) {
    Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);
  }

  /// Teks yang dicetak (dipakai printTicker4 & testPrint)
  ({String text, bool hasRegistrationCode, String regCode}) _buildPrintText() {
    final fullName = detail?['fullname'] as String? ?? '';
    final email = detail?['email'] as String? ?? '';
    final formValues = (detail?['orderForms'] as List<Map<String, dynamic>>?) ?? const [];

    final strTextBuilder = StringBuffer();
    var company = "";
    var job = "";
    var hasRegistrationCode = false;
    var regCode = "";

    if (formValues.isEmpty) {
      strTextBuilder.write(fullName);
      strTextBuilder.write("\n");
      strTextBuilder.write(email);
      strTextBuilder.write("\n\n");
    } else {
      for (final value in formValues) {
        final idQuestion = value['idQuestion'] as String?;
        final questionText = (idQuestion == null ? null : questionMap[idQuestion]) ?? "";
        switch (questionText) {
          case "Company Name (Nama Perusahaan)":
            company = normalizeAnswer(value['answer'] as String? ?? '');
            break;
          case "Job Title (Nama Pekerjaan)":
            job = normalizeAnswer(value['answer'] as String? ?? '');
            break;
          case "Registration Code (Kode Registrasi)":
            hasRegistrationCode = true;
            regCode = value['answer'] as String? ?? '';
            break;
        }
      }

      if (company.isEmpty) {
        strTextBuilder.write(fullName);
        strTextBuilder.write("\n");
        strTextBuilder.write(email);
        strTextBuilder.write("\n\n");
      } else {
        strTextBuilder.write(company);
        strTextBuilder.write("\n");
        strTextBuilder.write(fullName);
        strTextBuilder.write("\n");
        strTextBuilder.write(job);
        strTextBuilder.write("\n\n");
      }
    }
    return (text: strTextBuilder.toString(), hasRegistrationCode: hasRegistrationCode, regCode: regCode);
  }

  void printTicker4() {
    final built = _buildPrintText();
    final printama = PrintamaOps();

    // Cetak teks
    printama.setNormalText();
    printama.printText(built.text, PrinterService.printamaCenter);

    // Gift icon kalau ada regCode valid
    if (built.hasRegistrationCode && referralCodes.contains(built.regCode.trim())) {
      printama.printImage(PrintamaImage.decodeResource('icon_gift'), 50, PrinterService.printamaLeft);
    }

    // QR Code kalau showQr == "1"
    if (showQr == "1") {
      printama.printImage(PrintamaImage.qrCode(idTicket, 200), 200, PrinterService.printamaCenter);
    }

    printama.addNewLine(4);
    printama.close();

    PrinterService.printamaConnect(printama).then((result) {
      if (result['event'] == 'failed') {
        showToast(result['message'] as String? ?? "Printer error");
      }
    });

    finish();
  }

  void testPrint() {
    final built = _buildPrintText();

    // ==== MODE TEST: tampilkan hasil di Toast, JANGAN print dulu ====
    Fluttertoast.showToast(
      msg: "hasRegistrationCode=${built.hasRegistrationCode}, regCode=[${built.regCode}]\n\n${built.text}",
      toastLength: Toast.LENGTH_LONG,
    );

    debugPrint("PRINT_TEST: strTextBuilder=[${built.text}] regCode=[${built.regCode}]");

    finish();
  }

  @override
  Widget build(BuildContext context) {
    return ParticipantDetailLayout(
      content: DetailAdapter(
        fullname: detail?['fullname'] as String?,
        email: detail?['email'] as String?,
        detail: (detail?['orderForms'] as List<Map<String, dynamic>>?) ?? const [],
        questionMap: questionMap,
      ),
      printText: canPrint ? LangService.getString('print') : LangService.getString('completed'),
      onPrint: onPrintClick,
      onBack: finish,
      onClose: finish,
    );
  }
}
