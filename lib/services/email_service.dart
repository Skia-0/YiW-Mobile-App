import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:yiw_field_report/models/field_report.dart';

class EmailService {
  String? _sendGridApiKey;
  String? _senderEmail;
  String? _senderName;
  String? _ceoEmail;
  String? _yiwEmail;

  Future<void> _loadConfig() async {
    if (_sendGridApiKey != null) return;
    try {
      final jsonStr = await rootBundle.loadString('lib/config/secrets.json');
      final config = jsonDecode(jsonStr);
      _sendGridApiKey = config['sendgrid_api_key'];
      _senderEmail = config['sender_email'];
      _senderName = 'YiW Field Report - SEG Ghana';
      _ceoEmail = config['ceo_email'];
      _yiwEmail = config['yiw_email'];
    } catch (e) {
      debugPrint('Error loading email config: $e');
    }
  }

  Future<void> sendReportEmail({
    required String toEmail,
    required FieldReport report,
    required String recipientName,
  }) async {
    try {
      await _loadConfig();
      final subject = 'YiW Field Report - ${report.focalPerson.visitDate.toString().split(' ')[0]} - ${report.trainingCentre.centreName}';
      final htmlContent = _buildEmailHtml(report, recipientName);
      await _sendEmailViaSendGrid(toEmail: toEmail, subject: subject, htmlContent: htmlContent);
      debugPrint('Email sent to $toEmail');
    } catch (e) {
      debugPrint('Error sending email to $toEmail: $e');
    }
  }

  Future<void> sendConfirmationEmail({
    required String toEmail,
    required FieldReport report,
  }) async {
    try {
      await _loadConfig();
      final subject = 'Confirmation: YiW Field Report Submitted Successfully';
      final htmlContent = _buildConfirmationHtml(report);
      await _sendEmailViaSendGrid(toEmail: toEmail, subject: subject, htmlContent: htmlContent);
      debugPrint('Confirmation email sent to $toEmail');
    } catch (e) {
      debugPrint('Error sending confirmation email: $e');
    }
  }

