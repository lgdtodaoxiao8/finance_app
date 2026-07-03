import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class BlackAndWhiteSlider extends StatefulWidget {
  const BlackAndWhiteSlider({
    super.key,
    this.sliderHeight = 12,
    required this.onColorChanged,
  });

  final double sliderHeight;
  final void Function(Color) onColorChanged;

  @override
  State<BlackAndWhiteSlider> createState() => _BlackAndWhiteSliderState();
}

class _BlackAndWhiteSliderState extends State<BlackAndWhiteSlider> {
  final _baseColor = Colors.black;
  final _lightColor = Colors.white;
  late Color _selectedColor;

  double _lightness = 0.7;

  @override
  void initState() {
    super.initState();
    _updateSelectedColor();
  }

  void _updateSelectedColor() {
    final lerpColor = Color.lerp(_lightColor, _baseColor, _lightness)!;

    setState(() {
      _selectedColor = lerpColor;
    });

    WidgetsBinding.instance.addPostFrameCallback((duration) {
      if (mounted) widget.onColorChanged(_selectedColor);
    });
  }

  void _updateLightness(double value) {
    setState(() {
      _lightness = value;
      _updateSelectedColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(20),
      ),
      width: double.infinity,
      child: SliderTheme(
        data: SliderThemeData(
          overlayShape: SliderComponentShape.noOverlay,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 15,
            pressedElevation: 0,
          ),
          trackShape: GradientTrackShapeForBlackAndWhite(
            baseColor: _baseColor,
            minColor: _lightColor,
          ),
          trackHeight: widget.sliderHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
          child: Slider(
            value: _lightness,
            min: 0.0,
            max: 1.0,
            onChanged: _updateLightness,
            activeColor: _selectedColor,
            inactiveColor: Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

class GradientTrackShapeForBlackAndWhite extends SliderTrackShape {
  final Color baseColor;
  final Color minColor;
  final double borderWidth;
  final Color borderColor;

  const GradientTrackShapeForBlackAndWhite({
    required this.baseColor,
    required this.minColor,
    this.borderWidth = 1,
    this.borderColor = const Color(0x7E9E9E9E),
  });

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 0;
    final trackLeft = offset.dx;
    // Сдвигаем позицию на половину ширины обводки
    final trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2 - borderWidth / 2;
    final trackWidth = parentBox.size.width;

    // Увеличиваем высоту на ширину обводки сверху и снизу
    return Rect.fromLTWH(
      trackLeft,
      trackTop,
      trackWidth,
      trackHeight + borderWidth,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    Offset? secondaryOffset,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );

    // Рисуем обводку
    _paintBorder(context, trackRect);

    // Рисуем градиентный трек внутри обводки
    _paintGradientTrack(context, trackRect);
  }

  void _paintBorder(PaintingContext context, Rect trackRect) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Скругление с учетом ширины обводки
    final roundedRect = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(4 + borderWidth / 2),
    );

    context.canvas.drawRRect(roundedRect, borderPaint);
  }

  void _paintGradientTrack(PaintingContext context, Rect trackRect) {
    // Создаем внутренний прямоугольник для градиента
    final innerRect = Rect.fromLTWH(
      trackRect.left + borderWidth / 2,
      trackRect.top + borderWidth / 2,
      trackRect.width - borderWidth,
      trackRect.height - borderWidth,
    );

    final gradient = LinearGradient(
      colors: [minColor, baseColor],
      stops: const [0.2, .9],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final paint = Paint()..shader = gradient.createShader(innerRect);

    // Рисуем градиент с меньшим радиусом скругления
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        innerRect,
        const Radius.circular(4),
      ),
      paint,
    );
  }
}
