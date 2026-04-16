import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/payment_controller.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/common/custom_widgets.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  String _billingCycle = 'monthly';

  @override
  void initState() {
    super.initState();
    final paymentController = Get.find<PaymentController>();
    paymentController.fetchMembershipTiers();
    paymentController.fetchUserMembership();
  }

  @override
  Widget build(BuildContext context) {
    final paymentController = Get.find<PaymentController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Membership'), elevation: 0),
      body: Obx(() {
        if (paymentController.isLoading.value) {
          return const LoadingIndicator();
        }

        return CustomScrollView(
          slivers: [
            // Current Membership
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  if (paymentController.userMembership.value != null) {
                    final membership = paymentController.userMembership.value;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal[400]!, Colors.teal[700]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Membership',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              membership!['tier_name'] ?? 'Premium',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _buildExpiryDateText(membership),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  _showCancelDialog(
                                    context,
                                    membership['id'] ?? '',
                                    paymentController,
                                  );
                                },
                                child: const Text(
                                  'Manage Subscription',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ),
            ),
            // Billing Cycle Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: 'monthly',
                            label: Text('Monthly'),
                          ),
                          ButtonSegment<String>(
                            value: 'annual',
                            label: Text('Annual'),
                          ),
                        ],
                        selected: <String>{_billingCycle},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _billingCycle = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Membership Tiers
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final tier = paymentController.membershipTiers[index];
                  final price = _billingCycle == 'monthly'
                      ? tier['monthly_price'] ?? 0.0
                      : tier['annual_price'] ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tier['name'] ?? 'Tier',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (tier['name'] == 'Free')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            ...[
                              const SizedBox(height: 8),
                              Text(
                                tier['description'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '\$${price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '/${_billingCycle == 'monthly' ? 'month' : 'year'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Features List
                            if ((tier['features'] as List?)?.isNotEmpty ??
                                false) ...[
                              Column(
                                children: ((tier['features'] as List?) ?? [])
                                    .map((feature) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                feature.trim(),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              child: tier['name'] == 'Free'
                                  ? ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[400],
                                      ),
                                      onPressed: null,
                                      child: const Text('Current Plan'),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                      onPressed: () {
                                        _initiateUpgrade(
                                          context,
                                          tier,
                                          price,
                                          paymentController,
                                        );
                                      },
                                      child: const Text('Upgrade Now'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: paymentController.membershipTiers.length),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _initiateUpgrade(
    BuildContext context,
    dynamic tier,
    double price,
    PaymentController controller,
  ) {
    final authController = Get.find<AuthController>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Upgrade to ${tier.name}'),
          content: Text(
            'Upgrade to ${tier.name} for \$${price.toStringAsFixed(2)}/${_billingCycle == 'monthly' ? 'month' : 'year'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                Navigator.pop(context);
                final tierId = tier['id'] ?? '';
                final price = _billingCycle == 'monthly'
                    ? (tier['monthly_price'] ?? 9.99)
                    : (tier['annual_price'] ?? 99.99);

                controller.initiateMembershipPayment(tierId, price.toDouble());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Redirecting to payment...')),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog(
    BuildContext context,
    String membershipId,
    PaymentController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Subscription'),
          content: const Text(
            'Are you sure you want to cancel your subscription? You will lose access to premium features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                controller.cancelMembership();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscription cancelled')),
                );
              },
              child: const Text('Cancel Subscription'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _buildExpiryDateText(Map<String, dynamic> membership) {
    final expiryValue = membership['expiry_date'];
    if (expiryValue == null) {
      return 'Membership active indefinitely';
    }

    try {
      late DateTime expiryDate;
      if (expiryValue is DateTime) {
        expiryDate = expiryValue;
      } else if (expiryValue is String) {
        expiryDate = DateTime.parse(expiryValue);
      } else {
        return 'Membership active indefinitely';
      }

      return 'Valid until ${_formatDate(expiryDate)}';
    } catch (e) {
      return 'Membership details unavailable';
    }
  }
}
