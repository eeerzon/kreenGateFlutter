import 'package:flutter/material.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/pages/participant/detail_adapter.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/printer_service.dart';

/// ui/main/ParticipantDetail3Activity (printer ESC/POS)
class ParticipantDetail3Page extends StatefulWidget {
  final String? idEvent;
  final String? idTicket;
  final String? showQr;
  final Map<String, dynamic>? detail;
  final Map<String, String> questionMap;

  const ParticipantDetail3Page({
    super.key,
    this.idEvent,
    this.idTicket,
    this.showQr,
    this.detail,
    this.questionMap = const {},
  });

  @override
  State<ParticipantDetail3Page> createState() => _ParticipantDetail3PageState();
}

class _ParticipantDetail3PageState extends State<ParticipantDetail3Page> {
  String idEvent = "";
  String idTicket = "";
  String showQr = "";
  Map<String, dynamic>? detail;
  final String printType = "escpos";
  Map<String, String> questionMap = {};

  late final bool canPrint;

  /// selectedDevice: index BluetoothConnection dari dialog pilihan, null = default (selectFirstPaired)
  int? selectedDevice;

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
      checkBluetoothPermissions(() => printBluetooth());
    } else {
      finish();
    }
  }

  // ===============================================================================
  // BLUETOOTH PART
  // ===============================================================================

  void browseBluetoothDevice() {
    checkBluetoothPermissions(() async {
      final selected = await PrinterService.escposBrowseBluetoothDevice();
      final index = selected['index'] as int;
      selectedDevice = index == -1 ? null : index;
      // binding.btnBluetoothBrowse.text = items[i1]
    });
  }

  // myAdd
  void printBluetooth() {
    checkBluetoothPermissions(() async {
      final result = await PrinterService.escposPrintBluetooth(
        deviceIndex: selectedDevice,
        printerDpi: 203,
        printerWidthMM: 48,
        printerNbrCharactersPerLine: 32,
        textsToPrint: [getAsyncEscPosPrinterText(idTicket)],
      );
      if (result['event'] == 'success') {
        debugPrint("Async.OnPrintFinished: AsyncEscPosPrint.OnPrintFinished : Print is finished !");
      } else {
        debugPrint("Async.OnPrintFinished: AsyncEscPosPrint.OnPrintFinished : An error occurred !");
      }
    });
  }

  // ===============================================================================
  // ESC/POS PRINTER PART
  // ===============================================================================

  /// getAsyncEscPosPrinter(printerConnection, idTicket): AsyncEscPosPrinter(conn, 203, 48f, 32).addTextToPrint(...)
  String getAsyncEscPosPrinterText(String idTicket) {
    final fullName = detail?['fullname'] as String? ?? '';
    final email = detail?['email'] as String? ?? '';
    final formValues = (detail?['orderForms'] as List<Map<String, dynamic>>?) ?? const [];

    final strTextBuilder = StringBuffer();
    var company = "";
    var job = "";
    var hasRegistrationCode = false;
    var regCode = "";

    if (formValues.isEmpty) {
      strTextBuilder.write("[C]$fullName\n");
      strTextBuilder.write("[C]$email\n\n");
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
        strTextBuilder.write("[C]$fullName\n");
        strTextBuilder.write("[C]$email\n\n");
      } else {
        strTextBuilder.write("[C]$company\n");
        strTextBuilder.write("[C]$fullName\n");
        strTextBuilder.write("[C]$job\n\n");
      }
    }

    // Gift icon kalau ada regCode valid
    if (hasRegistrationCode && referralCodes.contains(regCode.trim())) {
      // AsyncEscPosPrinter tidak bisa langsung load bitmap, tapi bisa kasih simbol teks khusus
      strTextBuilder.write("[L]<img>$regCode</img>\n");
    }

    // QR Code kalau showQr == "1"
    if (showQr == "1") {
      strTextBuilder.write("[C]<qrcode size='20'>$idTicket</qrcode>\n");
    }

    return strTextBuilder.toString();
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
