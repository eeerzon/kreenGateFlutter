import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';

// =====================================================================================
// Teks (TextView Android + includeFontPadding)
// =====================================================================================

/// Font resource Android (@font/...). [roboto] = font default sistem (tanpa fontFamily).
enum AFont { poppins, medium, semibold, bold, roboto, robotoMedium }

class _FontMetrics {
  final String family;
  final FontWeight weight;
  final double yMax, yMin, ascent, descent; // per 1000 unitsPerEm
  const _FontMetrics(this.family, this.weight, this.yMax, this.yMin, this.ascent, this.descent);
}

// Nilai dari tabel head / hhea masing-masing file TTF di res/font
const Map<AFont, _FontMetrics> _metrics = {
  AFont.poppins: _FontMetrics('Poppins', FontWeight.w400, 1076, -439, 1115, -525),
  AFont.medium: _FontMetrics('PoppinsMedium', FontWeight.w500, 1077, -582, 1050, -350),
  AFont.semibold: _FontMetrics('PoppinsSemiBold', FontWeight.w600, 1100, -476, 1115, -525),
  AFont.bold: _FontMetrics('PoppinsBold', FontWeight.w700, 1115, -525, 1115, -525),
  // Roboto sistem (unitsPerEm 2048: yMax 2163, yMin -555, ascent 1900, descent -500)
  AFont.roboto: _FontMetrics('', FontWeight.w400, 1056.15, -270.99, 927.73, -244.14),
  // sans-serif-medium (TextAppearance.MaterialComponents.Button)
  AFont.robotoMedium: _FontMetrics('', FontWeight.w500, 1056.15, -270.99, 927.73, -244.14),
};

/// TextView. [size] dalam dp (logical px); untuk ukuran sp kalikan [systemTextScale] dulu.
class AText extends StatelessWidget {
  final String text;
  final AFont font;
  final double size;
  final Color color;
  final bool bold; // android:textStyle="bold"
  final TextAlign align;
  final int? maxLines;
  final bool ellipsize;
  final double letterSpacing; // em

  const AText(
    this.text, {
    super.key,
    this.font = AFont.roboto,
    required this.size,
    this.color = const Color(0xDE000000),
    this.bold = false,
    this.align = TextAlign.start,
    this.maxLines,
    this.ellipsize = false,
    this.letterSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final m = _metrics[font]!;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    // Paint.getFontMetricsInt(): top=floor, ascent/descent=round, bottom=ceil (dalam px)
    // getDimensionPixelSize(): ukuran font dibulatkan ke pixel bulat
    final px = (size * dpr).roundToDouble();
    final fontSize = px / dpr;
    final topPx = (m.yMax / 1000 * px).ceilToDouble();
    final bottomPx = (-m.yMin / 1000 * px).ceilToDouble();
    final ascPx = (m.ascent / 1000 * px).roundToDouble();
    final descPx = (-m.descent / 1000 * px).roundToDouble();

    // Fake bold kalau textStyle=bold tapi file font tidak bold (seperti Minikin)
    final weight = bold && m.weight.value < 600 ? FontWeight.w700 : m.weight;

    return _FontPadding(
      top: (topPx - ascPx) / dpr,
      bottom: (bottomPx - descPx) / dpr,
      child: Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        overflow: ellipsize ? TextOverflow.ellipsis : null,
        style: TextStyle(
          fontFamily: m.family.isEmpty ? null : m.family,
          fontWeight: weight,
          fontSize: fontSize,
          color: color,
          height: (ascPx + descPx) / px,
          leadingDistribution: TextLeadingDistribution.even,
          letterSpacing: letterSpacing * fontSize,
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: true,
          applyHeightToLastDescent: true,
        ),
      ),
    );
  }
}

