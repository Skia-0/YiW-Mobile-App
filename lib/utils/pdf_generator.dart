import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:yiw_field_report/models/field_report.dart';

class PdfGenerator {
  static Future<Uint8List> generateReportPdf(FieldReport report) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(report),
        footer: (context) => _buildFooter(),
        build: (context) => [
          _buildTitle(),
          pw.SizedBox(height: 20),
          _buildFocalPersonSection(report),
          pw.SizedBox(height: 20),
          _buildTrainingCentreSection(report),
          pw.SizedBox(height: 20),
          _buildAttendanceSection(report),
          pw.SizedBox(height: 20),
          _buildEmploymentSection(report),
          pw.SizedBox(height: 20),
          _buildTrainingQualitySection(report),
          pw.SizedBox(height: 20),
          _buildPartnerSection(report),
          pw.SizedBox(height: 20),
          _buildSafeguardingSection(report),
          pw.SizedBox(height: 20),
          _buildFinalNotesSection(report),
        ],
      ),
    );
    
    return pdf.save();
  }

  static pw.Widget _buildHeader(FieldReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.green, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'YiW Daily Field Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'SEG Ghana — Youth in Work Programme',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Report ID: ${report.id}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Date: ${report.createdAt.toString().split(' ')[0]}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Status: ${report.status.toUpperCase()}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _getStatusColor(report.status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitle() {
    return pw.Center(
      child: pw.Text(
        'FIELD REPORT',
        style: pw.TextStyle(
          fontSize: 28,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  static pw.Widget _buildFocalPersonSection(FieldReport report) {
    return _buildSection(
      'FOCAL PERSON DETAILS',
      [
        _buildInfoRow('Full Name', report.focalPerson.fullName),
        _buildInfoRow('Phone Number', report.focalPerson.phoneNumber),
        _buildInfoRow('Email', report.focalPerson.email ?? 'N/A'),
        _buildInfoRow('Zone / Region', report.focalPerson.zone),
        _buildInfoRow('Date of Visit', report.focalPerson.visitDate.toString().split(' ')[0]),
        _buildInfoRow('Visit Types', report.focalPerson.visitTypes.join(', ')),
      ],
    );
  }

  static pw.Widget _buildTrainingCentreSection(FieldReport report) {
    return _buildSection(
      'TRAINING CENTRE DETAILS',
      [
        _buildInfoRow('Hub / TSP', report.trainingCentre.hub),
        if (report.trainingCentre.otherHubName != null)
          _buildInfoRow('Hub Name', report.trainingCentre.otherHubName!),
        _buildInfoRow('Community', report.trainingCentre.community),
        _buildInfoRow('Centre Name', report.trainingCentre.centreName),
        _buildInfoRow('Address', report.trainingCentre.centreAddress ?? 'N/A'),
        _buildInfoRow('Contact Person', report.trainingCentre.contactPerson ?? 'N/A'),
        _buildInfoRow('Contact Phone', report.trainingCentre.contactPhone ?? 'N/A'),
        _buildInfoRow('Time Arrived', report.trainingCentre.timeArrived?.toString().split(' ')[1].substring(0, 5) ?? 'N/A'),
        _buildInfoRow('Time Departed', report.trainingCentre.timeDeparted?.toString().split(' ')[1].substring(0, 5) ?? 'N/A'),
      ],
    );
  }

  static pw.Widget _buildAttendanceSection(FieldReport report) {
    return _buildSection(
      'ATTENDANCE COUNT',
      [
        _buildInfoRow('Young Men Present', report.attendance.youngMenPresent.toString()),
        _buildInfoRow('Young Women Present', report.attendance.youngWomenPresent.toString()),
        _buildInfoRow('Persons with Disability', report.attendance.personsWithDisability.toString()),
        _buildInfoRow('Hub Staff on Duty', report.attendance.hubStaffOnDuty.toString()),
        _buildInfoRow('Trainers / Facilitators', report.attendance.trainersPresent.toString()),
        _buildInfoRow('Total Youth', report.attendance.totalYouth.toString()),
        _buildInfoRow('Total Staff', report.attendance.totalStaff.toString()),
        _buildInfoRow('Total Present', report.attendance.totalPresent.toString()),
      ],
    );
  }

  static pw.Widget _buildEmploymentSection(FieldReport report) {
    return _buildSection(
      'EMPLOYMENT & PLACEMENT OUTCOMES',
      [
        _buildInfoRow('Youth Activated Today', report.employmentOutcome.youthActivatedToday.toString()),
        _buildInfoRow('Placed in Formal Employment', report.employmentOutcome.placedInFormalEmployment.toString()),
        _buildInfoRow('Placed in Internships', report.employmentOutcome.placedInInternships.toString()),
        _buildInfoRow('Joined Cooperatives', report.employmentOutcome.joinedCooperatives.toString()),
        _buildInfoRow('Referred for Further Training', report.employmentOutcome.referredForFurtherTraining.toString()),
        _buildInfoRow('Total Placed', report.employmentOutcome.totalPlaced.toString()),
        if (report.employmentOutcome.namesOfYouthPlaced.isNotEmpty)
          _buildInfoRow('Youth Placed', report.employmentOutcome.namesOfYouthPlaced.join(', ')),
        if (report.employmentOutcome.employerNames.isNotEmpty)
          _buildInfoRow('Employers', report.employmentOutcome.employerNames.join(', ')),
        if (report.employmentOutcome.sectorOfPlacement != null)
          _buildInfoRow('Sector', report.employmentOutcome.sectorOfPlacement!),
        if (report.newEnrolmentsMale.isNotEmpty)
          _buildInfoRow('New Enrolments (Male)', report.newEnrolmentsMale.length.toString()),
        if (report.newEnrolmentsFemale.isNotEmpty)
          _buildInfoRow('New Enrolments (Female)', report.newEnrolmentsFemale.length.toString()),
        if (report.courseEnrolledIn != null)
          _buildInfoRow('Course Enrolled', report.courseEnrolledIn!),
        if (report.successStory != null && report.successStory!.isNotEmpty)
          _buildInfoRow('Success Story', report.successStory!),
        if (report.youthVoice != null && report.youthVoice!.isNotEmpty)
          _buildInfoRow('Youth Voice', report.youthVoice!),
      ],
    );
  }

  static pw.Widget _buildTrainingQualitySection(FieldReport report) {
    return _buildSection(
      'TRAINING CENTRE QUALITY',
      [
        if (report.overallRating != null)
          _buildInfoRow('Overall Rating', '${report.overallRating}/5 - ${_getRatingLabel(report.overallRating!)}'),
        if (report.qualityIndicators.isNotEmpty)
          _buildInfoRow('Quality Indicators', report.qualityIndicators.join('\n• ')),
        if (report.issuesFlagged.isNotEmpty)
          _buildInfoRow('Issues Flagged', report.issuesFlagged.join('\n• ')),
        if (report.facilitiesAvailable.isNotEmpty)
          _buildInfoRow('Facilities Available', report.facilitiesAvailable.join('\n• ')),
        if (report.activitiesObserved.isNotEmpty)
          _buildInfoRow('Activities Observed', report.activitiesObserved.join('\n• ')),
        if (report.challengesObserved != null && report.challengesObserved!.isNotEmpty)
          _buildInfoRow('Challenges Observed', report.challengesObserved!),
        if (report.recommendations != null && report.recommendations!.isNotEmpty)
          _buildInfoRow('Recommendations', report.recommendations!),
        if (report.urgencyOfAction != null)
          _buildInfoRow('Urgency of Action', report.urgencyOfAction!),
        if (report.followUpBy != null)
          _buildInfoRow('Follow-up By', report.followUpBy!),
      ],
    );
  }

  static pw.Widget _buildPartnerSection(FieldReport report) {
    return _buildSection(
      'PARTNER ENGAGEMENT',
      [
        _buildInfoRow('Partners Engaged Today', '${report.partnerCompanies.length}/15 zone target'),
        if (report.partnerEngagementNotes != null && report.partnerEngagementNotes!.isNotEmpty)
          _buildInfoRow('Partner Notes', report.partnerEngagementNotes!),
        if (report.nextPartnerEngagementDate != null)
          _buildInfoRow('Next Engagement Date', report.nextPartnerEngagementDate!.toString().split(' ')[0]),
        if (report.partnerCompanies.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Partner Companies:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          ...report.partnerCompanies.map((company) => pw.Bullet(
            text: '${company.companyName} - ${company.sector ?? "N/A"} (${company.status ?? "N/A"})',
          )),
        ],
      ],
    );
  }

  static pw.Widget _buildSafeguardingSection(FieldReport report) {
    return _buildSection(
      'SAFEGUARDING CHECKLIST',
      [
        _buildInfoRow('Consent Obtained', report.safeguarding.consentObtained ? 'Yes' : 'No'),
        _buildInfoRow('Two-Adult Rule', report.safeguarding.twoAdultRule ? 'Yes' : 'No'),
        _buildInfoRow('Policy Visible', report.safeguarding.policyVisible ? 'Yes' : 'No'),
        _buildInfoRow('No Discrimination', report.safeguarding.noDiscrimination ? 'Yes' : 'No'),
        _buildInfoRow('Reporting Mechanism', report.safeguarding.reportingMechanismCommunicated ? 'Yes' : 'No'),
        _buildInfoRow('ID Badge Worn', report.safeguarding.idBadgeWorn ? 'Yes' : 'No'),
        _buildInfoRow('No Personal Contacts', report.safeguarding.noPersonalContacts ? 'Yes' : 'No'),
        _buildInfoRow('Gifts Guidelines', report.safeguarding.giftsFollowGuidelines ? 'Yes' : 'No'),
        _buildInfoRow('Concern Identified', report.safeguarding.concernIdentified ? 'Yes' : 'No'),
        if (report.safeguarding.concernIdentified) ...[
          _buildInfoRow('Concern Description', report.safeguarding.concernDescription ?? 'N/A'),
          _buildInfoRow('Action Taken', report.safeguarding.actionTaken ?? 'N/A'),
          _buildInfoRow('Reported To', report.safeguarding.reportedTo ?? 'N/A'),
        ],
        if (report.safeguarding.notes != null && report.safeguarding.notes!.isNotEmpty)
          _buildInfoRow('Safeguarding Notes', report.safeguarding.notes!),
      ],
    );
  }

  static pw.Widget _buildFinalNotesSection(FieldReport report) {
    if (report.finalNotes == null || report.finalNotes!.isEmpty) {
      return pw.SizedBox();
    }
    
    return _buildSection(
      'FINAL NOTES',
      [
        pw.Text(report.finalNotes!),
      ],
    );
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.green, width: 1),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by YiW Field Report App',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
          pw.Text(
            'Page ${1}', // This would need context.pageNumber
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  static PdfColor _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return PdfColors.green;
      case 'draft':
        return PdfColors.orange;
      case 'synced':
        return PdfColors.blue;
      default:
        return PdfColors.grey;
    }
  }

  static String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}