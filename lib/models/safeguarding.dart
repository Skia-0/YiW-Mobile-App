class Safeguarding {
  final bool consentObtained;
  final bool twoAdultRule;
  final bool policyVisible;
  final bool noDiscrimination;
  final bool reportingMechanismCommunicated;
  final bool idBadgeWorn;
  final bool noPersonalContacts;
  final bool giftsFollowGuidelines;
  final bool concernIdentified;
  final String? concernDescription;
  final String? actionTaken;
  final String? reportedTo;
  final String? notes;

  Safeguarding({
    this.consentObtained = false,
    this.twoAdultRule = false,
    this.policyVisible = false,
    this.noDiscrimination = false,
    this.reportingMechanismCommunicated = false,
    this.idBadgeWorn = false,
    this.noPersonalContacts = false,
    this.giftsFollowGuidelines = false,
    this.concernIdentified = false,
    this.concernDescription,
    this.actionTaken,
    this.reportedTo,
    this.notes,
  });

  factory Safeguarding.fromJson(Map<String, dynamic> json) {
    return Safeguarding(
      consentObtained: json['consentObtained'] ?? false,
      twoAdultRule: json['twoAdultRule'] ?? false,
      policyVisible: json['policyVisible'] ?? false,
      noDiscrimination: json['noDiscrimination'] ?? false,
      reportingMechanismCommunicated: json['reportingMechanismCommunicated'] ?? false,
      idBadgeWorn: json['idBadgeWorn'] ?? false,
      noPersonalContacts: json['noPersonalContacts'] ?? false,
      giftsFollowGuidelines: json['giftsFollowGuidelines'] ?? false,
      concernIdentified: json['concernIdentified'] ?? false,
      concernDescription: json['concernDescription'],
      actionTaken: json['actionTaken'],
      reportedTo: json['reportedTo'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consentObtained': consentObtained,
      'twoAdultRule': twoAdultRule,
      'policyVisible': policyVisible,
      'noDiscrimination': noDiscrimination,
      'reportingMechanismCommunicated': reportingMechanismCommunicated,
      'idBadgeWorn': idBadgeWorn,
      'noPersonalContacts': noPersonalContacts,
      'giftsFollowGuidelines': giftsFollowGuidelines,
      'concernIdentified': concernIdentified,
      'concernDescription': concernDescription,
      'actionTaken': actionTaken,
      'reportedTo': reportedTo,
      'notes': notes,
    };
  }

  Safeguarding copyWith({
    bool? consentObtained,
    bool? twoAdultRule,
    bool? policyVisible,
    bool? noDiscrimination,
    bool? reportingMechanismCommunicated,
    bool? idBadgeWorn,
    bool? noPersonalContacts,
    bool? giftsFollowGuidelines,
    bool? concernIdentified,
    String? concernDescription,
    String? actionTaken,
    String? reportedTo,
    String? notes,
  }) {
    return Safeguarding(
      consentObtained: consentObtained ?? this.consentObtained,
      twoAdultRule: twoAdultRule ?? this.twoAdultRule,
      policyVisible: policyVisible ?? this.policyVisible,
      noDiscrimination: noDiscrimination ?? this.noDiscrimination,
      reportingMechanismCommunicated: reportingMechanismCommunicated ?? this.reportingMechanismCommunicated,
      idBadgeWorn: idBadgeWorn ?? this.idBadgeWorn,
      noPersonalContacts: noPersonalContacts ?? this.noPersonalContacts,
      giftsFollowGuidelines: giftsFollowGuidelines ?? this.giftsFollowGuidelines,
      concernIdentified: concernIdentified ?? this.concernIdentified,
      concernDescription: concernDescription ?? this.concernDescription,
      actionTaken: actionTaken ?? this.actionTaken,
      reportedTo: reportedTo ?? this.reportedTo,
      notes: notes ?? this.notes,
    );
  }
}