/// Menambah (atau mengurangi, boleh negatif) ruang di atas/bawah teks:
/// baris pertama pakai "top" font, baris terakhir pakai "bottom" font (includeFontPadding).
class _FontPadding extends SingleChildRenderObjectWidget {
  final double top;
  final double bottom;
  const _FontPadding({required this.top, required this.bottom, required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFontPadding(top, bottom);

  @override
  void updateRenderObject(BuildContext context, _RenderFontPadding renderObject) {
    renderObject
      ..top = top
      ..bottom = bottom;
  }
}

class _RenderFontPadding extends RenderShiftedBox {
  double _top;
  double _bottom;
  _RenderFontPadding(this._top, this._bottom) : super(null);

  set top(double v) {
    if (v == _top) return;
    _top = v;
    markNeedsLayout();
  }

  set bottom(double v) {
    if (v == _bottom) return;
    _bottom = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child!;
    c.layout(constraints.copyWith(minHeight: 0, maxHeight: double.infinity), parentUsesSize: true);
    (c.parentData! as BoxParentData).offset = Offset(0, _top);
    size = constraints.constrain(Size(c.size.width, math.max(0, c.size.height + _top + _bottom)));
  }

  @override
  double computeMinIntrinsicWidth(double height) => child!.getMinIntrinsicWidth(height);
  @override
  double computeMaxIntrinsicWidth(double height) => child!.getMaxIntrinsicWidth(height);
  @override
  double computeMinIntrinsicHeight(double width) => child!.getMinIntrinsicHeight(width) + _top + _bottom;
  @override
  double computeMaxIntrinsicHeight(double width) => child!.getMaxIntrinsicHeight(width) + _top + _bottom;
}

/// TextStyle untuk EditText (tanpa kotak font padding; dipakai di TextField).
TextStyle aTextStyle(AFont font, double size, Color color, {bool bold = false}) {
  final m = _metrics[font]!;
  return TextStyle(
    fontFamily: m.family.isEmpty ? null : m.family,
    fontWeight: bold && m.weight.value < 600 ? FontWeight.w700 : m.weight,
    fontSize: textSizeDp(size),
    color: color,
  );
}

// ---- style.xml ----
// FontHeaderX = poppins_medium, FontHeaderBoldX = poppins_bold+bold, FontSmallTextX = poppins_medium,
// FontSmallTextSemiBold12 = poppins_semibold, FontTitle15 = poppins_medium (__18ssp), FontBody14 = poppins_medium (__15ssp),
// FontTinyX = poppins.

// =====================================================================================
// Ikon (AppCompatImageView + vector drawable + tint)
// =====================================================================================

class SvgIcon extends StatelessWidget {
  final String name;
  final double width;
  final double height;
  final Color? tint;
  final BoxFit fit;

  const SvgIcon(this.name, {super.key, required this.width, required this.height, this.tint, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: width,
      height: height,
      fit: fit,
      colorFilter: tint == null ? null : ColorFilter.mode(tint!, BlendMode.srcIn),
    );
  }
}

// =====================================================================================
// MaterialToolbar (contentInsetStart 16dp, minHeight ?actionBarSize 56dp)
// =====================================================================================

class AToolbar extends StatelessWidget {
  final Color background;
  final Widget child;

  const AToolbar({super.key, required this.background, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsetsDirectional.only(start: 16),
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
  }
}

// =====================================================================================
// MaterialButton (Widget.MaterialComponents.Button)
// =====================================================================================

class MButton extends StatelessWidget {
  final String text;
  final double height;
  final double cornerRadius;
  final Color backgroundColor;
  final Color textColor;
  final AFont font;
  final double textSize;
  final bool bold;
  final bool enabled;
  final VoidCallback? onPressed;
  final AlignmentGeometry alignment;
  final bool allCaps;

  const MButton({
    super.key,
    required this.text,
    required this.height,
    required this.cornerRadius,
    this.backgroundColor = colorPrimary,
    this.textColor = white,
    this.font = AFont.bold,
    required this.textSize,
    this.bold = true,
    this.enabled = true,
    this.onPressed,
    this.alignment = Alignment.center,
    this.allCaps = false,
  });

  @override
  Widget build(BuildContext context) {
    // disabled: colorOnSurface 12% (background), 38% (text)
    final bg = enabled ? backgroundColor : const Color(0x1F000000);
    final fg = enabled ? textColor : const Color(0x61000000);
    return SizedBox(
      height: height,
      child: Padding(
        // android:insetTop / insetBottom = 6dp
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cornerRadius)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            splashColor: fg.withValues(alpha: 0.24),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: alignment,
                child: AText(
                  allCaps ? text.toUpperCase() : text,
                  font: font,
                  size: textSize,
                  color: fg,
                  bold: bold,
                  align: TextAlign.center,
                  maxLines: 1,
                  // TextAppearance.MaterialComponents.Button letterSpacing
                  letterSpacing: 0.0892857143,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer 2 tombol (Close/Cancel kiri, aksi kanan) dengan guideline 50% dan view selebar __10sdp di tengah.
class TwoButtonRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  const TwoButtonRow({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final gap = dsdp(10);
      final half = c.maxWidth / 2;
      return Row(children: [
        SizedBox(width: half - gap / 2, child: left),
        SizedBox(width: gap),
        SizedBox(width: c.maxWidth - half - gap / 2, child: right),
      ]);
    });
  }
}

// =====================================================================================
// Kartu (MaterialCardView / CardView)
// =====================================================================================

class ACard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double elevation;
  final Color? strokeColor;
  final double strokeWidth;
  final VoidCallback? onTap;

  const ACard({
    super.key,
    required this.child,
    this.color = white,
    required this.radius,
    this.elevation = 0,
    this.strokeColor,
    this.strokeWidth = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: strokeColor == null ? BorderSide.none : BorderSide(color: strokeColor!, width: strokeWidth),
    );
    return Material(
      color: color,
      elevation: elevation,
      shadowColor: Colors.black,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? child
          : InkWell(onTap: onTap, highlightColor: Colors.transparent, child: child),
    );
  }
}

/// @drawable/form_background (solid transparent, corner __5sdp, stroke __2sdp #dadce0)
BoxDecoration formBackground() => _StrokeDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(dsdp(5)),
      border: Border.all(color: formStroke, width: dsdp(2)),
    );

/// Stroke shape Android tidak menambah padding konten (beda dengan Border di Container Flutter).
class _StrokeDecoration extends BoxDecoration {
  const _StrokeDecoration({super.color, super.borderRadius, super.border});

  @override
  EdgeInsetsGeometry get padding => EdgeInsets.zero;
}

/// Sentuhan tanpa visual (setOnClickListener pada layout tanpa background)
class Clickable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Clickable({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
  }
}

/// Area status bar.
/// targetSdk 35 di Android 15+ (API 35+) = edge-to-edge: konten di belakang status bar,
/// sedangkan di bawah API 35 window.statusBarColor dipakai dan konten mulai di bawah status bar.
/// (Navigation bar bawah untuk API < 35 ditangani di MaterialApp.builder.)
class AWindow extends StatelessWidget {
  final Color statusBarColor;
  final Color background;
  final Widget child;
  final bool edgeToEdge;

  const AWindow({
    super.key,
    required this.statusBarColor,
    required this.background,
    required this.child,
    required this.edgeToEdge,
  });

  @override
  Widget build(BuildContext context) {
    if (edgeToEdge) return ColoredBox(color: background, child: child);
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: background,
      child: Column(children: [
        Container(height: top, color: statusBarColor),
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
        ),
      ]),
    );
  }
}

// =====================================================================================
// ScanningIndicator.kt & ScanningIndicator3.kt
// =====================================================================================

class ScanningIndicatorController extends ChangeNotifier {
  bool _running = false;
  bool get running => _running;

