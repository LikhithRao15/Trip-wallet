import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../services/close_trip_service.dart';
import '../settlement/settlement_screen.dart';

class CloseTripScreen extends StatefulWidget {
  final Trip trip;

  const CloseTripScreen({
    super.key,
    required this.trip,
  });

  @override
  State<CloseTripScreen> createState() => _CloseTripScreenState();
}

class _CloseTripScreenState extends State<CloseTripScreen> {
  final CloseTripService _service = CloseTripService();

  bool _isClosing = false;

  Future<void> _closeTrip() async {
    setState(() {
      _isClosing = true;
    });

    try {
      await _service.closeTrip(widget.trip.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip closed successfully'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClosing = false;
        });
      }
    }
  }

  Future<void> _showConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Close Trip?'),
          content: const Text(
            'Once the trip is closed, new contributions and expenses '
            'cannot be added.\n\n'
            'The financial records will remain available for viewing.\n\n'
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Close Trip'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _closeTrip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Close Trip'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    child: Icon(
                      Icons.lock_outline,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    widget.trip.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Finalise this trip',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Closing the trip will:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildPoint(
                    Icons.block,
                    'Prevent new contributions',
                  ),

                  _buildPoint(
                    Icons.block,
                    'Prevent new expenses',
                  ),

                  _buildPoint(
                    Icons.lock_outline,
                    'Make the wallet read-only',
                  ),

                  _buildPoint(
                    Icons.history,
                    'Keep all financial records',
                  ),

                  _buildPoint(
                    Icons.handshake_outlined,
                    'Allow final settlement review',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _isClosing ? null : _showConfirmation,
            icon: _isClosing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.lock_outline),
            label: Text(
              _isClosing ? 'Closing Trip...' : 'Close Trip',
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettlementScreen(
                    trip: widget.trip,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('View Current Settlement'),
          ),
        ],
      ),
    );
  }

  Widget _buildPoint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}