import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../services/auth_service.dart';
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
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();

  List<TripMember> _members = [];
  bool _isAdmin = false;
  bool _isLoading = true;
  bool _isAdding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = await _authService.getMe().catchError((_) => null);
      if (mounted && user != null) {
        setState(() {
          _isAdmin = user['id'] == widget.trip.adminId;
        });
      }
    } catch (_) {}

    await _loadMembers();
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
        _error = e.toString().replaceFirst('Exception: ', '');
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

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
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
        title: const Text('Deactivate Member?'),
        content: Text(
          'Are you sure you want to deactivate ${member.name}? '
          'They will not be included in future expenses, but their past records are preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
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

      _showMessage('${member.name} deactivated successfully');
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

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.trip.status == 'CLOSED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Members'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadMembers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
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
            )
          else if (_isAdmin)
            _buildAddMemberSection(),
          Expanded(
            child: _buildMembersList(isClosed),
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
              'Add Trip Member',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'User Email',
                hintText: 'user@example.com',
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add),
                label: Text(_isAdding ? 'Adding...' : 'Add Member'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(bool isClosed) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMembers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return const Center(child: Text('No members found'));
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final isMemberAdmin = member.role == 'ADMIN';
          final isActive = member.status == 'ACTIVE';
          final joinedDate = _formatDate(member.joinedAt);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isMemberAdmin
                    ? Colors.amber.shade100
                    : Colors.blue.shade100,
                child: Text(
                  member.name.isNotEmpty
                      ? member.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMemberAdmin
                        ? Colors.amber.shade900
                        : Colors.blue.shade900,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      member.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration:
                            !isActive ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isMemberAdmin
                          ? Colors.amber.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      member.role,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isMemberAdmin
                            ? Colors.amber.shade900
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      member.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    if (joinedDate.isNotEmpty)
                      Text(
                        'Joined: $joinedDate',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
              trailing: (_isAdmin && !isClosed && !isMemberAdmin && isActive)
                  ? IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      tooltip: 'Deactivate Member',
                      onPressed: () => _removeMember(member),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}