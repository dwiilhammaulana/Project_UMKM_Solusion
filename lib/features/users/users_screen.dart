import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  late Future<List<_TeamUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: const StatusChip(
            label: 'Kelola akun',
            color: Colors.white,
            icon: Icons.manage_accounts_rounded,
          ),
          title: 'Atur akun kasir toko dari satu tempat.',
          subtitle:
              'Admin owner bisa melihat daftar user toko dan membuat akun kasir karyawan.',
          bottom: FilledButton.icon(
            onPressed: _showCreateCashierSheet,
            icon: const AppIcon(Icons.person_add_alt_1_rounded),
            label: const Text('Tambah kasir'),
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<_TeamUser>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AppSectionCard(
                child: LoadingState(label: 'Memuat daftar user...'),
              );
            }
            if (snapshot.hasError) {
              return AppSectionCard(
                child: ErrorState(
                  title: 'Daftar user gagal dimuat',
                  subtitle: _messageFromError(snapshot.error),
                  onRetry: _reloadUsers,
                ),
              );
            }
            final users = snapshot.data ?? const <_TeamUser>[];
            return AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'User toko',
                    subtitle: '${users.length} akun terdaftar di toko ini.',
                  ),
                  const SizedBox(height: 16),
                  if (users.isEmpty)
                    const EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'Belum ada user',
                      subtitle: 'Akun toko akan tampil di sini.',
                    )
                  else
                    for (final user in users) ...[
                      _UserTile(user: user),
                      if (user != users.last) const SizedBox(height: 10),
                    ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<List<_TeamUser>> _fetchUsers() async {
    final rows = await Supabase.instance.client
        .from('profiles')
        .select('id, email, full_name, role, created_at')
        .order('full_name');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_TeamUser.fromJson)
        .toList();
  }

  void _reloadUsers() {
    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  Future<void> _showCreateCashierSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateCashierSheet(),
    );
    if (created == true && mounted) {
      _reloadUsers();
    }
  }

  static String _messageFromError(Object? error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final _TeamUser user;

  @override
  Widget build(BuildContext context) {
    final roleColor =
        user.role == 'admin' ? AppTheme.deepTeal : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: roleColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withValues(alpha: 0.12),
            foregroundColor: roleColor,
            child: AppIcon(
              user.role == 'admin'
                  ? Icons.admin_panel_settings_rounded
                  : Icons.point_of_sale_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(
            label: user.role == 'admin' ? 'Admin' : 'Kasir',
            color: roleColor,
          ),
        ],
      ),
    );
  }
}

class _CreateCashierSheet extends ConsumerStatefulWidget {
  const _CreateCashierSheet();

  @override
  ConsumerState<_CreateCashierSheet> createState() =>
      _CreateCashierSheetState();
}

class _CreateCashierSheetState extends ConsumerState<_CreateCashierSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Akun Kasir',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Kasir akan masuk ke data toko yang sama dengan admin owner.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama kasir'),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Nama kasir wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email kasir'),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Email wajib diisi';
                  if (!text.contains('@')) return 'Format email belum valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Password sementara'),
                validator: (value) {
                  if ((value ?? '').length < 8) {
                    return 'Password minimal 8 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _createCashier,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const AppIcon(Icons.person_add_alt_1_rounded),
                  label:
                      Text(_isSaving ? 'Membuat akun...' : 'Buat akun kasir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createCashier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.functions.invoke(
        'admin-create-cashier',
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'full_name': _nameController.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun kasir berhasil dibuat.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_UsersScreenState._messageFromError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _TeamUser {
  const _TeamUser({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
  });

  final String id;
  final String email;
  final String role;
  final String? fullName;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }

  factory _TeamUser.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] as String?;
    return _TeamUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '-',
      fullName: json['full_name'] as String?,
      role: rawRole == 'admin' ? 'admin' : 'kasir',
    );
  }
}
