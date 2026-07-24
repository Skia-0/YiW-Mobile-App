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

  @override
  void initState() {
    super.initState();
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final reportService = Provider.of<ReportService>(context);
    final user = authService.appUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YiW Field Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: _currentIndex == 0
          ? _buildDashboard(context, user, reportService)
          : _currentIndex == 1
              ? _buildReportsList(context, reportService)
              : _buildSettings(context),
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
          _loadData(); // Refresh after returning
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
                  child: Text(
                    user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.fullName ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () { Navigator.pop(context); setState(() { _currentIndex = 0; }); },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('My Reports'),
            onTap: () { Navigator.pop(context); setState(() { _currentIndex = 1; }); },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('New Report'),
            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/new-report'); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () { Navigator.pop(context); setState(() { _currentIndex = 2; }); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              Navigator.pop(context);
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
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
                  // Welcome
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome, ${user?.fullName?.split(' ').first ?? 'User'}!',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          Text('Zone: ${user?.zone ?? 'Not specified'}', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          const Text('Ready to submit your field report?', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Stats
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
                      DashboardCard(
                        title: 'This Month',
                        value: reportService.reports.where((r) => r.createdAt.month == DateTime.now().month && r.createdAt.year == DateTime.now().year).length.toString(),
                        icon: Icons.calendar_month, color: AppColors.secondary),
                      DashboardCard(
                        title: 'Youth Placed',
                        value: reportService.reports.fold(0, (sum, r) => sum + r.employmentOutcome.totalPlaced).toString(),
                        icon: Icons.people, color: AppColors.success),
                      DashboardCard(
                        title: 'Partners',
                        value: reportService.reports.fold(0, (sum, r) => sum + r.partnerCompanies.length).toString(),
                        icon: Icons.handshake, color: AppColors.accent),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Reports
                  const Text('Recent Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  if (reportService.reports.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.description_outlined, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            const Text('No reports yet', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            const Text('Create your first field report', style: TextStyle(color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...reportService.reports.take(5).map((report) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: report.status == 'submitted' ? AppColors.success : AppColors.warning,
                          child: Icon(report.status == 'submitted' ? Icons.check_circle : Icons.edit_note, color: Colors.white),
                        ),
                        title: Text(report.trainingCentre.centreName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${report.focalPerson.visitDate.toString().split(' ')[0]} • ${report.focalPerson.zone}'),
                        trailing: Text('Youth: ${report.attendance.totalYouth}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/new-report'),
              icon: const Icon(Icons.add),
              label: const Text('New Report'),
            ),
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
                backgroundColor: report.status == 'submitted' ? AppColors.success : AppColors.warning,
                child: Icon(report.status == 'submitted' ? Icons.check_circle : Icons.edit_note, color: Colors.white),
              ),
              title: Text(report.trainingCentre.centreName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${report.focalPerson.visitDate.toString().split(' ')[0]} • ${report.focalPerson.zone}'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Focal Person', report.focalPerson.fullName),
                      _buildDetailRow('Hub', report.trainingCentre.hub),
                      _buildDetailRow('Total Youth', report.attendance.totalYouth.toString()),
                      _buildDetailRow('Youth Placed', report.employmentOutcome.totalPlaced.toString()),
                      _buildDetailRow('Partners', report.partnerCompanies.length.toString()),
                      _buildDetailRow('Status', report.status.toUpperCase()),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // View full report
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('View'),
                          ),
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

  Widget _buildSettings(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.appUser;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                        child: Text(user?.fullName?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(user?.fullName ?? 'User'),
                      subtitle: Text(user?.email ?? ''),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.info_outline), title: const Text('App Version'), subtitle: const Text('1.0.0')),
                  const Divider(),
                  ListTile(leading: const Icon(Icons.contact_support_outlined), title: const Text('Contact Support'), subtitle: const Text('yiw@seghana.net')),
                  const Divider(),
                  ListTile(leading: const Icon(Icons.logout, color: AppColors.error), title: const Text('Logout', style: TextStyle(color: AppColors.error)),
                    onTap: () async {
                      await authService.signOut();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
