import 'package:yiw_field_report/models/focal_person.dart';
import 'package:yiw_field_report/models/training_centre.dart';
import 'package:yiw_field_report/models/attendance.dart';
import 'package:yiw_field_report/models/employment_outcome.dart';
import 'package:yiw_field_report/models/partner_company.dart';
import 'package:yiw_field_report/models/safeguarding.dart';

class FieldReport {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String? userId;
  final String? userName;
  final FocalPerson focalPerson;
  final TrainingCentre trainingCentre;
  final Attendance attendance;
  final EmploymentOutcome employmentOutcome;
  final List<String> newEnrolmentsMale;
  final List<String> newEnrolmentsFemale;
  final String? courseEnrolledIn;
  final String? successStory;
  final String? youthVoice;
  final int? overallRating;
  final List<String> qualityIndicators;
  final List<String> issuesFlagged;
  final List<String> facilitiesAvailable;
  final List<String> activitiesObserved;
  final String? challengesObserved;
  final String? recommendations;
  final String? urgencyOfAction;
  final String? followUpBy;
  final List<PartnerCompany> partnerCompanies;
  final String? partnerEngagementNotes;
  final DateTime? nextPartnerEngagementDate;
  final Safeguarding safeguarding;
  final String? finalNotes;
  final List<String> photoPaths;
  final List<String> videoPaths;
  final List<String> documentPaths;
  final List<String> attendanceSheetPaths;
  final List<String> financialDocPaths;
  final List<String> mouPaths;
  final List<String> trackingSheetPaths;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  FieldReport({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'draft',
    this.userId,
    this.userName,
    required this.focalPerson,
    required this.trainingCentre,
    required this.attendance,
    required this.employmentOutcome,
    this.newEnrolmentsMale = const [],
    this.newEnrolmentsFemale = const [],
    this.courseEnrolledIn,
    this.successStory,
    this.youthVoice,
    this.overallRating,
    this.qualityIndicators = const [],
    this.issuesFlagged = const [],
    this.facilitiesAvailable = const [],
    this.activitiesObserved = const [],
    this.challengesObserved,
    this.recommendations,
    this.urgencyOfAction,
    this.followUpBy,
    this.partnerCompanies = const [],
    this.partnerEngagementNotes,
    this.nextPartnerEngagementDate,
    required this.safeguarding,
    this.finalNotes,
    this.photoPaths = const [],
    this.videoPaths = const [],
    this.documentPaths = const [],
    this.attendanceSheetPaths = const [],
    this.financialDocPaths = const [],
    this.mouPaths = const [],
    this.trackingSheetPaths = const [],
    this.latitude,
    this.longitude,
    this.locationName,
  });

  factory FieldReport.fromJson(Map<String, dynamic> json) {
    return FieldReport(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: json['status'] ?? 'draft',
      userId: json['userId'],
      userName: json['userName'],
      focalPerson: FocalPerson.fromJson(json['focalPerson']),
      trainingCentre: TrainingCentre.fromJson(json['trainingCentre']),
      attendance: Attendance.fromJson(json['attendance']),
      employmentOutcome: EmploymentOutcome.fromJson(json['employmentOutcome']),
      safeguarding: Safeguarding.fromJson(json['safeguarding']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'userId': userId,
      'userName': userName,
      'focalPerson': focalPerson.toJson(),
      'trainingCentre': trainingCentre.toJson(),
      'attendance': attendance.toJson(),
      'employmentOutcome': employmentOutcome.toJson(),
      'safeguarding': safeguarding.toJson(),
    };
  }

  FieldReport copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? userId,
    String? userName,
    FocalPerson? focalPerson,
    TrainingCentre? trainingCentre,
    Attendance? attendance,
    EmploymentOutcome? employmentOutcome,
    List<String>? newEnrolmentsMale,
    List<String>? newEnrolmentsFemale,
    String? courseEnrolledIn,
    String? successStory,
    String? youthVoice,
    int? overallRating,
    List<String>? qualityIndicators,
    List<String>? issuesFlagged,
    List<String>? facilitiesAvailable,
    List<String>? activitiesObserved,
    String? challengesObserved,
    String? recommendations,
    String? urgencyOfAction,
    String? followUpBy,
    List<PartnerCompany>? partnerCompanies,
    String? partnerEngagementNotes,
    DateTime? nextPartnerEngagementDate,
    Safeguarding? safeguarding,
    String? finalNotes,
    List<String>? photoPaths,
    List<String>? videoPaths,
    List<String>? documentPaths,
    List<String>? attendanceSheetPaths,
    List<String>? financialDocPaths,
    List<String>? mouPaths,
    List<String>? trackingSheetPaths,
    double? latitude,
    double? longitude,
    String? locationName,
  }) {
    return FieldReport(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      focalPerson: focalPerson ?? this.focalPerson,
      trainingCentre: trainingCentre ?? this.trainingCentre,
      attendance: attendance ?? this.attendance,
      employmentOutcome: employmentOutcome ?? this.employmentOutcome,
      newEnrolmentsMale: newEnrolmentsMale ?? this.newEnrolmentsMale,
      newEnrolmentsFemale: newEnrolmentsFemale ?? this.newEnrolmentsFemale,
      courseEnrolledIn: courseEnrolledIn ?? this.courseEnrolledIn,
      successStory: successStory ?? this.successStory,
      youthVoice: youthVoice ?? this.youthVoice,
      overallRating: overallRating ?? this.overallRating,
      qualityIndicators: qualityIndicators ?? this.qualityIndicators,
      issuesFlagged: issuesFlagged ?? this.issuesFlagged,
      facilitiesAvailable: facilitiesAvailable ?? this.facilitiesAvailable,
      activitiesObserved: activitiesObserved ?? this.activitiesObserved,
      challengesObserved: challengesObserved ?? this.challengesObserved,
      recommendations: recommendations ?? this.recommendations,
      urgencyOfAction: urgencyOfAction ?? this.urgencyOfAction,
      followUpBy: followUpBy ?? this.followUpBy,
      partnerCompanies: partnerCompanies ?? this.partnerCompanies,
      partnerEngagementNotes: partnerEngagementNotes ?? this.partnerEngagementNotes,
      nextPartnerEngagementDate: nextPartnerEngagementDate ?? this.nextPartnerEngagementDate,
      safeguarding: safeguarding ?? this.safeguarding,
      finalNotes: finalNotes ?? this.finalNotes,
      photoPaths: photoPaths ?? this.photoPaths,
      videoPaths: videoPaths ?? this.videoPaths,
      documentPaths: documentPaths ?? this.documentPaths,
      attendanceSheetPaths: attendanceSheetPaths ?? this.attendanceSheetPaths,
      financialDocPaths: financialDocPaths ?? this.financialDocPaths,
      mouPaths: mouPaths ?? this.mouPaths,
      trackingSheetPaths: trackingSheetPaths ?? this.trackingSheetPaths,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
    );
  }
}