  Future<void> _sendEmailViaSendGrid({
    required String toEmail,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
      final emailData = {
        'personalizations': [
          {
            'to': [{'email': toEmail}],
            'subject': subject,
          }
        ],
        'from': {
          'email': _senderEmail,
          'name': _senderName,
        },
        'reply_to': {
          'email': _senderEmail,
          'name': _senderName,
        },
        'subject': subject,
        'content': [
          {
            'type': 'text/html',
            'value': htmlContent,
          }
        ],
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_sendGridApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 202) {
        debugPrint('Email sent successfully to $toEmail');
      } else {
        debugPrint('Failed to send email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in SendGrid API call: $e');
    }
  }

  String _buildEmailHtml(FieldReport report, String recipientName) {
    final visitDate = report.focalPerson.visitDate.toString().split(' ')[0];
    final timeArrived = report.trainingCentre.timeArrived?.toString().split(' ')[1].substring(0, 5) ?? 'N/A';
    final timeDeparted = report.trainingCentre.timeDeparted?.toString().split(' ')[1].substring(0, 5) ?? 'N/A';
    final timeOnSite = '$timeArrived - $timeDeparted';

    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>YiW Field Report</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5; color: #333333;">
      
      <!-- Main Container -->
      <div style="max-width: 800px; margin: 0 auto; background-color: #ffffff;">
        
        <!-- Dark Header -->
        <div style="background-color: #2d2d2d; padding: 30px 40px; text-align: center;">
          <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 700; letter-spacing: 0.5px;">Youth in Work Programme</h1>
          <p style="margin: 8px 0 0 0; color: #b0b0b0; font-size: 14px;">SEG Ghana — Field Report</p>
        </div>
        
        <!-- Report Metadata Row -->
        <div style="background-color: #f8f9fa; padding: 20px 40px; border-bottom: 1px solid #e0e0e0;">
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 8px 16px 8px 0; border-right: 1px solid #e0e0e0;">
                <span style="font-size: 11px; color: #888888; text-transform: uppercase; letter-spacing: 0.5px;">Beneficiary</span><br>
                <span style="font-size: 14px; font-weight: 600; color: #2d2d2d;">${report.focalPerson.fullName}</span>
              </td>
              <td style="padding: 8px 16px; border-right: 1px solid #e0e0e0;">
                <span style="font-size: 11px; color: #888888; text-transform: uppercase; letter-spacing: 0.5px;">Phone</span><br>
                <span style="font-size: 14px; font-weight: 600; color: #2d2d2d;">${report.focalPerson.phoneNumber}</span>
              </td>
              <td style="padding: 8px 16px; border-right: 1px solid #e0e0e0;">
                <span style="font-size: 11px; color: #888888; text-transform: uppercase; letter-spacing: 0.5px;">Report Date</span><br>
                <span style="font-size: 14px; font-weight: 600; color: #2d2d2d;">$visitDate</span>
              </td>
              <td style="padding: 8px 0 8px 16px;">
                <span style="font-size: 11px; color: #888888; text-transform: uppercase; letter-spacing: 0.5px;">Region</span><br>
                <span style="font-size: 14px; font-weight: 600; color: #2d2d2d;">${report.focalPerson.zone}</span>
              </td>
            </tr>
          </table>
        </div>
        
        <!-- Google Sheet Banner -->
        <div style="margin: 20px 40px; background-color: #e3f2fd; border: 1px solid #90caf9; border-radius: 8px; padding: 20px;">
          <table style="width: 100%;">
            <tr>
              <td style="width: 70%; vertical-align: middle;">
                <h3 style="margin: 0 0 8px 0; font-size: 16px; color: #1565c0;">📊 View & Download Master Data Sheet</h3>
                <p style="margin: 0; font-size: 13px; color: #555555;">This report has been automatically added to the central Google Sheet for consolidated data tracking and analysis.</p>
              </td>
              <td style="width: 30%; text-align: right; vertical-align: middle;">
                <a href="https://docs.google.com/spreadsheets/d/1vC3HSNrd78N4IGftTSXEdr39_zjZcliaenxwBAnw4pM" style="display: inline-block; background-color: #1565c0; color: #ffffff; padding: 12px 24px; border-radius: 6px; text-decoration: none; font-weight: 600; font-size: 14px;">Open Sheet →</a>
              </td>
            </tr>
          </table>
        </div>
        
        <!-- Visit Details Section -->
        <div style="margin: 0 40px 20px; background-color: #ffffff; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
          <div style="background-color: #2d2d2d; padding: 14px 20px;">
            <h2 style="margin: 0; color: #ffffff; font-size: 15px; font-weight: 600;">📍 Visit Details</h2>
          </div>
          <div style="padding: 20px;">
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0; width: 35%;"><span style="font-size: 13px; color: #888888;">Visit Type</span></td>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 14px; font-weight: 500;">${report.focalPerson.visitTypes.join(', ')}</span></td>
              </tr>
              <tr>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 13px; color: #888888;">Hub / TSP</span></td>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 14px; font-weight: 500;">${report.trainingCentre.hub}</span></td>
              </tr>
              <tr>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 13px; color: #888888;">Community</span></td>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 14px; font-weight: 500;">${report.trainingCentre.community}</span></td>
              </tr>
              <tr>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 13px; color: #888888;">Training Centre</span></td>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 14px; font-weight: 500;">${report.trainingCentre.centreName}</span></td>
              </tr>
              <tr>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 13px; color: #888888;">Address</span></td>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 14px; font-weight: 500;">${report.trainingCentre.centreAddress ?? 'N/A'}</span></td>
              </tr>
              <tr>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 13px; color: #888888;">Centre Contact</span></td>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 14px; font-weight: 500;">${report.trainingCentre.contactPerson ?? 'N/A'} ${report.trainingCentre.contactPhone != null ? '(${report.trainingCentre.contactPhone})' : ''}</span></td>
              </tr>
              <tr>
                <td style="padding: 10px 0;"><span style="font-size: 13px; color: #888888;">Time on Site</span></td>
                <td style="padding: 10px 0;"><span style="font-size: 14px; font-weight: 500;">$timeOnSite</span></td>
              </tr>
            </table>
          </div>
        </div>
        
        <!-- Attendance Count Section -->
        <div style="margin: 0 40px 20px; background-color: #ffffff; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
          <div style="background-color: #2d2d2d; padding: 14px 20px;">
            <h2 style="margin: 0; color: #ffffff; font-size: 15px; font-weight: 600;">👥 Attendance Count</h2>
          </div>
          <div style="padding: 20px;">
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="width: 20%; padding: 8px; text-align: center;">
                  <div style="background-color: #e8f5e9; border-radius: 8px; padding: 16px 8px;">
                    <div style="font-size: 32px; font-weight: 700; color: #2e7d32;">${report.attendance.youngMenPresent}</div>
                    <div style="font-size: 11px; color: #666666; margin-top: 4px;">Young Men</div>
                  </div>
                </td>
                <td style="width: 20%; padding: 8px; text-align: center;">
                  <div style="background-color: #fce4ec; border-radius: 8px; padding: 16px 8px;">
                    <div style="font-size: 32px; font-weight: 700; color: #c62828;">${report.attendance.youngWomenPresent}</div>
                    <div style="font-size: 11px; color: #666666; margin-top: 4px;">Young Women</div>
                  </div>
                </td>
                <td style="width: 20%; padding: 8px; text-align: center;">
                  <div style="background-color: #fff3e0; border-radius: 8px; padding: 16px 8px;">
                    <div style="font-size: 32px; font-weight: 700; color: #e65100;">${report.attendance.personsWithDisability}</div>
                    <div style="font-size: 11px; color: #666666; margin-top: 4px;">PWD</div>
                  </div>
                </td>
                <td style="width: 20%; padding: 8px; text-align: center;">
                  <div style="background-color: #e3f2fd; border-radius: 8px; padding: 16px 8px;">
                    <div style="font-size: 32px; font-weight: 700; color: #1565c0;">${report.attendance.hubStaffOnDuty}</div>
                    <div style="font-size: 11px; color: #666666; margin-top: 4px;">Staff</div>
                  </div>
                </td>
                <td style="width: 20%; padding: 8px; text-align: center;">
                  <div style="background-color: #f3e5f5; border-radius: 8px; padding: 16px 8px;">
                    <div style="font-size: 32px; font-weight: 700; color: #7b1fa2;">${report.attendance.trainersPresent}</div>
                    <div style="font-size: 11px; color: #666666; margin-top: 4px;">Trainers</div>
                  </div>
                </td>
              </tr>
            </table>
          </div>
        </div>
        
        <!-- Activation & Employment Section -->
        <div style="margin: 0 40px 20px; background-color: #ffffff; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
          <div style="background-color: #2d2d2d; padding: 14px 20px;">
            <h2 style="margin: 0; color: #ffffff; font-size: 15px; font-weight: 600;">🚀 Activation & Employment</h2>
          </div>
          <div style="padding: 20px;">
            <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
              <tr>
                <td style="width: 25%; padding: 8px; text-align: center;">
                  <div style="background-color: #e8f5e9; border-radius: 8px; padding: 16px 8px;">
                    <div style="font-size: 32px; font-weight: 700; color: #2e7d32;">${report.employmentOutcome.placedInFormalEmployment}</div>
                    <div style="font-size: 11px; color: #666666; margin-top: 4px;">Formal Jobs</div>
                  </div>
                </td>
                <td style="width: 25%; padding: 8px; text-align: center;">
                  <div style="background-color: #e3f2fd; border-radius: 8px; padding: 16px 8px;">
                    <div style="font-size: 32px; font-weight: 700; color: #1565c0;">${report.employmentOutcome.placedInInternships}</div>
                    <div style="font-size: 11px; color: #666666; margin-top: 4px;">Internships</div>
                  </div>
                </td>
                <td style="width: 25%; padding: 8px; text-align: center;">
                  <div style="background-color: #fff3e0; border-radius: 8px; padding: 16px 8px;">
                    <div style="font-size: 32px; font-weight: 700; color: #e65100;">${report.employmentOutcome.joinedCooperatives}</div>
                    <div style="font-size: 11px; color: #666666; margin-top: 4px;">Cooperatives</div>
                  </div>
                </td>
                <td style="width: 25%; padding: 8px; text-align: center;">
                  <div style="background-color: #f3e5f5; border-radius: 8px; padding: 16px 8px;">
                    <div style="font-size: 32px; font-weight: 700; color: #7b1fa2;">${report.employmentOutcome.referredForFurtherTraining}</div>
                    <div style="font-size: 11px; color: #666666; margin-top: 4px;">Further Training</div>
                  </div>
                </td>
              </tr>
            </table>
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0; width: 35%;"><span style="font-size: 13px; color: #888888;">New Enrolments</span></td>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 14px; font-weight: 500;">${report.newEnrolmentsMale.length} Male, ${report.newEnrolmentsFemale.length} Female</span></td>
              </tr>
              <tr>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 13px; color: #888888;">Course Enrolled In</span></td>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 14px; font-weight: 500;">${report.courseEnrolledIn ?? 'N/A'}</span></td>
              </tr>
              <tr>
                <td style="padding: 10px 0;"><span style="font-size: 13px; color: #888888;">Employer / Cooperative</span></td>
                <td style="padding: 10px 0;"><span style="font-size: 14px; font-weight: 500;">${report.employmentOutcome.employerNames.join(', ')}</span></td>
              </tr>
            </table>
          </div>
        </div>
        
        <!-- Training Centre Quality Section -->
        <div style="margin: 0 40px 20px; background-color: #ffffff; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
          <div style="background-color: #2d2d2d; padding: 14px 20px;">
            <h2 style="margin: 0; color: #ffffff; font-size: 15px; font-weight: 600;">⭐ Training Centre Quality</h2>
          </div>
          <div style="padding: 20px;">
            <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
              <tr>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0; width: 35%;"><span style="font-size: 13px; color: #888888;">Overall Rating</span></td>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 14px; font-weight: 600; color: #2e7d32;">${report.overallRating ?? 'N/A'}/5</span></td>
              </tr>
              <tr>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 13px; color: #888888;">Urgency</span></td>
                <td style="padding: 10px 0; border-bottom: 1px solid #f0f0f0;"><span style="font-size: 14px; font-weight: 500;">${report.urgencyOfAction ?? 'No action needed'}</span></td>
              </tr>
              <tr>
                <td style="padding: 10px 0;"><span style="font-size: 13px; color: #888888;">Follow-up By</span></td>
                <td style="padding: 10px 0;"><span style="font-size: 14px; font-weight: 500;">${report.followUpBy ?? 'N/A'}</span></td>
              </tr>
            </table>
            ${report.qualityIndicators.isNotEmpty ? '''
            <div style="margin-bottom: 16px;">
              <div style="font-size: 13px; color: #888888; margin-bottom: 8px;">Quality Indicators</div>
              <div style="font-size: 14px;">${report.qualityIndicators.join(' • ')}</div>
            </div>
            ''' : ''}
            ${report.issuesFlagged.isNotEmpty ? '''
            <div style="margin-bottom: 16px;">
              <div style="font-size: 13px; color: #888888; margin-bottom: 8px;">Issues Flagged</div>
              <div style="font-size: 14px; color: #c62828;">${report.issuesFlagged.join(' • ')}</div>
            </div>
            ''' : ''}
            ${report.activitiesObserved.isNotEmpty ? '''
            <div style="margin-bottom: 16px;">
              <div style="font-size: 13px; color: #888888; margin-bottom: 8px;">Activities Observed</div>
              <div style="font-size: 14px;">${report.activitiesObserved.join(' • ')}</div>
            </div>
            ''' : ''}
            ${report.facilitiesAvailable.isNotEmpty ? '''
            <div>
              <div style="font-size: 13px; color: #888888; margin-bottom: 8px;">Facilities</div>
              <div style="font-size: 14px;">${report.facilitiesAvailable.join(' • ')}</div>
            </div>
            ''' : ''}
          </div>
        </div>
        
        <!-- Partner Engagement Section -->
        <div style="margin: 0 40px 20px; background-color: #ffffff; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
          <div style="background-color: #2d2d2d; padding: 14px 20px;">
            <h2 style="margin: 0; color: #ffffff; font-size: 15px; font-weight: 600;">🤝 Partner Engagement</h2>
          </div>
          <div style="padding: 20px;">
            <table style="width: 100%; border-collapse: collapse; border: 1px solid #e0e0e0;">
              <thead>
                <tr style="background-color: #f8f9fa;">
                  <th style="padding: 10px 12px; text-align: left; font-size: 12px; font-weight: 600; color: #555555; border-bottom: 1px solid #e0e0e0;">Company</th>
                  <th style="padding: 10px 12px; text-align: left; font-size: 12px; font-weight: 600; color: #555555; border-bottom: 1px solid #e0e0e0;">Location</th>
                  <th style="padding: 10px 12px; text-align: left; font-size: 12px; font-weight: 600; color: #555555; border-bottom: 1px solid #e0e0e0;">Sector</th>
                  <th style="padding: 10px 12px; text-align: left; font-size: 12px; font-weight: 600; color: #555555; border-bottom: 1px solid #e0e0e0;">Status</th>
                  <th style="padding: 10px 12px; text-align: left; font-size: 12px; font-weight: 600; color: #555555; border-bottom: 1px solid #e0e0e0;">Slots</th>
                </tr>
              </thead>
              <tbody>
                ${report.partnerCompanies.isNotEmpty 
                  ? report.partnerCompanies.map((p) => '''
                    <tr>
                      <td style="padding: 10px 12px; font-size: 13px; border-bottom: 1px solid #f0f0f0;">${p.companyName}</td>
                      <td style="padding: 10px 12px; font-size: 13px; border-bottom: 1px solid #f0f0f0;">${p.location ?? 'N/A'}</td>
                      <td style="padding: 10px 12px; font-size: 13px; border-bottom: 1px solid #f0f0f0;">${p.sector ?? 'N/A'}</td>
                      <td style="padding: 10px 12px; font-size: 13px; border-bottom: 1px solid #f0f0f0;">${p.status ?? 'N/A'}</td>
                      <td style="padding: 10px 12px; font-size: 13px; border-bottom: 1px solid #f0f0f0;">${p.youthSlots ?? 0}</td>
                    </tr>
                  ''').join('')
                  : '''
                    <tr>
                      <td colspan="5" style="padding: 30px; text-align: center; color: #999999; font-size: 14px;">No partner companies logged</td>
                    </tr>
                  '''}
              </tbody>
            </table>
          </div>
        </div>
        
        <!-- Safeguarding Section -->
        <div style="margin: 0 40px 20px; background-color: #ffffff; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
          <div style="background-color: #2d2d2d; padding: 14px 20px;">
            <h2 style="margin: 0; color: #ffffff; font-size: 15px; font-weight: 600;">🛡️ Safeguarding</h2>
          </div>
          <div style="padding: 20px;">
            <div style="margin-bottom: 16px;">
              <span style="display: inline-block; background-color: #e8f5e9; color: #2e7d32; padding: 6px 12px; border-radius: 4px; font-size: 13px; font-weight: 600; margin-right: 8px;">${_getSafeguardingCount(report.safeguarding)}/8 Checks Completed</span>
              ${report.safeguarding.concernIdentified 
                ? '<span style="display: inline-block; background-color: #ffebee; color: #c62828; padding: 6px 12px; border-radius: 4px; font-size: 13px; font-weight: 600;">Concern Identified</span>'
                : '<span style="display: inline-block; background-color: #e8f5e9; color: #2e7d32; padding: 6px 12px; border-radius: 4px; font-size: 13px; font-weight: 600;">No Concerns</span>'}
            </div>
            ${report.safeguarding.concernIdentified && report.safeguarding.concernDescription != null ? '''
            <div style="background-color: #fff3e0; border-left: 4px solid #ff9800; padding: 12px 16px; border-radius: 0 4px 4px 0;">
              <div style="font-size: 13px; color: #888888; margin-bottom: 4px;">Concern Detail</div>
              <div style="font-size: 14px;">${report.safeguarding.concernDescription}</div>
            </div>
            ''' : ''}
          </div>
        </div>
        
        <!-- Footer -->
        <div style="background-color: #f8f9fa; padding: 30px 40px; text-align: center; border-top: 1px solid #e0e0e0;">
          <p style="margin: 0 0 8px 0; font-size: 13px; color: #888888;">Submitted on ${report.createdAt.toIso8601String().split('T')[0]} at ${report.createdAt.toIso8601String().split('T')[1].substring(0, 5)}</p>
          <p style="margin: 0; font-size: 12px; color: #aaaaaa;">Submitted via Youth in Work Field Reporting System</p>
          <p style="margin: 4px 0 0 0; font-size: 12px; color: #aaaaaa;">SEG Ghana | Youth in Work Programme</p>
        </div>
        
      </div>
    </body>
    </html>
    ''';
  }

  int _getSafeguardingCount(dynamic safeguarding) {
    int count = 0;
    if (safeguarding.consentObtained) count++;
    if (safeguarding.twoAdultRule) count++;
    if (safeguarding.policyVisible) count++;
    if (safeguarding.noDiscrimination) count++;
    if (safeguarding.reportingMechanismCommunicated) count++;
    if (safeguarding.idBadgeWorn) count++;
    if (safeguarding.noPersonalContacts) count++;
    if (safeguarding.giftsFollowGuidelines) count++;
    return count;
  }

  String _buildConfirmationHtml(FieldReport report) {
    final visitDate = report.focalPerson.visitDate.toString().split(' ')[0];
    
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Report Confirmation</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5; color: #333333;">
      
      <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
        
        <!-- Header -->
        <div style="background-color: #2e7d32; padding: 40px; text-align: center;">
          <div style="font-size: 48px; margin-bottom: 16px;">✅</div>
          <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 700;">Report Submitted Successfully</h1>
        </div>
        
        <!-- Content -->
        <div style="padding: 40px;">
          <p style="font-size: 16px; margin: 0 0 24px 0;">Dear ${report.focalPerson.fullName},</p>
          <p style="font-size: 14px; color: #555555; margin: 0 0 24px 0;">Your field report has been submitted and distributed to the management team.</p>
          
          <!-- Summary Card -->
          <div style="background-color: #f8f9fa; border: 1px solid #e0e0e0; border-radius: 8px; padding: 24px; margin-bottom: 24px;">
            <h3 style="margin: 0 0 16px 0; font-size: 16px; color: #2d2d2d;">Report Summary</h3>
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 8px 0; border-bottom: 1px solid #e0e0e0; width: 40%;"><span style="font-size: 13px; color: #888888;">Date</span></td>
                <td style="padding: 8px 0; border-bottom: 1px solid #e0e0e0;"><span style="font-size: 14px; font-weight: 500;">$visitDate</span></td>
              </tr>
              <tr>
                <td style="padding: 8px 0; border-bottom: 1px solid #e0e0e0;"><span style="font-size: 13px; color: #888888;">Training Centre</span></td>
                <td style="padding: 8px 0; border-bottom: 1px solid #e0e0e0;"><span style="font-size: 14px; font-weight: 500;">${report.trainingCentre.centreName}</span></td>
              </tr>
              <tr>
                <td style="padding: 8px 0; border-bottom: 1px solid #e0e0e0;"><span style="font-size: 13px; color: #888888;">Zone</span></td>
                <td style="padding: 8px 0; border-bottom: 1px solid #e0e0e0;"><span style="font-size: 14px; font-weight: 500;">${report.focalPerson.zone}</span></td>
              </tr>
              <tr>
                <td style="padding: 8px 0; border-bottom: 1px solid #e0e0e0;"><span style="font-size: 13px; color: #888888;">Total Youth</span></td>
                <td style="padding: 8px 0; border-bottom: 1px solid #e0e0e0;"><span style="font-size: 14px; font-weight: 600; color: #2e7d32;">${report.attendance.totalYouth}</span></td>
              </tr>
              <tr>
                <td style="padding: 8px 0;"><span style="font-size: 13px; color: #888888;">Youth Placed</span></td>
                <td style="padding: 8px 0;"><span style="font-size: 14px; font-weight: 600; color: #2e7d32;">${report.employmentOutcome.totalPlaced}</span></td>
              </tr>
            </table>
          </div>
          
          <p style="font-size: 14px; color: #555555; margin: 0;">The report has been sent to the Executive Director and YiW team. Data has also been recorded in the central database.</p>
        </div>
        
        <!-- Footer -->
        <div style="background-color: #f8f9fa; padding: 24px 40px; text-align: center; border-top: 1px solid #e0e0e0;">
          <p style="margin: 0; font-size: 12px; color: #aaaaaa;">SEG Ghana | Youth in Work Programme</p>
        </div>
        
      </div>
    </body>
    </html>
    ''';
  }
}
