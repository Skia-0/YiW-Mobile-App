import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yiw_field_report/services/auth_service.dart';
import 'package:yiw_field_report/services/offline_service.dart';
import 'package:yiw_field_report/theme/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _offlineMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    final darkMode = await offlineService.getSetting('darkMode');
    final notifications = await offlineService.getSetting('notifications');
    final offline = await offlineService.getSetting('offlineMode');
    setState(() {
      _darkMode = darkMode ?? false;
      _notificationsEnabled = notifications ?? true;
      _offlineMode = offline ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    await offlineService.saveSetting(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.appUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(user?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.email ?? ''),
                      Text('Zone: ${user?.zone ?? 'Not specified'}'),
                      Text('Role: ${user?.role ?? 'Field Officer'}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // App Settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('App Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() { _darkMode = value; });
                    _saveSetting('darkMode', value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dark mode ${value ? "enabled" : "disabled"}')),
                    );
                  },
                  secondary: const Icon(Icons.dark_mode_outlined),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Receive push notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() { _notificationsEnabled = value; });
                    _saveSetting('notifications', value);
                  },
                  secondary: const Icon(Icons.notifications_outlined),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Offline Mode'),
                  subtitle: const Text('Save reports locally when offline'),
                  value: _offlineMode,
                  onChanged: (value) {
                    setState(() { _offlineMode = value; });
                    _saveSetting('offlineMode', value);
                  },
                  secondary: const Icon(Icons.offline_bolt_outlined),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Data Management
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Sync Data'),
                  subtitle: const Text('Upload offline reports to server'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Syncing data...'), backgroundColor: AppColors.info),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export Data'),
                  subtitle: const Text('Download reports as Excel/PDF'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Export Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.table_chart, color: AppColors.success),
                              title: const Text('Export as Excel'),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Exporting as Excel...'), backgroundColor: AppColors.success),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
                              title: const Text('Export as PDF'),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Exporting as PDF...'), backgroundColor: AppColors.success),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Clear Cache', style: TextStyle(color: AppColors.error)),
                  subtitle: const Text('Remove temporary files'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Cache'),
                        content: const Text('This will remove temporary files. Are you sure?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cache cleared'), backgroundColor: AppColors.success),
                              );
                            },
                            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // About
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                const ListTile(leading: Icon(Icons.info_outline), title: Text('App Version'), subtitle: Text('1.0.0')),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showInfoDialog('Terms of Service', 'Terms of service content...'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showInfoDialog('Privacy Policy', 'Privacy policy content...'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.contact_support_outlined),
                  title: const Text('Contact Support'),
                  subtitle: const Text('yiw@seghana.net'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showInfoDialog('Contact Support', 'Email: yiw@seghana.net\nPhone: +233 XXX XXX XXX\nHours: Mon-Fri 9am-5pm GMT'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Logout
        ElevatedButton(
          onPressed: () => _logout(context),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('Logout'),
        ),

        const SizedBox(height: 24),

        const Center(child: Text('SEG Ghana — Youth in Work Programme', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        const SizedBox(height: 8),
        const Center(child: Text('© 2026 SEG Ghana. All rights reserved.', style: TextStyle(color: AppColors.textHint, fontSize: 10))),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
