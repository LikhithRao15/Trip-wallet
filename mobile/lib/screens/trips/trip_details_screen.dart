import 'package:flutter/material.dart';

import '../../models/trip.dart';
import 'members_screen.dart';
import '../wallet/wallet_screen.dart';
import 'statistics_screen.dart';
import 'member_financial_screen.dart';
import 'close_trip_screen.dart';
import '../expenses/pay_expense_screen.dart';
import '../expenses/expense_history_screen.dart';
import '../settlement/settlement_screen.dart';

class TripDetailsScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final isClosed = trip.status == 'CLOSED';
    return Scaffold(
      appBar: AppBar(title: Text(trip.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTripHeader(),
          const SizedBox(height: 20),

          _buildSection(
            context,
            icon: Icons.people_outline,
            title: 'Members',
            subtitle: isClosed ? 'View trip members' : 'Manage trip members',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MembersScreen(trip: trip),
                ),
              );
            },
          ),

          _buildSection(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: 'View common trip wallet',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletScreen(trip: trip),
                ),
              );
            },
          ),

          if (!isClosed)
            _buildSection(
              context,
              icon: Icons.payments_outlined,
              title: 'Contributions',
              subtitle: 'Record and view member contributions',
              onTap: () {
                // Contributions screen
              },
            ),

          _buildSection(
            context,
            icon: Icons.account_balance_outlined,
            title: 'Member Finances',
            subtitle: 'View contributions and spending by member',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemberFinancialScreen(trip: trip),
                ),
              );
            },
          ),

          _buildSection(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Pay / Expenses',
            subtitle: isClosed
                ? 'View trip expenses'
                : 'Record expenses from the common wallet',
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isClosed)
                          ListTile(
                            leading: const Icon(Icons.payment),
                            title: const Text('Pay New Expense'),
                            subtitle: const Text(
                              'Record an expense from the common wallet',
                            ),
                            onTap: () {
                              Navigator.pop(context);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PayExpenseScreen(trip: trip),
                                ),
                              );
                            },
                          ),

                        ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: const Text('Expense History'),
                          subtitle: const Text('View all trip expenses'),
                          onTap: () {
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExpenseHistoryScreen(trip: trip),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          _buildSection(
            context,
            icon: Icons.bar_chart_outlined,
            title: 'Statistics',
            subtitle: 'View trip spending statistics',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatisticsScreen(trip: trip),
                ),
              );
            },
          ),

          _buildSection(
            context,
            icon: Icons.handshake_outlined,
            title: 'Settlement',
            subtitle: 'Calculate who should receive or pay',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettlementScreen(trip: trip),
                ),
              );
            },
          ),

          if (!isClosed)
  _buildSection(
    context,
    icon: Icons.lock_outline,
    title: 'Close Trip',
    subtitle: 'Finalise the trip and lock financial changes',
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CloseTripScreen(trip: trip),
        ),
      );

      if (result == true && context.mounted) {
        Navigator.pop(context, true);
      }
    },
  ),
        ],
      ),
    );
  }

  Widget _buildTripHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    trip.name.isNotEmpty ? trip.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 22,
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
                        trip.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (trip.destination != null)
                        Text(
                          trip.destination!,
                          style: const TextStyle(fontSize: 15),
                        ),
                    ],
                  ),
                ),
                Chip(label: Text(trip.status)),
              ],
            ),

            if (trip.description != null && trip.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(trip.description!),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.currency_exchange, size: 20),
                const SizedBox(width: 8),
                Text('Currency: ${trip.currency}'),
              ],
            ),

            if (trip.startDate != null || trip.endDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 20),
                  const SizedBox(width: 8),
                  Text('${trip.startDate ?? '—'} → ${trip.endDate ?? '—'}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
