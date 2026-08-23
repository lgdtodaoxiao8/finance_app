import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Prompts for a single numeric amount. Owns its controller (disposed after the
/// close animation, so it survives the field rebuild during dismissal). Returns
/// the entered value, or null on cancel. [confirmLabel] defaults to Save.
Future<double?> showAmountInput(
  BuildContext context, {
  required String title,
  String? label,
  String? symbol,
  double? initial,
  String? confirmLabel,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _AmountInputDialog(
      title: title,
      label: label,
      symbol: symbol,
      initial: initial,
      confirmLabel: confirmLabel,
    ),
  );
}

class _AmountInputDialog extends StatefulWidget {
  const _AmountInputDialog({
    required this.title,
    this.label,
    this.symbol,
    this.initial,
    this.confirmLabel,
  });

  final String title;
  final String? label;
  final String? symbol;
  final double? initial;
  final String? confirmLabel;

  @override
  State<_AmountInputDialog> createState() => _AmountInputDialogState();
}

class _AmountInputDialogState extends State<_AmountInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: (widget.initial == null || widget.initial! <= 0)
        ? ''
        : (widget.initial! % 1 == 0
              ? widget.initial!.toInt().toString()
              : widget.initial!.toString()),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          suffixText: widget.symbol,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(_controller.text.replaceAll(',', '.'));
            Navigator.pop(context, v);
          },
          child: Text(widget.confirmLabel ?? l.save),
        ),
      ],
    );
  }
}
