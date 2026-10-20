import 'dart:async';
import 'package:flutter/services.dart';

/// Jembatan ke library printer Android yang dipakai app aslinya:
///  - com.github.anggastudio:Printama:0.9.73
///  - com.github.DantSu:ESCPOS-ThermalPrinter-Android:3.3.0 (+ AsyncEscPosPrint*.java dari proyek)
///
/// Logic cetak (teks, urutan, kondisi) tetap di Dart; native hanya mengeksekusi
/// perintah ke library tersebut supaya hasil cetak dan dialog bawaan library sama persis.
class PrinterService {
  static const MethodChannel _channel = MethodChannel('id.kreen.android.kreengate/printer');

  static int _nextId = 0;
  static final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'callback') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final completer = _pending.remove(args['id'] as int);
        completer?.complete(args);
      }
      return null;
    });
  }

  static Future<Map<String, dynamic>> _invokeWithCallback(String method, Map<String, dynamic> args) {
    _init();
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _channel.invokeMethod(method, {...args, 'id': id});
    return completer.future;
  }

  // =============================================================================
  // Printama
  // =============================================================================

  static const int printamaCenter = -1; // Printama.CENTER
  static const int printamaRight = -2; // Printama.RIGHT
  static const int printamaLeft = 0; // Printama.LEFT
  static const int printamaFullWidth = -1; // Printama.FULL_WIDTH
  static const int printamaOriginalWidth = 0; // Printama.ORIGINAL_WIDTH

  /// Printama.with(this).connectedPrinter?.name  (null kalau belum ada printer tersimpan)
  static Future<String?> printamaConnectedPrinterName() async {
    _init();
    final result = await _channel.invokeMethod<Map>('printama.connectedPrinter');
    if (result == null || result['connected'] != true) return null;
    return result['name'] as String?;
  }

  /// Printama.showPrinterList(activity, R.color.colorPrimary) { printerName -> ... }
  static Future<String> printamaShowPrinterList() async {
    final result = await _invokeWithCallback('printama.showPrinterList', {});
    return result['printerName'] as String;
  }

  /// Printama.with(this).printTest()
  static Future<void> printamaPrintTest() async {
    _init();
    await _channel.invokeMethod('printama.printTest');
  }

  /// Printama.with(this).connect({ printama -> ops }, onFailed)
  ///
  /// Return {"event": "connected", "results": [...]} atau {"event": "failed", "message": ...}.
  /// Kalau [withOnFailed] false (connect tanpa lambda onFailed), Future tidak selesai saat gagal.
  static Future<Map<String, dynamic>> printamaConnect(PrintamaOps ops, {bool withOnFailed = true}) {
    return _invokeWithCallback('printama.connect', {
      'ops': ops.ops,
      'withOnFailed': withOnFailed,
    });
  }

  // =============================================================================
  // ESC/POS (DantSu)
  // =============================================================================

  /// Dialog "Bluetooth printer selection" (android.app.AlertDialog + setItems) dari
  /// BluetoothPrintersConnections().getList(). Return {"index": i, "label": items[i]} saat item dipilih.
  /// index -1 = "Default printer" (selectedDevice = null).
  /// Kalau list null, atau izin BLUETOOTH_CONNECT hilang, dialog tidak muncul dan Future tidak selesai.
  static Future<Map<String, dynamic>> escposBrowseBluetoothDevice() {
    return _invokeWithCallback('escpos.browseBluetooth', {});
  }

  /// AsyncBluetoothEscPosPrint(this, onPrintFinished).execute(AsyncEscPosPrinter(selectedDevice, dpi, widthMM, chars).addTextToPrint(text))
  ///
  /// [deviceIndex] = index dari escposBrowseBluetoothDevice, atau null (selectedDevice == null -> selectFirstPaired()).
  /// Teks boleh berisi token `{{IMG_HEX:nama_drawable}}` yang diganti native dengan
  /// PrinterTextParserImg.bitmapToHexadecimalString(printer, getDrawableForDensity(drawable, DENSITY_MEDIUM)).
  static Future<Map<String, dynamic>> escposPrintBluetooth({
    required int? deviceIndex,
    required int printerDpi,
    required double printerWidthMM,
    required int printerNbrCharactersPerLine,
    required List<String> textsToPrint,
  }) {
    return _invokeWithCallback('escpos.printBluetooth', {
      'deviceIndex': deviceIndex,
      'dpi': printerDpi,
      'widthMM': printerWidthMM,
      'chars': printerNbrCharactersPerLine,
      'texts': textsToPrint,
    });
  }

  /// PrinterTestEscposActivity.printUsb() (termasuk BroadcastReceiver izin USB)
  static Future<void> escposPrintUsb({
    required int printerDpi,
    required double printerWidthMM,
    required int printerNbrCharactersPerLine,
    required List<String> textsToPrint,
  }) async {
    _init();
    await _channel.invokeMethod('escpos.printUsb', {
      'dpi': printerDpi,
      'widthMM': printerWidthMM,
      'chars': printerNbrCharactersPerLine,
      'texts': textsToPrint,
    });
  }

  /// AsyncTcpEscPosPrint(this, ...).execute(getAsyncEscPosPrinter(TcpConnection(ip, port)))
  static Future<Map<String, dynamic>> escposPrintTcp({
    required String ipAddress,
    required int port,
    required int printerDpi,
    required double printerWidthMM,
    required int printerNbrCharactersPerLine,
    required List<String> textsToPrint,
  }) {
    return _invokeWithCallback('escpos.printTcp', {
      'ip': ipAddress,
      'port': port,
      'dpi': printerDpi,
      'widthMM': printerWidthMM,
      'chars': printerNbrCharactersPerLine,
      'texts': textsToPrint,
    });
  }

  // =============================================================================
  // Lain-lain (perilaku Android yang dipakai Activity)
  // =============================================================================

  /// android.app.AlertDialog.Builder(this).setTitle(title).setMessage(message).show()
  static Future<void> showNativeAlert(String title, String message) async {
    _init();
    await _channel.invokeMethod('alert', {'title': title, 'message': message});
  }

  /// RingtoneManager.getRingtone(context, android.resource://.../raw/beep1).play()
  static Future<void> playBeep() async {
    _init();
    await _channel.invokeMethod('playBeep');
  }

  /// Gambar `@android:drawable/name` milik device (mis. ic_menu_camera), sebagai PNG.
  static Future<Uint8List?> systemDrawable(String name) async {
    _init();
    return _channel.invokeMethod<Uint8List>('systemDrawable', {'name': name});
  }
}

