import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/payment/payment_service.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final String itemType; // 'course' or 'membership'
  final String itemId;
  final double amount;
  final String itemTitle;

  const PaymentCheckoutScreen({
    Key? key,
    required this.itemType,
    required this.itemId,
    required this.amount,
    required this.itemTitle,
  }) : super(key: key);

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final paymentService = GetIt.I<PaymentService>();
  String selectedMethod = 'card'; // 'card' or 'bank_transfer'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.itemTitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '₦${widget.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '₦${widget.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment Method Selection
          Text(
            'Select Payment Method',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Card Payment Option
          _PaymentMethodCard(
            title: 'Debit/Credit Card',
            subtitle: 'Mastercard, Visa, Verve',
            icon: Icons.credit_card,
            isSelected: selectedMethod == 'card',
            onTap: () {
              setState(() => selectedMethod = 'card');
            },
          ),

          const SizedBox(height: 12),

          // Bank Transfer Option
          _PaymentMethodCard(
            title: 'Bank Transfer',
            subtitle: 'Transfer from any bank account',
            icon: Icons.account_balance,
            isSelected: selectedMethod == 'bank_transfer',
            onTap: () {
              setState(() => selectedMethod = 'bank_transfer');
            },
          ),

          const SizedBox(height: 24),

          // Proceed Button
          ElevatedButton(
            onPressed: () {
              if (selectedMethod == 'card') {
                _proceedCardPayment();
              } else {
                _proceedBankTransfer();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Proceed to Payment',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedCardPayment() async {
    showDialog(
      context: context,
      builder: (context) => const _CardPaymentDialog(),
    );

    final response = await paymentService.initializeCardPayment(
      itemType: widget.itemType,
      itemId: widget.itemId,
      amount: widget.amount,
      description: widget.itemTitle,
    );

    if (!mounted) return;

    if (response != null) {
      Navigator.of(context).pop();

      // Show payment processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _CardPaymentProgressDialog(
          response: response,
          itemType: widget.itemType,
          itemId: widget.itemId,
        ),
      );

      // Launch Paystack payment URL
      if (await canLaunch(response.paymentUrl)) {
        await launch(response.paymentUrl);
      }
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize payment')),
      );
    }
  }

  void _proceedBankTransfer() async {
    showDialog(context: context, builder: (context) => const _LoadingDialog());

    final response = await paymentService.initializeBankTransfer(
      itemType: widget.itemType,
      itemId: widget.itemId,
      amount: widget.amount,
      description: widget.itemTitle,
    );

    if (!mounted) return;

    Navigator.of(context).pop();

    if (response != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _BankTransferDetailsScreen(response: response),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize bank transfer')),
      );
    }
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        color: isSelected ? Colors.deepPurple.withOpacity(0.1) : null,
        border: isSelected
            ? Border.all(color: Colors.deepPurple, width: 2)
            : Border.all(color: Colors.grey[300]!),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Colors.deepPurple, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardPaymentDialog extends StatelessWidget {
  const _CardPaymentDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Processing'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing card payment...'),
        ],
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Processing'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Preparing bank transfer details...'),
        ],
      ),
    );
  }
}

class _CardPaymentProgressDialog extends StatefulWidget {
  final CardPaymentResponse response;
  final String itemType;
  final String itemId;

  const _CardPaymentProgressDialog({
    required this.response,
    required this.itemType,
    required this.itemId,
  });

  @override
  State<_CardPaymentProgressDialog> createState() =>
      _CardPaymentProgressDialogState();
}

class _CardPaymentProgressDialogState
    extends State<_CardPaymentProgressDialog> {
  final paymentService = GetIt.I<PaymentService>();

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() async {
    // Poll every 2 seconds for 5 minutes
    for (int i = 0; i < 150; i++) {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final result = await paymentService.verifyCardPayment(
        reference: widget.response.reference,
      );

      if (result != null && result['status'] == 'completed') {
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessDialog();
        }
        return;
      }
    }

    // Timeout after 5 minutes
    if (mounted) {
      Navigator.of(context).pop();
      _showTimeoutDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Payment Successful'),
        content: const Text(
          'Your payment has been confirmed. You now have access to the content!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Pending'),
        content: const Text(
          'Your payment is being processed. Please check your email for confirmation. You will receive access shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment Processing'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Waiting for payment confirmation...'),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Reference: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: widget.response.reference),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _BankTransferDetailsScreen extends StatelessWidget {
  final BankTransferResponse response;

  const _BankTransferDetailsScreen({required this.response});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Transfer Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Instructions
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transfer Instructions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...response.instructions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bank Details
          Text(
            'Bank Account Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          _DetailField(
            label: 'Account Name',
            value: response.bankDetails.accountName,
          ),
          _DetailField(
            label: 'Account Number',
            value: response.bankDetails.accountNumber,
          ),
          _DetailField(
            label: 'Bank Name',
            value: response.bankDetails.bankName,
          ),
          _DetailField(
            label: 'Bank Code',
            value: response.bankDetails.bankCode,
          ),
          _DetailField(
            label: 'Amount',
            value: '₦${response.bankDetails.amount.toStringAsFixed(2)}',
            highlighted: true,
          ),
          _DetailField(
            label: 'Reference',
            value: response.bankDetails.transferReference,
          ),

          const SizedBox(height: 24),

          // Expiry Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Expires',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(response.expiresAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check),
            label: const Text('I have made the transfer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (difference.inHours > 0) {
      return '${difference.inHours} hours from now';
    } else {
      return '${difference.inMinutes} minutes from now';
    }
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _DetailField({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: highlighted ? Colors.deepPurple.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
                    fontSize: highlighted ? 16 : 14,
                    color: highlighted ? Colors.deepPurple : null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    // Copy to clipboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  child: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