  void startAnimation() {
    _running = true;
    notifyListeners();
  }

  void stopAnimation() {
    _running = false;
    notifyListeners();
  }
}

/// ScanningIndicator3: background rounded rect #20000000 radius 20px + garis colorPrimary 6px,
/// ValueAnimator 0..1, 2000ms, INFINITE, REVERSE.
class ScanningIndicator3 extends StatefulWidget {
  final ScanningIndicatorController controller;
  const ScanningIndicator3({super.key, required this.controller});

  @override
  State<ScanningIndicator3> createState() => _ScanningIndicator3State();
}

class _ScanningIndicator3State extends State<ScanningIndicator3> with SingleTickerProviderStateMixin {
  late final AnimationController _animator =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

  double _scannerY = 0;
  bool _isGoingDown = true;
  bool _isAnimating = false;
  double _height = 0;
  static const double _scannerHeight = 60; // px

  @override
  void initState() {
    super.initState();
    _animator.addListener(() {
      _updateScannerPosition(_animator.value);
      setState(() {});
    });
    widget.controller.addListener(_onControl);
    _onControl();
  }

  void _onControl() {
    if (widget.controller.running) {
      if (!_isAnimating) {
        _isAnimating = true;
        _animator.repeat(reverse: true);
      }
    } else {
      if (_isAnimating) {
        _isAnimating = false;
        _animator.stop();
        _scannerY = 0;
        setState(() {});
      }
    }
  }

