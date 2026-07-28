import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// One-colour picker: a curated palette of saturated swatches plus a full
/// hue-spectrum slider for any shade in between. No alpha control by design —
/// the item's circle tint is always derived from this colour (see ItemAvatar).
class TintColorPicker extends StatelessWidget {
  const TintColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color> onChanged;

  /// Saturated, tint-friendly hues (Material 500-700 range).
  static const palette = <Color>[
    Color(0xFFE53935), // red
    Color(0xFFF4511E), // deep orange
    Color(0xFFFB8C00), // orange
    Color(0xFFFFA000), // amber
    Color(0xFFAFB42B), // lime
    Color(0xFF7CB342), // light green
    Color(0xFF43A047), // green
    Color(0xFF00897B), // teal
    Color(0xFF00ACC1), // cyan
    Color(0xFF039BE5), // light blue
    Color(0xFF1E88E5), // blue
    Color(0xFF3F51B5), // indigo
    Color(0xFF673AB7), // deep purple
    Color(0xFF9C27B0), // purple
    Color(0xFFE91E63), // pink
    Color(0xFF546E7A), // blue grey
    Color(0xFF795548), // brown
    Color(0xFF424242), // graphite
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in palette)
              _Swatch(
                color: c,
                selected: c.toARGB32() == color.toARGB32(),
                onTap: () => onChanged(c),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _HueSlider(color: color, onChanged: onChanged),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 3,
                )
              : null,
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 8)]
              : null,
        ),
        child: selected
            ? const Icon(PhosphorIconsFill.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Full-spectrum hue slider: any hue, fixed pleasant saturation/lightness,
/// alpha locked at 1.
class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  static Color _fromHue(double hue) =>
      HSLColor.fromAHSL(1, hue, 0.62, 0.52).toColor();

  @override
  Widget build(BuildContext context) {
    final hue = HSLColor.fromColor(color).hue;
    return SliderTheme(
      data: SliderThemeData(
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12,
          elevation: 2,
        ),
        trackHeight: 12,
        trackShape: const _SpectrumTrackShape(),
        thumbColor: color,
      ),
      child: Slider(
        value: hue.clamp(0, 360),
        min: 0,
        max: 360,
        onChanged: (h) => onChanged(_fromHue(h)),
      ),
    );
  }
}

class _SpectrumTrackShape extends RoundedRectSliderTrackShape {
  const _SpectrumTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          for (var h = 0; h <= 360; h += 30) _HueSlider._fromHue(h.toDouble()),
        ],
      ).createShader(rect);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      paint,
    );
  }
}
