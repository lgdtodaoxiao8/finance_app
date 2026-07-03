part of 'accounts_cubit.dart';

class AccountsState extends Equatable {
  const AccountsState({
    this.status = ManageStatus.loading,
    this.accounts = const [],
    this.message,
  });

  final ManageStatus status;
  final List<Account> accounts;

  /// Transient message (e.g. a blocked deletion) surfaced as a snackbar.
  final String? message;

  AccountsState copyWith({
    ManageStatus? status,
    List<Account>? accounts,
    String? message,
  }) {
    return AccountsState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, accounts, message];
}
