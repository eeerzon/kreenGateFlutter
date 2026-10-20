package id.kreen.android.kreengate

import android.Manifest
import android.app.AlertDialog
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.res.Resources
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Parcelable
import android.util.DisplayMetrics
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.anggastudio.printama.Printama
import com.dantsu.escposprinter.connection.DeviceConnection
import com.dantsu.escposprinter.connection.bluetooth.BluetoothConnection
import com.dantsu.escposprinter.connection.bluetooth.BluetoothPrintersConnections
import com.dantsu.escposprinter.connection.tcp.TcpConnection
import com.dantsu.escposprinter.connection.usb.UsbConnection
import com.dantsu.escposprinter.connection.usb.UsbPrintersConnections
import com.dantsu.escposprinter.textparser.PrinterTextParserImg
import com.google.zxing.BarcodeFormat
import com.google.zxing.WriterException
import com.google.zxing.qrcode.QRCodeWriter
import id.kreen.android.kreengate.printer.escpos.async.AsyncBluetoothEscPosPrint
import id.kreen.android.kreengate.printer.escpos.async.AsyncEscPosPrint
import id.kreen.android.kreengate.printer.escpos.async.AsyncEscPosPrinter
import id.kreen.android.kreengate.printer.escpos.async.AsyncTcpEscPosPrint
import id.kreen.android.kreengate.printer.escpos.async.AsyncUsbEscPosPrint
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.glxn.qrgen.android.QRCode
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * Menjalankan pemanggilan library printer asli (Printama 0.9.73 & DantSu ESCPOS 3.3.0) atas permintaan Dart.
 * Isi cetakan (teks, gambar, urutan) ditentukan di Dart; kode di sini hanya meneruskan ke library,
 * persis seperti yang dilakukan Activity di app Android asli.
 */
