class TrainingCentre {
  final String hub;
  final String? otherHubName;
  final String community;
  final String centreName;
  final String? centreAddress;
  final String? contactPerson;
  final String? contactPhone;
  final DateTime? timeArrived;
  final DateTime? timeDeparted;

  TrainingCentre({
    required this.hub,
    this.otherHubName,
    required this.community,
    required this.centreName,
    this.centreAddress,
    this.contactPerson,
    this.contactPhone,
    this.timeArrived,
    this.timeDeparted,
  });

  factory TrainingCentre.fromJson(Map<String, dynamic> json) {
    return TrainingCentre(
      hub: json['hub'] ?? '',
      otherHubName: json['otherHubName'],
      community: json['community'] ?? '',
      centreName: json['centreName'] ?? '',
      centreAddress: json['centreAddress'],
      contactPerson: json['contactPerson'],
      contactPhone: json['contactPhone'],
      timeArrived: json['timeArrived'] != null ? DateTime.parse(json['timeArrived']) : null,
      timeDeparted: json['timeDeparted'] != null ? DateTime.parse(json['timeDeparted']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hub': hub,
      'otherHubName': otherHubName,
      'community': community,
      'centreName': centreName,
      'centreAddress': centreAddress,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'timeArrived': timeArrived?.toIso8601String(),
      'timeDeparted': timeDeparted?.toIso8601String(),
    };
  }

  TrainingCentre copyWith({
    String? hub,
    String? otherHubName,
    String? community,
    String? centreName,
    String? centreAddress,
    String? contactPerson,
    String? contactPhone,
    DateTime? timeArrived,
    DateTime? timeDeparted,
  }) {
    return TrainingCentre(
      hub: hub ?? this.hub,
      otherHubName: otherHubName ?? this.otherHubName,
      community: community ?? this.community,
      centreName: centreName ?? this.centreName,
      centreAddress: centreAddress ?? this.centreAddress,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      timeArrived: timeArrived ?? this.timeArrived,
      timeDeparted: timeDeparted ?? this.timeDeparted,
    );
  }
}
