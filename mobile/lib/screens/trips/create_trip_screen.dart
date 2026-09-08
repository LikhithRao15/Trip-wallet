import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  DateTime? _startDate;
  DateTime? _endDate;

  String _currency = 'INR';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _startDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _startDate = date;

        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      _showError('End date cannot be before start date');
      return;
    }

    final token = await _tokenStorage.getToken();

    if (token == null) {
      _showError('Please login again');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiClient.post(ApiConstants.trips, {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'destination': _destinationController.text.trim().isEmpty
            ? null
            : _destinationController.text.trim(),
        'start_date': _startDate?.toIso8601String().split('T').first,
        'end_date': _endDate?.toIso8601String().split('T').first,
        'currency': _currency,
      }, token: token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip created successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trip')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Trip Name',
                hintText: 'Example: Kerala Trip',
                prefixIcon: Icon(Icons.luggage),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Trip name is required';
                }

                if (value.trim().length > 150) {
                  return 'Trip name is too long';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'Example: Kerala',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Add some details about the trip',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Trip Dates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectStartDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text('Start\n${_formatDate(_startDate)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectEndDate,
                    icon: const Icon(Icons.event),
                    label: Text('End\n${_formatDate(_endDate)}'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'INR',
                  child: Text('INR - Indian Rupee'),
                ),
                DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                DropdownMenuItem(
                  value: 'GBP',
                  child: Text('GBP - British Pound'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currency = value;
                  });
                }
              },
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createTrip,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isLoading ? 'Creating...' : 'Create Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
