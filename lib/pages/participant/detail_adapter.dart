import 'package:flutter/material.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/services/lang_service.dart';

/// ui/main/adapter/DetailAdapter (RecyclerView: header item_header_fullname + item_detail)
class DetailAdapter extends StatelessWidget {
  final String? fullname;
  final String? email;
  final List<Map<String, dynamic>> detail;
  final Map<String, String> questionMap;

  const DetailAdapter({
    super.key,
    required this.fullname,
    required this.email,
    required this.detail,
    this.questionMap = const {},
  });

  int get itemCount => detail.length + 1; // +1 untuk header

  Widget _header() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dsdp(10), horizontal: dsdp(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AText(LangService.getString('full_name'), font: AFont.poppins, size: dssp(12), color: black),
          AText(fullname ?? '', font: AFont.bold, bold: true, size: dssp(14), color: black),
          AText("Email", font: AFont.poppins, size: dssp(12), color: black),
          AText(email ?? '', font: AFont.bold, bold: true, size: dssp(14), color: black),
        ],
      ),
    );
  }

  Widget _item(Map<String, dynamic> item) {
    final idQuestion = item['idQuestion'] as String?;
    final questionText = (idQuestion == null ? null : questionMap[idQuestion]) ?? '';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dsdp(10), horizontal: dsdp(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AText(questionText, font: AFont.poppins, size: dssp(14), color: black),
          AText(normalizeAnswer(item['answer'] as String?), font: AFont.bold, size: dssp(14), color: black),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int position = 0; position < itemCount; position++)
          position == 0 ? _header() : _item(detail[position - 1]), // -1 karena 0 dipakai header
      ],
    );
  }
}

/// Layout activity_participant_detail2.xml / activity_participant_detail3.xml (isinya identik).
class ParticipantDetailLayout extends StatelessWidget {
  final Widget content;
  final String printText;
  final double printAlpha;
  final bool printEnabled;
  final VoidCallback onPrint;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const ParticipantDetailLayout({
    super.key,
    required this.content,
    required this.printText,
    this.printAlpha = 1.0,
    this.printEnabled = true,
    required this.onPrint,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
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
                child: Row(children: [
                  Clickable(
                    onTap: onBack,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: dsdp(10)),
                      child: SvgIcon('ic_close', width: dsdp(25), height: dsdp(25), tint: colorTextPrimary),
                    ),
                  ),
                ]),
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
                          child: AText(LangService.getString('participant_detail'),
                              font: AFont.bold, bold: true, size: dssp(25), color: colorTextPrimary,
                              maxLines: 1, ellipsize: true),
                        ),
                        AText(LangService.getString('please_double_check_compatibility_with_ticket_data'),
                            font: AFont.medium, size: dssp(12), color: colorTextSecondary),
                        Padding(
                          padding: EdgeInsets.only(top: dsdp(20), bottom: 4),
                          child: ACard(
                            color: colorStrokeBg,
                            radius: dsdp(10),
                            elevation: dsdp(2),
                            child: content,
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
              child: TwoButtonRow(
                left: MButton(
                  text: LangService.getString('cancel'),
                  height: dsdp(60),
                  cornerRadius: dsdp(20),
                  textSize: dssp(16),
                  backgroundColor: colorPrimaryTransparent,
                  textColor: colorPrimary,
                  onPressed: onClose,
                ),
                right: Opacity(
                  opacity: printAlpha,
                  child: MButton(
                    text: printText,
                    height: dsdp(60),
                    cornerRadius: dsdp(20),
                    textSize: dssp(16),
                    enabled: printEnabled,
                    onPressed: onPrint,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
