class AppConfig {
  // App Information
  static const String appName = 'YiW Field Report';
  static const String appVersion = '1.0.0';

  // Email Recipients
  static const String ceoEmail = 'execdir@seghana.net';
  static const String yiwEmail = 'yiw@seghana.net';

  // Zones
  static const List<String> zones = [
    'Greater Accra',
    'Ashanti',
    'Northern',
    'Western',
    'Central',
    'Eastern',
    'Volta',
    'Upper East',
    'Upper West',
    'Bono',
    'Bono East',
    'Savannah',
    'Oti',
    'Ahafo',
    'North East',
    'Western North',
  ];

  // Hub/Training Service Providers by Zone
  static const Map<String, List<String>> hubsByZone = {
    'Greater Accra': [
      'Accra Technical University',
    ],
    'Ashanti': [
      'Kumasi City Incubation Hub',
    ],
    'Northern': [
      'AfriTech Hub',
      'The Assistance Hub',
      'Afrik Shea Butter',
    ],
    'Western': [
      'Duapa Werkspace',
    ],
    'Central': [],
    'Eastern': [
      'Agritech',
      'Qet Farms',
    ],
    'Volta': [
      'Sabon Sake',
    ],
    'Upper East': [
      'Dansyn ISO',
    ],
    'Upper West': [
      'Noni Hub',
    ],
    'Bono': [],
    'Bono East': [
      'Agrico Hub',
    ],
    'Savannah': [],
    'Oti': [],
    'Ahafo': [
      'Ketiwa Enterprise',
    ],
    'North East': [
      'Innovation Light LGB',
      'Northern Innovation Lab Foundation',
    ],
    'Western North': [
      'Rutab Hub',
    ],
  };

  // Communities by Hub
  static const Map<String, List<String>> communitiesByHub = {
    'Accra Technical University': ['ATU Campus', 'Accra Central'],
    'Kumasi City Incubation Hub': ['Boadi'],
    'AfriTech Hub': ['Gbanyamni'],
    'The Assistance Hub': ['Kanvili', 'Kanvili (Jana)'],
    'Afrik Shea Butter': ['Sakasaka'],
    'Duapa Werkspace': ['Takoradi', 'Anaji', 'Takoradi, Anaji'],
    'Agritech': ['Teacher Mante'],
    'Qet Farms': ['Mame Dede'],
    'Sabon Sake': ['Sogakope', 'Sogakope, Dabala'],
    'Dansyn ISO': ['Bolgatanga'],
    'Noni Hub': ['Wa'],
    'Agrico Hub': ['Techiman'],
    'Ketiwa Enterprise': ['Goaso'],
    'Innovation Light LGB': ['Gambaga'],
    'Northern Innovation Lab Foundation': ['Nasia'],
    'Rutab Hub': ['Kesekrom'],
  };

  // Visit Types
  static const List<String> visitTypes = [
    'Routine monitoring',
    'Training supervision',
    'Document collection',
    'Partner engagement',
    'Youth activation',
    'Troubleshooting / support',
    'Attendance data collection',
    'MoU signing',
    'Desk search',
  ];

  // Quality Indicators
  static const List<String> qualityIndicators = [
    'Training ongoing as scheduled',
    'Trainers present and prepared',
    'Participants engaged and attentive',
    'Course content displayed / visible',
    'Training materials available',
    'IDs / registration checked',
    'Attendance sheet in use',
    'Hub clean and safe',
  ];

  // Issues
  static const List<String> issues = [
    'No trainer present',
    'Training not following curriculum',
    'Attendance not being recorded',
    'Low youth attendance (<50%)',
    'Equipment failure / unavailable',
    'Safety hazard identified',
    'Participant misconduct',
    'Staff demanding payment from youth',
    'Financial irregularity noted',
    'Hub premises unsafe',
  ];

  // Facilities
  static const List<String> facilities = [
    'Internet / Wi-Fi',
    'Computers / tablets',
    'Projector / display',
    'Power / electricity',
    'Clean water',
    'Sanitation / toilets',
    'Training room available',
    'Notice board updated',
    'First aid kit',
    'Fire safety equipment',
  ];

  // Activities
  static const List<String> activities = [
    'Technical skills training',
    'Entrepreneurship session',
    'CV & job readiness',
    'Mentorship / coaching',
    'Employer talk / industry visit',
    'Group work / project',
    'Assessment / exam',
    'Sports / wellness',
  ];

  // Sectors
  static const List<String> sectors = [
    'Agriculture / Agribusiness',
    'ICT / Digital',
    'Manufacturing',
    'Construction / Trade',
    'Financial services',
    'Health / Care',
    'Education / Training',
    'Hospitality / Tourism',
    'Creative industries',
    'Other',
  ];
}
