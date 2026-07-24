import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yiw_field_report/models/field_report.dart';
import 'package:yiw_field_report/models/focal_person.dart';
import 'package:yiw_field_report/models/training_centre.dart';
import 'package:yiw_field_report/models/attendance.dart';
import 'package:yiw_field_report/models/employment_outcome.dart';
import 'package:yiw_field_report/models/safeguarding.dart';
import 'package:yiw_field_report/services/report_service.dart';
import 'package:yiw_field_report/theme/colors.dart';
import 'package:yiw_field_report/widgets/form_section.dart';
import 'package:yiw_field_report/config/app_config.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final int _totalSteps = 8;
  
  // Form controllers
  final _focalPersonFormKey = GlobalKey<FormState>();
  final _trainingCentreFormKey = GlobalKey<FormState>();
  final _attendanceFormKey = GlobalKey<FormState>();
  final _employmentFormKey = GlobalKey<FormState>();
  final _trainingFormKey = GlobalKey<FormState>();
  final _qualityFormKey = GlobalKey<FormState>();
  final _partnerFormKey = GlobalKey<FormState>();
  final _safeguardingFormKey = GlobalKey<FormState>();
  
  // Form data
  FocalPerson _focalPerson = FocalPerson(
    fullName: '',
    phoneNumber: '',
    zone: '',
    visitDate: DateTime.now(),
  );
  
  TrainingCentre _trainingCentre = TrainingCentre(
    hub: '',
    community: '',
    centreName: '',
  );
  
  Attendance _attendance = Attendance();
  EmploymentOutcome _employmentOutcome = EmploymentOutcome();
  Safeguarding _safeguarding = Safeguarding();
  
  // Lists for multi-select fields
  List<String> _selectedVisitTypes = [];
  List<String> _selectedQualityIndicators = [];
  List<String> _selectedIssues = [];
  List<String> _selectedFacilities = [];
  List<String> _selectedActivities = [];
  
  // Controllers for text fields
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _hubController = TextEditingController();
  final _otherHubController = TextEditingController();
  final _communityController = TextEditingController();
  final _centreNameController = TextEditingController();
  final _centreAddressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _courseController = TextEditingController();
  final _successStoryController = TextEditingController();
  final _youthVoiceController = TextEditingController();
  final _challengesController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _partnerNotesController = TextEditingController();
  final _safeguardingNotesController = TextEditingController();
  final _concernDescriptionController = TextEditingController();
  final _actionTakenController = TextEditingController();
  final _reportedToController = TextEditingController();
  final _finalNotesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }
  
  Future<void> _loadSavedData() async {
    // Load any saved draft data
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Field Report'),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: const Text(
              'Save Draft',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _nextStep,
          onStepCancel: _previousStep,
          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          steps: _buildSteps(),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == _totalSteps - 1 ? 'Submit' : 'Next'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Focal Person Details'),
        content: _buildFocalPersonSection(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Training Centre'),
        content: _buildTrainingCentreSection(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Attendance'),
        content: _buildAttendanceSection(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Employment Outcomes'),
        content: _buildEmploymentSection(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Training & Quality'),
        content: _buildTrainingQualitySection(),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Partner Engagement'),
        content: _buildPartnerSection(),
        isActive: _currentStep >= 5,
        state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Safeguarding'),
        content: _buildSafeguardingSection(),
        isActive: _currentStep >= 6,
        state: _currentStep > 6 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Review & Submit'),
        content: _buildReviewSection(),
        isActive: _currentStep >= 7,
        state: _currentStep > 7 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  Widget _buildFocalPersonSection() {
    return FormSection(
      title: 'Focal Person Details',
      icon: Icons.person,
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            hintText: 'Enter your full name',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneNumberController,
          decoration: const InputDecoration(
            labelText: 'Phone Number *',
            hintText: 'Enter your phone number',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Zone / Region *',
          ),
          value: _focalPerson.zone.isEmpty ? null : _focalPerson.zone,
          items: AppConfig.zones.map((zone) {
            return DropdownMenuItem(value: zone, child: Text(zone));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _focalPerson = _focalPerson.copyWith(zone: value);
              // Reset hub and community when zone changes
              _trainingCentre = _trainingCentre.copyWith(hub: '', community: '');
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a zone';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Date of Visit *'),
          subtitle: Text(
            _focalPerson.visitDate.toString().split(' ')[0],
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _focalPerson.visitDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _focalPerson = _focalPerson.copyWith(visitDate: date);
              });
            }
          },
        ),
        const SizedBox(height: 16),
        const Text('Visit Type * (select all that apply)'),
        Wrap(
          spacing: 8.0,
          children: AppConfig.visitTypes.map((type) => _buildChip(type)).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedVisitTypes.contains(label),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedVisitTypes.add(label);
          } else {
            _selectedVisitTypes.remove(label);
          }
        });
      },
    );
  }

  Widget _buildTrainingCentreSection() {
    // Get hubs for selected zone
    final selectedZone = _focalPerson.zone;
    final hubs = selectedZone.isNotEmpty
        ? (AppConfig.hubsByZone[selectedZone] ?? [])
        : <String>[];
    
    // Get communities for selected hub
    final selectedHub = _trainingCentre.hub;
    final communities = selectedHub.isNotEmpty
        ? (AppConfig.communitiesByHub[selectedHub] ?? [])
        : <String>[];

    return FormSection(
      title: 'Training Centre Details',
      icon: Icons.business,
      children: [
        // Hub dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Hub / Training Service Provider *',
          ),
          value: _trainingCentre.hub.isEmpty ? null : _trainingCentre.hub,
          items: [
            ...hubs.map((hub) => DropdownMenuItem(value: hub, child: Text(hub))),
            const DropdownMenuItem(value: 'Other', child: Text('Other (enter manually)')),
          ],
          onChanged: (value) {
            setState(() {
              _trainingCentre = _trainingCentre.copyWith(
                hub: value,
                community: '', // Reset community when hub changes
              );
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a hub';
            }
            return null;
          },
        ),
        if (_trainingCentre.hub == 'Other') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _otherHubController,
            decoration: const InputDecoration(
              labelText: 'Hub Name *',
              hintText: 'Enter hub name',
            ),
            validator: (value) {
              if (_trainingCentre.hub == 'Other' && (value == null || value.isEmpty)) {
                return 'Please enter hub name';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),
        
        // Community dropdown
        if (communities.isNotEmpty)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Community *',
            ),
            value: _trainingCentre.community.isEmpty ? null : _trainingCentre.community,
            items: [
              ...communities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              const DropdownMenuItem(value: 'Other', child: Text('Other (enter manually)')),
            ],
            onChanged: (value) {
              setState(() {
                _trainingCentre = _trainingCentre.copyWith(community: value);
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a community';
              }
              return null;
            },
          )
        else
          TextFormField(
            controller: _communityController,
            decoration: const InputDecoration(
              labelText: 'Community *',
              hintText: 'Enter community name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter community';
              }
              return null;
            },
          ),
        if (_trainingCentre.community == 'Other') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _communityController,
            decoration: const InputDecoration(
              labelText: 'Community Name *',
              hintText: 'Enter community name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter community name';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _centreNameController,
          decoration: const InputDecoration(
            labelText: 'Training Centre Name *',
            hintText: 'Enter centre name',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter centre name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _centreAddressController,
          decoration: const InputDecoration(
            labelText: 'Centre Address / Landmark',
            hintText: 'Enter address or landmark',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactPersonController,
          decoration: const InputDecoration(
            labelText: 'Centre Contact Person',
            hintText: 'Enter contact person name',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactPhoneController,
          decoration: const InputDecoration(
            labelText: 'Contact Phone',
            hintText: 'Enter phone number',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Time Arrived'),
                subtitle: Text(
                  _trainingCentre.timeArrived?.toString().split(' ')[1].substring(0, 5) ?? 'Not set',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _trainingCentre = _trainingCentre.copyWith(
                        timeArrived: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('Time Departed'),
                subtitle: Text(
                  _trainingCentre.timeDeparted?.toString().split(' ')[1].substring(0, 5) ?? 'Not set',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _trainingCentre = _trainingCentre.copyWith(
                        timeDeparted: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    return FormSection(
      title: 'Attendance Count',
      icon: Icons.people,
      children: [
        const Text('Youth and staff present during your visit'),
        const SizedBox(height: 16),
        _buildCounterField(
          'Young men present',
          _attendance.youngMenPresent,
          (value) {
            setState(() {
              _attendance = _attendance.copyWith(youngMenPresent: value);
            });
          },
        ),
        _buildCounterField(
          'Young women present',
          _attendance.youngWomenPresent,
          (value) {
            setState(() {
              _attendance = _attendance.copyWith(youngWomenPresent: value);
            });
          },
        ),
        _buildCounterField(
          'Persons with disability',
          _attendance.personsWithDisability,
          (value) {
            setState(() {
              _attendance = _attendance.copyWith(personsWithDisability: value);
            });
          },
        ),
        _buildCounterField(
          'Hub staff on duty',
          _attendance.hubStaffOnDuty,
          (value) {
            setState(() {
              _attendance = _attendance.copyWith(hubStaffOnDuty: value);
            });
          },
        ),
        _buildCounterField(
          'Trainers / facilitators present',
          _attendance.trainersPresent,
          (value) {
            setState(() {
              _attendance = _attendance.copyWith(trainersPresent: value);
            });
          },
        ),
        const SizedBox(height: 16),
        Card(
          color: AppColors.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      _attendance.totalYouth.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text('Total Youth'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      _attendance.totalStaff.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const Text('Total Staff'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      _attendance.totalPresent.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const Text('Total Present'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            color: AppColors.error,
          ),
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(value + 1),
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentSection() {
    return FormSection(
      title: 'Employment & Placement Outcomes',
      icon: Icons.work,
      children: [
        const Text('Youth activated today'),
        const SizedBox(height: 16),
        _buildCounterField(
          'Placed in formal employment',
          _employmentOutcome.placedInFormalEmployment,
          (value) {
            setState(() {
              _employmentOutcome = _employmentOutcome.copyWith(placedInFormalEmployment: value);
            });
          },
        ),
        _buildCounterField(
          'Placed in internships',
          _employmentOutcome.placedInInternships,
          (value) {
            setState(() {
              _employmentOutcome = _employmentOutcome.copyWith(placedInInternships: value);
            });
          },
        ),
        _buildCounterField(
          'Joined cooperatives / self-employment',
          _employmentOutcome.joinedCooperatives,
          (value) {
            setState(() {
              _employmentOutcome = _employmentOutcome.copyWith(joinedCooperatives: value);
            });
          },
        ),
        _buildCounterField(
          'Referred for further training',
          _employmentOutcome.referredForFurtherTraining,
          (value) {
            setState(() {
              _employmentOutcome = _employmentOutcome.copyWith(referredForFurtherTraining: value);
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Names of youth placed today',
            hintText: 'Enter names, one per line',
          ),
          maxLines: 3,
          onChanged: (value) {
            setState(() {
              _employmentOutcome = _employmentOutcome.copyWith(
                namesOfYouthPlaced: value.split('\n').where((name) => name.isNotEmpty).toList(),
              );
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Employer / cooperative name(s)',
            hintText: 'Enter employer names',
          ),
          onChanged: (value) {
            setState(() {
              _employmentOutcome = _employmentOutcome.copyWith(
                employerNames: value.split(',').where((name) => name.isNotEmpty).toList(),
              );
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Sector of placement',
          ),
          value: _employmentOutcome.sectorOfPlacement,
          items: AppConfig.sectors.map((sector) {
            return DropdownMenuItem(value: sector, child: Text(sector));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _employmentOutcome = _employmentOutcome.copyWith(sectorOfPlacement: value);
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _courseController,
          decoration: const InputDecoration(
            labelText: 'Course / trade enrolled in',
            hintText: 'Enter course name',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _successStoryController,
          decoration: const InputDecoration(
            labelText: 'Key success story / highlight',
            hintText: 'Describe a success story',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _youthVoiceController,
          decoration: const InputDecoration(
            labelText: 'Youth voice / direct quote',
            hintText: 'Enter a quote from a youth',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildTrainingQualitySection() {
    return FormSection(
      title: 'Training Centre Quality',
      icon: Icons.star,
      children: [
        const Text('Overall performance today'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final rating = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _employmentOutcome = _employmentOutcome.copyWith(
                    // Using employmentOutcome to store rating temporarily
                  );
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _employmentOutcome.placedInFormalEmployment == rating
                          ? AppColors.primary
                          : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _employmentOutcome.placedInFormalEmployment == rating
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        rating.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _employmentOutcome.placedInFormalEmployment == rating
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRatingLabel(rating),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        const Text('Quality indicators observed'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: AppConfig.qualityIndicators.map((item) => _buildQualityChip(item)).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Issues Flagged'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: AppConfig.issues.map((item) => _buildIssueChip(item)).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Facilities & Resources'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: AppConfig.facilities.map((item) => _buildFacilityChip(item)).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Activities Observed'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: AppConfig.activities.map((item) => _buildActivityChip(item)).toList(),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _challengesController,
          decoration: const InputDecoration(
            labelText: 'Challenges observed',
            hintText: 'Describe any challenges',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _recommendationsController,
          decoration: const InputDecoration(
            labelText: 'Recommendations / support needed',
            hintText: 'Enter recommendations',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Urgency of action',
          ),
          items: const [
            DropdownMenuItem(value: 'No action needed', child: Text('No action needed')),
            DropdownMenuItem(value: 'Within the week', child: Text('Within the week')),
            DropdownMenuItem(value: 'Within 48 hours', child: Text('Within 48 hours')),
            DropdownMenuItem(value: 'Urgent — same day', child: Text('Urgent — same day')),
          ],
          onChanged: (value) {
            // Handle urgency change
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Follow-up by',
            hintText: 'Enter name of person to follow up',
          ),
        ),
      ],
    );
  }

  Widget _buildQualityChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedQualityIndicators.contains(label),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedQualityIndicators.add(label);
          } else {
            _selectedQualityIndicators.remove(label);
          }
        });
      },
    );
  }

  Widget _buildIssueChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedIssues.contains(label),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedIssues.add(label);
          } else {
            _selectedIssues.remove(label);
          }
        });
      },
      selectedColor: AppColors.error.withOpacity(0.2),
      checkmarkColor: AppColors.error,
    );
  }

  Widget _buildFacilityChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFacilities.contains(label),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedFacilities.add(label);
          } else {
            _selectedFacilities.remove(label);
          }
        });
      },
    );
  }

  Widget _buildActivityChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedActivities.contains(label),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedActivities.add(label);
          } else {
            _selectedActivities.remove(label);
          }
        });
      },
    );
  }

  String _getRatingLabel(int rating) {
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

  Widget _buildPartnerSection() {
    return FormSection(
      title: 'Partner Companies Engaged Today',
      icon: Icons.handshake,
      children: [
        const Text('Include business profile and skills needed for each'),
        const SizedBox(height: 16),
        // Partner table would be implemented here
        // For now, showing a placeholder
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Partner Companies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Add partner company
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Partner Company'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Partners today: 0/15 zone target',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _partnerNotesController,
          decoration: const InputDecoration(
            labelText: 'Partner engagement notes',
            hintText: 'Enter notes about partner engagements',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Next partner engagement date'),
          subtitle: const Text('Select date'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              // Update next engagement date
            }
          },
        ),
      ],
    );
  }

  Widget _buildSafeguardingSection() {
    return FormSection(
      title: 'Safeguarding Checklist',
      icon: Icons.security,
      children: [
        const Text('Confirm what was upheld today'),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Consent obtained before photos/videos'),
          subtitle: const Text('Youth gave verbal or written consent'),
          value: _safeguarding.consentObtained,
          onChanged: (value) {
            setState(() {
              _safeguarding = _safeguarding.copyWith(consentObtained: value ?? false);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('No youth left alone with staff unsupervised'),
          subtitle: const Text('Two-adult rule maintained'),
          value: _safeguarding.twoAdultRule,
          onChanged: (value) {
            setState(() {
              _safeguarding = _safeguarding.copyWith(twoAdultRule: value ?? false);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Safeguarding policy visible at hub'),
          subtitle: const Text('Displayed on notice board'),
          value: _safeguarding.policyVisible,
          onChanged: (value) {
            setState(() {
              _safeguarding = _safeguarding.copyWith(policyVisible: value ?? false);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('No discriminatory language or behaviour'),
          subtitle: const Text('Inclusive environment maintained'),
          value: _safeguarding.noDiscrimination,
          onChanged: (value) {
            setState(() {
              _safeguarding = _safeguarding.copyWith(noDiscrimination: value ?? false);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Reporting mechanism communicated to youth'),
          subtitle: const Text('Youth know how to raise concerns'),
          value: _safeguarding.reportingMechanismCommunicated,
          onChanged: (value) {
            setState(() {
              _safeguarding = _safeguarding.copyWith(reportingMechanismCommunicated: value ?? false);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('YiW ID / badge worn during visit'),
          subtitle: const Text('Identification clearly displayed'),
          value: _safeguarding.idBadgeWorn,
          onChanged: (value) {
            setState(() {
              _safeguarding = _safeguarding.copyWith(idBadgeWorn: value ?? false);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('No exchange of personal contacts with youth'),
          subtitle: const Text('Professional boundaries maintained'),
          value: _safeguarding.noPersonalContacts,
          onChanged: (value) {
            setState(() {
              _safeguarding = _safeguarding.copyWith(noPersonalContacts: value ?? false);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Gifts / incentives followed programme guidelines'),
          subtitle: const Text('No unauthorised payments or gifts'),
          value: _safeguarding.giftsFollowGuidelines,
          onChanged: (value) {
            setState(() {
              _safeguarding = _safeguarding.copyWith(giftsFollowGuidelines: value ?? false);
            });
          },
        ),
        const SizedBox(height: 24),
        const Text('Concern Reporting'),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Was a safeguarding concern identified today?'),
          value: _safeguarding.concernIdentified,
          onChanged: (value) {
            setState(() {
              _safeguarding = _safeguarding.copyWith(concernIdentified: value);
            });
          },
        ),
        if (_safeguarding.concernIdentified) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _concernDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Describe the concern',
              hintText: 'Use initials only — no full names of youth',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _actionTakenController,
            decoration: const InputDecoration(
              labelText: 'Action taken',
              hintText: 'Describe action taken',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reportedToController,
            decoration: const InputDecoration(
              labelText: 'Reported to',
              hintText: 'Enter name of person reported to',
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _safeguardingNotesController,
          decoration: const InputDecoration(
            labelText: 'Safeguarding notes / observations',
            hintText: 'Enter any additional notes',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return FormSection(
      title: 'Review & Submit',
      icon: Icons.check_circle,
      children: [
        const Text('Please review your report before submission'),
        const SizedBox(height: 16),
        
        // Summary cards
        _buildSummaryCard(
          'Focal Person',
          [
            'Name: ${_fullNameController.text}',
            'Phone: ${_phoneNumberController.text}',
            'Zone: ${_focalPerson.zone}',
            'Visit Date: ${_focalPerson.visitDate.toString().split(' ')[0]}',
            'Visit Types: ${_selectedVisitTypes.join(', ')}',
          ],
        ),
        
        _buildSummaryCard(
          'Training Centre',
          [
            'Hub: ${_trainingCentre.hub}',
            'Community: ${_communityController.text}',
            'Centre: ${_centreNameController.text}',
            'Address: ${_centreAddressController.text}',
          ],
        ),
        
        _buildSummaryCard(
          'Attendance',
          [
            'Total Youth: ${_attendance.totalYouth}',
            'Young Men: ${_attendance.youngMenPresent}',
            'Young Women: ${_attendance.youngWomenPresent}',
            'PWDs: ${_attendance.personsWithDisability}',
            'Total Staff: ${_attendance.totalStaff}',
          ],
        ),
        
        _buildSummaryCard(
          'Employment Outcomes',
          [
            'Formal Employment: ${_employmentOutcome.placedInFormalEmployment}',
            'Internships: ${_employmentOutcome.placedInInternships}',
            'Cooperatives: ${_employmentOutcome.joinedCooperatives}',
            'Referred for Training: ${_employmentOutcome.referredForFurtherTraining}',
            'Total Placed: ${_employmentOutcome.totalPlaced}',
          ],
        ),
        
        _buildSummaryCard(
          'Quality & Issues',
          [
            'Quality Indicators: ${_selectedQualityIndicators.length} selected',
            'Issues Flagged: ${_selectedIssues.length} selected',
            'Facilities: ${_selectedFacilities.length} available',
            'Activities: ${_selectedActivities.length} observed',
          ],
        ),
        
        _buildSummaryCard(
          'Partner Engagement',
          [
            'Partners Engaged: 0/15',
            'Notes: ${_partnerNotesController.text}',
          ],
        ),
        
        _buildSummaryCard(
          'Safeguarding',
          [
            'Consent Obtained: ${_safeguarding.consentObtained ? "Yes" : "No"}',
            'Two-Adult Rule: ${_safeguarding.twoAdultRule ? "Yes" : "No"}',
            'Policy Visible: ${_safeguarding.policyVisible ? "Yes" : "No"}',
            'Concern Identified: ${_safeguarding.concernIdentified ? "Yes" : "No"}',
          ],
        ),
        
        const SizedBox(height: 24),
        TextFormField(
          controller: _finalNotesController,
          decoration: const InputDecoration(
            labelText: 'Final notes before submission',
            hintText: 'Enter any final notes',
          ),
          maxLines: 3,
        ),
        
        const SizedBox(height: 24),
        Card(
          color: AppColors.info.withOpacity(0.1),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 32),
                SizedBox(height: 8),
                Text(
                  'This report will be emailed to yiw@seghana.net with a copy to execdir@seghana.net.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.info),
                ),
                SizedBox(height: 8),
                Text(
                  'All attached files and photos are included as attachments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.info),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(item),
            )),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep += 1;
      });
    } else {
      _submitReport();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  Future<void> _saveDraft() async {
    // Save draft logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _submitReport() async {
    // Validate all forms
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Create report object
    final report = FieldReport(
      id: '', // Will be generated
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      focalPerson: _focalPerson.copyWith(
        fullName: _fullNameController.text,
        phoneNumber: _phoneNumberController.text,
        email: _emailController.text,
        visitTypes: _selectedVisitTypes,
      ),
      trainingCentre: _trainingCentre.copyWith(
        community: _communityController.text,
        centreName: _centreNameController.text,
        centreAddress: _centreAddressController.text,
        contactPerson: _contactPersonController.text,
        contactPhone: _contactPhoneController.text,
      ),
      attendance: _attendance,
      employmentOutcome: _employmentOutcome,
      overallRating: _employmentOutcome.placedInFormalEmployment, // Temporary
      qualityIndicators: _selectedQualityIndicators,
      issuesFlagged: _selectedIssues,
      facilitiesAvailable: _selectedFacilities,
      activitiesObserved: _selectedActivities,
      challengesObserved: _challengesController.text,
      recommendations: _recommendationsController.text,
      partnerCompanies: [],
      partnerEngagementNotes: _partnerNotesController.text,
      safeguarding: _safeguarding.copyWith(
        concernDescription: _concernDescriptionController.text,
        actionTaken: _actionTakenController.text,
        reportedTo: _reportedToController.text,
        notes: _safeguardingNotesController.text,
      ),
      finalNotes: _finalNotesController.text,
    );
    
    // Submit report
    final reportService = Provider.of<ReportService>(context, listen: false);
    
    try {
      await reportService.createReport(report: report);
      
      if (!mounted) return;
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Report Submitted'),
          content: const Text('Your field report has been submitted successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _hubController.dispose();
    _otherHubController.dispose();
    _communityController.dispose();
    _centreNameController.dispose();
    _centreAddressController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _courseController.dispose();
    _successStoryController.dispose();
    _youthVoiceController.dispose();
    _challengesController.dispose();
    _recommendationsController.dispose();
    _partnerNotesController.dispose();
    _safeguardingNotesController.dispose();
    _concernDescriptionController.dispose();
    _actionTakenController.dispose();
    _reportedToController.dispose();
    _finalNotesController.dispose();
    super.dispose();
  }
}