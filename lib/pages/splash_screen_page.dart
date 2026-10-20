import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/helper/live_data.dart';
import 'package:kreengate/pages/auth/login_event_page.dart';
import 'package:kreengate/pages/main_page.dart';
import 'package:kreengate/services/api_services.dart';
import 'package:kreengate/services/storage_services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// SplashScreenActivity
class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  static const int delaySplash = 5000;

  final LiveData<Resource> checkServerData = LiveData();
  String versionText = "V.1.2"; // android:text di layout, diganti di onCreate

  @override
  void initState() {
    super.initState();

    setStatusBarColorAndAppearance(colorPrimary, false);

    StorageService.setPrintTypeSdk(printTypePrintama);

    delay();
    observeUI();

    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => versionText = "V.${info.version}");
    });
  }

  void delay() {
    Future.delayed(const Duration(milliseconds: delaySplash), () {
      if (!mounted) return;
      final login = StorageService.getLoginStatus();
      // FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_NO_ANIMATION + finish()
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => login ? const MainPage() : const LoginEventPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );

      /*getCheckServer(
          vCode = BuildConfig.VERSION_CODE.toString(),
          typeApp = "android",
          platform = "user"
      )*/
    });
  }

  /// CheckServerViewModel.getCheckServer (tidak dipanggil, sama seperti aslinya)
  Future<void> getCheckServer(String vCode, String typeApp, String platform) async {
    checkServerData.postValue(const Resource.empty());
    checkServerData.postValue(const Resource.loading());
    final result = await ApiService.getCheckServer(vCode, typeApp, platform);
    final res = Resource.fromApi(result);
    if (res != null) checkServerData.postValue(res);
  }

  void observeUI() {
    checkServerData.observe((it) {
      if (!mounted || it == null) return;
      switch (it.type) {
        case ResourceType.success:
          final login = StorageService.getLoginStatus();
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, _, _) => login ? const MainPage() : const LoginEventPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          break;
        case ResourceType.error:
          if (it.errorCode == null) {
            Fluttertoast.showToast(msg: "Error Connection= ${it.message}", toastLength: Toast.LENGTH_SHORT);
          } else {
            Fluttertoast.showToast(msg: "Error Api= ${it.message}", toastLength: Toast.LENGTH_SHORT);
          }
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    checkServerData.removeObservers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spinSize = dsdp(50);
    return Scaffold(
      backgroundColor: white,
      body: AWindow(
        statusBarColor: colorPrimary,
        background: white,
        edgeToEdge: edgeToEdge,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/logo_kreen.png',
                  width: dsdp(200),
                  height: dsdp(70),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: dsdp(20)),
              child: Column(
                children: [
                  SizedBox(
                    width: spinSize,
                    height: spinSize,
                    child: Center(child: SpinKitThreeBounce(color: colorPrimary, size: spinSize / 2)),
                  ),
                  SizedBox(height: dsdp(20)),
                  AText(versionText, size: dssp(20), color: colorTextPrimary, bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
