package id.kreen.android.kreengate

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * FlutterFragmentActivity (bukan FlutterActivity) karena Printama.showPrinterList()
 * menampilkan DeviceListFragment lewat supportFragmentManager.
 */
class MainActivity : FlutterFragmentActivity() {
    private var printerBridge: PrinterBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        printerBridge = PrinterBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        printerBridge?.dispose()
        super.onDestroy()
    }
}
