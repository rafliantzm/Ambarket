import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final actionState = ref.watch(adminActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moderasi Pengguna')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cari Pengguna...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = users.where((u) => 
                  (u.name?.toLowerCase().contains(_searchQuery) ?? false) || 
                  (u.username?.toLowerCase().contains(_searchQuery) ?? false)
                ).toList();
                
                if (filtered.isEmpty) {
                  return const Center(child: Text('Tidak ada pengguna ditemukan.'));
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(adminUsersProvider.future),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(user.username?[0].toUpperCase() ?? '?')),
                        title: Text(user.name ?? user.username ?? 'Unknown'),
                        subtitle: Text('Role: ${user.role} | Suspended: ${user.isSuspended}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!user.isSuspended && user.role != 'admin')
                              IconButton(
                                icon: const Icon(Icons.block, color: Colors.red),
                                onPressed: actionState.isLoading ? null : () => _showActionDialog('Suspend', () {
                                  ref.read(adminActionControllerProvider.notifier).suspendUser(user.id, 'Suspended by admin');
                                }),
                              ),
                            if (user.isSuspended)
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: actionState.isLoading ? null : () => _showActionDialog('Unsuspend', () {
                                  ref.read(adminActionControllerProvider.notifier).unsuspendUser(user.id);
                                }),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionDialog(String actionName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName Pengguna?'),
        content: const Text('Tindakan ini akan dicatat dalam audit logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Ya'),
          )
        ],
      ),
    );
  }
}
