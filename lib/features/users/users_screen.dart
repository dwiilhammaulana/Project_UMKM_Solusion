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
                      _UserTile(
                        user: user,
                        onEdit: user.role == 'kasir'
                            ? () => _showEditCashierSheet(user)
                            : null,
                        onDelete: user.role == 'kasir'
                            ? () => _confirmDeleteCashier(user)
                            : null,
                      ),
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
        .select('id, email, full_name, role, nik, phone, created_at')
        .order('full_name');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_TeamUser.fromJson)
        .toList();
  }

  Future<_TeamUser> _fetchUser(String userId) async {
    final client = Supabase.instance.client;
    try {
      final result = await client.rpc(
        'admin_get_cashier_info',
        params: {'cashier_user_id': userId},
      );
      if (result is List<dynamic> && result.isNotEmpty) {
        return _TeamUser.fromJson(result.first as Map<String, dynamic>);
      }
      if (result is Map<String, dynamic>) {
        return _TeamUser.fromJson(result);
      }
    } catch (error) {
      if (!_isMissingGetCashierInfoRpc(error)) rethrow;
    }

    final row = await client
        .from('profiles')
        .select('id, email, full_name, role, nik, phone, created_at')
        .eq('id', userId)
        .single();
    return _TeamUser.fromJson(row);
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

  Future<void> _showEditCashierSheet(_TeamUser user) async {
    _TeamUser selectedUser = user;
    try {
      selectedUser = await _fetchUser(user.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(error))),
      );
      return;
    }
    if (!mounted) return;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditCashierSheet(user: selectedUser),
    );
    if (updated == true && mounted) {
      _reloadUsers();
    }
  }

  Future<void> _confirmDeleteCashier(_TeamUser user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus akun kasir?'),
        content: Text(
          'Akun ${user.displayName} akan dihapus dan tidak bisa login lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await _deleteCashierAccount(user.id);
      if (!mounted) return;
      _reloadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun kasir berhasil dihapus.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(error))),
      );
    }
  }

  Future<void> _deleteCashierAccount(String userId) async {
    final client = Supabase.instance.client;
    try {
      await client.functions.invoke(
        'admin-delete-cashier',
        body: {'user_id': userId},
      );
      return;
    } catch (error) {
      if (!_isMissingEdgeFunction(error)) rethrow;
    }

    try {
      await client.rpc(
        'admin_delete_cashier',
        params: {'cashier_user_id': userId},
      );
    } catch (error) {
      if (_isMissingRpcFunction(error)) {
        throw Exception(
          'Fungsi hapus akun kasir belum tersedia. Terapkan migration '
          '20260611_000009_admin_delete_cashier_rpc.sql atau deploy Edge '
          'Function admin-delete-cashier.',
        );
      }
      rethrow;
    }
  }

  static bool _isMissingEdgeFunction(Object error) {
    final message = error.toString();
    return message.contains('status: 404') &&
        (message.contains('NOT_FOUND') ||
            message.contains('Requested function was not found'));
  }

  static bool _isMissingRpcFunction(Object error) {
    final message = error.toString();
    return message.contains('admin_delete_cashier') &&
        (message.contains('PGRST202') ||
            message.contains('Could not find the function') ||
            message.contains('not found'));
  }

  static bool _isMissingGetCashierInfoRpc(Object error) {
    final message = error.toString();
    return message.contains('admin_get_cashier_info') &&
        (message.contains('PGRST202') ||
            message.contains('Could not find the function') ||
            message.contains('not found'));
  }

  static String _messageFromError(Object? error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    this.onEdit,
    this.onDelete,
  });

  final _TeamUser user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
                if (user.role == 'kasir' ||
                    user.nikText != null ||
                    user.phoneText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'NIK ${user.nikText ?? '-'} - No HP ${user.phoneText ?? '-'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.subtext,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(
                label: user.role == 'admin' ? 'Admin' : 'Kasir',
                color: roleColor,
              ),
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        key: Key('users-edit-cashier-${user.id}'),
                        tooltip: 'Edit informasi kasir',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppTheme.deepTeal.withValues(alpha: 0.08),
                          foregroundColor: AppTheme.deepTeal,
                          fixedSize: const Size(36, 36),
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.deepTeal.withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                        onPressed: onEdit,
                        icon: const AppIcon(Icons.edit_outlined, size: 18),
                      ),
                    if (onEdit != null && onDelete != null)
                      const SizedBox(width: 6),
                    if (onDelete != null)
                      IconButton(
                        key: Key('users-delete-cashier-${user.id}'),
                        tooltip: 'Hapus akun kasir',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppTheme.danger.withValues(alpha: 0.08),
                          foregroundColor: AppTheme.danger,
                          fixedSize: const Size(36, 36),
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.danger.withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                        onPressed: onDelete,
                        icon: const AppIcon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EditCashierSheet extends ConsumerStatefulWidget {
  const _EditCashierSheet({required this.user});

  final _TeamUser user;

  @override
  ConsumerState<_EditCashierSheet> createState() => _EditCashierSheetState();
}

class _EditCashierSheetState extends ConsumerState<_EditCashierSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nikController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName ?? '');
    _nikController = TextEditingController(text: widget.user.nik ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxFormHeight = MediaQuery.sizeOf(context).height * 0.72;
    return BottomSheetContainer(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxFormHeight),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Informasi Kasir',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Perbarui data kasir yang tersimpan untuk akun ini.',
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
                  controller: _nikController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'NIK'),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'NIK wajib diisi';
                    if (text.length != 16) return 'NIK harus 16 digit';
                    if (!RegExp(r'^\d+$').hasMatch(text)) {
                      return 'NIK hanya boleh berisi angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'No HP'),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'No HP wajib diisi';
                    if (text.length < 8) return 'No HP belum valid';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _updateCashier,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const AppIcon(Icons.save_outlined),
                    label:
                        Text(_isSaving ? 'Menyimpan...' : 'Simpan perubahan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateCashier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.rpc(
        'admin_update_cashier_info',
        params: {
          'cashier_user_id': widget.user.id,
          'cashier_email': _emailController.text.trim(),
          'cashier_full_name': _nameController.text.trim(),
          'cashier_nik': _nikController.text.trim(),
          'cashier_phone': _phoneController.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informasi kasir berhasil diperbarui.')),
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

class _CreateCashierSheet extends ConsumerStatefulWidget {
  const _CreateCashierSheet();

  @override
  ConsumerState<_CreateCashierSheet> createState() =>
      _CreateCashierSheetState();
}

class _CreateCashierSheetState extends ConsumerState<_CreateCashierSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
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
                controller: _nikController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'NIK'),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'NIK wajib diisi';
                  if (text.length != 16) return 'NIK harus 16 digit';
                  if (!RegExp(r'^\d+$').hasMatch(text)) {
                    return 'NIK hanya boleh berisi angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No HP'),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'No HP wajib diisi';
                  if (text.length < 8) return 'No HP belum valid';
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
          'nik': _nikController.text.trim(),
          'phone': _phoneController.text.trim(),
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
    this.nik,
    this.phone,
  });

  final String id;
  final String email;
  final String role;
  final String? fullName;
  final String? nik;
  final String? phone;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }

  String? get nikText {
    final value = nik?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get phoneText {
    final value = phone?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  factory _TeamUser.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] as String?;
    return _TeamUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '-',
      fullName: json['full_name'] as String?,
      nik: json['nik'] as String?,
      phone: json['phone'] as String?,
      role: rawRole == 'admin' ? 'admin' : 'kasir',
    );
  }
}
