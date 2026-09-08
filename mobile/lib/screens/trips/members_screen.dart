import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../services/members_service.dart';

class MembersScreen extends StatefulWidget {
  final Trip trip;

  const MembersScreen({
    super.key,
    required this.trip,
  });

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final MemberService _memberService = MemberService();
  final TextEditingController _emailController = TextEditingController();

  List<TripMember> _members = [];

  bool _isLoading = true;
  bool _isAdding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await _memberService.getMembers(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addMember() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Enter the member email');
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      await _memberService.addMember(
        tripId: widget.trip.id,
        email: email,
      );

      _emailController.clear();

      if (!mounted) return;

      _showMessage('Member added successfully');

      await _loadMembers();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  Future<void> _removeMember(TripMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text(
          'Are you sure you want to remove ${member.name} from this trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _memberService.removeMember(
        tripId: widget.trip.id,
        memberId: member.id,
      );

      if (!mounted) return;

      _showMessage('${member.name} removed successfully');
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.trip.status == 'CLOSED';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Members'),
      ),
      body: Column(
  children: [
    if (!isClosed) _buildAddMemberSection(),
    if (isClosed)
      Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This trip is closed. Members can only be viewed.',
              ),
            ),
          ],
        ),
      ),
    Expanded(
      child: _buildMembersList(),
    ),
  ],
),
    );
  }

  Widget _buildAddMemberSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Member',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Member Email',
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isAdding ? null : _addMember,
                icon: _isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.person_add),
                label: Text(
                  _isAdding ? 'Adding...' : 'Add Member',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    final isClosed = widget.trip.status == 'CLOSED';

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadMembers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return const Center(
        child: Text('No members found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];

          final isAdmin = member.role == 'ADMIN';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  member.name.isNotEmpty
                      ? member.name[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(
                member.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(
                      isAdmin ? 'ADMIN' : 'MEMBER',
                    ),
                  ),
                  if (!isClosed && !isAdmin)
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      tooltip: 'Remove Member',
                      onPressed: () => _removeMember(member),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}