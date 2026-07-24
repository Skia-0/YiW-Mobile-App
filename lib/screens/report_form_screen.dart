import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yiw_field_report/models/field_report.dart';
import 'package:yiw_field_report/models/focal_person.dart';
import 'package:yiw_field_report/models/training_centre.dart';
import 'package:yiw_field_report/models/attendance.dart';
import 'package:yiw_field_report/models/employment_outcome.dart';
import 'package:yiw_field_report/models/safeguarding.dart';
import 'package:yiw_field_report/services/report_service.dart';
import 'package:yiw_field_report/services/auth_service.dart';
import 'package:yiw_field_report/theme/colors.dart';
import 'package:yiw_field_report/config/app_config.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;
  
  // Form data
  String _selectedZone = '';
  String _selectedHub = '';
  String _selectedCommunity = '';
  DateTime _visitDate = DateTime.now();
  List<String> _selectedVisitTypes = [];
  
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _centreNameController = TextEditingController();
  final _centreAddressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _communityController = TextEditingController();
  final _otherHubController = TextEditingController();
  
  // Attendance
  int _youngMen = 0;
  int _youngWomen = 0;
  int _pwd = 0;
  int _staff = 0;
  int _trainers = 0;
  
  // Employment
  int _formalJobs = 0;
  int _internships = 0;
  int _cooperatives = 0;
  int _furtherTraining = 0;
  final _employerController = TextEditingController();
  final _courseController = TextEditingController();
  
  // Quality
  int _rating = 0;
  List<String> _selectedQuality = [];
  List<String> _selectedIssues = [];
  List<String> _selectedFacilities = [];
  List<String> _selectedActivities = [];
  final _challengesController = TextEditingController();
  final _recommendationsController = TextEditingController();
  
  // Safeguarding
  bool _consentObtained = false;
  bool _twoAdultRule = false;
  bool _policyVisible = false;
  bool _noDiscrimination = false;
  bool _reportingMechanism = false;
  bool _idBadgeWorn = false;
  bool _noPersonalContacts = false;
  bool _giftsGuidelines = false;
  bool _concernIdentified = false;
  final _concernDescriptionController = TextEditingController();
  
  final _finalNotesController = TextEditingController();
  
  // Time
  TimeOfDay? _timeArrived;
  TimeOfDay? _timeDeparted;

  List<String> _getHubsForZone() {
    return AppConfig.hubsByZone[_selectedZone] ?? [];
  }

  List<String> _getCommunitiesForHub() {
    return AppConfig.communitiesByHub[_selectedHub] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Field Report'),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: const Text('Save Draft', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: _nextStep,
          onStepCancel: _previousStep,
          onStepTapped: (step) => setState(() { _currentStep = step; }),
          steps: _buildSteps(),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(child: OutlinedButton(onPressed: details.onStepCancel, child: const Text('Previous'))),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : details.onStepContinue,
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_currentStep == 7 ? 'Submit' : 'Next'),
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
      Step(title: const Text('Person'), content: _buildPersonSection(), isActive: _currentStep >= 0),
      Step(title: const Text('Centre'), content: _buildCentreSection(), isActive: _currentStep >= 1),
      Step(title: const Text('Attendance'), content: _buildAttendanceSection(), isActive: _currentStep >= 2),
      Step(title: const Text('Employment'), content: _buildEmploymentSection(), isActive: _currentStep >= 3),
      Step(title: const Text('Quality'), content: _buildQualitySection(), isActive: _currentStep >= 4),
      Step(title: const Text('Partners'), content: _buildPartnerSection(), isActive: _currentStep >= 5),
      Step(title: const Text('Safety'), content: _buildSafeguardingSection(), isActive: _currentStep >= 6),
      Step(title: const Text('Review'), content: _buildReviewSection(), isActive: _currentStep >= 7),
    ];
  }

  Widget _buildPersonSection() {
    return Column(
      children: [
        // Row 1: Name and Phone
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name *', hintText: 'Enter full name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone *', hintText: 'Phone number'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 2: Email and Zone
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', hintText: 'Email address'),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Zone *'),
                value: _selectedZone.isEmpty ? null : _selectedZone,
                items: AppConfig.zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                onChanged: (v) => setState(() {
                  _selectedZone = v!;
                  _selectedHub = '';
                  _selectedCommunity = '';
                }),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 3: Date and Visit Type
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Visit Date *'),
                subtitle: Text(_visitDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: _visitDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (date != null) setState(() { _visitDate = date; });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Visit Types
        const Align(alignment: Alignment.centerLeft, child: Text('Visit Type *', style: TextStyle(fontWeight: FontWeight.w500))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: AppConfig.visitTypes.map((type) => FilterChip(
            label: Text(type, style: const TextStyle(fontSize: 12)),
            selected: _selectedVisitTypes.contains(type),
            onSelected: (selected) => setState(() {
              if (selected) _selectedVisitTypes.add(type);
              else _selectedVisitTypes.remove(type);
            }),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCentreSection() {
    final hubs = _getHubsForZone();
    final communities = _getCommunitiesForHub();

    return Column(
      children: [
        // Row 1: Hub and Community
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Hub / TSP *'),
                value: _selectedHub.isEmpty ? null : _selectedHub,
                items: [
                  ...hubs.map((h) => DropdownMenuItem(value: h, child: Text(h, overflow: TextOverflow.ellipsis))),
                  const DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() { _selectedHub = v!; _selectedCommunity = ''; }),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: communities.isNotEmpty
                  ? DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Community *'),
                      value: _selectedCommunity.isEmpty ? null : _selectedCommunity,
                      items: [
                        ...communities.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                        const DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() { _selectedCommunity = v!; }),
                      validator: (v) => v == null ? 'Required' : null,
                    )
                  : TextFormField(
                      controller: _communityController,
                      decoration: const InputDecoration(labelText: 'Community *', hintText: 'Enter community'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 2: Centre Name and Address
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _centreNameController,
                decoration: const InputDecoration(labelText: 'Centre Name *', hintText: 'Training centre name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _centreAddressController,
                decoration: const InputDecoration(labelText: 'Address', hintText: 'Address / landmark'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 3: Contact and Phone
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(labelText: 'Contact Person', hintText: 'Contact name'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(labelText: 'Contact Phone', hintText: 'Phone number'),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 4: Times
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Time Arrived'),
                subtitle: Text(_timeArrived?.format(context) ?? 'Not set'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) setState(() { _timeArrived = time; });
                },
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('Time Departed'),
                subtitle: Text(_timeDeparted?.format(context) ?? 'Not set'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) setState(() { _timeDeparted = time; });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    return Column(
      children: [
        // Row 1: Youth counts
        Row(
          children: [
            Expanded(child: _buildStatCard('Young Men', _youngMen, Colors.green, Icons.male, () => setState(() { _youngMen++; }), () => setState(() { if (_youngMen > 0) _youngMen--; }))),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Young Women', _youngWomen, Colors.pink, Icons.female, () => setState(() { _youngWomen++; }), () => setState(() { if (_youngWomen > 0) _youngWomen--; }))),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('PWD', _pwd, Colors.orange, Icons.accessible, () => setState(() { _pwd++; }), () => setState(() { if (_pwd > 0) _pwd--; }))),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 2: Staff counts
        Row(
          children: [
            Expanded(child: _buildStatCard('Staff', _staff, Colors.blue, Icons.people, () => setState(() { _staff++; }), () => setState(() { if (_staff > 0) _staff--; }))),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Trainers', _trainers, Colors.purple, Icons.school, () => setState(() { _trainers++; }), () => setState(() { if (_trainers > 0) _trainers--; }))),
            const SizedBox(width: 8),
            Expanded(child: Container()), // Empty for alignment
          ],
        ),
        const SizedBox(height: 16),
        
        // Total
        Card(
          color: AppColors.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [Text('${_youngMen + _youngWomen}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)), const Text('Total Youth')]),
                Column(children: [Text('${_staff + _trainers}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary)), const Text('Total Staff')]),
                Column(children: [Text('${_youngMen + _youngWomen + _pwd + _staff + _trainers}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.success)), const Text('Total Present')]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon, VoidCallback onInc, VoidCallback onDec) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color), textAlign: TextAlign.center),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(onTap: onDec, child: Container(padding: const EdgeInsets.all(4), child: Icon(Icons.remove, size: 16, color: color))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color))),
              GestureDetector(onTap: onInc, child: Container(padding: const EdgeInsets.all(4), child: Icon(Icons.add, size: 16, color: color))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Formal Jobs', _formalJobs, Colors.green, Icons.work, () => setState(() { _formalJobs++; }), () => setState(() { if (_formalJobs > 0) _formalJobs--; }))),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Internships', _internships, Colors.blue, Icons.school, () => setState(() { _internships++; }), () => setState(() { if (_internships > 0) _internships--; }))),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Cooperatives', _cooperatives, Colors.orange, Icons.group, () => setState(() { _cooperatives++; }), () => setState(() { if (_cooperatives > 0) _cooperatives--; }))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Further Training', _furtherTraining, Colors.purple, Icons.menu_book, () => setState(() { _furtherTraining++; }), () => setState(() { if (_furtherTraining > 0) _furtherTraining--; }))),
            const SizedBox(width: 8),
            Expanded(child: Container()),
            const SizedBox(width: 8),
            Expanded(child: Container()),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _employerController, decoration: const InputDecoration(labelText: 'Employer / Cooperative', hintText: 'Enter employer name')),
        const SizedBox(height: 12),
        TextFormField(controller: _courseController, decoration: const InputDecoration(labelText: 'Course Enrolled', hintText: 'Enter course name')),
      ],
    );
  }

  Widget _buildQualitySection() {
    return Column(
      children: [
        // Rating
        const Align(alignment: Alignment.centerLeft, child: Text('Overall Rating', style: TextStyle(fontWeight: FontWeight.w500))),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() { _rating = i + 1; }),
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: _rating == i + 1 ? AppColors.primary : AppColors.inputFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _rating == i + 1 ? AppColors.primary : AppColors.border),
              ),
              child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _rating == i + 1 ? Colors.white : AppColors.textPrimary))),
            ),
          )),
        ),
        const SizedBox(height: 16),
        
        // Quality Indicators
        const Align(alignment: Alignment.centerLeft, child: Text('Quality Indicators', style: TextStyle(fontWeight: FontWeight.w500))),
        Wrap(spacing: 6.0, runSpacing: 4.0, children: AppConfig.qualityIndicators.map((item) => FilterChip(
          label: Text(item, style: const TextStyle(fontSize: 11)),
          selected: _selectedQuality.contains(item),
          onSelected: (s) => setState(() { if (s) _selectedQuality.add(item); else _selectedQuality.remove(item); }),
        )).toList()),
        const SizedBox(height: 12),
        
        // Issues
        const Align(alignment: Alignment.centerLeft, child: Text('Issues Flagged', style: TextStyle(fontWeight: FontWeight.w500))),
        Wrap(spacing: 6.0, runSpacing: 4.0, children: AppConfig.issues.map((item) => FilterChip(
          label: Text(item, style: const TextStyle(fontSize: 11)),
          selected: _selectedIssues.contains(item),
          selectedColor: AppColors.error.withOpacity(0.2),
          onSelected: (s) => setState(() { if (s) _selectedIssues.add(item); else _selectedIssues.remove(item); }),
        )).toList()),
        const SizedBox(height: 12),
        
        // Facilities
        const Align(alignment: Alignment.centerLeft, child: Text('Facilities', style: TextStyle(fontWeight: FontWeight.w500))),
        Wrap(spacing: 6.0, runSpacing: 4.0, children: AppConfig.facilities.map((item) => FilterChip(
          label: Text(item, style: const TextStyle(fontSize: 11)),
          selected: _selectedFacilities.contains(item),
          onSelected: (s) => setState(() { if (s) _selectedFacilities.add(item); else _selectedFacilities.remove(item); }),
        )).toList()),
        const SizedBox(height: 12),
        
        // Activities
        const Align(alignment: Alignment.centerLeft, child: Text('Activities', style: TextStyle(fontWeight: FontWeight.w500))),
        Wrap(spacing: 6.0, runSpacing: 4.0, children: AppConfig.activities.map((item) => FilterChip(
          label: Text(item, style: const TextStyle(fontSize: 11)),
          selected: _selectedActivities.contains(item),
          onSelected: (s) => setState(() { if (s) _selectedActivities.add(item); else _selectedActivities.remove(item); }),
        )).toList()),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(child: TextFormField(controller: _challengesController, decoration: const InputDecoration(labelText: 'Challenges', hintText: 'Describe challenges'), maxLines: 2)),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _recommendationsController, decoration: const InputDecoration(labelText: 'Recommendations', hintText: 'Enter recommendations'), maxLines: 2)),
          ],
        ),
      ],
    );
  }

  Widget _buildPartnerSection() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Partner Companies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () { /* Add partner dialog */ },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Partner Company'),
                ),
                const SizedBox(height: 16),
                const Text('Partners today: 0/15 zone target', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafeguardingSection() {
    return Column(
      children: [
        const Align(alignment: Alignment.centerLeft, child: Text('Safeguarding Checklist', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
        const SizedBox(height: 8),
        CheckboxListTile(title: const Text('Consent obtained before photos/videos'), value: _consentObtained, onChanged: (v) => setState(() { _consentObtained = v!; })),
        CheckboxListTile(title: const Text('Two-adult rule maintained'), value: _twoAdultRule, onChanged: (v) => setState(() { _twoAdultRule = v!; })),
        CheckboxListTile(title: const Text('Safeguarding policy visible'), value: _policyVisible, onChanged: (v) => setState(() { _policyVisible = v!; })),
        CheckboxListTile(title: const Text('No discriminatory language'), value: _noDiscrimination, onChanged: (v) => setState(() { _noDiscrimination = v!; })),
        CheckboxListTile(title: const Text('Reporting mechanism communicated'), value: _reportingMechanism, onChanged: (v) => setState(() { _reportingMechanism = v!; })),
        CheckboxListTile(title: const Text('YiW ID badge worn'), value: _idBadgeWorn, onChanged: (v) => setState(() { _idBadgeWorn = v!; })),
        CheckboxListTile(title: const Text('No personal contacts exchanged'), value: _noPersonalContacts, onChanged: (v) => setState(() { _noPersonalContacts = v!; })),
        CheckboxListTile(title: const Text('Gifts followed guidelines'), value: _giftsGuidelines, onChanged: (v) => setState(() { _giftsGuidelines = v!; })),
        const SizedBox(height: 16),
        SwitchListTile(title: const Text('Concern identified?'), value: _concernIdentified, onChanged: (v) => setState(() { _concernIdentified = v; })),
        if (_concernIdentified) ...[
          const SizedBox(height: 8),
          TextFormField(controller: _concernDescriptionController, decoration: const InputDecoration(labelText: 'Describe concern', hintText: 'Use initials only'), maxLines: 2),
        ],
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      children: [
        _buildSummaryCard('Person', ['Name: ${_fullNameController.text}', 'Phone: ${_phoneController.text}', 'Zone: $_selectedZone', 'Date: ${_visitDate.toString().split(' ')[0]}']),
        _buildSummaryCard('Centre', ['Hub: $_selectedHub', 'Community: $_selectedCommunity', 'Centre: ${_centreNameController.text}']),
        _buildSummaryCard('Attendance', ['Youth: ${_youngMen + _youngWomen}', 'Men: $_youngMen | Women: $_youngWomen', 'PWD: $_pwd | Staff: $_staff | Trainers: $_trainers']),
        _buildSummaryCard('Employment', ['Formal: $_formalJobs | Intern: $_internships', 'Cooperatives: $_cooperatives | Training: $_furtherTraining']),
        _buildSummaryCard('Quality', ['Rating: $_rating/5', 'Issues: ${_selectedIssues.length}', 'Facilities: ${_selectedFacilities.length}']),
        const SizedBox(height: 16),
        TextFormField(controller: _finalNotesController, decoration: const InputDecoration(labelText: 'Final Notes', hintText: 'Any final notes'), maxLines: 3),
      ],
    );
  }

  Widget _buildSummaryCard(String title, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const Divider(),
            ...items.map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(item, style: const TextStyle(fontSize: 13)))),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 7) {
      setState(() { _currentStep++; });
    } else {
      _submitReport();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() { _currentStep--; });
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSubmitting = true; });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;

      final report = FieldReport(
        id: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: user?.uid,
        userName: _fullNameController.text,
        focalPerson: FocalPerson(
          fullName: _fullNameController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
          zone: _selectedZone,
          visitDate: _visitDate,
          visitTypes: _selectedVisitTypes,
        ),
        trainingCentre: TrainingCentre(
          hub: _selectedHub,
          community: _selectedCommunity.isNotEmpty ? _selectedCommunity : _communityController.text,
          centreName: _centreNameController.text,
          centreAddress: _centreAddressController.text,
          contactPerson: _contactPersonController.text,
          contactPhone: _contactPhoneController.text,
          timeArrived: _timeArrived != null ? DateTime(2026, 1, 1, _timeArrived!.hour, _timeArrived!.minute) : null,
          timeDeparted: _timeDeparted != null ? DateTime(2026, 1, 1, _timeDeparted!.hour, _timeDeparted!.minute) : null,
        ),
        attendance: Attendance(
          youngMenPresent: _youngMen,
          youngWomenPresent: _youngWomen,
          personsWithDisability: _pwd,
          hubStaffOnDuty: _staff,
          trainersPresent: _trainers,
        ),
        employmentOutcome: EmploymentOutcome(
          placedInFormalEmployment: _formalJobs,
          placedInInternships: _internships,
          joinedCooperatives: _cooperatives,
          referredForFurtherTraining: _furtherTraining,
          employerNames: _employerController.text.isNotEmpty ? [_employerController.text] : [],
        ),
        courseEnrolledIn: _courseController.text,
        overallRating: _rating,
        qualityIndicators: _selectedQuality,
        issuesFlagged: _selectedIssues,
        facilitiesAvailable: _selectedFacilities,
        activitiesObserved: _selectedActivities,
        challengesObserved: _challengesController.text,
        recommendations: _recommendationsController.text,
        partnerCompanies: [],
        safeguarding: Safeguarding(
          consentObtained: _consentObtained,
          twoAdultRule: _twoAdultRule,
          policyVisible: _policyVisible,
          noDiscrimination: _noDiscrimination,
          reportingMechanismCommunicated: _reportingMechanism,
          idBadgeWorn: _idBadgeWorn,
          noPersonalContacts: _noPersonalContacts,
          giftsFollowGuidelines: _giftsGuidelines,
          concernIdentified: _concernIdentified,
          concernDescription: _concernDescriptionController.text,
        ),
        finalNotes: _finalNotesController.text,
      );

      final reportService = Provider.of<ReportService>(context, listen: false);
      await reportService.createReport(report: report);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success! ✅'),
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
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() { _isSubmitting = false; });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _centreNameController.dispose();
    _centreAddressController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _communityController.dispose();
    _otherHubController.dispose();
    _employerController.dispose();
    _courseController.dispose();
    _challengesController.dispose();
    _recommendationsController.dispose();
    _concernDescriptionController.dispose();
    _finalNotesController.dispose();
    super.dispose();
  }
}
