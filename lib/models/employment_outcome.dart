class EmploymentOutcome {
  final int youthActivatedToday;
  final int placedInFormalEmployment;
  final int placedInInternships;
  final int joinedCooperatives;
  final int referredForFurtherTraining;
  final List<String> namesOfYouthPlaced;
  final List<String> employerNames;
  final String? sectorOfPlacement;

  EmploymentOutcome({
    this.youthActivatedToday = 0,
    this.placedInFormalEmployment = 0,
    this.placedInInternships = 0,
    this.joinedCooperatives = 0,
    this.referredForFurtherTraining = 0,
    this.namesOfYouthPlaced = const [],
    this.employerNames = const [],
    this.sectorOfPlacement,
  });

  factory EmploymentOutcome.fromJson(Map<String, dynamic> json) {
    return EmploymentOutcome(
      youthActivatedToday: json['youthActivatedToday'] ?? 0,
      placedInFormalEmployment: json['placedInFormalEmployment'] ?? 0,
      placedInInternships: json['placedInInternships'] ?? 0,
      joinedCooperatives: json['joinedCooperatives'] ?? 0,
      referredForFurtherTraining: json['referredForFurtherTraining'] ?? 0,
      namesOfYouthPlaced: List<String>.from(json['namesOfYouthPlaced'] ?? []),
      employerNames: List<String>.from(json['employerNames'] ?? []),
      sectorOfPlacement: json['sectorOfPlacement'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'youthActivatedToday': youthActivatedToday,
      'placedInFormalEmployment': placedInFormalEmployment,
      'placedInInternships': placedInInternships,
      'joinedCooperatives': joinedCooperatives,
      'referredForFurtherTraining': referredForFurtherTraining,
      'namesOfYouthPlaced': namesOfYouthPlaced,
      'employerNames': employerNames,
      'sectorOfPlacement': sectorOfPlacement,
    };
  }

  int get totalPlaced => placedInFormalEmployment + placedInInternships + joinedCooperatives;

  EmploymentOutcome copyWith({
    int? youthActivatedToday,
    int? placedInFormalEmployment,
    int? placedInInternships,
    int? joinedCooperatives,
    int? referredForFurtherTraining,
    List<String>? namesOfYouthPlaced,
    List<String>? employerNames,
    String? sectorOfPlacement,
  }) {
    return EmploymentOutcome(
      youthActivatedToday: youthActivatedToday ?? this.youthActivatedToday,
      placedInFormalEmployment: placedInFormalEmployment ?? this.placedInFormalEmployment,
      placedInInternships: placedInInternships ?? this.placedInInternships,
      joinedCooperatives: joinedCooperatives ?? this.joinedCooperatives,
      referredForFurtherTraining: referredForFurtherTraining ?? this.referredForFurtherTraining,
      namesOfYouthPlaced: namesOfYouthPlaced ?? this.namesOfYouthPlaced,
      employerNames: employerNames ?? this.employerNames,
      sectorOfPlacement: sectorOfPlacement ?? this.sectorOfPlacement,
    );
  }
}
