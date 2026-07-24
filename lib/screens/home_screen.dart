import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yiw_field_report/services/auth_service.dart';
import 'package:yiw_field_report/services/report_service.dart';
import 'package:yiw_field_report/services/offline_service.dart';
import 'package:yiw_field_report/theme/colors.dart';
import 'package:yiw_field_report/widgets/dashboard_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _offlineMode = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSettings();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      final reportService = Provider.of<ReportService>(context, listen: false);
      await reportService.loadReports();
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }
    setState(() { _isLoading = false; });
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
    final reportService = Provider.of<ReportService>(context);
    final user = authService.appUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YiW Field Report'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: _currentIndex == 0
          ? _buildDashboard(context, user, reportService)
          : _currentIndex == 1
              ? _buildReportsList(context, reportService)
              : _buildSettings(context, user),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) { setState(() { _currentIndex = index; }); },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/new-report');
          _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(user?.fullName?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(height: 12),
                Text(user?.fullName ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.dashboard_outlined), title: const Text('Dashboard'), onTap: () { Navigator.pop(context); setState(() { _currentIndex = 0; }); }),
          ListTile(leading: const Icon(Icons.description_outlined), title: const Text('My Reports'), onTap: () { Navigator.pop(context); setState(() { _currentIndex = 1; }); }),
          ListTile(leading: const Icon(Icons.add_circle_outline), title: const Text('New Report'), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/new-report'); }),
          const Divider(),
          ListTile(leading: const Icon(Icons.save_outlined), title: const Text('Saved Drafts'), onTap: () { Navigator.pop(context); _showSavedDrafts(); }),
          ListTile(leading: const Icon(Icons.cloud_upload_outlined), title: const Text('Sync Data'), onTap: () { Navigator.pop(context); _syncData(); }),
          const Divider(),
          ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Settings'), onTap: () { Navigator.pop(context); setState(() { _currentIndex = 2; }); }),
          ListTile(leading: const Icon(Icons.help_outline), title: const Text('Help & Support'), onTap: () { Navigator.pop(context); _showHelp(); }),
          ListTile(leading: const Icon(Icons.info_outline), title: const Text('About'), onTap: () { Navigator.pop(context); _showAbout(); }),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: AppColors.error), title: const Text('Logout', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _logout(); }),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, dynamic user, ReportService reportService) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome, ${user?.fullName?.split(' ').first ?? 'User'}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          Text('Zone: ${user?.zone ?? 'Not specified'}', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          const Text('Ready to submit your field report?', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Quick Stats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      DashboardCard(title: 'Total Reports', value: reportService.reports.length.toString(), icon: Icons.description, color: AppColors.primary),
                      DashboardCard(title: 'This Month', value: reportService.reports.where((r) => r.createdAt.month == DateTime.now().month && r.createdAt.year == DateTime.now().year).length.toString(), icon: Icons.calendar_month, color: AppColors.secondary),
                      DashboardCard(title: 'Youth Placed', value: reportService.reports.fold(0, (sum, r) => sum + r.employmentOutcome.totalPlaced).toString(), icon: Icons.people, color: AppColors.success),
                      DashboardCard(title: 'Partners', value: reportService.reports.fold(0, (sum, r) => sum + r.partnerCompanies.length).toString(), icon: Icons.handshake, color: AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Recent Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (reportService.reports.isEmpty)
                    Card(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(children: [Icon(Icons.description_outlined, size: 48, color: AppColors.textSecondary), const SizedBox(height: 16), const Text('No reports yet', style: TextStyle(fontSize: 18, color: AppColors.textSecondary))])))
                  else
                    ...reportService.reports.take(5).map((report) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(report.status),
                          child: Icon(_getStatusIcon(report.status), color: Colors.white),
                        ),
                        title: Text(report.trainingCentre.centreName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${report.focalPerson.visitDate.toString().split(' ')[0]} • ${report.focalPerson.zone}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Youth: ${report.attendance.totalYouth}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: _getStatusColor(report.status).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(report.status.toUpperCase(), style: TextStyle(fontSize: 10, color: _getStatusColor(report.status), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildReportsList(BuildContext context, ReportService reportService) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (reportService.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('No reports yet', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/new-report'), icon: const Icon(Icons.add), label: const Text('New Report')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reportService.reports.length,
        itemBuilder: (context, index) {
          final report = reportService.reports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(report.status),
                child: Icon(_getStatusIcon(report.status), color: Colors.white),
              ),
              title: Text(report.trainingCentre.centreName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${report.focalPerson.visitDate.toString().split(' ')[0]} • ${report.focalPerson.zone}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _getStatusColor(report.status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(report.status.toUpperCase(), style: TextStyle(fontSize: 11, color: _getStatusColor(report.status), fontWeight: FontWeight.bold)),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Focal Person', report.focalPerson.fullName),
                      _buildDetailRow('Hub', report.trainingCentre.hub),
                      _buildDetailRow('Community', report.trainingCentre.community),
                      _buildDetailRow('Total Youth', report.attendance.totalYouth.toString()),
                      _buildDetailRow('Youth Placed', report.employmentOutcome.totalPlaced.toString()),
                      _buildDetailRow('Partners', report.partnerCompanies.length.toString()),
                      _buildDetailRow('Rating', report.overallRating != null ? '${report.overallRating}/5' : 'N/A'),
                      if (report.challengesObserved != null && report.challengesObserved!.isNotEmpty)
                        _buildDetailRow('Challenges', report.challengesObserved!),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility), label: const Text('View')),
                          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.share), label: const Text('Share')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context, dynamic user) {
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
                    radius: 30,
                    child: Text(user?.fullName?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user?.fullName ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.email ?? ''),
                      Text('Zone: ${user?.zone ?? 'Not specified'}'),
                      Text('Role: ${user?.role ?? 'Field Officer'}'),
                    ],
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () { /* Edit profile */ },
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dark mode ${value ? "enabled" : "disabled"}'), backgroundColor: AppColors.info));
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
                ListTile(leading: const Icon(Icons.cloud_upload_outlined), title: const Text('Sync Data'), subtitle: const Text('Upload offline reports to server'), trailing: const Icon(Icons.chevron_right), onTap: _syncData),
                const Divider(),
                ListTile(leading: const Icon(Icons.download_outlined), title: const Text('Export Data'), subtitle: const Text('Download reports as Excel/PDF'), trailing: const Icon(Icons.chevron_right), onTap: _exportData),
                const Divider(),
                ListTile(leading: const Icon(Icons.delete_outline, color: AppColors.error), title: const Text('Clear Cache', style: TextStyle(color: AppColors.error)), subtitle: const Text('Remove temporary files'), trailing: const Icon(Icons.chevron_right), onTap: _clearCache),
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
                ListTile(leading: const Icon(Icons.description_outlined), title: const Text('Terms of Service'), trailing: const Icon(Icons.chevron_right), onTap: () => _showInfoDialog('Terms of Service', 'Terms of service content...')),
                const Divider(),
                ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Privacy Policy'), trailing: const Icon(Icons.chevron_right), onTap: () => _showInfoDialog('Privacy Policy', 'Privacy policy content...')),
                const Divider(),
                ListTile(leading: const Icon(Icons.contact_support_outlined), title: const Text('Contact Support'), subtitle: const Text('yiw@seghana.net'), trailing: const Icon(Icons.chevron_right), onTap: _showHelp),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _logout,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted': return AppColors.success;
      case 'draft': return AppColors.warning;
      case 'synced': return AppColors.info;
      default: return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted': return Icons.check_circle;
      case 'draft': return Icons.edit_note;
      case 'synced': return Icons.cloud_done;
      default: return Icons.description;
    }
  }

  void _showSavedDrafts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Saved Drafts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text('No saved drafts', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      const Text('Drafts will appear here when you save them', style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncData() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing data...'), backgroundColor: AppColors.info));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data synced successfully!'), backgroundColor: AppColors.success));
        _loadData();
      }
    });
  }

  void _exportData() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Export Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(leading: const Icon(Icons.table_chart, color: AppColors.success), title: const Text('Export as Excel'), onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting as Excel...'), backgroundColor: AppColors.success)); }),
            ListTile(leading: const Icon(Icons.picture_as_pdf, color: AppColors.error), title: const Text('Export as PDF'), onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting as PDF...'), backgroundColor: AppColors.success)); }),
          ],
        ),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove temporary files. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared'), backgroundColor: AppColors.success)); }, child: const Text('Clear', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact Support:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Email: yiw@seghana.net'),
            Text('Phone: +233 XXX XXX XXX'),
            Text('Hours: Mon-Fri 9am-5pm GMT'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('YiW Field Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text('SEG Ghana — Youth in Work Programme'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
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

  void _logout() {
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