class PrinterBridge(private val activity: FragmentActivity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "id.kreen.android.kreengate/printer")
    private val mainHandler = Handler(Looper.getMainLooper())

    /** BluetoothPrintersConnections().getList() terakhir yang ditampilkan di dialog pilihan printer */
    private var bluetoothDevicesList: Array<BluetoothConnection>? = null

    private var usbReceiver: BroadcastReceiver? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        usbReceiver?.let { runCatching { activity.unregisterReceiver(it) } }
    }

    private fun callback(id: Int, data: Map<String, Any?>) {
        mainHandler.post { channel.invokeMethod("callback", data + ("id" to id)) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "printama.connectedPrinter" -> {
                    val printer = Printama.with(activity).connectedPrinter
                    if (printer == null) {
                        result.success(mapOf("connected" to false))
                    } else {
                        @Suppress("MissingPermission")
                        result.success(mapOf("connected" to true, "name" to printer.name))
                    }
                }

                "printama.showPrinterList" -> {
                    val id = call.argument<Int>("id")!!
                    Printama.showPrinterList(activity, com.anggastudio.printama.R.color.colorPrimary) { printerName: String ->
                        callback(id, mapOf("printerName" to printerName))
                    }
                    result.success(null)
                }

                "printama.printTest" -> {
                    Printama.with(activity).printTest()
                    result.success(null)
                }

                "printama.connect" -> {
                    val id = call.argument<Int>("id")!!
                    val ops = call.argument<List<Map<String, Any?>>>("ops")!!
                    val withOnFailed = call.argument<Boolean>("withOnFailed") ?: true
                    val onConnected = Printama.OnConnected { printama ->
                        val results = runOps(printama, ops)
                        callback(id, mapOf("event" to "connected", "results" to results))
                    }
                    if (withOnFailed) {
                        Printama.with(activity).connect(onConnected) { message: String? ->
                            callback(id, mapOf("event" to "failed", "message" to message))
                        }
                    } else {
                        Printama.with(activity).connect(onConnected)
                    }
                    result.success(null)
                }

                "escpos.browseBluetooth" -> {
                    browseBluetoothDevice(call.argument<Int>("id")!!)
                    result.success(null)
                }

                "escpos.printBluetooth" -> {
                    val id = call.argument<Int>("id")!!
                    val index = call.argument<Int>("deviceIndex")
                    val selectedDevice: DeviceConnection? = index?.let { bluetoothDevicesList?.getOrNull(it) }
                    AsyncBluetoothEscPosPrint(activity, onPrintFinished(id))
                        .execute(buildPrinter(selectedDevice, call))
                    result.success(null)
                }

                "escpos.printUsb" -> {
                    printUsb(call)
                    result.success(null)
                }

                "escpos.printTcp" -> {
                    val id = call.argument<Int>("id")!!
                    val connection = TcpConnection(call.argument<String>("ip")!!, call.argument<Int>("port")!!)
                    AsyncTcpEscPosPrint(activity, onPrintFinished(id)).execute(buildPrinter(connection, call))
                    result.success(null)
                }

                "alert" -> {
                    AlertDialog.Builder(activity)
                        .setTitle(call.argument<String>("title"))
                        .setMessage(call.argument<String>("message"))
                        .show()
                    result.success(null)
                }

                "playBeep" -> {
                    val sound = Uri.parse("android.resource://" + activity.packageName + "/" + R.raw.beep1)
                    RingtoneManager.getRingtone(activity.applicationContext, sound)?.play()
                    result.success(null)
                }

                "systemDrawable" -> {
                    val name = call.argument<String>("name")!!
                    val resId = Resources.getSystem().getIdentifier(name, "drawable", "android")
                    val drawable = if (resId == 0) null else ContextCompat.getDrawable(activity, resId)
                    if (drawable == null) {
                        result.success(null)
                    } else {
                        val bitmap = Bitmap.createBitmap(
                            drawable.intrinsicWidth.coerceAtLeast(1),
                            drawable.intrinsicHeight.coerceAtLeast(1),
                            Bitmap.Config.ARGB_8888
                        )
                        val canvas = Canvas(bitmap)
                        drawable.setBounds(0, 0, canvas.width, canvas.height)
                        drawable.draw(canvas)
                        val out = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                        result.success(out.toByteArray())
                    }
                }

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e("PrinterBridge", "${call.method} failed", e)
            result.error("ERROR", e.message, null)
        }
    }

    // ===========================================================================================
    // Printama
    // ===========================================================================================

    /** Eksekusi pemanggilan method Printama di dalam blok connect { printama -> ... } */
    private fun runOps(printama: Printama, ops: List<Map<String, Any?>>): List<Any?> {
        val results = ArrayList<Any?>()
        for (op in ops) {
            val method = op["method"] as String
            @Suppress("UNCHECKED_CAST")
            val rawArgs = (op["args"] as? List<Any?>) ?: emptyList()
            try {
                when (method) {
                    "_printFromViewPng" -> {
                        // printama.printFromView(view): bitmap grayscale, printImage setelah 500ms di executor
                        val png = rawArgs[0] as ByteArray
                        val source = BitmapFactory.decodeByteArray(png, 0, png.size)
                        val b = Bitmap.createBitmap(source.width, source.height, Bitmap.Config.ARGB_8888)
                        val canvas = Canvas(b)
                        val ma = ColorMatrix().apply { setSaturation(0f) }
                        canvas.drawBitmap(source, 0f, 0f, Paint().apply { colorFilter = ColorMatrixColorFilter(ma) })
                        Handler(Looper.getMainLooper()).postDelayed({
                            Executors.newSingleThreadExecutor().execute { printama.printImage(b) }
                        }, 500)
                        results.add(null)
                    }

                    "_closeAfterDelay" -> {
                        val ms = (rawArgs[0] as Number).toLong()
                        Handler(Looper.myLooper() ?: Looper.getMainLooper()).postDelayed({ printama.close() }, ms)
                        results.add(null)
                    }

                    else -> {
                        val args = ArrayList<Any?>()
                        var skip = false
                        for (a in rawArgs) {
                            if (a is Map<*, *> && a.containsKey("image")) {
                                @Suppress("UNCHECKED_CAST")
                                val bmp = resolveImage(a["image"] as Map<String, Any?>)
                                if (bmp == null) skip = true else args.add(bmp)
                            } else if (a is Number) {
                                args.add(a.toInt())
                            } else {
                                args.add(a)
                            }
                        }
                        if (skip) {
                            // WriterException di blok try/catch Activity: printImage tidak dipanggil
                            results.add(null)
                            continue
                        }
                        // printImage(rowBitmap, rowBitmap.width, ...): -100 = lebar bitmap
                        if (method == "printImage" && args.size >= 2 && args[1] == -100) {
                            args[1] = (args[0] as Bitmap).width
                        }
                        results.add(invoke(printama, method, args))
                    }
                }
            } catch (e: Exception) {
                Log.e("PrinterBridge", "Printama.$method failed", e)
                results.add(null)
            }
        }
        return results
    }

    private fun invoke(target: Any, name: String, args: List<Any?>): Any? {
        val m = target.javaClass.methods.firstOrNull { m ->
            m.name == name && m.parameterTypes.size == args.size &&
                m.parameterTypes.withIndex().all { (i, t) ->
                    val a = args[i]
                    when {
                        t == Int::class.javaPrimitiveType -> a is Int
                        t == String::class.java -> a is String?
                        t == Bitmap::class.java -> a is Bitmap
                        else -> false
                    }
                }
        } ?: throw NoSuchMethodException("Printama.$name(${args.joinToString { it?.javaClass?.simpleName ?: "null" }})")
        return m.invoke(target, *args.toTypedArray())
    }

    private fun resId(name: String, type: String): Int =
        activity.resources.getIdentifier(name, type, activity.packageName)

    private fun resolveImage(spec: Map<String, Any?>): Bitmap? {
        return when (spec["type"]) {
            "decodeResource" -> BitmapFactory.decodeResource(activity.resources, resId(spec["name"] as String, "drawable"))
            "vector" -> {
                val type = if (spec["mipmap"] == true) "mipmap" else "drawable"
                Printama.getBitmapFromVector(activity, resId(spec["name"] as String, type))
            }
            "qr" -> {
                val size = (spec["size"] as Number).toInt()
                try {
                    val bitMatrix = QRCodeWriter().encode(spec["data"] as String, BarcodeFormat.QR_CODE, size, size)
                    val width = bitMatrix.width
                    val height = bitMatrix.height
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)
                    for (x in 0 until width) {
                        for (y in 0 until height) {
                            bitmap.setPixel(x, y, if (bitMatrix[x, y]) Color.BLACK else Color.WHITE)
                        }
                    }
                    bitmap
                } catch (e: WriterException) {
                    e.printStackTrace()
                    if (spec["emptyOnError"] == true) Bitmap.createBitmap(200, 200, Bitmap.Config.RGB_565) else null
                }
            }
            "qrgen" -> QRCode.from(spec["data"] as String).bitmap()
            "row" -> {
                @Suppress("UNCHECKED_CAST")
                val left = resolveImage(spec["left"] as Map<String, Any?>) ?: return null
                @Suppress("UNCHECKED_CAST")
                val right = resolveImage(spec["right"] as Map<String, Any?>) ?: return null
                val rowBitmap = Bitmap.createBitmap(
                    left.width + right.width, maxOf(left.height, right.height), Bitmap.Config.ARGB_8888
                )
                val canvas = Canvas(rowBitmap)
                canvas.drawBitmap(left, 0f, 0f, null)
                canvas.drawBitmap(right, left.width.toFloat(), 0f, null)
                rowBitmap
            }
            "png" -> {
                val bytes = spec["bytes"] as ByteArray
                BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            }
            else -> null
        }
    }

    // ===========================================================================================
    // ESC/POS
    // ===========================================================================================

    private fun buildPrinter(connection: DeviceConnection?, call: MethodCall): AsyncEscPosPrinter {
        val printer = AsyncEscPosPrinter(
            connection,
            call.argument<Int>("dpi")!!,
            (call.argument<Number>("widthMM")!!).toFloat(),
            call.argument<Int>("chars")!!
        )
        val texts = call.argument<List<String>>("texts")!!
        for (text in texts) {
            printer.addTextToPrint(replaceImageTokens(printer, text))
        }
        return printer
    }

    /** {{IMG_HEX:logo}} -> PrinterTextParserImg.bitmapToHexadecimalString(printer, getDrawableForDensity(R.drawable.logo, DENSITY_MEDIUM)) */
    private fun replaceImageTokens(printer: AsyncEscPosPrinter, text: String): String {
        return Regex("\\{\\{IMG_HEX:([a-z0-9_]+)\\}\\}").replace(text) { match ->
            val drawable = activity.applicationContext.resources.getDrawableForDensity(
                resId(match.groupValues[1], "drawable"), DisplayMetrics.DENSITY_MEDIUM, null
            )
            PrinterTextParserImg.bitmapToHexadecimalString(printer, drawable)
        }
    }

    private fun onPrintFinished(id: Int) = object : AsyncEscPosPrint.OnPrintFinished() {
        override fun onError(asyncEscPosPrinter: AsyncEscPosPrinter?, codeException: Int) {
            Log.e("Async.OnPrintFinished", "AsyncEscPosPrint.OnPrintFinished : An error occurred !")
            callback(id, mapOf("event" to "error", "code" to codeException))
        }

        override fun onSuccess(asyncEscPosPrinter: AsyncEscPosPrinter?) {
            Log.i("Async.OnPrintFinished", "AsyncEscPosPrint.OnPrintFinished : Print is finished !")
            callback(id, mapOf("event" to "success"))
        }
    }

    private fun browseBluetoothDevice(id: Int) {
        val list: Array<BluetoothConnection>? = BluetoothPrintersConnections().list
        if (list != null) {
            val items: Array<String?> = arrayOfNulls(list.size + 1)
            items[0] = "Default printer"
            for (index in list.indices) {
                if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_CONNECT)
                    != PackageManager.PERMISSION_GRANTED
                ) {
                    return
                }
                @Suppress("MissingPermission")
                items[index + 1] = list[index].device.name
            }
            bluetoothDevicesList = list

            val alertDialog = AlertDialog.Builder(activity)
            alertDialog.setTitle("Bluetooth printer selection")
            alertDialog.setItems(items) { _, i1 ->
                callback(id, mapOf("index" to i1 - 1, "label" to items[i1]))
            }
            val alert = alertDialog.create()
            alert.setCanceledOnTouchOutside(false)
            alert.show()
        }
    }

    private val ACTION_USB_PERMISSION = "com.android.example.USB_PERMISSION"

    /** PrinterTestEscposActivity.printUsb() */
    private fun printUsb(call: MethodCall) {
        val dpi = call.argument<Int>("dpi")!!
        val widthMM = (call.argument<Number>("widthMM")!!).toFloat()
        val chars = call.argument<Int>("chars")!!
        val texts = call.argument<List<String>>("texts")!!

        val usbConnection = UsbPrintersConnections.selectFirstConnected(activity)
        val usbManager = activity.getSystemService(Context.USB_SERVICE) as UsbManager?

        if (usbConnection == null || usbManager == null) {
            AlertDialog.Builder(activity)
                .setTitle("USB Connection")
                .setMessage("No USB printer found.")
                .show()
            return
        }

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (ACTION_USB_PERMISSION == intent.action) {
                    synchronized(this) {
                        val manager = activity.getSystemService(Context.USB_SERVICE) as UsbManager?
                        @Suppress("DEPRECATION")
                        val usbDevice = intent.getParcelableExtra<Parcelable>(UsbManager.EXTRA_DEVICE) as UsbDevice?
                        if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                            if (manager != null && usbDevice != null) {
                                val printer = AsyncEscPosPrinter(UsbConnection(manager, usbDevice), dpi, widthMM, chars)
                                for (t in texts) printer.addTextToPrint(replaceImageTokens(printer, t))
                                AsyncUsbEscPosPrint(context, object : AsyncEscPosPrint.OnPrintFinished() {
                                    override fun onError(asyncEscPosPrinter: AsyncEscPosPrinter?, codeException: Int) {
                                        Log.e("Async.OnPrintFinished", "AsyncEscPosPrint.OnPrintFinished : An error occurred !")
                                    }

                                    override fun onSuccess(asyncEscPosPrinter: AsyncEscPosPrinter?) {
                                        Log.i("Async.OnPrintFinished", "AsyncEscPosPrint.OnPrintFinished : Print is finished !")
                                    }
                                }).execute(printer)
                            }
                        }
                    }
                }
            }
        }
        usbReceiver = receiver

        val permissionIntent = PendingIntent.getBroadcast(
            activity,
            0,
            Intent(ACTION_USB_PERMISSION),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        )
        val filter = IntentFilter(ACTION_USB_PERMISSION)
        ContextCompat.registerReceiver(activity, receiver, filter, ContextCompat.RECEIVER_EXPORTED)
        usbManager.requestPermission(usbConnection.device, permissionIntent)
    }
}
