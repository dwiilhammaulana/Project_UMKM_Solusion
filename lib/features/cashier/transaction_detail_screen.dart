import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';

// perubahan trasanksi
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;
  Future<void> _printReceipt(
    BuildContext context,
    TransactionRecord transaction,
    DebtRecord? debt,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'STRUK PEMBELIAN',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Kode: ${transaction.transactionCode}'),
              pw.Text(
                  'Tanggal: ${AppFormatters.dateTime(transaction.createdAt)}'),
              pw.Text('Pelanggan: ${transaction.customerName}'),
              pw.Text('Dibuat oleh: ${_creatorName(transaction)}'),
              pw.Text('Metode: ${transaction.paymentMethod.label}'),
              pw.Divider(),
              ...transaction.items.map(
                (item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.productName),
                    pw.Text(
                        '${item.quantity} x ${AppFormatters.currency(item.sellPrice)}'),
                    pw.Text(
                        'Subtotal: ${AppFormatters.currency(item.subtotal)}'),
                    pw.SizedBox(height: 5),
                  ],
                ),
              ),
              pw.Divider(),
              pw.Text(
                  'Total: ${AppFormatters.currency(transaction.totalAmount)}'),
              pw.Text('Bayar: ${_amountPaidLabel(transaction, debt)}'),
              pw.Text('Status: ${_paymentStatusLabel(transaction, debt)}'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final transaction = state.transactionById(transactionId);

    if (transaction == null) {
      return const EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'Transaksi tidak ditemukan',
        subtitle: 'Buka kembali riwayat transaksi lalu pilih data yang lain.',
      );
    }

    final debt = _debtForTransaction(state, transaction);
    final debtPayments = debt == null
        ? const <DebtPayment>[]
        : (state.payments.where((payment) => payment.debtId == debt.id).toList()
          ..sort((a, b) => b.paidAt.compareTo(a.paidAt)));

    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: StatusChip(
            label: transaction.paymentMethod == PaymentMethod.bon
                ? 'Detail BON'
                : 'Detail transaksi',
            color: Colors.white,
            icon: Icons.receipt_long_rounded,
          ),
          title: transaction.transactionCode,
          subtitle: AppFormatters.dateTime(transaction.createdAt),
          trailing: IconButton.filled(
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.deepTeal,
            ),
            icon: const AppIcon(Icons.arrow_back_rounded),
          ),
          bottom: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusChip(
                label: '${transaction.totalQuantity} qty',
                color: Colors.white,
                icon: Icons.shopping_bag_rounded,
              ),
              StatusChip(
                label: '${transaction.lineItemCount} jenis item',
                color: Colors.white,
                icon: Icons.list_alt_rounded,
              ),
              StatusChip(
                label: transaction.paymentMethod.label,
                color: Colors.white,
                icon: Icons.payments_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PaymentHighlight(
                      label: 'Total',
                      value: AppFormatters.currency(transaction.totalAmount),
                      icon: Icons.receipt_long_rounded,
                      color: AppTheme.deepTeal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PaymentHighlight(
                      label: 'Status',
                      value: _paymentStatusLabel(transaction, debt),
                      icon: transaction.paymentMethod == PaymentMethod.bon
                          ? Icons.schedule_rounded
                          : Icons.verified_rounded,
                      color: transaction.paymentMethod == PaymentMethod.bon
                          ? AppTheme.warning
                          : AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _CompactInfoRow(
                key: const Key('transaction-paid-amount-row'),
                icon: Icons.payments_rounded,
                label: 'Dibayar',
                value: _amountPaidLabel(transaction, debt),
              ),
              _CompactInfoRow(
                icon: Icons.credit_score_rounded,
                label: 'Metode',
                value: transaction.paymentMethod.label,
              ),
              const Divider(height: 22),
              SectionHeader(
                title: 'Ringkasan Transaksi',
                action: Tooltip(
                  message: 'Cetak struk',
                  child: IconButton.filled(
                    onPressed: () => _printReceipt(context, transaction, debt),
                    icon: const AppIcon(Icons.print_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _CompactInfoRow(
                icon: Icons.receipt_long_outlined,
                label: 'Kode',
                value: transaction.transactionCode,
              ),
              _CompactInfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Pelanggan',
                value: transaction.customerName,
              ),
              _CompactInfoRow(
                icon: Icons.verified_user_rounded,
                label: 'Dibuat oleh',
                value: _creatorName(transaction),
              ),
              if ((transaction.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.foam,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    transaction.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (transaction.paymentMethod == PaymentMethod.bon) ...[
          const SizedBox(height: 20),
          _DebtPaymentHistoryCard(payments: debtPayments),
        ],
        const SizedBox(height: 20),
        AppSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Detail Item',
                action: Wrap(
                  spacing: 8,
                  children: [
                    _MiniMetric(
                      label: 'Qty',
                      value: '${transaction.totalQuantity}',
                      color: AppTheme.deepTeal,
                    ),
                    _MiniMetric(
                      label: 'Jenis',
                      value: '${transaction.lineItemCount}',
                      color: AppTheme.info,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < transaction.items.length; index++)
                _TransactionItemCard(
                  item: transaction.items[index],
                  index: index + 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _creatorName(TransactionRecord transaction) {
    final name = transaction.createdByName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'Belum tersedia';
  }

  static DebtRecord? _debtForTransaction(
    PosAppState state,
    TransactionRecord transaction,
  ) {
    for (final debt in state.debts) {
      if (debt.transactionId == transaction.id) {
        return debt;
      }
    }
    return null;
  }

  static String _paymentStatusLabel(
    TransactionRecord transaction,
    DebtRecord? debt,
  ) {
    if (transaction.paymentMethod != PaymentMethod.bon) {
      return 'Lunas';
    }
    if (debt == null) {
      return 'BON';
    }
    return switch (debt.status) {
      DebtStatus.paid => 'Lunas',
      DebtStatus.partial => 'Cicilan',
      DebtStatus.unpaid => 'Belum Lunas',
    };
  }

  static String _amountPaidLabel(
    TransactionRecord transaction,
    DebtRecord? debt,
  ) {
    if (transaction.paymentMethod == PaymentMethod.bon && debt != null) {
      return AppFormatters.currency(debt.paidAmount);
    }
    return AppFormatters.currency(transaction.amountPaid);
  }
}

class _DebtPaymentHistoryCard extends StatelessWidget {
  const _DebtPaymentHistoryCard({required this.payments});

  final List<DebtPayment> payments;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Riwayat Pembayaran BON'),
          const SizedBox(height: 12),
          if (payments.isEmpty)
            const EmptyState(
              icon: Icons.payments_outlined,
              title: 'Belum ada cicilan',
              subtitle: 'Cicilan bon akan muncul di sini setelah dicatat.',
            )
          else
            ...payments.map(
              (payment) => _DebtPaymentHistoryTile(payment: payment),
            ),
        ],
      ),
    );
  }
}

class _DebtPaymentHistoryTile extends StatelessWidget {
  const _DebtPaymentHistoryTile({required this.payment});

  final DebtPayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.foam,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const AppIcon(
              Icons.payments_rounded,
              color: AppTheme.deepTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppFormatters.currency(payment.amount),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${payment.paymentMethod.label} - ${AppFormatters.dateTime(payment.paidAt)}',
                  style: theme.textTheme.bodySmall,
                ),
                if ((payment.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItemCard extends StatelessWidget {
  const _TransactionItemCard({required this.item, required this.index});

  final TransactionItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.deepTeal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.deepTeal,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} x ${AppFormatters.currency(item.sellPrice)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Subtotal',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.currency(item.subtotal),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentHighlight extends StatelessWidget {
  const _PaymentHighlight({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: color, size: 20),
          const SizedBox(height: 14),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.titleLarge?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.foam,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(icon, size: 16, color: AppTheme.deepTeal),
          ),
          const SizedBox(width: 10),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
