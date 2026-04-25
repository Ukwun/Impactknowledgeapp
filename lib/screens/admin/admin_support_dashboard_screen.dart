import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../services/support/support_service.dart';

class AdminSupportDashboardScreen extends StatefulWidget {
  const AdminSupportDashboardScreen({super.key});

  @override
  State<AdminSupportDashboardScreen> createState() =>
      _AdminSupportDashboardScreenState();
}

class _AdminSupportDashboardScreenState
    extends State<AdminSupportDashboardScreen> {
  final supportService = GetIt.I<SupportService>();
  String selectedStatus = 'open';
  late Future<Map<String, dynamic>?> ticketsFuture;
  late Future<Map<String, dynamic>?> statsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      ticketsFuture = supportService.getAdminTickets(status: selectedStatus);
      statsFuture = supportService.getStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistics cards
          FutureBuilder<Map<String, dynamic>?>(
            future: statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const Text('Error loading statistics');
              }

              final stats = snapshot.data!['stats'];
              return Column(
                children: [
                  _StatCard(
                    label: 'Total Tickets',
                    value: stats['total_tickets'].toString(),
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Open',
                          value: stats['open_tickets'].toString(),
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'In Progress',
                          value: stats['in_progress_tickets'].toString(),
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Resolved',
                          value: stats['resolved_tickets'].toString(),
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Closed',
                          value: stats['closed_tickets'].toString(),
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Filter buttons
          Row(
            children: [
              Text('Filter:', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['open', 'in-progress', 'resolved', 'all']
                        .map(
                          (status) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(status.toUpperCase()),
                              selected: selectedStatus == status,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedStatus = status;
                                    _loadData();
                                  });
                                }
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tickets list
          FutureBuilder<Map<String, dynamic>?>(
            future: ticketsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const Text('Error loading tickets');
              }

              final tickets = snapshot.data!['tickets'] as List<SupportTicket>;

              if (tickets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tickets',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: tickets.map((ticket) {
                  return _AdminTicketCard(
                    ticket: ticket,
                    onStatusChange: (newStatus) {
                      supportService.updateTicketStatus(
                        ticketId: ticket.id,
                        status: newStatus,
                      );
                      _loadData();
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTicketCard extends StatefulWidget {
  final SupportTicket ticket;
  final Function(String) onStatusChange;

  const _AdminTicketCard({required this.ticket, required this.onStatusChange});

  @override
  State<_AdminTicketCard> createState() => _AdminTicketCardState();
}

class _AdminTicketCardState extends State<_AdminTicketCard> {
  late String _selectedNewStatus;

  @override
  void initState() {
    super.initState();
    _selectedNewStatus = widget.ticket.status;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in-progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${widget.ticket.id} - ${widget.ticket.subject}',
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${widget.ticket.category}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.ticket.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.ticket.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(widget.ticket.status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Created ${_formatDate(widget.ticket.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Update Status',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedNewStatus,
                  isExpanded: true,
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      setState(() => _selectedNewStatus = newStatus);
                      widget.onStatusChange(newStatus);
                    }
                  },
                  items: ['open', 'in-progress', 'resolved', 'closed']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
