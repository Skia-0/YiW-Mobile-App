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
  bool _autoSync = true;

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
    final autoSync = await offlineService.getSetting('autoSync');
    
    setState(() {
      _darkMode = darkMode ?? false;
      _notificationsEnabled = notifications ?? true;
      _offlineMode = offline ?? true;
      _autoSync = autoSync ?? true;
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 30,
                      child: Text(
                        user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(
                      user?.fullName ?? 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.email ?? ''),
                        Text('Zone: ${user?.zone ?? 'Not specified'}'),
                      ],
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      // Navigate to profile edit
                    },
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
                  const Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Switch between light and dark theme'),
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() {
                        _darkMode = value;
                      });
                      _saveSetting('darkMode', value);
                    },
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Receive push notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
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
                      setState(() {
                        _offlineMode = value;
                      });
                      _saveSetting('offlineMode', value);
                    },
                    secondary: const Icon(Icons.offline_bolt_outlined),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Auto Sync'),
                    subtitle: const Text('Automatically sync when online'),
                    value: _autoSync,
                    onChanged: (value) {
                      setState(() {
                        _autoSync = value;
                      });
                      _saveSetting('autoSync', value);
                    },
                    secondary: const Icon(Icons.sync_outlined),
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
                  const Text(
                    'Data Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined),
                    title: const Text('Sync Data Now'),
                    subtitle: const Text('Upload offline reports to server'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _syncData();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Export Data'),
                    subtitle: const Text('Download reports as Excel/PDF'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _exportData();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: const Text('Backup Data'),
                    subtitle: const Text('Create a backup of your data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _backupData();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.restore_outlined),
                    title: const Text('Restore Data'),
                    subtitle: const Text('Restore from a backup'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _restoreData();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.error),
                    title: const Text('Clear Cache', style: TextStyle(color: AppColors.error)),
                    subtitle: const Text('Remove temporary files'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _clearCache();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // About Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('App Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showTerms();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showPrivacyPolicy();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.contact_support_outlined),
                    title: const Text('Contact Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _contactSupport();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: const Text('Rate App'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _rateApp();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          ElevatedButton(
            onPressed: () {
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Logout'),
          ),
          
          const SizedBox(height: 16),
          
          // Footer
          const Center(
            child: Text(
              'SEG Ghana — Youth in Work Programme',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Center(
            child: Text(
              '© 2026 SEG Ghana. All rights reserved.',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _syncData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Syncing data...'),
          ],
        ),
      ),
    );
    
    // Simulate sync
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data synced successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _exportData() async {
    // Show export options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.success),
              title: const Text('Export as Excel'),
              subtitle: const Text('Download all reports as Excel file'),
              onTap: () {
                Navigator.pop(context);
                // Export as Excel
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
              title: const Text('Export as PDF'),
              subtitle: const Text('Download all reports as PDF'),
              onTap: () {
                Navigator.pop(context);
                // Export as PDF
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: AppColors.info),
              title: const Text('Export as JSON'),
              subtitle: const Text('Download raw data as JSON'),
              onTap: () {
                Navigator.pop(context);
                // Export as JSON
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backupData() async {
    // Implement backup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup created successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _restoreData() async {
    // Implement restore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data restored successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove temporary files. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Clear cache
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showTerms() {
    // Show terms of service
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service content goes here...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    // Show privacy policy
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy content goes here...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    // Contact support
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@seghana.net'),
            SizedBox(height: 8),
            Text('Phone: +233 XXX XXX XXX'),
            SizedBox(height: 8),
            Text('Hours: Mon-Fri 9am-5pm GMT'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    // Rate app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your feedback!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      if (!mounted) return;
      
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}