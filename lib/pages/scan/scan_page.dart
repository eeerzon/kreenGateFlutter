import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:vibration/vibration.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/helper/global_widget.dart';
import 'package:kreengate/helper/live_data.dart';
import 'package:kreengate/helper/loading_page.dart';
import 'package:kreengate/pages/participant/participant_detail2_page.dart';
import 'package:kreengate/pages/participant/participant_detail3_page.dart';
import 'package:kreengate/pages/scan/input_manual_ticket_dialog.dart';
import 'package:kreengate/services/api_services.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/printer_service.dart';
import 'package:kreengate/services/storage_services.dart';

/// Pengganti Intent ke ParticipantDetail2/3Activity beserta extras-nya.
class ParticipantIntent {
  final String target; // printTypeEscpos -> ParticipantDetail3, printTypePrintama -> ParticipantDetail2
  final Map<String, dynamic> extras = {};
  ParticipantIntent(this.target);

  Widget build() {
    final questionMap = Map<String, String>.from(extras['questionMap'] as Map? ?? {});
    final idEvent = extras['idEvent'] as String?;
    final idTicket = extras['idTicket'] as String?;
    final showQr = extras['showQr'] as String?;
    final detail = extras['detail'] as Map<String, dynamic>?;
    return target == printTypeEscpos
        ? ParticipantDetail3Page(
            idEvent: idEvent,
            idTicket: idTicket,
            showQr: showQr,
            detail: detail,
            questionMap: questionMap,
          )
        : ParticipantDetail2Page(
            idEvent: idEvent,
            idTicket: idTicket,
            showQr: showQr,
            detail: detail,
            questionMap: questionMap,
          );
  }
}