  void _updateScannerPosition(double progress) {
    if (_isGoingDown) {
      _scannerY = _height * progress;
      if (_scannerY > _height - _scannerHeight) {
        _scannerY = _height - _scannerHeight;
        _isGoingDown = false;
      }
    } else {
      _scannerY = _height - _height * progress;
      if (_scannerY < 0) {
        _scannerY = 0;
        _isGoingDown = true;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControl);
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(builder: (context, c) {
      _height = c.maxHeight * dpr;
      return CustomPaint(
        size: Size(c.maxWidth, c.maxHeight),
        painter: _Scanner3Painter(_scannerY / dpr, dpr),
      );
    });
  }
}

class _Scanner3Painter extends CustomPainter {
  final double y;
  final double dpr;
  _Scanner3Painter(this.y, this.dpr);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(20 / dpr)),
      Paint()..color = const Color(0x20000000),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = colorPrimary
        ..strokeWidth = 6 / dpr,
    );
  }

  @override
  bool shouldRepaint(_Scanner3Painter old) => old.y != y;
}

/// ScanningIndicator: garis merah 5px, bergerak 15px tiap frame naik-turun.
class ScanningIndicator extends StatefulWidget {
  final ScanningIndicatorController controller;
  const ScanningIndicator({super.key, required this.controller});

  @override
  State<ScanningIndicator> createState() => _ScanningIndicatorState();
}

class _ScanningIndicatorState extends State<ScanningIndicator> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => _refreshView());
  double _posY = 0;
  bool _isGoingDown = true;
  bool _showLine = true;
  double _height = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControl);
    _ticker.start();
  }

  void _onControl() {
    if (widget.controller.running) {
      _showLine = true;
      if (!_ticker.isActive) _ticker.start();
    } else {
      _showLine = false;
      _posY = 0;
      _isGoingDown = true;
      _ticker.stop();
    }
    setState(() {});
  }

  void _refreshView() {
    if (_isGoingDown) {
      _posY += 15;
      if (_posY > _height) {
        _posY = _height;
        _isGoingDown = false;
      }
    } else {
      _posY -= 15;
      if (_posY < 0) {
        _posY = 0;
        _isGoingDown = true;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControl);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(builder: (context, c) {
      _height = c.maxHeight * dpr;
      return CustomPaint(
        size: Size(c.maxWidth, c.maxHeight),
        painter: _showLine ? _LinePainter(_posY / dpr, 5 / dpr) : null,
      );
    });
  }
}

class _LinePainter extends CustomPainter {
  final double y;
  final double width;
  _LinePainter(this.y, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()
      ..color = const Color(0xFFFF0000)
      ..strokeWidth = width);
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.y != y;
}

/// android:overScrollMode="never"
class NoOverscroll extends ScrollBehavior {
  const NoOverscroll();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

/// Tinggi satu baris TextView/EditText (includeFontPadding) dalam dp.
double aLineHeight(BuildContext context, AFont font, double size) {
  final m = _metrics[font]!;
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final px = (size * dpr).roundToDouble();
  return ((m.yMax / 1000 * px).ceilToDouble() + (-m.yMin / 1000 * px).ceilToDouble()) / dpr;
}

/// Footer putih dengan android:elevation (bayangan ke atas).
BoxDecoration elevatedFooter() => const BoxDecoration(
      color: white,
      boxShadow: [BoxShadow(color: Color(0x24000000), blurRadius: 12, offset: Offset(0, -2))],
    );
