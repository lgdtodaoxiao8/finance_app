import 'package:flutter/material.dart';
import 'package:finance_app/main.dart';

class NewTransaction extends StatefulWidget {
  const NewTransaction({super.key});

  @override
  State<NewTransaction> createState() => _NewTransactionState();
}

class _NewTransactionState extends State<NewTransaction> {
  int indexPage = 0; // moved into state (was global in your snippet)

  Widget _button(int index) {
    final bool selected = indexPage == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => indexPage = index),
        child: SizedBox(
          child: Center(
            child: Text(
              'Button ${index + 1}',
              style: kTextStyle.copyWith(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.primary,
            ),
            child: SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sliding indicator: FractionallySizedBox widthFactor=1/3 sits inside AnimatedAlign
                  AnimatedAlign(
                    alignment: Alignment(-1 + indexPage.toDouble(), 0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: FractionallySizedBox(
                      widthFactor: 1 / 3,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 34,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),

                  // Buttons row on top of the sliding background
                  Row(
                    children: [
                      _button(0),
                      _button(1),
                      _button(2),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: const Center(child: Text('some content')),
    );
  }
}
