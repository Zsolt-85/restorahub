import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../repositories/business_repository.dart';
import '../repositories/firestore_user_repository.dart';
import '../repositories/user_repository.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

class TeamManagementPage extends StatefulWidget {
  const TeamManagementPage({super.key});

  @override
  State<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  bool _busy = true;
  String? _error;
  List<User> _staff = [];
  final UserRepository _userRepo = FirestoreUserRepository.instance;

  @override
  void initState() {
    super.initState();
    _ensureBusinessLoaded();
  }

  Future<void> _ensureBusinessLoaded() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    if (businessProvider.currentBusiness != null) {
      _loadStaff();
      return;
    }

    final userBusinessId = user.businessId;
    if (userBusinessId == null || userBusinessId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _staff = [];
      });
      return;
    }

    try {
      final repository = Provider.of<BusinessRepository>(context, listen: false);
      final business = await repository.getBusinessById(userBusinessId);
      if (business != null && mounted) {
        businessProvider.setBusiness(business);
      }
    } catch (e, stack) {
      AppLogger.error('TeamManagementPage._ensureBusinessLoaded error: $e\n$stack');
    }

    if (!mounted) return;
    _loadStaff();
  }

  bool _isAdmin(String role) {
    return role == 'business_admin' || role == 'super_admin';
  }

  Future<void> _loadStaff() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) return;
    if (!_isAdmin(user.role)) {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
      return;
    }

    final businessId = businessProvider.currentBusiness?.id;
    if (businessId == null || businessId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _staff = [];
        _busy = false;
      });
      return;
    }

    try {
      final staff = await _userRepo.getProfessionals(businessId: businessId);
      if (!mounted) return;
      setState(() {
        _staff = staff;
        _busy = false;
      });
    } catch (e, stack) {
      AppLogger.error('TeamManagementPage._loadStaff error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _openAddStaffDialog() async {
    final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
    final businessId = businessProvider.currentBusiness?.id;
    if (businessId == null || businessId.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'No business selected');
      return;
    }

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final specialtyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty / Service',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final phone = phoneController.text.trim();
              final specialty = specialtyController.text.trim();

              if (name.isEmpty || email.isEmpty) {
                ErrorHandler.showErrorSnackBar(dialogContext, 'Name and email are required');
                return;
              }

              Navigator.pop(dialogContext);

              try {
                await _userRepo.insertUser(User(
                  name: name,
                  email: email,
                  phone: phone,
                  role: 'professional',
                  businessId: businessId,
                  category: specialty,
                ));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Staff member added'),
                  ),
                );
                _loadStaff();
              } catch (e) {
                if (!mounted) return;
                ErrorHandler.showErrorSnackBar(context, e.toString());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    if (!_isAdmin(user.role)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Team Management'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to access team management.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddStaffDialog,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Staff'),
      ),
    );
  }

  Widget _buildBody() {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Could not load team',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadStaff,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_staff.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No staff members found',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _staff.length,
      itemBuilder: (context, index) {
        final member = _staff[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                member.name.isNotEmpty
                    ? member.name.substring(0, 1).toUpperCase()
                    : '?',
              ),
            ),
            title: Text(member.name),
            subtitle: Text(
              member.category.isNotEmpty
                  ? '${member.roleLabel} \u2022 ${member.category}'
                  : member.roleLabel,
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