/// ui/main/ScanActivity
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with ActivityLifecycle {
  final QRCodeDartScanController mCodeScanner = QRCodeDartScanController();
  bool isFrontCamera = false;
  bool isFlashEnabled = false;
  bool previewActive = false;

  late final CustomProgressDialogue dProgress = CustomProgressDialogue(context, cancelable: false);

  String? idEvent;
  String? printTypeSDK;

  Route<void>? mBottomSheetDialog;

  final ScanningIndicatorController scanningView = ScanningIndicatorController();

  final Map<String, String> questionMap = {};
  bool isQuestionMapReady = false;
  ParticipantIntent? pendingParticipantIntent;

  String? currentIdTicket;
  int currentRequestId = 0;
  bool navigatedForCurrentRequest = false;
  int loadingSeenForRequest = -1;
  bool isProcessingScan = false;

  bool isSwitchingCamera = false;

  final LiveData<Resource> bookingRedeem2Data = LiveData();
  final LiveData<Resource> checkBookingData = LiveData();
  final LiveData<Resource> listQuestionOrderFormData = LiveData();

  Uint8List? icMenuCamera;

  final String inputManual = LangService.getString('input_manual');

  @override
  void initState() {
    super.initState();
    setStatusBarColorAndAppearance(white, true);

    configScanner();

    idEvent = StorageService.getIdEvent();
    printTypeSDK = StorageService.getPrintTypeSdk();

    observeUI();

    final event = idEvent;
    if (event != null && event.isNotEmpty) {
      listQuestionOrderForm(kreenConnectSecretKey, event);
    }

    PrinterService.systemDrawable('ic_menu_camera').then((png) {
      if (mounted) setState(() => icMenuCamera = png);
    });
  }

  // ===============================================================================
  // BookingViewModel
  // ===============================================================================

  Future<void> _run(LiveData<Resource> data, Future<Map<String, dynamic>> Function() call) async {
    data.postValue(const Resource.empty());
    data.postValue(const Resource.loading());
    final result = await call();
    final res = Resource.fromApi(result);
    if (res != null && mounted) data.postValue(res);
  }

  void bookingRedeem2(String idRedeem, String idTicket, String idEvent) =>
      _run(bookingRedeem2Data, () => ApiService.bookingRedeem2(idRedeem, idTicket, idEvent));

  void checkBooking(String idTicket, String idEvent) =>
      _run(checkBookingData, () => ApiService.checkBooking(idTicket, idEvent));

  void listQuestionOrderForm(String secretKey, String idEvent) =>
      _run(listQuestionOrderFormData, () => ApiService.listQuestionOrderForm(secretKey, idEvent));

  // ===============================================================================

  void showBottomSheetsScan() {
    isProcessingScan = false;
    _dismissBottomSheet();
    final route = _ScanBottomSheet.route(
      onRescan: () {
        isProcessingScan = false;
        _dismissBottomSheet();
        scannerActive(true);
      },
      onClose: () {
        _dismissBottomSheet();
        finish();
      },
    );
    mBottomSheetDialog = route;
    Navigator.of(context).push(route).then((_) {
      if (identical(mBottomSheetDialog, route)) mBottomSheetDialog = null;
    });
  }

  void _dismissBottomSheet() {
    final route = mBottomSheetDialog;
    mBottomSheetDialog = null;
    if (route != null && route.isActive) Navigator.of(context).removeRoute(route);
  }

  void startActivity(ParticipantIntent intent) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => intent.build()));
  }

  void finish() {
    if (mounted) Navigator.of(context).pop();
  }

  void navigateToParticipantDetail(ParticipantIntent intent) {
    navigatedForCurrentRequest = true;

    if (isQuestionMapReady) {
      intent.extras['questionMap'] = Map<String, String>.from(questionMap);
      debugPrint("questionMap: $questionMap");
      startActivity(intent);
      dProgress.hide();
      scannerActive(false);
      isProcessingScan = false;
    } else {
      // Tahan intent-nya, tunggu questionMap selesai di-load
      pendingParticipantIntent = intent;
      dProgress.show(); // tetap tampilkan loading, jangan biarkan user bingung
    }
  }

  void showDialog() {
    scannerActive(false);
    showInputManualTicketDialog(context, onDataReceived: onDataReceived);
  }

  void getData(String idTicket) {
    scannerActive(false);
    final idRedeem = random(20, "123456789", "");
    currentIdTicket = idTicket;

    currentRequestId++;
    navigatedForCurrentRequest = false;

    bookingRedeem2(idRedeem, idTicket, idEvent!);
  }

  ParticipantIntent? _intentForPrintType() {
    switch (printTypeSDK) {
      case printTypeEscpos:
        return ParticipantIntent(printTypeEscpos); // 3
      case printTypePrintama:
        return ParticipantIntent(printTypePrintama);
      default:
        return null;
    }
  }

  void observeUI() {
    bookingRedeem2Data.observe((it) {
      if (!mounted) return;
      switch (it?.type) {
        case ResourceType.success:
          final value = it!.data!;
          final result = value['result'] as Map<String, dynamic>;

          dProgress.hide();

          debugPrint("observeUI: $result");

          final intent = _intentForPrintType();

          if (intent != null) {
            intent.extras['idEvent'] = idEvent;
            intent.extras['detail'] = result['detail'];
            intent.extras['idTicket'] = result['id'];
            intent.extras['showQr'] = result['showQr'];
            navigateToParticipantDetail(intent);
          } else {
            dProgress.hide();
            scannerActive(false);
          }
          break;

        case ResourceType.error:
          dProgress.hide();
          if (navigatedForCurrentRequest) return;

          debugPrint("currentIdTicket: $currentIdTicket");

          final ticket = currentIdTicket;
          final event = idEvent;
          if (ticket != null && event != null) {
            checkBooking(ticket, event);
          } else {
            showBottomSheetsScan();
            debugPrint("Resource.Error: showBottomSheetsScan aktif");
          }
          break;

        case ResourceType.loading:
          loadingSeenForRequest = currentRequestId;
          dProgress.show();
          scannerActive(false);
          break;

        case ResourceType.empty:
          dProgress.hide();
          if (navigatedForCurrentRequest) return;
          if (loadingSeenForRequest != currentRequestId) return;

          final ticket = currentIdTicket;
          final event = idEvent;
          if (ticket != null && event != null) {
            checkBooking(ticket, event);
          } else {
            showBottomSheetsScan();
            debugPrint("Resource.Error: showBottomSheetsScan aktif");
          }
          break;

        default:
          dProgress.hide();
      }
    });

    checkBookingData.observe((it) {
      if (!mounted) return;
      switch (it?.type) {
        case ResourceType.success:
          final value = it!.data!;
          final result = value['result'] as Map<String, dynamic>;

          dProgress.hide();

          final intent = _intentForPrintType();

          if (intent != null) {
            intent.extras['idEvent'] = idEvent;
            intent.extras['detail'] = result['detail'];
            intent.extras['idTicket'] = result['id'];
            intent.extras['showQr'] = result['showQr'];
            navigateToParticipantDetail(intent);
          } else {
            dProgress.hide();
          }

          scannerActive(false);
          break;

        case ResourceType.error:
          dProgress.hide();
          if (navigatedForCurrentRequest) return;
          // sudah dicoba di dua-duanya (bookingRedeem2 & checkBooking), memang tidak ketemu
          showBottomSheetsScan();
          debugPrint("CheckingResource.Error: showBottomSheetsScan aktif");
          break;

        case ResourceType.loading:
          loadingSeenForRequest = currentRequestId;
          dProgress.show();
          scannerActive(false);
          break;

        case ResourceType.empty:
          dProgress.hide();
          if (navigatedForCurrentRequest) return;
          if (loadingSeenForRequest != currentRequestId) return;
          debugPrint("CheckingResource.Empty: showBottomSheetsScan aktif");
          break;

        default:
          dProgress.hide();
      }
    });

    listQuestionOrderFormData.observe((it) {
      if (!mounted) return;
      switch (it?.type) {
        case ResourceType.success:
          final data = it!.data!;
          debugPrint("QUESTION_MAP_DEBUG: success = ${data['success']}");
          debugPrint("QUESTION_MAP_DEBUG: message = ${data['message']}");

          questionMap.clear();
          for (final item in (data['data'] as List<Map<String, dynamic>>? ?? const [])) {
            final id = item['idQuestion'] as String?;
            final question = item['question'] as String?;
            if (id != null && id.isNotEmpty && question != null) {
              questionMap[id] = question;
            } else {
              debugPrint("QUESTION_MAP_DEBUG: SKIPPED — id atau question null/kosong");
            }
          }

          debugPrint("QUESTION_MAP_DEBUG: final questionMap = $questionMap");

          isQuestionMapReady = true;
          _flushPendingIntent();
          break;

        case ResourceType.error:
          debugPrint("LIST_QUESTION: Failed to load question mapping: ${it!.message}");
          isQuestionMapReady = true;
          _flushPendingIntent();
          break;

        default:
          break;
      }
    });
  }

  /// Kalau ada intent yang tadinya ditahan karena questionMap belum siap, lanjutkan sekarang
  void _flushPendingIntent() {
    final pending = pendingParticipantIntent;
    if (pending == null) return;
    pending.extras['questionMap'] = Map<String, String>.from(questionMap);
    debugPrint("questionMap: $questionMap");
    startActivity(pending);
    dProgress.hide();
    scannerActive(false);
    pendingParticipantIntent = null;
  }

  // ===============================================================================
  // Scanner (code-scanner: ScanMode.SINGLE, ALL_FORMATS)
  // ===============================================================================

  Future<void> scannerActive(bool isActive) async {
    if (isActive) {
      previewActive = true;
      await mCodeScanner.cameraController?.resumePreview();
      await mCodeScanner.startScan();
      scanningView.startAnimation();
    } else {
      previewActive = false;
      await mCodeScanner.stopScan();
      await mCodeScanner.cameraController?.pausePreview();
      scanningView.stopAnimation();
    }
  }

  Future<void> configScanner() async {
    scanningView.startAnimation();

    if (await Permission.camera.isGranted) {
      scannerActive(true);
    } else {
      requestCameraPermissions(true);
    }
  }

  void onDecode(ScanResult result) {
    // ScanMode.SINGLE: preview berhenti setelah satu kode terbaca
    mCodeScanner.stopScan();
    mCodeScanner.cameraController?.pausePreview();

    if (isProcessingScan) return;
    isProcessingScan = true;

    PrinterService.playBeep();
    Vibration.vibrate(duration: 500);

    getData(result.text);
  }

  Future<void> toggleFlash() async {
    final enable = !isFlashEnabled;
    await mCodeScanner.setFlash(enable);
    setState(() => isFlashEnabled = enable);
  }

  Future<void> switchCamera() async {
    isFrontCamera = !isFrontCamera;

    try {
      await mCodeScanner.changeCamera(isFrontCamera ? TypeCamera.front : TypeCamera.back);
      if (!previewActive) previewActive = true;
      await mCodeScanner.startScan();
    } catch (e) {
      debugPrint("ScanActivity: switchCamera error: $e");
    }

    setState(() {
      if (isFrontCamera) isFlashEnabled = false;
    });

    scanningView.startAnimation();
  }

  Future<void> requestCameraPermissions(bool appStartup) async {
    if (!await Permission.camera.isGranted) {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        scannerActive(true);
      } else {
        Fluttertoast.showToast(
          msg: LangService.getString('camera_permission_required'),
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    } else {
      scannerActive(true);
    }
  }

  @override
  void onResume() {
    setStatusBarColorAndAppearance(white, true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) scannerActive(true);
    });
  }

  /// CallbackListener.onDataReceived
  void onDataReceived(String data) {
    if (isProcessingScan) return;
    isProcessingScan = true;
    getData(data);
  }

  @override
  void dispose() {
    try {
      mCodeScanner.dispose();
    } catch (e) {
      debugPrint("ScanActivity: Error releasing scanner: $e");
    }
    bookingRedeem2Data.removeObservers();
    checkBookingData.removeObservers();
    listQuestionOrderFormData.removeObservers();
    scanningView.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = dsdp(30);
    final iconTint = const Color(0xB7FFFEFE);
    return Scaffold(
      backgroundColor: white,
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // consScanner (layout_above layFooter)
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                return Stack(
                  children: [
                    // CodeScannerView (frame tidak terlihat: frameCornersSize 0, maskColor transparan)
                    Positioned.fill(
                      child: Clickable(
                        onTap: () => scannerActive(true),
                        child: QRCodeDartScanView(
                          controller: mCodeScanner,
                          typeCamera: TypeCamera.back,
                          formats: BarcodeFormat.values,
                          // code-scanner memilih preview terbesar dengan rasio terdekat ke view (16:9 di HP)
                          resolutionPreset: QRCodeDartScanResolutionPreset.veryHigh,
                          widthPreview: c.maxWidth,
                          heightPreview: c.maxHeight,
                          onCapture: onDecode,
                          onCameraError: (e) => debugPrint("ScanActivity: CodeScanner error: $e"),
                        ),
                      ),
                    ),
                    // scanningView.bringToFront()
                    Positioned.fill(
                      child: IgnorePointer(child: ScanningIndicator3(controller: scanningView)),
                    ),
                    Positioned(
                      left: dsdp(16),
                      right: dsdp(16),
                      top: 0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Clickable(
                              onTap: finish,
                              child: SvgIcon('ic_cancel', width: iconSize, height: iconSize, tint: iconTint),
                            ),
                            const Spacer(),
                            Column(
                              children: [
                                Visibility(
                                  visible: !isFrontCamera,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: Clickable(
                                    onTap: toggleFlash,
                                    child: SvgIcon(
                                      isFlashEnabled ? 'ic_flash' : 'ic_flash_off',
                                      width: iconSize,
                                      height: iconSize,
                                      tint: iconTint,
                                    ),
                                  ),
                                ),
                                SizedBox(height: dsdp(12)),
                                Clickable(
                                  onTap: () {
                                    if (isSwitchingCamera) return;
                                    isSwitchingCamera = true;
                                    switchCamera();
                                    // buka lock lagi setelah delay singkat, kasih waktu kamera settle
                                    Future.delayed(const Duration(milliseconds: 800), () => isSwitchingCamera = false);
                                  },
                                  child: SizedBox(
                                    width: iconSize,
                                    height: iconSize,
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(iconTint, BlendMode.srcIn),
                                      child: icMenuCamera != null
                                          ? Image.memory(icMenuCamera!, fit: BoxFit.contain)
                                          : Image.asset('assets/images/ic_menu_camera.png', fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // layFooter
          ACard(
            radius: dsdp(10),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: dsdp(16), vertical: dsdp(15)),
              child: ACard(
                radius: dsdp(10),
                strokeColor: colorStroke,
                strokeWidth: dsdp(2),
                onTap: showDialog,
                child: Padding(
                  padding: EdgeInsets.all(dsdp(15)),
                  child: SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(end: dsdp(5)),
                          child: AText(
                            inputManual,
                            font: AFont.bold,
                            bold: true,
                            size: dssp(14),
                            color: colorTextPrimary,
                            align: TextAlign.center,
                          ),
                        ),
                        PositionedDirectional(
                          end: 0,
                          child: SvgIcon(
                            'ic_chevron_right',
                            width: dsdp(20),
                            height: dsdp(20),
                            tint: colorPrimary,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// bottomsheet_scanner.xml dalam BottomSheetDialog(R.style.BottomSheetDialogTheme)
class _ScanBottomSheet extends StatelessWidget {
  final VoidCallback onRescan;
  final VoidCallback onClose;
  const _ScanBottomSheet({required this.onRescan, required this.onClose});

  static Route<void> route({required VoidCallback onRescan, required VoidCallback onClose}) {
    return _SheetRoute(_ScanBottomSheet(onRescan: onRescan, onClose: onClose));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: dsdp(15)),
            child: Container(
              width: dsdp(50),
              height: dsdp(3),
              decoration: BoxDecoration(color: const Color(0xFFCCCCCC), borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: dsdp(10)),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: dsdp(5), bottom: dsdp(10)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: dsdp(16), vertical: dsdp(10)),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: dsdp(20), right: dsdp(10)),
                          child: Image.asset('assets/images/not_found.png', width: dsdp(150), height: dsdp(150)),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: dsdp(25)),
                          child: AText(
                            LangService.getString('problems_with_qr_codes'),
                            font: AFont.bold,
                            bold: true,
                            size: dssp(14),
                            color: colorTextPrimary,
                          ),
                        ),
                        AText(
                          LangService.getString('make_sure_the_qr_code_is_correct_please_check_your_ticket_again'),
                          font: AFont.medium,
                          size: dssp(12),
                          color: colorTextSecondary,
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: dsdp(16)),
                  child: TwoButtonRow(
                    left: MButton(
                      text: LangService.getString('close'),
                      height: dsdp(60),
                      cornerRadius: dsdp(20),
                      textSize: dssp(16),
                      backgroundColor: colorPrimaryTransparent,
                      textColor: colorPrimary,
                      onPressed: onClose,
                    ),
                    right: MButton(
                      text: LangService.getString('rescan'),
                      height: dsdp(60),
                      cornerRadius: dsdp(20),
                      textSize: dssp(16),
                      onPressed: onRescan,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// setCanceledOnTouchOutside(false), behavior.isDraggable = false, back tetap menutup
class _SheetRoute extends PopupRoute<void> {
  final Widget sheet;
  _SheetRoute(this.sheet);

  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => false;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final curve = CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn);
    // dim menutupi seluruh layar; sheet berada di atas inset navigation bar
    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: animation,
            child: const ColoredBox(color: Color(0x99000000)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: bottomInset,
          child: ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curve),
                child: Material(type: MaterialType.transparency, child: sheet),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
