import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/helper/live_data.dart';
import 'package:kreengate/helper/loading_page.dart';
import 'package:kreengate/pages/main_page.dart';
import 'package:kreengate/services/api_services.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/storage_services.dart';

/// LoginEventActivity
class LoginEventPage extends StatefulWidget {
  const LoginEventPage({super.key});

  @override
  State<LoginEventPage> createState() => _LoginEventPageState();
}

class _LoginEventPageState extends State<LoginEventPage> with ActivityLifecycle {
  final TextEditingController etEventId = TextEditingController();
  final LiveData<Resource> checkEventData = LiveData();
  late final CustomProgressDialogue dProgress = CustomProgressDialogue(context, cancelable: false);

  bool ivNextEnabled = false;

  // teks layout (diambil saat inflate)
  final String welcomeToKreen = LangService.getString('welcome_to_kreen');
  final String pleaseEnterYourEventId = LangService.getString('please_enter_your_event_id');
  final String enterEventId = LangService.getString('enter_event_id');

  @override
  void initState() {
    super.initState();
    validation();
  }

  /// BookingViewModel.getCheckEvent
  Future<void> getCheckEvent(String idEvent) async {
    checkEventData.postValue(const Resource.empty());
    checkEventData.postValue(const Resource.loading());
    final result = await ApiService.getCheckEvent(idEvent);
    final res = Resource.fromApi(result);
    if (res != null && mounted) checkEventData.postValue(res);
  }

  void saveData(Map<String, dynamic> result) {
    StorageService.setEvent(
      idEvent: result['idEvent'] as String,
      title: result['title'] as String,
      topic: result['topic'] as String,
      typeEvent: result['typeEvent'] as String,
      bannerTopList: kotlinBannerListToString(result['bannerTopList'] as List<Map<String, dynamic>>?),
      bannerDownList: kotlinBannerListToString(result['bannerBottomList'] as List<Map<String, dynamic>>?),
    );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void observeUI() {
    checkEventData.observe((it) {
      if (!mounted) return;
      switch (it?.type) {
        case ResourceType.success:
          final value = it!.data!;
          final result = value['data'] as Map<String, dynamic>; // bukan result
          saveData(result);
          dProgress.hide();
          break;
        case ResourceType.error:
          dProgress.hide();
          Fluttertoast.showToast(msg: it!.message ?? '', toastLength: Toast.LENGTH_SHORT);
          break;
        case ResourceType.loading:
          dProgress.show();
          break;
        case ResourceType.empty:
          dProgress.hide();
          break;
        default:
          dProgress.hide();
      }
    });
  }

  void validation() {
    etEventId.addListener(() {
      final enabled = etEventId.text.isNotEmpty;
      if (enabled != ivNextEnabled) setState(() => ivNextEnabled = enabled);
    });
  }

  @override
  void onResume() {
    // window default tema: status bar putih, ikon terang (windowLightStatusBar tidak diset)
    setStatusBarColorAndAppearance(white, false);
    observeUI();
  }

  @override
  void dispose() {
    checkEventData.removeObservers();
    etEventId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circle = dsdp(40);
    final border = dsdp(2);
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: white,
        // adjustResize hanya berefek di bawah API 35 (di edge-to-edge window tidak di-resize oleh IME)
        resizeToAvoidBottomInset: !edgeToEdge,
        body: AWindow(
          statusBarColor: white,
          background: white,
          edgeToEdge: edgeToEdge,
          child: LayoutBuilder(
            builder: (context, c) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.all(dsdp(25)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                          child: Image.asset(
                            'assets/images/logo_kreen.png',
                            width: dsdp(150),
                            height: dsdp(70),
                            fit: BoxFit.contain,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                          child: SizedBox(
                            width: double.infinity,
                            child: AText(
                              welcomeToKreen,
                              font: AFont.bold,
                              bold: true,
                              size: dssp(20),
                              color: colorTextPrimary,
                              align: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: AText(
                            pleaseEnterYourEventId,
                            font: AFont.medium,
                            size: dssp(16),
                            color: colorTextPrimary,
                            align: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: dsdp(20), bottom: dsdp(15)),
                          child: Container(
                            height: dsdp(40),
                            decoration: formBackground(),
                            alignment: Alignment.center,
                            child: TextField(
                              controller: etEventId,
                              keyboardType: TextInputType.emailAddress,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              cursorColor: colorPrimaryLight,
                              style: aTextStyle(AFont.poppins, dssp(14), const Color(0xDE000000)),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: enterEventId,
                                hintStyle: aTextStyle(AFont.poppins, dssp(14), const Color(0x99000000)),
                              ),
                            ),
                          ),
                        ),
                        // CircleImageView (civ_circle_background_color, border transparan __2sdp)
                        SizedBox(
                          width: circle,
                          height: circle,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: ivNextEnabled ? () => getCheckEvent(etEventId.text) : null,
                              highlightColor: const Color(0x1F000000),
                              child: Padding(
                                padding: EdgeInsets.all(border),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ivNextEnabled ? colorPrimary : colorBg,
                                  ),
                                  child: SvgPicture.asset('assets/icons/ic_arrow_right.svg', fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
