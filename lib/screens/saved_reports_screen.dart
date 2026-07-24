import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yiw_field_report/services/report_service.dart';
import 'package:yiw_field_report/theme/colors.dart';

class SavedReportsScreen extends StatefulWidget {
  const SavedReportsScreen({super.key});

  @override
  State<SavedReportsScreen> createState() => _SavedReportsScreenState();
}

class _SavedReportsScreenState extends State<SavedReportsScreen> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reportService = Provider.of<ReportService>(context, listen: false);
    await reportService.loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final reportService = Provider.of<ReportService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: reportService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportService.reports.isEmpty
              ? _buildEmptyState()
              : _buildReportsList(reportService),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No saved reports',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your submitted reports will appear here',
            style: TextStyle(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/new-report');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(ReportService reportService) {
    return RefreshIndicator(
      onRefresh: _loadReports,
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
                child: Icon(
                  _getStatusIcon(report.status),
                  color: Colors.white,
                ),
              ),
              title: Text(
                report.trainingCentre.centreName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${report.focalPerson.visitDate.toString().split(' ')[0]} • ${report.focalPerson.zone}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Report ID', report.id),
                      _buildDetailRow('Status', report.status.toUpperCase()),
                      _buildDetailRow('Focal Person', report.focalPerson.fullName),
                      _buildDetailRow('Hub', report.trainingCentre.hub),
                      _buildDetailRow('Community', report.trainingCentre.community),
                      const Divider(),
                      _buildDetailRow('Total Youth', report.attendance.totalYouth.toString()),
                      _buildDetailRow('Young Men', report.attendance.youngMenPresent.toString()),
                      _buildDetailRow('Young Women', report.attendance.youngWomenPresent.toString()),
                      _buildDetailRow('PWDs', report.attendance.personsWithDisability.toString()),
                      const Divider(),
                      _buildDetailRow('Youth Placed', report.employmentOutcome.totalPlaced.toString()),
                      _buildDetailRow('Formal Employment', report.employmentOutcome.placedInFormalEmployment.toString()),
                      _buildDetailRow('Internships', report.employmentOutcome.placedInInternships.toString()),
                      _buildDetailRow('Cooperatives', report.employmentOutcome.joinedCooperatives.toString()),
                      const Divider(),
                      _buildDetailRow('Partners Engaged', report.partnerCompanies.length.toString()),
                      _buildDetailRow('Quality Rating', report.overallRating?.toString() ?? 'N/A'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // View full report
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('View'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Edit report
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              _deleteReport(report.id);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppColors.success;
      case 'draft':
        return AppColors.warning;
      case 'synced':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.check_circle;
      case 'draft':
        return Icons.edit_note;
      case 'synced':
        return Icons.cloud_done;
      default:
        return Icons.description;
    }
  }

  Future<void> _deleteReport(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final reportService = Provider.of<ReportService>(context, listen: false);
      await reportService.deleteReport(reportId);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}