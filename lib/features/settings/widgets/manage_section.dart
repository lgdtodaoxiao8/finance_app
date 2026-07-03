import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// A white card with a titled header, an "add" action, and a list of rows
/// (or a loading/empty placeholder). Shared by the account/category sections.
class ManageSection extends StatelessWidget {
  const ManageSection({
    super.key,
    required this.title,
    required this.onAdd,
    required this.loading,
    required this.isEmpty,
    required this.emptyLabel,
    required this.children,
  });

  final String title;
  final VoidCallback onAdd;
  final bool loading;
  final bool isEmpty;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: kTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Add',
                onPressed: onAdd,
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(
                emptyLabel,
                style: kTextStyle.copyWith(color: Colors.grey[600]),
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

/// A single manageable row: leading widget, title, and a delete button.
class ManageTile extends StatelessWidget {
  const ManageTile({
    super.key,
    required this.leading,
    required this.title,
    required this.onDelete,
  });

  final Widget leading;
  final String title;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 34, height: 34, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: kTextStyle.copyWith(fontSize: 15),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a confirmation dialog and runs [onConfirm] if the user accepts.
Future<void> confirmDelete(
  BuildContext context, {
  required String what,
  required VoidCallback onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete "$what"?', style: kTextStyle.copyWith()),
      content: Text(
        'This action cannot be undone.',
        style: kTextStyle.copyWith(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: kTextStyle.copyWith()),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Delete', style: kTextStyle.copyWith(color: Colors.red)),
        ),
      ],
    ),
  );
  if (confirmed == true) onConfirm();
}