/// Sumber Bitmap untuk printImage.
class PrintamaImage {
  final Map<String, dynamic> spec;
  const PrintamaImage._(this.spec);

  /// BitmapFactory.decodeResource(resources, R.drawable.name)
  factory PrintamaImage.decodeResource(String name) =>
      PrintamaImage._({'type': 'decodeResource', 'name': name});

  /// Printama.getBitmapFromVector(this, R.drawable.name / R.mipmap.name)
  factory PrintamaImage.fromVector(String name, {bool mipmap = false}) =>
      PrintamaImage._({'type': 'vector', 'name': name, 'mipmap': mipmap});

  /// QRCodeWriter().encode(data, QR_CODE, size, size) -> Bitmap RGB_565 hitam/putih.
  /// [emptyOnError]: generateQRCodeBitmap() mengembalikan bitmap kosong kalau WriterException;
  /// kalau false, op printImage dilewati (blok try/catch di Activity).
  factory PrintamaImage.qrCode(String data, int size, {bool emptyOnError = false}) =>
      PrintamaImage._({'type': 'qr', 'data': data, 'size': size, 'emptyOnError': emptyOnError});

  /// net.glxn.qrgen QRCode.from(qrCode).bitmap() (printama/util/Util.getQrCode)
  factory PrintamaImage.qrGen(String data) => PrintamaImage._({'type': 'qrgen', 'data': data});

  /// createRowBitmap(left, right)
  factory PrintamaImage.row(PrintamaImage left, PrintamaImage right) =>
      PrintamaImage._({'type': 'row', 'left': left.spec, 'right': right.spec});

  /// Bitmap dari PNG (dipakai printFromView)
  factory PrintamaImage.png(Uint8List bytes) => PrintamaImage._({'type': 'png', 'bytes': bytes});
}

/// Daftar pemanggilan method Printama di dalam blok connect { printama -> ... }.
class PrintamaOps {
  final List<Map<String, dynamic>> ops = [];

  /// Panggil method Printama apa saja; argumen String / int / PrintamaImage.
  void call(String method, [List<Object> args = const []]) {
    ops.add({
      'method': method,
      'args': args.map((a) => a is PrintamaImage ? {'image': a.spec} : a).toList(),
    });
  }

  void setNormalText() => call('setNormalText');
  void setSmallText() => call('setSmallText');
  void setUnderline() => call('setUnderline');
  void setDeleteLine() => call('setDeleteLine');
  void feedPaper() => call('feedPaper');
  void printDashedLine() => call('printDashedLine');
  void printDoubleDashedLine() => call('printDoubleDashedLine');
  void close() => call('close');

  void printText(String text, [int? align]) => call('printText', [text, ?align]);
  void printTextln(String text, [int? align]) => call('printTextln', [text, ?align]);

  void addNewLine([int? count]) => call('addNewLine', [?count]);

  /// printImage(bitmap) / printImage(bitmap, width) / printImage(bitmap, width, alignment)
  void printImage(PrintamaImage image, [int? width, int? alignment]) =>
      call('printImage', [image, ?width, ?alignment]);

  /// printama.printFromView(view): render view jadi bitmap (grayscale) lalu printImage setelah 500ms.
  void printFromViewPng(Uint8List png) => ops.add({'method': '_printFromViewPng', 'args': [png]});

  /// Handler(Looper.myLooper()!!).postDelayed({ printama.close() }, ms)
  void closeAfterDelay(int ms) => ops.add({'method': '_closeAfterDelay', 'args': [ms]});
}
