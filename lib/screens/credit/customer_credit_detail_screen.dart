import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/models/credit_sale.dart';
import 'package:pos_app/models/payment.dart';
import '../../models/customer.dart';
import '../../services/credit_service.dart';
import '../../utils/format_utils.dart';
import 'record_payment_screen.dart';

class CustomerCreditDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerCreditDetailScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  _CustomerCreditDetailScreenState createState() => _CustomerCreditDetailScreenState();
}

class _CustomerCreditDetailScreenState extends State<CustomerCreditDetailScreen>
    with SingleTickerProviderStateMixin {
  final CreditService _creditService = CreditService();
  late TabController _tabController;
  Customer? _customer;
  List<CreditSale> _creditSales = [];
  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomerDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _creditService.getCustomerCreditDetails(widget.customerId);
      setState(() {
        _customer = data['customer'];
        _creditSales = data['creditSales'];
        _payments = data['payments'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_customer?.name ?? 'Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomerDetails,
          ),
        ],
        bottom: _isLoading || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Credit Sales'),
                  Tab(text: 'Payments'),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCustomerDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
      floatingActionButton: !_isLoading && _error == null && _customer != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecordPaymentScreen(customer: _customer!),
                  ),
                );
                if (result == true) {
                  _loadCustomerDetails();
                }
              },
              label: const Text('Record Payment'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_customer == null) {
      return const Center(child: Text('Customer information not available'));
    }

    return Column(
      children: [
        // Customer Summary Card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        radius: 24,
                        child: Text(
                          _customer?.name != null && _customer!.name.isNotEmpty 
                              ? _customer!.name.substring(0, 1).toUpperCase() 
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _customer?.name ?? 'Unknown Customer',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Phone: ${_customer?.phone ?? 'N/A'}'),
                            if (_customer?.email != null && _customer!.email!.isNotEmpty)
                              Text('Email: ${_customer!.email}'),
                            if (_customer?.address != null && _customer!.address!.isNotEmpty)
                              Text('Address: ${_customer!.address}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Outstanding Balance:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'KSh ${formatCurrency(_customer?.balance ?? 0.0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD35400),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCreditSalesTab(),
              _buildPaymentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditSalesTab() {
    if (_creditSales.isEmpty) {
      return const Center(
        child: Text(
          'No credit sales found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _creditSales.length,
      itemBuilder: (context, index) {
        final creditSale = _creditSales[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sale #${creditSale.referenceNo}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: creditSale.paymentStatus == 'paid'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        creditSale.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: creditSale.paymentStatus == 'paid'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat('MMM dd, yyyy').format(creditSale.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const Divider(height: 24),
                
                // Sale Items
                ...creditSale.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.product?['name'] ?? 'Product'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        'KSh ${formatCurrency(item.subtotal)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
                
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'KSh ${formatCurrency(creditSale.finalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return const Center(
        child: Text(
          'No payments recorded yet',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment #${payment.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'KSh ${formatCurrency(payment.amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFD35400),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat('MMM dd, yyyy').format(payment.createdAt)}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Method: ${payment.paymentMethod.replaceAll('_', ' ').toUpperCase()}',
                ),
                if (payment.referenceNumber != null && payment.referenceNumber!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reference: ${payment.referenceNumber}',
                  ),
                ],
                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${payment.notes}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}