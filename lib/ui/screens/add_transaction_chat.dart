import 'package:finance_app/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finance_app/main.dart';

class AddTransactionChat extends StatefulWidget {
  const AddTransactionChat({
    super.key,
    required this.accounts,
    required this.categories,
    required this.currencies,
    required this.pushToBase,
  });
  final Future<void> Function(Map<String, dynamic>) pushToBase;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> currencies;

  @override
  State<AddTransactionChat> createState() {
    return _AddTransactionChatState(
      accounts: accounts,
      categories: categories,
      currencies: currencies,
    );
  }
}

class _AddTransactionChatState extends State<AddTransactionChat>
    with TickerProviderStateMixin {
  _AddTransactionChatState({
    required this.accounts,
    required this.categories,
    required this.currencies,
  });

  final _formKey = GlobalKey<FormState>();
  bool isSending = false;

  final db = DatabaseHelper.instance;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> currencies;

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String transactionType = 'expense';

  int? accountId;
  int? accountDestinationId;

  int? categoryId;

  int? currencyId;

  DateTime transactionDate = DateTime.now();

  String? _error;

  int _selectedIndex = 0;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    initialiseDropDown();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) return;
      setState(() {
        _selectedIndex = tabController.index;
        transactionType = _selectedIndex == 0 ? 'expense' : 'transfer';
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    tabController.dispose();
    super.dispose();
  }

  void initialiseDropDown() {
    if (accounts.isNotEmpty) {
      accountId = accounts.first['id'];
    } else {
      _error = 'You had no added any account';
    }

    if (categories.isNotEmpty) {
      categoryId = categories.first['id'];
    } else {
      _error = 'You had no added any category';
    }

    if (currencies.isNotEmpty) {
      currencyId = currencies.first['id'];
    } else {
      _error = 'You have no added any currency';
    }
  }

  Future<void> addTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSending = true);

    await widget.pushToBase({
      "account_id": accountId,
      "account_destination_id": accountDestinationId,
      "category_id": categoryId,
      "currency_id": currencyId,
      "amount": double.parse(_amountController.text),
      "date": transactionDate.toUtc().toIso8601String(),
      "note": _noteController.text.trim(),
      "type": transactionType,
      "is_canceled": 0,
    });

    if (!mounted) return;

    setState(() {
      isSending = false;
      _amountController.clear();
      _noteController.clear();
    });

    Navigator.of(context).pop();
  }

  // ---- small helpers for UI
  String _fmtShort(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: transactionDate,
      firstDate: DateTime(transactionDate.year - 30),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => transactionDate = picked);
    }
  }

  InputDecoration _inputDecoration({
    String? label,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: kTextStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Add Transaction' : 'Add Transfer',
          style: kTextStyle.copyWith(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // top hint / error
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: kTextStyle.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Form card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Transaction type (small segmented)
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedControl(
                              value: transactionType,
                              onChanged: (v) =>
                                  setState(() => transactionType = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Accounts / Destination
                      if (accounts.isEmpty || accountId == null)
                        Center(
                          child: Text(
                            'You have no accounts',
                            style: kTextStyle.copyWith(),
                          ),
                        )
                      else ...[
                        DropdownButtonFormField<int>(
                          value: accountId,
                          decoration: _inputDecoration(
                            label: 'From account',
                            prefix: const Icon(Icons.account_balance_wallet),
                          ),
                          items: [
                            for (final a in accounts.where(
                              (a) => a['id'] != accountDestinationId,
                            ))
                              DropdownMenuItem(
                                value: int.parse(a['id'].toString()),
                                child: Text(
                                  a['name'],
                                  style: kTextStyle.copyWith(),
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => accountId = v),
                        ),
                        const SizedBox(height: 12),

                        if (transactionType == 'transfer') ...[
                          if (accounts.length > 1)
                            DropdownButtonFormField<int>(
                              value: accountDestinationId,
                              decoration: _inputDecoration(
                                label: 'To account',
                                prefix: const Icon(Icons.account_balance),
                              ),
                              items: [
                                for (final a in accounts.where(
                                  (a) => a['id'] != accountId,
                                ))
                                  DropdownMenuItem(
                                    value: int.parse(a['id'].toString()),
                                    child: Text(
                                      a['name'],
                                      style: kTextStyle.copyWith(),
                                    ),
                                  ),
                              ],
                              onChanged: (v) =>
                                  setState(() => accountDestinationId = v),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No second account available',
                                style: kTextStyle.copyWith(),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],

                        // Amount + currency
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(
                                  label: 'Amount',
                                  prefix: const Icon(
                                    Icons.attach_money_rounded,
                                  ),
                                ),
                                style: kTextStyle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Enter amount';
                                  final n = double.tryParse(
                                    value.replaceAll(',', '.'),
                                  );
                                  if (n == null || n <= 0)
                                    return 'Amount must be > 0';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: currencyId,
                                decoration: _inputDecoration(
                                  label: 'Currency',
                                  prefix: const Icon(Icons.currency_exchange),
                                ),
                                items: [
                                  for (final c in currencies)
                                    DropdownMenuItem(
                                      value: int.parse(c['id'].toString()),
                                      child: Text(
                                        c['symbol'],
                                        style: kTextStyle.copyWith(),
                                      ),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => currencyId = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Category (for non-transfer)
                        if (transactionType != 'transfer')
                          DropdownButtonFormField<int>(
                            value: categoryId,
                            decoration: _inputDecoration(
                              label: 'Category',
                              prefix: const Icon(Icons.category),
                            ),
                            items: [
                              for (final c in categories)
                                DropdownMenuItem(
                                  value: int.parse(c['id'].toString()),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Color(
                                          c['color'] ?? 0xFF6C6C6C,
                                        ),
                                        child: Icon(
                                          IconData(
                                            c['icon_code_point'] ?? 0xe3af,
                                            fontFamily: 'MaterialIcons',
                                          ),
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c['name'],
                                        style: kTextStyle.copyWith(),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            onChanged: (v) => setState(() => categoryId = v),
                          ),

                        const SizedBox(height: 12),

                        // Note
                        TextFormField(
                          controller: _noteController,
                          decoration: _inputDecoration(
                            label: 'Note',
                            prefix: const Icon(Icons.note),
                          ),
                          maxLength: 80,
                          style: kTextStyle.copyWith(),
                        ),
                        const SizedBox(height: 12),

                        // Date picker row
                        Row(
                          children: [
                            _DatePickerButton(
                              date: transactionDate,
                              onTap: _pickDate,
                              fmt: _fmtShort,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Selected: ${_fmtShort(transactionDate)}, ${transactionDate.year}',
                                style: kTextStyle.copyWith(
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSending
                                    ? null
                                    : () {
                                        _formKey.currentState!.reset();
                                        setState(() {
                                          _noteController.clear();
                                          _amountController.clear();
                                          initialiseDropDown();
                                        });
                                      },
                                child: Text(
                                  'Reset',
                                  style: kTextStyle.copyWith(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSending ? null : addTransaction,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: isSending
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Add',
                                        style: kTextStyle.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // small helper / hint
            Text(
              'Tip: you can add categories and accounts in settings',
              style: kTextStyle.copyWith(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small segmented control for transaction type (expense/income/transfer)
class SegmentedControl extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const SegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = <Map<String, dynamic>>[
      {'v': 'expense', 'label': 'Expense', 'icon': Icons.arrow_upward_rounded},
      {'v': 'income', 'label': 'Income', 'icon': Icons.arrow_downward_rounded},
      {'v': 'transfer', 'label': 'Transfer', 'icon': Icons.swap_horiz_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options.map((opt) {
          final selected = opt['v'] == value;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(opt['v'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt['icon'] as IconData,
                      size: 16,
                      color: selected ? cs.onPrimary : cs.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt['label'] as String,
                      style: kTextStyle.copyWith(
                        fontSize: 13,
                        color: selected ? cs.onPrimary : cs.onSurface,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Tiny date button that shows a compact rounded chip with date and calendar icon.
class _DatePickerButton extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  final String Function(DateTime) fmt;
  const _DatePickerButton({
    required this.date,
    required this.onTap,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline.withOpacity(0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: cs.onSurface.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            Text(
              fmt(date),
              style: kTextStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
