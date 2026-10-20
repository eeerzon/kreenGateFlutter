import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/storage_services.dart';

/// ui/main/LanguageActivity
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String? language;

  bool rbIdnChecked = true; // android:checked="true"
  bool rbEngChecked = false;
  static const String rbIdnTag = "in";
  static const String rbEngTag = "en";

  bool btnSubmitEnabled = true;

  final String languageText = LangService.getString('language');
  final String indonesia = LangService.getString('indonesia');
  final String english = LangService.getString('english');
  final String save = LangService.getString('save');

  @override
  void initState() {
    super.initState();
    setStatusBarColorAndAppearance(white, true);

    language = StorageService.getString(languageSp, "");

    if (language!.isEmpty) {
      StorageService.putString(languageSp, "en");
    }

    language = StorageService.getString(languageSp, "");

    if (language == "in") {
      rbIdnChecked = true;
      rbEngChecked = false;
    } else if (language == "en") {
      rbIdnChecked = false;
      rbEngChecked = true;
    }

    setContinue(false);
  }

  void onIdnClick() {
    setState(() {
      if (rbIdnChecked) {
        rbEngChecked = false;
        setContinue(rbIdnTag != language);
      }
    });
  }

  void onEngClick() {
    setState(() {
      if (rbEngChecked) {
        rbIdnChecked = false;
        setContinue(rbEngTag != language);
      }
    });
  }

  /// Klik RadioButton: toggle ke checked (RadioButton tidak bisa di-uncheck lewat klik)
  void onRbIdnClick() {
    rbIdnChecked = true;
    onIdnClick();
  }

  void onRbEngClick() {
    rbEngChecked = true;
    onEngClick();
  }

  void onSubmit() {
    if (rbIdnChecked) {
      dialogConfirm("in", "Indonesia");
    } else if (rbEngChecked) {
      dialogConfirm("en", "English");
    }
  }

  void dialogConfirm(String codeLanguage, String mLanguage) {
    final headMessage = LangService.getString('change_language');
    final titleMessage = "${LangService.getString('are_you_sure_want_to_change_the_language_into')} $mLanguage ?";

    setState(() {
      if (codeLanguage == "in") {
        rbIdnChecked = true;
        rbEngChecked = false;
      } else if (codeLanguage == "en") {
        rbIdnChecked = false;
        rbEngChecked = true;
      }
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: ConfirmMessageDialog(
          headMessage: headMessage,
          titleMessage: titleMessage,
          onNegative: () {
            Navigator.of(dialogContext).pop();
            language = StorageService.getString(languageSp, "");
            setState(() {
              if (language == "in") {
                rbIdnChecked = true;
                rbEngChecked = false;
              } else if (language == "en") {
                rbIdnChecked = false;
                rbEngChecked = true;
              }
            });
          },
          onPositive: () {
            Navigator.of(dialogContext).pop();
            StorageService.putString(languageSp, codeLanguage);

            Fluttertoast.showToast(
                msg: LangService.getString('success_change_language_setting'), toastLength: Toast.LENGTH_SHORT);

            setState(() {
              if (codeLanguage == "in") {
                rbIdnChecked = true;
                rbEngChecked = false;
              } else if (codeLanguage == "en") {
                rbIdnChecked = false;
                rbEngChecked = true;
              }
            });
          },
        ),
      ),
    );
  }

  void setContinue(bool status) {
    btnSubmitEnabled = status;
  }

  Widget _languageRow(String flag, String label, bool checked, VoidCallback onRowTap, VoidCallback onRadioTap) {
    return Clickable(
      onTap: onRowTap,
      child: Container(
        color: white,
        padding: EdgeInsets.all(dsdp(15)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgIcon(flag, width: dsdp(24), height: dsdp(24)),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: dsdp(5)),
                child: Row(children: [
                  Expanded(
                    flex: 40,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: dsdp(10)),
                      child: AText(label, font: AFont.poppins, size: dssp(12), color: colorTextPrimary),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Clickable(
                        onTap: onRadioTap,
                        child: SizedBox(
                          width: dsdp(25),
                          child: Center(
                            // button=@drawable/checkbox_selector, buttonTint=colorPrimary
                            child: SvgIcon(checked ? 'ic_checked' : 'ic_checked_blank',
                                width: 24, height: 24, tint: checked ? colorPrimary : Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: dsdp(10)),
                      child: SvgIcon('ic_arrow_back', width: dsdp(25), height: dsdp(25), tint: colorTextPrimary),
                    ),
                  ),
                  Expanded(child: AText(languageText, font: AFont.bold, bold: true, size: dssp(16), color: black)),
                ]),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: dsdp(2), color: colorStroke),
                  Padding(
                    padding: EdgeInsets.only(left: dsdp(16), right: dsdp(16), top: dsdp(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _languageRow('ic_flag_ind', indonesia, rbIdnChecked, () {
                          rbIdnChecked = true;
                          onIdnClick();
                        }, onRbIdnClick),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: dsdp(15)),
                          child: Container(height: 1, color: colorStroke),
                        ),
                        _languageRow('ic_flag_eng', english, rbEngChecked, () {
                          rbEngChecked = true;
                          onEngClick();
                        }, onRbEngClick),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: elevatedFooter(),
              padding: EdgeInsets.symmetric(horizontal: dsdp(16), vertical: dsdp(10)),
              child: MButton(
                text: save,
                height: dsdp(60),
                cornerRadius: dsdp(20),
                textSize: dssp(16),
                enabled: btnSubmitEnabled,
                onPressed: onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// confirm_message_dialog.xml di dalam AlertDialog (setView)
class ConfirmMessageDialog extends StatelessWidget {
  final String headMessage;
  final String titleMessage;
  final VoidCallback onNegative;
  final VoidCallback onPositive;

  const ConfirmMessageDialog({
    super.key,
    required this.headMessage,
    required this.titleMessage,
    required this.onNegative,
    required this.onPositive,
  });

  @override
  Widget build(BuildContext context) {
    final buttonText = 14.0 * systemTextScale; // TextAppearance.AppCompat.Body2 (14sp)
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ACard(
        radius: dsdp(5),
        elevation: dsdp(5),
        child: Padding(
          padding: EdgeInsets.only(left: dsdp(15), right: dsdp(15), top: dsdp(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AText(headMessage, font: AFont.semibold, bold: true, size: 14 * systemTextScale, color: colorTextPrimary),
              Padding(
                padding: EdgeInsets.only(top: dsdp(8)),
                child: AText(titleMessage, font: AFont.poppins, size: dssp(12), color: const Color(0x8A000000)),
              ),
              Padding(
                padding: EdgeInsets.only(top: dsdp(25), bottom: dsdp(10)),
                child: Row(children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: dsdp(5)),
                      child: _button("Cancel", buttonText, colorPrimary, formBackground(), onNegative),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: dsdp(5)),
                      child: _button("Yes", buttonText, white, const BoxDecoration(color: colorPrimary), onPositive),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(String text, double size, Color color, BoxDecoration decoration, VoidCallback onTap) {
    return SizedBox(
      height: dsdp(40),
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: AText(text, font: AFont.bold, bold: true, size: size, color: color, letterSpacing: 0.0892857143),
            ),
          ),
        ),
      ),
    );
  }
}
