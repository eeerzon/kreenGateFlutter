import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/helper/live_data.dart';
import 'package:kreengate/pages/home_content/home_page.dart';
import 'package:kreengate/pages/home_content/setting_page.dart';
import 'package:kreengate/pages/scan/scan_page.dart';
import 'package:kreengate/services/lang_service.dart';

/// MainActivity (BaseActivity)
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with ActivityLifecycle {
  bool doubleBackToExitPressedOnce = false;

  bool isHomeCreated = false;
  bool isProfileCreated = false;

  // R.id.homeFragment / R.id.settingFragment
  static const int homeFragment = 0;
  static const int settingFragment = 2;
  int selectedItemId = homeFragment;
  int active = homeFragment;

  @override
  void initState() {
    super.initState();
    // BaseActivity.attachBaseContext
    LangService.updateResource();
    lightStatusBar(true);
    setupBottomNavigationView();
  }

  @override
  void onResume() {
    LangService.updateResource();
    applyStatusBar();
  }

  @override
  void onPause() {
    LangService.updateResource();
  }

  void applyStatusBar() {
    if (active == homeFragment) {
      setStatusBarColorAndAppearance(colorPrimary, false);
    } else {
      setStatusBarColorAndAppearance(white, true);
    }
  }

  void setupBottomNavigationView() {
    if (!isHomeCreated) {
      isHomeCreated = true;
      active = homeFragment;
      setStatusBarColorAndAppearance(colorPrimary, false);
    }
  }

  bool onItemSelected(int itemId) {
    switch (itemId) {
      case homeFragment:
        if (!isHomeCreated) isHomeCreated = true;
        setState(() {
          active = homeFragment;
          selectedItemId = homeFragment;
        });
        setStatusBarColorAndAppearance(colorPrimary, false);
        return true;
      case settingFragment:
        if (!isProfileCreated) isProfileCreated = true;
        setState(() {
          active = settingFragment;
          selectedItemId = settingFragment;
        });
        setStatusBarColorAndAppearance(white, true);
        return true;
    }
    return false;
  }

  void handleOnBackPressed() {
    if (selectedItemId == homeFragment) {
      if (doubleBackToExitPressedOnce) {
        SystemNavigator.pop();
        return;
      }
      doubleBackToExitPressedOnce = true;
      Fluttertoast.showToast(msg: LangService.getString('press_again_to_exit'), toastLength: Toast.LENGTH_SHORT);
      Future.delayed(const Duration(milliseconds: 2000), () => doubleBackToExitPressedOnce = false);
    } else {
      if (!isHomeCreated) isHomeCreated = true;
      onItemSelected(homeFragment);
    }
  }

  void openScan() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage()));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navHeight = 56 + bottomInset;
    final fabSize = dsdp(60);
    // posisi FAB hasil anchor ke BottomAppBar (56dp), diukur dari app asli
    final fabCenterFromBottom = 45.9 + bottomInset;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleOnBackPressed();
      },
      child: Scaffold(
        backgroundColor: white,
        body: Stack(
          children: [
            // FrameLayout flFragment (layout_above bottom_nav_view)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: navHeight,
              child: IndexedStack(
                index: active == homeFragment ? 0 : 1,
                children: [
                  const HomePage(),
                  isProfileCreated ? const SettingPage() : const SizedBox.shrink(),
                ],
              ),
            ),
            // bottomNavigationView
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomNavigation(
                selected: selectedItemId,
                bottomInset: bottomInset,
                onSelected: (id) => onItemSelected(id),
              ),
            ),
            // FloatingActionButton fab
            Positioned(
              left: 0,
              right: 0,
              bottom: fabCenterFromBottom - fabSize / 2,
              child: Center(
                child: SizedBox(
                  width: fabSize,
                  height: fabSize,
                  child: Material(
                    color: colorPrimary,
                    elevation: 6,
                    shape: CircleBorder(side: BorderSide(color: white, width: dsdp(2))),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: openScan,
                      splashColor: const Color(0x3DFFFFFF),
                      highlightColor: Colors.transparent,
                      child: Center(
                        child: SvgIcon('ic_qr_code_scanner', width: dsdp(40), height: dsdp(40), tint: white),
                      ),
                    ),
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

/// BottomNavigationView dengan menu_navgraph (Home, Scan [disabled, tanpa ikon], Setting)
class _BottomNavigation extends StatelessWidget {
  final int selected;
  final double bottomInset;
  final ValueChanged<int> onSelected;

  const _BottomNavigation({required this.selected, required this.bottomInset, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFEFF),
        boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          _item(0, 'ic_home', 'Home', true),
          _item(1, null, 'Scan', false),
          _item(2, 'ic_settings', 'Setting', true),
        ],
      ),
    );
  }

  Widget _item(int id, String? icon, String label, bool enabled) {
    final checked = selected == id;
    final color = checked ? navItemChecked : navItemUnchecked;
    return Expanded(
      child: Clickable(
        onTap: enabled ? () => onSelected(id) : null,
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (icon != null)
                Positioned(top: 8, child: SvgIcon(icon, width: 24, height: 24, tint: color)),
              Positioned(
                top: 35,
                // itemTextAppearance = BottomNavigationView (__11ssp), label aktif bold
                child: AText(label, size: dssp(11), color: color, bold: checked),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
