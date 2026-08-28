import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../models/business.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/super_admin_provider.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  bool _businessesBusy = true;
  bool _usersBusy = true;
  String? _businessesError;
  String? _usersError;
  String? _usersSearchQuery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBusinesses();
      _loadUsers();
    });
  }

  Future<void> _loadBusinesses() async {
    final provider = Provider.of<SuperAdminProvider>(context, listen: false);
    try {
      await provider.loadAllBusinesses();
      if (!mounted) return;
      setState(() => _businessesBusy = false);
    } catch (e, stack) {
      AppLogger.error('SuperAdminDashboardPage._loadBusinesses error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _businessesBusy = false;
        _businessesError = e.toString();
      });
    }
  }

  Future<void> _loadUsers() async {
    final provider = Provider.of<SuperAdminProvider>(context, listen: false);
    try {
      await provider.loadAllUsers(searchQuery: _usersSearchQuery);
      if (!mounted) return;
      setState(() => _usersBusy = false);
    } catch (e, stack) {
      AppLogger.error('SuperAdminDashboardPage._loadUsers error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _usersBusy = false;
        _usersError = e.toString();
      });
    }
  }

  Future<void> _openAddBusinessDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final ownerEmailController = TextEditingController();
    BusinessType selectedBusinessType = BusinessType.wellness;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Business'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Business Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Owner Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BusinessType>(
                  initialValue: selectedBusinessType,
                  decoration: const InputDecoration(
                    labelText: 'Business Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: BusinessType.wellness,
                      child: Text('Wellness'),
                    ),
                    DropdownMenuItem(
                      value: BusinessType.custom,
                      child: Text('Custom'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedBusinessType = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ErrorHandler.showErrorSnackBar(dialogContext, 'Business name is required');
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      final provider = Provider.of<SuperAdminProvider>(context, listen: false);
                      final pageMessenger = ScaffoldMessenger.of(context);
                      final dialogMessenger = ScaffoldMessenger.of(dialogContext);
                      final dialogNavigator = Navigator.of(dialogContext);
                      final error = await provider.createBusiness(
                        name: name,
                        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                        businessType: selectedBusinessType,
                        ownerEmail: ownerEmailController.text.trim().isEmpty ? null : ownerEmailController.text.trim(),
                      );

                      if (!mounted) return;

                      if (error == null) {
                        dialogNavigator.pop();
                        pageMessenger.showSnackBar(
                          const SnackBar(content: Text('Business created')),
                        );
                      } else {
                        setDialogState(() => isSaving = false);
                        dialogMessenger.showSnackBar(
                          SnackBar(content: Text('Failed to create business: $error')),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditBusinessDialog(Business business) async {
    final nameController = TextEditingController(text: business.name);
    final emailController = TextEditingController(text: business.email ?? '');
    final phoneController = TextEditingController(text: business.phone ?? '');
    final addressController = TextEditingController(text: business.address ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Business'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
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
              if (name.isEmpty) {
                ErrorHandler.showErrorSnackBar(dialogContext, 'Business name is required');
                return;
              }

              Navigator.pop(dialogContext);

              final provider = Provider.of<SuperAdminProvider>(context, listen: false);
              final error = await provider.updateBusiness(
                businessId: business.id,
                name: name,
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
              );

              if (!mounted) return;
              if (error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Business updated')),
                );
              } else {
                ErrorHandler.showErrorSnackBar(context, error);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditUserDialog(User user) async {
    final provider = Provider.of<SuperAdminProvider>(context, listen: false);
    final businesses = provider.businesses;
    String? selectedRole = user.role;
    String? selectedBusinessId = user.businessId;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'professional', child: Text('Professional')),
                  DropdownMenuItem(value: 'business_admin', child: Text('Business Admin')),
                  DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                ],
                onChanged: (value) {
                  if (value != null) selectedRole = value;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedBusinessId,
                decoration: const InputDecoration(
                  labelText: 'Business',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('None')),
                  ...businesses.map((b) => DropdownMenuItem<String>(
                        value: b.id,
                        child: Text(b.name),
                      )),
                ],
                onChanged: (value) {
                  selectedBusinessId = value;
                },
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
              if (selectedRole == null) {
                ErrorHandler.showErrorSnackBar(dialogContext, 'Role is required');
                return;
              }

              Navigator.pop(dialogContext);

              final error = await provider.updateUserRoleAndBusiness(
                userId: user.id ?? '',
                newRole: selectedRole!,
                businessId: selectedBusinessId,
              );

              if (!mounted) return;
              if (error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User updated')),
                );
              } else {
                ErrorHandler.showErrorSnackBar(context, error);
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

    if (user.role != 'super_admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Super Admin Dashboard'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Access denied. Super admin only.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (innerContext) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Super Admin Dashboard'),
              bottom: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(icon: Icon(Icons.business), text: 'Businesses'),
                  Tab(icon: Icon(Icons.people), text: 'Global Users'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildBusinessesTab(theme),
                _buildUsersTab(theme),
              ],
            ),
            floatingActionButton: DefaultTabController.of(innerContext).index == 0
                ? FloatingActionButton.extended(
                    onPressed: _openAddBusinessDialog,
                    icon: const Icon(Icons.add_outlined),
                    label: const Text('Add Business'),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildBusinessesTab(ThemeData theme) {
    final provider = Provider.of<SuperAdminProvider>(context);

    if (_businessesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('Could not load businesses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_businessesError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadBusinesses,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final businesses = provider.businesses;

    if (_businessesBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (businesses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No businesses found', textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: businesses.length,
      itemBuilder: (context, index) {
        final business = businesses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (business.email != null) ...[
                        const SizedBox(height: 4),
                        Text(business.email!, style: theme.textTheme.bodyMedium),
                      ],
                      if (business.phone != null) ...[
                        const SizedBox(height: 4),
                        Text(business.phone!, style: theme.textTheme.bodyMedium),
                      ],
                      if (business.address != null) ...[
                        const SizedBox(height: 4),
                        Text(business.address!, style: theme.textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openEditBusinessDialog(business),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTab(ThemeData theme) {
    final provider = Provider.of<SuperAdminProvider>(context);
    final businesses = provider.businesses;
    final businessMap = <String, Business>{for (final b in businesses) b.id: b};

    if (_usersError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('Could not load users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_usersError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final users = provider.users;

    if (_usersBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No users found', textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      children: [
        const ExpansionTile(
          leading: Icon(Icons.info_outline),
          title: Text('Role Capabilities Guide'),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: Can browse businesses, view available slots, book appointments, and view personal booking history.'),
                  SizedBox(height: 4),
                  Text('Professional / Staff: Can view personal appointment schedule, set work hours/specialties, and manage assigned client appointments.'),
                  SizedBox(height: 4),
                  Text('Business Admin: Full control over a single business tenant (manages business profile, branding, services catalog, team members, and full business calendar).'),
                  SizedBox(height: 4),
                  Text('Super Admin: Platform owner with full global control (can create/edit all business tenants, search all users, assign user roles, and reassign business tenants).'),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search users',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search_outlined),
            ),
            onChanged: (value) {
              final query = value.trim().isEmpty ? null : value.trim();
              if (query != _usersSearchQuery) {
                setState(() => _usersSearchQuery = query);
                _loadUsers();
              }
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final assignedBusiness = user.businessId != null ? businessMap[user.businessId] : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(user.email, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Chip(label: Text(_roleLabel(user.role))),
                            if (assignedBusiness != null && assignedBusiness.name.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Business: ${assignedBusiness.name}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openEditUserDialog(user),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'business_admin':
        return 'Business Admin';
      case 'professional':
        return 'Professional';
      case 'customer':
      default:
        return 'Customer';
    }
  }
}