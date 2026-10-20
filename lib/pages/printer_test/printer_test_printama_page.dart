import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/services/printer_service.dart';

/// printer/printama/PrinterTestPrintamaActivity
class PrinterTestPrintamaPage extends StatefulWidget {
  const PrinterTestPrintamaPage({super.key});

  @override
  State<PrinterTestPrintamaPage> createState() => _PrinterTestPrintamaPageState();
}

class _PrinterTestPrintamaPageState extends State<PrinterTestPrintamaPage> {
  final GlobalKey rootView = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Activity ini tidak mengatur status bar -> window default tema
    setStatusBarColorAndAppearance(white, false);
    checkBluetoothPermissions(() => getSavedPrinter());
  }

  Future<void> getSavedPrinter() async {
    final connectedPrinter = await PrinterService.printamaConnectedPrinterName();
    if (connectedPrinter == null) showPrinterList();
  }

  void showPrinterList() {
    checkBluetoothPermissions(() async {
      final printerName = await PrinterService.printamaShowPrinterList();
      Fluttertoast.showToast(msg: printerName, toastLength: Toast.LENGTH_SHORT);
    });
  }

  void showToast(String message) => Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);

  void testPrinter() => PrinterService.printamaPrintTest();

  /// connect { } tanpa onFailed
  void _connect(PrintamaOps ops) => PrinterService.printamaConnect(ops, withOnFailed: false);

  /// connect({ }) { message -> showToast(message!!) }
  void _connectWithFailed(PrintamaOps ops, {String? toastIfFirstResultFalse}) {
    PrinterService.printamaConnect(ops).then((result) {
      if (result['event'] == 'failed') {
        showToast(result['message'] as String);
      } else if (toastIfFirstResultFalse != null) {
        final results = result['results'] as List?;
        if (results != null && results.isNotEmpty && results.first == false) {
          Fluttertoast.showToast(msg: toastIfFirstResultFalse, toastLength: Toast.LENGTH_SHORT);
        }
      }
    });
  }

  static String _text(String align) => "-------------\n"
      "This will be printed\n"
      "$align aligned\n"
      "cool isn't it?\n"
      "------------------\n";

  void printTextLeft() {
    final p = PrintamaOps()
      ..printText(_text("Left"), PrinterService.printamaLeft)
      ..close();
    _connect(p);
  }

  void printTextCenter() {
    final p = PrintamaOps()
      ..printText(_text("Center"), PrinterService.printamaCenter)
      ..close();
    _connect(p);
  }

  void printTextRight() {
    final p = PrintamaOps()
      ..printText(_text("Right"), PrinterService.printamaRight)
      ..close();
    _connect(p);
  }

  void printTextJustified() {
    final p = PrintamaOps()
      ..call('printTextJustify', ["text1", "text2"])
      ..call('printTextJustify', ["text1", "text2", "text3"])
      ..call('printTextJustify', ["text1", "text2", "text3", "text4"])
      ..call('printTextJustifyBold', ["text1", "text2"])
      ..call('printTextJustifyBold', ["text1", "text2", "text3"])
      ..call('printTextJustifyBold', ["text1", "text2", "text3", "text4"])
      ..setNormalText()
      ..feedPaper()
      ..close();
    _connectWithFailed(p);
  }

  void printTextStyles() {
    final p = PrintamaOps()
      ..setSmallText()
      ..printText("small___________")
      ..printTextln("TEXTtext")
      ..setNormalText()
      ..printText("normal__________")
      ..printTextln("TEXTtext")
      ..call('printTextNormal', ["bold____________"])
      ..call('printTextlnBold', ["TEXTtext"])
      ..setNormalText()
      ..call('printTextNormal', ["tall____________"])
      ..call('printTextlnTall', ["TEXTtext"])
      ..call('printTextNormal', ["tall bold_______"])
      ..call('printTextlnTallBold', ["TEXTtext"])
      ..call('printTextNormal', ["wide____________"])
      ..call('printTextlnWide', ["TEXTtext"])
      ..call('printTextNormal', ["wide bold_______"])
      ..call('printTextlnWideBold', ["TEXTtext"])
      ..call('printTextNormal', ["wide tall_______"])
      ..call('printTextlnWideTall', ["TEXTtext"])
      ..call('printTextNormal', ["wide tall bold__"])
      ..call('printTextlnWideTallBold', ["TEXTtext"])
      ..call('printTextNormal', ["underline_______"])
      ..setUnderline()
      ..printTextln("TEXTtext")
      ..call('printTextNormal', ["delete line_____"])
      ..setDeleteLine()
      ..printTextln("TEXTtext")
      ..setNormalText()
      ..feedPaper()
      ..close();
    _connectWithFailed(p);
  }

  PrintamaImage get _launcher => PrintamaImage.fromVector('ic_launcher', mipmap: true);

  void printImageLeft() {
    _connectWithFailed(PrintamaOps()
      ..printImage(_launcher, 200, PrinterService.printamaLeft)
      ..close());
  }

  void printImageCenter() {
    _connectWithFailed(
      PrintamaOps()
        ..printImage(_launcher, 200, PrinterService.printamaCenter)
        ..close(),
      toastIfFirstResultFalse: "Print image failed",
    );
  }

  void printImageRight() {
    _connectWithFailed(PrintamaOps()
      ..printImage(_launcher, 200, PrinterService.printamaRight)
      ..close());
  }

  void printImageOri() {
    _connectWithFailed(PrintamaOps()
      ..printImage(_launcher) // original size, centered as default
      ..close());
  }

  void printImageFull() {
    _connectWithFailed(PrintamaOps()
      ..printImage(_launcher, PrinterService.printamaFullWidth)
      ..close());
  }

  void printImageBackground() {
    _connectWithFailed(PrintamaOps()
      ..printImage(PrintamaImage.fromVector('ic_launcher_background'), PrinterService.printamaOriginalWidth)
      ..close());
  }

  void printImagePhoto() {
    _connectWithFailed(PrintamaOps()
      ..printImage(PrintamaImage.decodeResource('rose'), PrinterService.printamaFullWidth)
      ..close());
  }

  Future<void> printView() async {
    final boundary = rootView.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context));
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    _connectWithFailed(PrintamaOps()
      ..printFromViewPng(bytes!.buffer.asUint8List())
      ..closeAfterDelay(2000));
  }

  /// Mock.getPrintModelMock()
  void printQrReceipt() {
    const date = "DATE: 17/08/2020";
    const invoice = "INVOICE: 000034";
    final p = PrintamaOps()
      ..printImage(PrintamaImage.fromVector('logo_gopay_print'), 300)
      ..addNewLine(1)
      ..setNormalText()
      ..printTextln("Kedai Juragan Bebek".toUpperCase(), PrinterService.printamaCenter)
      ..printTextln("Jalan Mawar No 7".toUpperCase(), PrinterService.printamaCenter)
      ..printTextln("Cibinong Bogor".toUpperCase(), PrinterService.printamaCenter)
      ..printTextln("MERC${"008".toUpperCase()}", PrinterService.printamaCenter)
      ..printDoubleDashedLine()
      // body
      ..printTextln(date)
      ..printTextln(invoice)
      ..printDashedLine()
      ..printTextln("TAGIHAN", PrinterService.printamaCenter)
      ..printDashedLine()
      ..printTextln("Scan kode QR untuk membayar", PrinterService.printamaCenter)
      ..printImage(PrintamaImage.qrGen("test qr code"), 300)
      ..printTextln("TOTAL         Rp125.000", PrinterService.printamaCenter)
      // footer
      ..printTextln("Acquirer ACQ1", PrinterService.printamaCenter)
      // footer.issuer == null
      ..printTextln("*** POWERED BY PRINTAMA ***", PrinterService.printamaCenter)
      ..printTextln("Development", PrinterService.printamaCenter)
      ..addNewLine(4)
      ..close();
    _connectWithFailed(p);
  }

  void printQrReceipt2() {
    const nota = "Some Text";
    final p = PrintamaOps()
      ..printImage(PrintamaImage.fromVector('logo_gopay_print'), 200)
      ..addNewLine()
      ..printTextln("Title Text", PrinterService.printamaCenter)
      ..setNormalText()
      ..printTextln("Some Text", PrinterService.printamaCenter)
      ..printDashedLine()
      ..addNewLine()
      ..printImage(PrintamaImage.qrCode(nota, 300))
      ..addNewLine()
      ..feedPaper()
      ..close();
    _connectWithFailed(p);
  }

  void printQrReceipt3() {
    final p = PrintamaOps()
      ..addNewLine(1)
      ..setNormalText()
      ..printTextln("Kedai Juragan Bebek1 Kedai Juragan Bebek2 Kedai Juragan Bebek3".toUpperCase(),
          PrinterService.printamaCenter)
      ..printTextln("Jalan Mawar No 7, bogor, jakarta, bandung, yogyakarta, indonesia".toUpperCase(),
          PrinterService.printamaCenter)
      ..printTextln("Cibinong Bogor".toUpperCase(), PrinterService.printamaCenter)
      ..addNewLine(1)
      ..printImage(PrintamaImage.fromVector('icon_gift'), 50, PrinterService.printamaRight)
      ..setNormalText()
      ..printText("QR Code", PrinterService.printamaRight)
      ..printImage(PrintamaImage.qrCode("12345678901", 200), 200, PrinterService.printamaRight)
      ..addNewLine(1)
      ..close();
    _connectWithFailed(p);
  }

  Widget _btn(String text, VoidCallback onTap, {Alignment alignment = Alignment.center}) {
    return MButton(
      text: text,
      height: 48,
      cornerRadius: 4,
      backgroundColor: colorAccent,
      textColor: colorWhite,
      font: AFont.robotoMedium,
      textSize: 12 * systemTextScale,
      bold: false,
      alignment: alignment,
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final small = 12 * systemTextScale;
    return Scaffold(
      backgroundColor: white,
      body: AWindow(
        statusBarColor: white,
        background: white,
        edgeToEdge: edgeToEdge,
        child: RepaintBoundary(
          key: rootView,
          child: Container(
            color: white,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ACard(
                        color: colorPrimary,
                        radius: 25,
                        onTap: showPrinterList,
                        child: SizedBox(
                          height: 50,
                          child: Row(children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.only(start: 10),
                              child: Container(
                                color: colorPrimary,
                                padding: const EdgeInsets.all(10),
                                child: const SvgIcon('ic_print', width: 24, height: 24, tint: colorWhite),
                              ),
                            ),
                            Expanded(child: AText("printer is not found", size: small, color: colorWhite)),
                            const Padding(
                              padding: EdgeInsetsDirectional.only(end: 8),
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: SvgIcon('ic_settings', width: 24, height: 24, tint: white),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  // btn_printer_test: visibility gone
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Expanded(child: _btn("Print Text Left", printTextLeft, alignment: Alignment.centerLeft)),
                    Expanded(child: _btn("Print Text Center", printTextCenter)),
                    Expanded(child: _btn("Print Text Right", printTextRight, alignment: Alignment.centerRight)),
                  ]),
                ),
                Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: _btn("Print Many Text Style", printTextStyles)),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: _btn("Print Text Justify Alignment", printTextJustified)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Expanded(child: _btn("Print Image Left", printImageLeft, alignment: Alignment.centerLeft)),
                    Expanded(child: _btn("Print Image Center", printImageCenter)),
                    Expanded(child: _btn("Print Image Right", printImageRight, alignment: Alignment.centerRight)),
                  ]),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5), child: _btn("Print Image Full Width", printImageFull)),
                Center(child: IntrinsicWidth(child: _btn("Print Image Original Width", printImageOri))),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(children: [
                    Expanded(child: _btn("Print Image Background", printImageBackground)),
                    Expanded(child: _btn("Print Image Photo", printImagePhoto)),
                    Expanded(child: _btn("Print This Layout", printView)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(children: [
                    Expanded(child: _btn("Print Receipt QR1", printQrReceipt)),
                    Expanded(child: _btn("Print Receipt QR2", printQrReceipt2)),
                    Expanded(child: _btn("Print Receipt QR3", printQrReceipt3)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
