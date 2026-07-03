import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/settings/cubit/base_currency_cubit.dart';
import 'package:finance_app/features/settings/widgets/widgets.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: kTextStyle.copyWith()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: BlocProvider(
          create: (_) => BaseCurrencyCubit(getIt<CurrencyRepository>()),
          child: const SetBaseCurrency(),
        ),
      ),
    );
  }
}
