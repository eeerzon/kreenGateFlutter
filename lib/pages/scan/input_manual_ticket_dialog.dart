import 'package:flutter/material.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/services/lang_service.dart';

/// utils/dialog/InputManualTicketDialog (DialogFragment, R.style.DialogTheme = full screen)
///
/// [cancelable] default false (isCancelable): tombol back tidak menutup dialog.
Future<void> showInputManualTicketDialog(
  BuildContext context, {
  required ValueChanged<String> onDataReceived,
  bool cancelable = false,
}) {
  // Utility.setStatusBarColorAndAppearance(requireActivity().window, white, true)
  setStatusBarColorAndAppearance(white, true);
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => PopScope(
        canPop: cancelable,
        child: InputManualTicketView(
          onSubmit: (text, close) {
            // send back data to PARENT using callback, lalu dismiss
            onDataReceived(text);
            close();
          },
        ),
      ),
    ),
  );
}

/// Layout dialog_input_manual.xml (juga dipakai InputManualTicketActivity dengan inputType berbeda).
class InputManualTicketView extends StatefulWidget {
  final void Function(String text, VoidCallback close)? onSubmit;
  final VoidCallback? onBack;
  final bool numberInput;
  final bool backDismisses;

  const InputManualTicketView({
    super.key,
    this.onSubmit,
    this.onBack,
    this.numberInput = true,
    this.backDismisses = true,
  });

  @override
  State<InputManualTicketView> createState() => _InputManualTicketViewState();
}

class _InputManualTicketViewState extends State<InputManualTicketView> {
  final TextEditingController etCode = TextEditingController();

  final String inputManualTicket = LangService.getString('input_manual_ticket');
  final String enterTheTicketNumberCorrectly = LangService.getString('enter_the_ticket_number_correctly');
  final String ticketNumberQrCode = LangService.getString('ticket_number_qr_code');
  final String next = LangService.getString('next');

  @override
  void initState() {
    super.initState();
    // Window dialog sendiri: windowLightStatusBar tidak diset di DialogTheme -> ikon terang
    setStatusBarColorAndAppearance(white, false);
  }

  @override
  void dispose() {
    etCode.dispose();
    super.dispose();
  }

  /// dismiss(): tutup dialog ini sendiri (bisa saja ada route lain, mis. loading, di atasnya)
  void close() {
    // kembali ke window activity (status bar putih, ikon gelap)
    setStatusBarColorAndAppearance(white, true);
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    if (route.isCurrent) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldStyle = aTextStyle(AFont.medium, dssp(18), colorTextPrimary);
    return Scaffold(
      backgroundColor: white,
      // adjustResize hanya berefek di bawah API 35 (di edge-to-edge window tidak di-resize oleh IME)
      resizeToAvoidBottomInset: !edgeToEdge,
      body: AWindow(
        statusBarColor: white,
        background: white,
        edgeToEdge: edgeToEdge,
        child: Column(
          children: [
            AToolbar(
              background: white,
              child: Padding(
                padding: EdgeInsets.only(top: dsdp(10), bottom: dsdp(10), right: dsdp(16)),
                child: Row(
                  children: [
                    Clickable(
                      onTap: widget.backDismisses ? (widget.onBack ?? close) : null,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(end: dsdp(10)),
                        child: SvgIcon('ic_close', width: dsdp(25), height: dsdp(25), tint: colorTextPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: const NoOverscroll(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: dsdp(16)),
                  child: Padding(
                    padding: EdgeInsets.only(top: dsdp(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: AText(
                            inputManualTicket,
                            font: AFont.bold,
                            bold: true,
                            size: dssp(25),
                            color: colorTextPrimary,
                            maxLines: 1,
                            ellipsize: true,
                          ),
                        ),
                        AText(
                          enterTheTicketNumberCorrectly,
                          font: AFont.medium,
                          size: dssp(12),
                          color: colorTextSecondary,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: dsdp(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: dsdp(5)),
                                child: AText(
                                  ticketNumberQrCode,
                                  font: AFont.medium,
                                  size: dssp(12),
                                  color: colorTextSecondary,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(bottom: dsdp(10)),
                                decoration: formBackground(),
                                padding: EdgeInsets.symmetric(horizontal: dsdp(15), vertical: dsdp(5)),
                                child: SizedBox(
                                  height: aLineHeight(context, AFont.medium, dssp(18)),
                                  child: Center(
                                    child: TextField(
                                      controller: etCode,
                                      keyboardType: widget.numberInput
                                          ? const TextInputType.numberWithOptions(decimal: true)
                                          : TextInputType.emailAddress,
                                      cursorColor: colorPrimaryLight,
                                      style: fieldStyle,
                                      decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
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
                ),
              ),
            ),
            Container(
              decoration: elevatedFooter(),
              padding: EdgeInsets.symmetric(horizontal: dsdp(16), vertical: dsdp(10)),
              child: MButton(
                text: next,
                height: dsdp(60),
                cornerRadius: dsdp(20),
                textSize: dssp(16),
                onPressed: widget.onSubmit == null ? null : () => widget.onSubmit!(etCode.text, close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
