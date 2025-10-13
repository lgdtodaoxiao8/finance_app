import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QwenTransactionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const QwenTransactionsScreen({super.key, required this.transactions});

  @override
  State<QwenTransactionsScreen> createState() =>
      _QwenTransactionsScreenState(transactions);
}

class _QwenTransactionsScreenState extends State<QwenTransactionsScreen> {
  final List<Map<String, dynamic>> _transactions;
  bool _isIncome = false;
  String _selectedPeriod = 'This week';

  _QwenTransactionsScreenState(this._transactions);

  List<Map<String, dynamic>> _getFilteredTransactions() {
    return _transactions.where((t) {
      if (_isIncome) {
        return t['type'] == 'income';
      } else {
        return t['type'] == 'expense';
      }
    }).toList();
  }

  double _getTotalAmount() {
    return _getFilteredTransactions().fold(0.0, (sum, t) => sum + t['amount']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 30),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.primary,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemCount = 2;
                final availableWidth = constraints.maxWidth - 8;
                final buttonWidth = availableWidth / itemCount;

                return Stack(
                  children: [
                    // Кнопки Income/Expenses
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isIncome = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isIncome
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Income',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isIncome ? Colors.black : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isIncome = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isIncome
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Expenses',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_isIncome
                                      ? Colors.black
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Анимированный слайдер
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      left: buttonWidth * (_isIncome ? 0 : 1),
                      top: 0,
                      width: buttonWidth,
                      height: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Total Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isIncome ? 'Total income' : 'Total expenses',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  icon: const Icon(Icons.arrow_drop_down),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPeriod = newValue!;
                    });
                  },
                  items:
                      <String>[
                        'This week',
                        'Last week',
                        'This month',
                        'Last month',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${_getTotalAmount().toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Transactions List
            Expanded(
              child: ListView.builder(
                itemCount: _getFilteredTransactions().length,
                itemBuilder: (context, i) {
                  final t = _getFilteredTransactions()[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isIncome ? Colors.green : Colors.red,
                        ),
                        child: Icon(
                          _isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        "${t['category_name']} - \$${t['amount'].toStringAsFixed(2)} ${t['currency_code']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${t['date']} | ${t['account_name']} | ${t['note']}",
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Text(
                        t['type'].toUpperCase(),
                        style: TextStyle(
                          color: t['type'] == 'income'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
        selectedItemColor: const Color(0xFF5E4FA2),
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new_transaction');
        },
        backgroundColor: const Color(0xFF3A2E6F),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
