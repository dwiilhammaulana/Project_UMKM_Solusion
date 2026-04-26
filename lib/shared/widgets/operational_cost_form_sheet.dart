import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../state/app_state.dart';
import 'common_widgets.dart';

Future<void> showOperationalCostFormSheet(
  BuildContext context,
  WidgetRef ref, {
  OperationalCost? operationalCost,
  DateTime? initialMonth,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _OperationalCostFormSheet(
      ref: ref,
      operationalCost: operationalCost,
      initialMonth: initialMonth,
    ),
  );
}

class _OperationalCostFormSheet extends ConsumerStatefulWidget {
  const _OperationalCostFormSheet({
    required this.ref,
    this.operationalCost,
    this.initialMonth,
  });

  final WidgetRef ref;
  final OperationalCost? operationalCost;
  final DateTime? initialMonth;

  @override
  ConsumerState<_OperationalCostFormSheet> createState() =>
      _OperationalCostFormSheetState();
}

class _OperationalCostFormSheetState
    extends ConsumerState<_OperationalCostFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _costNameController;
  late final TextEditingController _amountController;
  late DateTime _monthYear;
  bool _isSaving = false;

  String get _monthLabel => DateFormat('MMMM yyyy', 'id_ID').format(_monthYear);

  @override
  void initState() {
    super.initState();
    _costNameController = TextEditingController(
      text: widget.operationalCost?.costName ?? '',
    );
    _amountController = TextEditingController(
      text: widget.operationalCost == null
          ? ''
          : widget.operationalCost!.amount.toStringAsFixed(0),
    );
    final baseMonth = widget.operationalCost?.monthYear ??
        widget.initialMonth ??
        DateTime.now();
    _monthYear = DateTime(baseMonth.year, baseMonth.month, 1);
  }

  @override
  void dispose() {
    _costNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.operationalCost == null
                    ? 'Tambah Biaya Operasional'
                    : 'Edit Biaya Operasional',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Catat biaya toko bulanan agar perhitungan net profit di laporan sesuai kondisi nyata.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _isSaving ? null : _pickMonth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Periode biaya',
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  child: Text(_monthLabel),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costNameController,
                decoration: const InputDecoration(labelText: 'Nama biaya'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama biaya wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Nominal biaya'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Nominal biaya harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(
                  _isSaving
                      ? 'Menyimpan...'
                      : widget.operationalCost == null
                          ? 'Simpan Biaya'
                          : 'Update Biaya',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _monthYear,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Pilih bulan biaya',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _monthYear = DateTime(picked.year, picked.month, 1));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.ref.read(posStateProvider).saveOperationalCost(
            id: widget.operationalCost?.id,
            monthYear: _monthYear,
            costName: _costNameController.text.trim(),
            amount: double.parse(_amountController.text.trim()),
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
