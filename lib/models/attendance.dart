class Attendance {
  final int youngMenPresent;
  final int youngWomenPresent;
  final int personsWithDisability;
  final int hubStaffOnDuty;
  final int trainersPresent;

  Attendance({
    this.youngMenPresent = 0,
    this.youngWomenPresent = 0,
    this.personsWithDisability = 0,
    this.hubStaffOnDuty = 0,
    this.trainersPresent = 0,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      youngMenPresent: json['youngMenPresent'] ?? 0,
      youngWomenPresent: json['youngWomenPresent'] ?? 0,
      personsWithDisability: json['personsWithDisability'] ?? 0,
      hubStaffOnDuty: json['hubStaffOnDuty'] ?? 0,
      trainersPresent: json['trainersPresent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'youngMenPresent': youngMenPresent,
      'youngWomenPresent': youngWomenPresent,
      'personsWithDisability': personsWithDisability,
      'hubStaffOnDuty': hubStaffOnDuty,
      'trainersPresent': trainersPresent,
    };
  }

  int get totalYouth => youngMenPresent + youngWomenPresent;
  int get totalStaff => hubStaffOnDuty + trainersPresent;
  int get totalPresent => totalYouth + totalStaff;

  Attendance copyWith({
    int? youngMenPresent,
    int? youngWomenPresent,
    int? personsWithDisability,
    int? hubStaffOnDuty,
    int? trainersPresent,
  }) {
    return Attendance(
      youngMenPresent: youngMenPresent ?? this.youngMenPresent,
      youngWomenPresent: youngWomenPresent ?? this.youngWomenPresent,
      personsWithDisability: personsWithDisability ?? this.personsWithDisability,
      hubStaffOnDuty: hubStaffOnDuty ?? this.hubStaffOnDuty,
      trainersPresent: trainersPresent ?? this.trainersPresent,
    );
  }
}
