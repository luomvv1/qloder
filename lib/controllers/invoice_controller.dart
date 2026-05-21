import 'package:flutter/material.dart';

import '../models/invoice.dart';
import '../models/order_detail.dart';
import '../services/invoice_service.dart';

class InvoiceController extends ChangeNotifier {
  InvoiceController({InvoiceService? invoiceService})
    : _invoiceService = invoiceService ?? InvoiceService();

  final InvoiceService _invoiceService;
  final searchController = TextEditingController();

  Stream<List<Invoice>> get invoicesStream => _invoiceService.watchInvoices();

  Stream<Invoice> watchInvoice(String invoiceId) {
    return _invoiceService.watchInvoice(invoiceId);
  }

  Stream<List<OrderDetail>> watchInvoiceDetails(String orderId) {
    return _invoiceService.watchInvoiceDetails(orderId);
  }

  Future<InvoiceReferenceInfo> getReferenceInfo(Invoice invoice) {
    return _invoiceService.getReferenceInfo(invoice);
  }

  void onSearchChanged() {
    notifyListeners();
  }

  List<Invoice> filterInvoices(List<Invoice> invoices) {
    final keyword = searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return invoices;

    return invoices.where((invoice) {
      final searchableText = [
        invoice.invoiceNo,
        invoice.id,
        invoice.orderId,
        invoice.tableId,
        ...invoice.tableIds,
        invoice.customerId ?? '',
        invoice.paymentMethod,
        invoice.paidBy,
      ].join(' ').toLowerCase();

      return searchableText.contains(keyword);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
