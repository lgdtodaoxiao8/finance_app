import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Кастомный цветовой пикер в стиле iOS
class ColorPicker extends StatefulWidget {
  /// Начальный цвет
  // final Color initialColor;

  /// Вызывается при изменении цвета
  final ValueChanged<Color> onColorChanged;

  /// Размер кружков в палитре
  final double paletteItemSize;

  /// Высота слайдера
  final double sliderHeight;

  /// Размер превью цвета
  final double previewSize;

  const ColorPicker({
    super.key,
    // this.initialColor = Colors.blue,
    required this.onColorChanged,
    this.paletteItemSize = 45,
    this.sliderHeight = 12,
    this.previewSize = 100,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late int _selectedPaletteColorIndex;
  late Color _selectedColor;
  double _lightness = 0.5;
  late List<List<Color>> _paletteColors;
  bool isOpened = true;

  @override
  void initState() {
    super.initState();
    _initColors();
  }

  void _initColors() {
    _paletteColors = [
      [Colors.cyan.shade400, Colors.cyan.shade100],
      [Colors.blue.shade400, Colors.blue.shade100],
      [Colors.deepPurple.shade400, Colors.deepPurple.shade100],
      [Colors.purple.shade400, Colors.purple.shade100],
      [Colors.pink.shade400, Colors.pink.shade100],
      [Colors.red.shade400, Colors.red.shade100],
      [Colors.deepOrange.shade400, Colors.deepOrange.shade100],
      [Colors.amberAccent.shade400, Colors.amberAccent.shade100],
      [Colors.yellow.shade400, Colors.yellow.shade100],
      [Colors.lime.shade400, Colors.lime.shade100],
      [Colors.lightGreen.shade400, Colors.lightGreen.shade100],
      [Colors.green.shade400, Colors.green.shade100],
    ];

    _selectedPaletteColorIndex = 0;
    _updateSelectedColor();
  }

  void _updateSelectedColor() {
    final baseColor = _paletteColors[_selectedPaletteColorIndex][0];
    final lightColor = _paletteColors[_selectedPaletteColorIndex][1];

    final lerpColor = Color.lerp(lightColor, baseColor, _lightness)!;

    setState(() {
      _selectedColor = lerpColor;
    });

    WidgetsBinding.instance.addPostFrameCallback((duration) {
      if (mounted) widget.onColorChanged(_selectedColor);
    });
  }

  void _selectPaletteColor(int index) {
    setState(() {
      _selectedPaletteColorIndex = index;
      _lightness = 0.5;
      _updateSelectedColor();
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
        color: const Color(0xFFEDEDF2),
        borderRadius: BorderRadius.circular(20),
      ),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedPadding(
            padding: isOpened
                ? const EdgeInsets.only(top: 25)
                : const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            duration: const Duration(milliseconds: 200),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isOpened
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: InkWell(
                onTap: () => setState(() => isOpened = !isOpened),
                child: Row(
                  children: [
                    Text(
                      'Color Picker',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: const Color(0xFF242528),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isOpened
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                  ],
                ),
              ),
              secondChild: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPalette(),
                  const SizedBox(height: 10),
                  _buildLightnessSlider(),
                  IconButton(
                    onPressed: () => setState(() => isOpened = !isOpened),
                    icon: Icon(
                      isOpened
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalette() {
    return SizedBox(
      height: widget.paletteItemSize,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (ctx, index) => const SizedBox(width: 6),
        itemCount: _paletteColors.length,
        itemBuilder: (ctx, index) => _buildPaletteItem(index),
      ),
    );
  }

  Widget _buildPaletteItem(int index) {
    final baseColor = _paletteColors[index][0];
    final lightColor = _paletteColors[index][1];
    final isSelected = index == _selectedPaletteColorIndex;

    return GestureDetector(
      onTap: () => _selectPaletteColor(index),
      child: Container(
        height: widget.paletteItemSize,
        width: widget.paletteItemSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(lightColor, baseColor, 0.7),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                // ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildLightnessSlider() {
    final baseColor = _paletteColors[_selectedPaletteColorIndex][0];
    final lightColor = _paletteColors[_selectedPaletteColorIndex][1];

    return SliderTheme(
      data: SliderThemeData(
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 15,
        ),
        trackShape: GradientTrackShape(
          baseColor: baseColor,
          minColor: lightColor,
        ),
        trackHeight: widget.sliderHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Slider(
          value: _lightness,
          min: 0.0,
          max: 1.0,
          onChanged: _updateLightness,
          activeColor: _selectedColor,
          inactiveColor: Colors.grey[300],
        ),
      ),
    );
  }
}

//custom track with gradient for slider
class GradientTrackShape extends SliderTrackShape {
  final Color baseColor;
  final Color minColor;
  final double borderWidth;
  final Color borderColor;

  const GradientTrackShape({
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
      stops: const [0.1, 1.0],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final paint = Paint()..shader = gradient.createShader(innerRect);

    // Рисуем градиент с меньшим радиусом скругления
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        innerRect,
        Radius.circular(4),
      ),
      paint,
    );
  }
}
