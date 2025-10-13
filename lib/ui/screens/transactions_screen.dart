import 'package:flutter/material.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen(this.transactions, {super.key});

  final List<Map<String, dynamic>> transactions;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late final TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this);
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: const Color(0xFFF7F7FA),

  //     appBar: AppBar(
  //       title: const Text('Transactions'),
  //       backgroundColor: const Color(0xFFF7F7FA),
  //       scrolledUnderElevation: 0,
  //     ),
  //     body: ListView.builder(
  //       shrinkWrap: true,
  //       itemCount: widget.transactions.length,
  //       itemBuilder: (context, index) {
  //         final t = widget.transactions[index];
  //         return Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 10),
  //           margin: const EdgeInsets.symmetric(horizontal: 15),
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.only(
  //               topLeft: index == 0 ? const Radius.circular(10) : Radius.zero,
  //               topRight: index == 0 ? const Radius.circular(10) : Radius.zero,
  //               bottomLeft: index == widget.transactions.length - 1
  //                   ? const Radius.circular(10)
  //                   : Radius.zero,
  //               bottomRight: index == widget.transactions.length - 1
  //                   ? const Radius.circular(10)
  //                   : Radius.zero,
  //             ),
  //             color: Colors.white,
  //           ),

  //           child: ListTile(
  //             title: Text(
  //               "${t['category_name']} - ${t['amount']} ${t['currency_code']}",
  //             ),
  //             subtitle: Text(
  //               "${t['account_name']} | ${t['note']}",
  //             ),
  //             trailing: Text(t['type']),
  //             leading: Icon(Icons.fastfood_outlined),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text("Transactions"),
            floating: true, // чтобы прятался при прокрутке
          ),

          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 23),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                padding: EdgeInsets.all(0),
                shrinkWrap: true, // чтобы подстраивался по высоте
                physics:
                    NeverScrollableScrollPhysics(), // чтобы не конфликтовал со скроллом CustomScrollView
                itemCount: widget.transactions.length,
                itemBuilder: (context, index) {
                  final t = widget.transactions[index];
                  return ListTile(
                    title: Text(
                      "${t['category_name']} - ${t['amount']} ${t['currency_code']}",
                    ),
                    subtitle: Text(
                      "${t['account_name']} | ${t['note']}",
                    ),
                    trailing: Text(t['type']),
                    leading: Icon(Icons.fastfood_outlined),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
