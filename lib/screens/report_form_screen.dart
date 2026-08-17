import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
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
import 'package:yiw_field_report/services/draft_service.dart';
import 'package:yiw_field_report/widgets/attachment_picker.dart';
import 'dart:async';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Draft auto-save
  Timer? _autoSaveTimer;
  DateTime? _lastSavedAt;
  bool _draftPromptShown = false;
  
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
  final _successStoryController = TextEditingController();
  final _youthVoiceController = TextEditingController();
  
  // Quality
  int _rating = 0;
  List<String> _selectedQuality = [];
  List<String> _selectedIssues = [];
  List<String> _selectedFacilities = [];
  List<String> _selectedActivities = [];
  final _challengesController = TextEditingController();
  final _recommendationsController = TextEditingController();
  String _urgency = 'No action needed';
  final _followUpController = TextEditingController();
  
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
  final _actionTakenController = TextEditingController();
  final _reportedToController = TextEditingController();
  
  final _finalNotesController = TextEditingController();
  
  // Documents (Docs step)
  List<String> _attendanceSheets = [];
  List<String> _financialDocs = [];
  List<String> _mous = [];
  List<String> _trackingSheets = [];
  final _documentNotesController = TextEditingController();

  // Media step
  List<String> _photos = [];
  List<String> _videos = [];
  final _photoCaptionController = TextEditingController();
  final _videoDescriptionController = TextEditingController();
  final _mediaContextController = TextEditingController();

  // Time
  TimeOfDay? _timeArrived;
  TimeOfDay? _timeDeparted;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();

    // Offer to restore an unfinished form, then checkpoint every 30s.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestoreDraft());
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _saveDraft(silent: true),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _animationController.dispose();
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
    _successStoryController.dispose();
    _youthVoiceController.dispose();
    _challengesController.dispose();
    _recommendationsController.dispose();
    _followUpController.dispose();
    _concernDescriptionController.dispose();
    _actionTakenController.dispose();
    _reportedToController.dispose();
    _documentNotesController.dispose();
    _photoCaptionController.dispose();
    _videoDescriptionController.dispose();
    _mediaContextController.dispose();
    _finalNotesController.dispose();
    super.dispose();
  }

  /// The hub name to record.
  ///
  /// When "Other" is chosen the dropdown value is the literal string "Other",
  /// which is useless in the spreadsheet - use what the officer typed instead.
  String get _effectiveHub => _selectedHub == 'Other'
      ? _otherHubController.text.trim()
      : _selectedHub;

  /// True when the hub was typed rather than picked from the configured list.
  bool get _isUnknownHub => _selectedHub == 'Other';

  List<String> _getHubsForZone() => AppConfig.hubsByZone[_selectedZone] ?? [];
  List<String> _getCommunitiesForHub() => AppConfig.communitiesByHub[_selectedHub] ?? [];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New Field Report'),
            if (_lastSavedAt != null)
              Text(
                'Draft saved ${_friendlyTime(_lastSavedAt!)}',
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400),
              ),
          ],
        ),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _saveDraft(),
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: const Text('Save Draft', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppColors.primary,
            child: Row(
              children: List.generate(10, (index) {
                final isActive = index <= _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Step label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              children: [
                Icon(_getStepIcon(_currentStep), size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(_getStepTitle(_currentStep), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const Spacer(),
                Text('Step ${_currentStep + 1} of 10', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          
          // Form content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _nextStep,
                    icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_currentStep == 9 ? Icons.send : Icons.arrow_forward),
                    label: Text(_currentStep == 9 ? 'Submit Report' : 'Continue'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _currentStep == 9 ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0: return Icons.person;
      case 1: return Icons.business;
      case 2: return Icons.people;
      case 3: return Icons.work;
      case 4: return Icons.star;
      case 5: return Icons.handshake;
      case 6: return Icons.folder_copy_outlined;
      case 7: return Icons.perm_media_outlined;
      case 8: return Icons.security;
      case 9: return Icons.check_circle;
      default: return Icons.circle;
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Focal Person Details';
      case 1: return 'Training Centre';
      case 2: return 'Attendance Count';
      case 3: return 'Employment Outcomes';
      case 4: return 'Training Quality';
      case 5: return 'Partner Engagement';
      case 6: return 'Document Uploads';
      case 7: return 'Photos & Videos';
      case 8: return 'Safeguarding';
      case 9: return 'Review & Submit';
      default: return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildPersonSection();
      case 1: return _buildCentreSection();
      case 2: return _buildAttendanceSection();
      case 3: return _buildEmploymentSection();
      case 4: return _buildQualitySection();
      case 5: return _buildPartnerSection();
      case 6: return _buildDocumentsSection();
      case 7: return _buildMediaSection();
      case 8: return _buildSafeguardingSection();
      case 9: return _buildReviewSection();
      default: return Container();
    }
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: child))).toList(),
      ),
    );
  }

  Widget _buildCounterCard(String label, int value, Color color, IconData icon, VoidCallback onInc, VoidCallback onDec) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCounterButton(Icons.remove, color, onDec),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              ),
              _buildCounterButton(Icons.add, color, onInc),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildPersonSection() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Personal Information',
          icon: Icons.person,
          children: [
            _buildInputRow([
              TextFormField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone *', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
            ]),
            _buildInputRow([
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Zone *', prefixIcon: Icon(Icons.location_on_outlined)),
                value: _selectedZone.isEmpty ? null : _selectedZone,
                items: AppConfig.zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                onChanged: (v) => setState(() { _selectedZone = v!; _selectedHub = ''; _selectedCommunity = ''; }),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ]),
          ],
        ),
        _buildSectionCard(
          title: 'Visit Details',
          icon: Icons.calendar_today,
          children: [
            InkWell(
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _visitDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                if (date != null) setState(() { _visitDate = date; });
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Visit Date *', prefixIcon: Icon(Icons.calendar_today)),
                child: Text(_visitDate.toString().split(' ')[0]),
              ),
            ),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('Visit Type *', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: AppConfig.visitTypes.map((type) => FilterChip(
                label: Text(type, style: const TextStyle(fontSize: 12)),
                selected: _selectedVisitTypes.contains(type),
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                onSelected: (s) => setState(() { if (s) _selectedVisitTypes.add(type); else _selectedVisitTypes.remove(type); }),
              )).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCentreSection() {
    final hubs = _getHubsForZone();
    final communities = _getCommunitiesForHub();

    return _buildSectionCard(
      title: 'Training Centre Details',
      icon: Icons.business,
      children: [
        _buildInputRow([
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Hub / TSP *', prefixIcon: Icon(Icons.business_outlined)),
            value: _selectedHub.isEmpty ? null : _selectedHub,
            items: [
              ...hubs.map((h) => DropdownMenuItem(value: h, child: Text(h, overflow: TextOverflow.ellipsis))),
              const DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() { _selectedHub = v!; _selectedCommunity = ''; }),
            validator: (v) => v == null ? 'Required' : null,
          ),
          _selectedHub == 'Other'
              ? TextFormField(
                  controller: _otherHubController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Hub name *',
                    hintText: 'Type the hub name',
                    prefixIcon: Icon(Icons.edit_outlined),
                    helperText: 'Logged under "Unknown Hubs"',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter the hub name'
                      : null,
                  onChanged: (_) => setState(() {}),
                )
              : communities.isNotEmpty
              ? DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Community *', prefixIcon: Icon(Icons.location_city_outlined)),
                  value: _selectedCommunity.isEmpty ? null : _selectedCommunity,
                  items: [
                    ...communities.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                    const DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() { _selectedCommunity = v!; }),
                  validator: (v) => v == null ? 'Required' : null,
                )
              : TextFormField(controller: _communityController, decoration: const InputDecoration(labelText: 'Community *', prefixIcon: Icon(Icons.location_city_outlined)), validator: (v) => v!.isEmpty ? 'Required' : null),
        ]),
        _buildInputRow([
          TextFormField(controller: _centreNameController, decoration: const InputDecoration(labelText: 'Centre Name *', prefixIcon: Icon(Icons.school_outlined)), validator: (v) => v!.isEmpty ? 'Required' : null),
          TextFormField(controller: _centreAddressController, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.map_outlined))),
        ]),
        _buildInputRow([
          TextFormField(controller: _contactPersonController, decoration: const InputDecoration(labelText: 'Contact Person', prefixIcon: Icon(Icons.person_outline))),
          TextFormField(controller: _contactPhoneController, decoration: const InputDecoration(labelText: 'Contact Phone', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
        ]),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) setState(() { _timeArrived = time; });
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Time Arrived', prefixIcon: Icon(Icons.access_time)),
                  child: Text(_timeArrived?.format(context) ?? 'Not set'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) setState(() { _timeDeparted = time; });
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Time Departed', prefixIcon: Icon(Icons.access_time)),
                  child: Text(_timeDeparted?.format(context) ?? 'Not set'),
                ),
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
        _buildSectionCard(
          title: 'Youth Attendance',
          icon: Icons.people,
          children: [
            Row(
              children: [
                Expanded(child: _buildCounterCard('Young Men', _youngMen, Colors.green, Icons.male, () => setState(() { _youngMen++; }), () => setState(() { if (_youngMen > 0) _youngMen--; }))),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterCard('Young Women', _youngWomen, Colors.pink, Icons.female, () => setState(() { _youngWomen++; }), () => setState(() { if (_youngWomen > 0) _youngWomen--; }))),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterCard('PWD', _pwd, Colors.orange, Icons.accessible, () => setState(() { _pwd++; }), () => setState(() { if (_pwd > 0) _pwd--; }))),
              ],
            ),
          ],
        ),
        _buildSectionCard(
          title: 'Staff & Trainers',
          icon: Icons.groups,
          children: [
            Row(
              children: [
                Expanded(child: _buildCounterCard('Staff', _staff, Colors.blue, Icons.people_outline, () => setState(() { _staff++; }), () => setState(() { if (_staff > 0) _staff--; }))),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterCard('Trainers', _trainers, Colors.purple, Icons.school_outlined, () => setState(() { _trainers++; }), () => setState(() { if (_trainers > 0) _trainers--; }))),
                const SizedBox(width: 8),
                Expanded(child: Container()),
              ],
            ),
          ],
        ),
        Card(
          color: AppColors.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [Text('${_youngMen + _youngWomen}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)), const Text('Total Youth', style: TextStyle(fontSize: 12))]),
                Column(children: [Text('${_staff + _trainers}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.secondary)), const Text('Total Staff', style: TextStyle(fontSize: 12))]),
                Column(children: [Text('${_youngMen + _youngWomen + _pwd + _staff + _trainers}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.success)), const Text('Total Present', style: TextStyle(fontSize: 12))]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmploymentSection() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Placement Outcomes',
          icon: Icons.work,
          children: [
            Row(
              children: [
                Expanded(child: _buildCounterCard('Formal Jobs', _formalJobs, Colors.green, Icons.work, () => setState(() { _formalJobs++; }), () => setState(() { if (_formalJobs > 0) _formalJobs--; }))),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterCard('Internships', _internships, Colors.blue, Icons.school, () => setState(() { _internships++; }), () => setState(() { if (_internships > 0) _internships--; }))),
                const SizedBox(width: 8),
                Expanded(child: _buildCounterCard('Cooperatives', _cooperatives, Colors.orange, Icons.group, () => setState(() { _cooperatives++; }), () => setState(() { if (_cooperatives > 0) _cooperatives--; }))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildCounterCard('Further Training', _furtherTraining, Colors.purple, Icons.menu_book, () => setState(() { _furtherTraining++; }), () => setState(() { if (_furtherTraining > 0) _furtherTraining--; }))),
                const SizedBox(width: 8),
                Expanded(child: Container()),
                const SizedBox(width: 8),
                Expanded(child: Container()),
              ],
            ),
          ],
        ),
        _buildSectionCard(
          title: 'Employment Details',
          icon: Icons.business_center,
          children: [
            TextFormField(controller: _employerController, decoration: const InputDecoration(labelText: 'Employer / Cooperative', prefixIcon: Icon(Icons.business_outlined))),
            const SizedBox(height: 12),
            TextFormField(controller: _courseController, decoration: const InputDecoration(labelText: 'Course Enrolled', prefixIcon: Icon(Icons.menu_book_outlined))),
            const SizedBox(height: 12),
            TextFormField(controller: _successStoryController, decoration: const InputDecoration(labelText: 'Success Story', prefixIcon: Icon(Icons.star_outlined)), maxLines: 2),
            const SizedBox(height: 12),
            TextFormField(controller: _youthVoiceController, decoration: const InputDecoration(labelText: 'Youth Voice / Quote', prefixIcon: Icon(Icons.format_quote_outlined)), maxLines: 2),
          ],
        ),
      ],
    );
  }

  Widget _buildQualitySection() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Overall Rating',
          icon: Icons.star,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() { _rating = i + 1; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _rating == i + 1 ? AppColors.primary : Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _rating == i + 1 ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)] : [],
                  ),
                  child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _rating == i + 1 ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color))),
                ),
              )),
            ),
            const SizedBox(height: 8),
            Text(_getRatingLabel(_rating), style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        _buildSectionCard(
          title: 'Quality Indicators',
          icon: Icons.check_circle_outline,
          children: [
            Wrap(spacing: 6.0, runSpacing: 6.0, children: AppConfig.qualityIndicators.map((item) => FilterChip(
              label: Text(item, style: const TextStyle(fontSize: 11)),
              selected: _selectedQuality.contains(item),
              selectedColor: AppColors.success.withOpacity(0.2),
              onSelected: (s) => setState(() { if (s) _selectedQuality.add(item); else _selectedQuality.remove(item); }),
            )).toList()),
          ],
        ),
        _buildSectionCard(
          title: 'Issues Flagged',
          icon: Icons.warning_outlined,
          children: [
            Wrap(spacing: 6.0, runSpacing: 6.0, children: AppConfig.issues.map((item) => FilterChip(
              label: Text(item, style: const TextStyle(fontSize: 11)),
              selected: _selectedIssues.contains(item),
              selectedColor: AppColors.error.withOpacity(0.2),
              onSelected: (s) => setState(() { if (s) _selectedIssues.add(item); else _selectedIssues.remove(item); }),
            )).toList()),
          ],
        ),
        _buildSectionCard(
          title: 'Facilities Available',
          icon: Icons.build_outlined,
          children: [
            Wrap(spacing: 6.0, runSpacing: 6.0, children: AppConfig.facilities.map((item) => FilterChip(
              label: Text(item, style: const TextStyle(fontSize: 11)),
              selected: _selectedFacilities.contains(item),
              selectedColor: AppColors.info.withOpacity(0.2),
              onSelected: (s) => setState(() { if (s) _selectedFacilities.add(item); else _selectedFacilities.remove(item); }),
            )).toList()),
          ],
        ),
        _buildSectionCard(
          title: 'Activities Observed',
          icon: Icons.directions_run,
          children: [
            Wrap(spacing: 6.0, runSpacing: 6.0, children: AppConfig.activities.map((item) => FilterChip(
              label: Text(item, style: const TextStyle(fontSize: 11)),
              selected: _selectedActivities.contains(item),
              selectedColor: AppColors.secondary.withOpacity(0.2),
              onSelected: (s) => setState(() { if (s) _selectedActivities.add(item); else _selectedActivities.remove(item); }),
            )).toList()),
          ],
        ),
        _buildSectionCard(
          title: 'Challenges & Recommendations',
          icon: Icons.note_outlined,
          children: [
            TextFormField(controller: _challengesController, decoration: const InputDecoration(labelText: 'Challenges Observed', prefixIcon: Icon(Icons.warning_amber_outlined)), maxLines: 2),
            const SizedBox(height: 12),
            TextFormField(controller: _recommendationsController, decoration: const InputDecoration(labelText: 'Recommendations', prefixIcon: Icon(Icons.lightbulb_outlined)), maxLines: 2),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Urgency of Action', prefixIcon: Icon(Icons.speed_outlined)),
              value: _urgency,
              items: ['No action needed', 'Within the week', 'Within 48 hours', 'Urgent — same day'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) => setState(() { _urgency = v!; }),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _followUpController, decoration: const InputDecoration(labelText: 'Follow-up By', prefixIcon: Icon(Icons.person_search_outlined))),
          ],
        ),
      ],
    );
  }

  Widget _buildPartnerSection() {
    return _buildSectionCard(
      title: 'Partner Engagement',
      icon: Icons.handshake,
      children: [
        Card(
          color: AppColors.secondary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.business_outlined, size: 48, color: AppColors.secondary),
                const SizedBox(height: 12),
                const Text('Partner Companies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Add partner companies engaged today', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () { /* Add partner dialog */ },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Partner Company'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                ),
                const SizedBox(height: 12),
                Text('Target: 15 partners per zone', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Docs step - mirrors the "Document Uploads" section of the YiW web form.
  Widget _buildDocumentsSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.info),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Roles 3 & 5: Scan and send attendance sheets, financial '
                  'documents and MoUs. Upload monthly tracking sheets.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        _buildSectionCard(
          title: 'Document Uploads',
          icon: Icons.folder_copy_outlined,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Use the camera to scan, or browse to attach files. '
                'Images are compressed automatically.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            AttachmentPicker(
              label: 'Attendance sheets',
              icon: Icons.fact_check_outlined,
              browseHint: 'PDF or Image',
              paths: _attendanceSheets,
              onChanged: (v) => setState(() { _attendanceSheets = v; }),
            ),
            const Divider(),
            AttachmentPicker(
              label: 'Financial documents',
              icon: Icons.receipt_long_outlined,
              browseHint: 'Receipts / Invoices',
              paths: _financialDocs,
              onChanged: (v) => setState(() { _financialDocs = v; }),
            ),
            const Divider(),
            AttachmentPicker(
              label: 'MoUs & signed agreements',
              icon: Icons.handshake_outlined,
              browseHint: 'Scanned copies',
              paths: _mous,
              onChanged: (v) => setState(() { _mous = v; }),
            ),
            const Divider(),
            AttachmentPicker(
              label: 'YiW tracking sheets (monthly)',
              icon: Icons.table_chart_outlined,
              browseHint: 'Excel / CSV / PDF',
              paths: _trackingSheets,
              onChanged: (v) => setState(() { _trackingSheets = v; }),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _documentNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Document notes',
                hintText: 'Anything the office should know about these files',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Media step - photos and videos captured during the visit.
  Widget _buildMediaSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.photo_camera_outlined,
                  size: 18, color: AppColors.accent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Capture training in progress, centre conditions, youth '
                  'activities and partner meetings.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        _buildSectionCard(
          title: 'Photos',
          icon: Icons.photo_library_outlined,
          children: [
            AttachmentPicker(
              label: 'Training, activities, hub conditions, meetings',
              icon: Icons.image_outlined,
              browseHint: 'Choose from device',
              allowDocuments: false,
              paths: _photos,
              onChanged: (v) => setState(() { _photos = v; }),
            ),
            TextFormField(
              controller: _photoCaptionController,
              decoration: const InputDecoration(
                labelText: 'Photo caption',
              ),
            ),
          ],
        ),
        _buildSectionCard(
          title: 'Videos',
          icon: Icons.videocam_outlined,
          children: [
            AttachmentPicker(
              label: 'Testimonials, training delivery, activities',
              icon: Icons.movie_outlined,
              browseHint: 'Choose from device',
              isVideo: true,
              allowDocuments: false,
              paths: _videos,
              onChanged: (v) => setState(() { _videos = v; }),
            ),
            TextFormField(
              controller: _videoDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Video description',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mediaContextController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Media context / overall description',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSafeguardingSection() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Safeguarding Checklist',
          icon: Icons.security,
          children: [
            _buildCheckItem('Consent obtained before photos/videos', _consentObtained, (v) => setState(() { _consentObtained = v; })),
            _buildCheckItem('Two-adult rule maintained', _twoAdultRule, (v) => setState(() { _twoAdultRule = v; })),
            _buildCheckItem('Safeguarding policy visible at hub', _policyVisible, (v) => setState(() { _policyVisible = v; })),
            _buildCheckItem('No discriminatory language or behaviour', _noDiscrimination, (v) => setState(() { _noDiscrimination = v; })),
            _buildCheckItem('Reporting mechanism communicated to youth', _reportingMechanism, (v) => setState(() { _reportingMechanism = v; })),
            _buildCheckItem('YiW ID / badge worn during visit', _idBadgeWorn, (v) => setState(() { _idBadgeWorn = v; })),
            _buildCheckItem('No exchange of personal contacts with youth', _noPersonalContacts, (v) => setState(() { _noPersonalContacts = v; })),
            _buildCheckItem('Gifts / incentives followed programme guidelines', _giftsGuidelines, (v) => setState(() { _giftsGuidelines = v; })),
          ],
        ),
        _buildSectionCard(
          title: 'Concern Reporting',
          icon: Icons.report_outlined,
          children: [
            SwitchListTile(
              title: const Text('Was a safeguarding concern identified today?'),
              value: _concernIdentified,
              onChanged: (v) => setState(() { _concernIdentified = v; }),
              activeColor: AppColors.error,
            ),
            if (_concernIdentified) ...[
              const SizedBox(height: 12),
              TextFormField(controller: _concernDescriptionController, decoration: const InputDecoration(labelText: 'Describe the concern', hintText: 'Use initials only — no full names', prefixIcon: Icon(Icons.description_outlined)), maxLines: 2),
              const SizedBox(height: 12),
              TextFormField(controller: _actionTakenController, decoration: const InputDecoration(labelText: 'Action taken', prefixIcon: Icon(Icons.check_circle_outline)), maxLines: 2),
              const SizedBox(height: 12),
              TextFormField(controller: _reportedToController, decoration: const InputDecoration(labelText: 'Reported to', prefixIcon: Icon(Icons.person_outlined))),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCheckItem(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? AppColors.success.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: value ? AppColors.success.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
      ),
      child: CheckboxListTile(
        title: Text(title, style: TextStyle(fontSize: 13, color: value ? AppColors.success : Theme.of(context).textTheme.bodyLarge?.color)),
        value: value,
        onChanged: (v) => onChanged(v!),
        activeColor: AppColors.success,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  int get _totalAttachments =>
      _attendanceSheets.length +
      _financialDocs.length +
      _mous.length +
      _trackingSheets.length +
      _photos.length +
      _videos.length;

  Widget _buildReviewSection() {
    return Column(
      children: [
        _buildReviewCard('Focal Person', [
          'Name: ${_fullNameController.text}',
          'Phone: ${_phoneController.text}',
          'Zone: $_selectedZone',
          'Date: ${_visitDate.toString().split(' ')[0]}',
          'Visit Types: ${_selectedVisitTypes.join(', ')}',
        ], Icons.person),
        _buildReviewCard('Training Centre', [
          'Hub: $_selectedHub',
          'Community: $_selectedCommunity',
          'Centre: ${_centreNameController.text}',
          'Address: ${_centreAddressController.text}',
        ], Icons.business),
        _buildReviewCard('Attendance', [
          'Total Youth: ${_youngMen + _youngWomen}',
          'Men: $_youngMen | Women: $_youngWomen',
          'PWD: $_pwd | Staff: $_staff | Trainers: $_trainers',
        ], Icons.people),
        _buildReviewCard('Employment', [
          'Formal: $_formalJobs | Intern: $_internships',
          'Cooperatives: $_cooperatives | Training: $_furtherTraining',
          'Employer: ${_employerController.text}',
        ], Icons.work),
        _buildReviewCard('Quality', [
          'Rating: $_rating/5',
          'Issues: ${_selectedIssues.length} flagged',
          'Facilities: ${_selectedFacilities.length} available',
        ], Icons.star),
        _buildReviewCard('Documents', [
          'Attendance sheets: ${_attendanceSheets.length}',
          'Financial documents: ${_financialDocs.length}',
          'MoUs: ${_mous.length}',
          'Tracking sheets: ${_trackingSheets.length}',
        ], Icons.folder_copy_outlined),
        _buildReviewCard('Media', [
          'Photos: ${_photos.length}',
          'Videos: ${_videos.length}',
          if (_totalAttachments > 0)
            '$_totalAttachments file(s) will be uploaded on submit',
        ], Icons.perm_media_outlined),
        _buildReviewCard('Safeguarding', [
          'Checks: ${_getSafeguardingCount()}/8',
          'Concern: ${_concernIdentified ? 'Yes' : 'No'}',
        ], Icons.security),
        const SizedBox(height: 16),
        TextFormField(controller: _finalNotesController, decoration: const InputDecoration(labelText: 'Final Notes', prefixIcon: Icon(Icons.note_outlined)), maxLines: 3),
      ],
    );
  }

  Widget _buildReviewCard(String title, List<String> items, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const Divider(),
            ...items.map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(item, style: const TextStyle(fontSize: 13)))),
          ],
        ),
      ),
    );
  }

  int _getSafeguardingCount() {
    int count = 0;
    if (_consentObtained) count++;
    if (_twoAdultRule) count++;
    if (_policyVisible) count++;
    if (_noDiscrimination) count++;
    if (_reportingMechanism) count++;
    if (_idBadgeWorn) count++;
    if (_noPersonalContacts) count++;
    if (_giftsGuidelines) count++;
    return count;
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Weak';
      case 3: return 'Fair';
      case 4: return 'Good';
      case 5: return 'Excellent';
      default: return 'Tap to rate';
    }
  }

  void _nextStep() {
    if (_currentStep < 9) {
      _animationController.reset();
      setState(() { _currentStep++; });
      _animationController.forward();
      _saveDraft(silent: true); // checkpoint progress at each step
    } else {
      _submitReport();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reset();
      setState(() { _currentStep--; });
      _animationController.forward();
    }
  }

  /// Snapshot of every field on the form, for draft persistence.
  Map<String, dynamic> _collectFormData() => {
        'currentStep': _currentStep,
        'selectedZone': _selectedZone,
        'selectedHub': _selectedHub,
        'selectedCommunity': _selectedCommunity,
        'visitDate': _visitDate.toIso8601String(),
        'selectedVisitTypes': _selectedVisitTypes,
        'fullName': _fullNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'centreName': _centreNameController.text,
        'centreAddress': _centreAddressController.text,
        'contactPerson': _contactPersonController.text,
        'contactPhone': _contactPhoneController.text,
        'community': _communityController.text,
        'otherHub': _otherHubController.text,
        'youngMen': _youngMen,
        'youngWomen': _youngWomen,
        'pwd': _pwd,
        'staff': _staff,
        'trainers': _trainers,
        'formalJobs': _formalJobs,
        'internships': _internships,
        'cooperatives': _cooperatives,
        'furtherTraining': _furtherTraining,
        'employer': _employerController.text,
        'course': _courseController.text,
        'successStory': _successStoryController.text,
        'youthVoice': _youthVoiceController.text,
        'rating': _rating,
        'selectedQuality': _selectedQuality,
        'selectedIssues': _selectedIssues,
        'selectedFacilities': _selectedFacilities,
        'selectedActivities': _selectedActivities,
        'challenges': _challengesController.text,
        'recommendations': _recommendationsController.text,
        'urgency': _urgency,
        'followUp': _followUpController.text,
        'consentObtained': _consentObtained,
        'twoAdultRule': _twoAdultRule,
        'policyVisible': _policyVisible,
        'noDiscrimination': _noDiscrimination,
        'reportingMechanism': _reportingMechanism,
        'idBadgeWorn': _idBadgeWorn,
        'noPersonalContacts': _noPersonalContacts,
        'giftsGuidelines': _giftsGuidelines,
        'concernIdentified': _concernIdentified,
        'concernDescription': _concernDescriptionController.text,
        'actionTaken': _actionTakenController.text,
        'reportedTo': _reportedToController.text,
        'finalNotes': _finalNotesController.text,
        'attendanceSheets': _attendanceSheets,
        'financialDocs': _financialDocs,
        'mous': _mous,
        'trackingSheets': _trackingSheets,
        'documentNotes': _documentNotesController.text,
        'photos': _photos,
        'videos': _videos,
        'photoCaption': _photoCaptionController.text,
        'videoDescription': _videoDescriptionController.text,
        'mediaContext': _mediaContextController.text,
        'timeArrivedHour': _timeArrived?.hour,
        'timeArrivedMinute': _timeArrived?.minute,
        'timeDepartedHour': _timeDeparted?.hour,
        'timeDepartedMinute': _timeDeparted?.minute,
      };

  void _applyFormData(Map<String, dynamic> d) {
    List<String> strList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : <String>[];
    int intOr(dynamic v, int fallback) => v is int ? v : fallback;

    setState(() {
      _currentStep = intOr(d['currentStep'], 0).clamp(0, 9);
      _selectedZone = d['selectedZone'] ?? '';
      _selectedHub = d['selectedHub'] ?? '';
      _selectedCommunity = d['selectedCommunity'] ?? '';
      _visitDate = DateTime.tryParse(d['visitDate'] ?? '') ?? DateTime.now();
      _selectedVisitTypes = strList(d['selectedVisitTypes']);
      _fullNameController.text = d['fullName'] ?? '';
      _phoneController.text = d['phone'] ?? '';
      _emailController.text = d['email'] ?? '';
      _centreNameController.text = d['centreName'] ?? '';
      _centreAddressController.text = d['centreAddress'] ?? '';
      _contactPersonController.text = d['contactPerson'] ?? '';
      _contactPhoneController.text = d['contactPhone'] ?? '';
      _communityController.text = d['community'] ?? '';
      _otherHubController.text = d['otherHub'] ?? '';
      _youngMen = intOr(d['youngMen'], 0);
      _youngWomen = intOr(d['youngWomen'], 0);
      _pwd = intOr(d['pwd'], 0);
      _staff = intOr(d['staff'], 0);
      _trainers = intOr(d['trainers'], 0);
      _formalJobs = intOr(d['formalJobs'], 0);
      _internships = intOr(d['internships'], 0);
      _cooperatives = intOr(d['cooperatives'], 0);
      _furtherTraining = intOr(d['furtherTraining'], 0);
      _employerController.text = d['employer'] ?? '';
      _courseController.text = d['course'] ?? '';
      _successStoryController.text = d['successStory'] ?? '';
      _youthVoiceController.text = d['youthVoice'] ?? '';
      _rating = intOr(d['rating'], 0);
      _selectedQuality = strList(d['selectedQuality']);
      _selectedIssues = strList(d['selectedIssues']);
      _selectedFacilities = strList(d['selectedFacilities']);
      _selectedActivities = strList(d['selectedActivities']);
      _challengesController.text = d['challenges'] ?? '';
      _recommendationsController.text = d['recommendations'] ?? '';
      _urgency = d['urgency'] ?? 'No action needed';
      _followUpController.text = d['followUp'] ?? '';
      _consentObtained = d['consentObtained'] == true;
      _twoAdultRule = d['twoAdultRule'] == true;
      _policyVisible = d['policyVisible'] == true;
      _noDiscrimination = d['noDiscrimination'] == true;
      _reportingMechanism = d['reportingMechanism'] == true;
      _idBadgeWorn = d['idBadgeWorn'] == true;
      _noPersonalContacts = d['noPersonalContacts'] == true;
      _giftsGuidelines = d['giftsGuidelines'] == true;
      _concernIdentified = d['concernIdentified'] == true;
      _concernDescriptionController.text = d['concernDescription'] ?? '';
      _actionTakenController.text = d['actionTaken'] ?? '';
      _reportedToController.text = d['reportedTo'] ?? '';
      _finalNotesController.text = d['finalNotes'] ?? '';
      _attendanceSheets = strList(d['attendanceSheets']);
      _financialDocs = strList(d['financialDocs']);
      _mous = strList(d['mous']);
      _trackingSheets = strList(d['trackingSheets']);
      _documentNotesController.text = d['documentNotes'] ?? '';
      _photos = strList(d['photos']);
      _videos = strList(d['videos']);
      _photoCaptionController.text = d['photoCaption'] ?? '';
      _videoDescriptionController.text = d['videoDescription'] ?? '';
      _mediaContextController.text = d['mediaContext'] ?? '';
      if (d['timeArrivedHour'] is int) {
        _timeArrived = TimeOfDay(
            hour: d['timeArrivedHour'],
            minute: intOr(d['timeArrivedMinute'], 0));
      }
      if (d['timeDepartedHour'] is int) {
        _timeDeparted = TimeOfDay(
            hour: d['timeDepartedHour'],
            minute: intOr(d['timeDepartedMinute'], 0));
      }
    });
  }

  /// True once the user has typed something worth preserving.
  bool get _formHasContent =>
      _fullNameController.text.isNotEmpty ||
      _centreNameController.text.isNotEmpty ||
      _selectedZone.isNotEmpty ||
      _selectedHub.isNotEmpty ||
      _challengesController.text.isNotEmpty ||
      _finalNotesController.text.isNotEmpty ||
      _rating > 0 ||
      _attendanceSheets.isNotEmpty ||
      _financialDocs.isNotEmpty ||
      _mous.isNotEmpty ||
      _trackingSheets.isNotEmpty ||
      _photos.isNotEmpty ||
      _videos.isNotEmpty ||
      _currentStep > 0;

  Future<void> _saveDraft({bool silent = false}) async {
    if (!mounted) return;
    if (silent && !_formHasContent) return;

    final draftService = Provider.of<DraftService>(context, listen: false);
    await draftService.save(_collectFormData());
    if (!mounted) return;

    setState(() { _lastSavedAt = DateTime.now(); });

    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _maybeRestoreDraft() async {
    if (_draftPromptShown || !mounted) return;
    _draftPromptShown = true;

    final draftService = Provider.of<DraftService>(context, listen: false);
    if (!draftService.hasDraft) return;

    final savedAt = draftService.savedAt;
    final when = savedAt == null ? 'earlier' : _friendlyTime(savedAt);

    final restore = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Resume draft?'),
        content: Text(
          'You have an unfinished report saved $when.\n\n'
          'Continue where you left off?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Start fresh'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (restore == true) {
      final data = draftService.load();
      if (data != null) {
        _applyFormData(data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft restored'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } else {
      await draftService.clear();
    }
  }

  String _friendlyTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'moments ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day(s) ago';
  }

  /// Intercepts back navigation so a part-filled form is never lost silently.
  Future<bool> _confirmLeave() async {
    if (!_formHasContent) return true;

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this report?'),
        content: const Text('Your progress can be saved as a draft.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard',
                style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save draft'),
          ),
        ],
      ),
    );

    if (!mounted) return false;
    if (action == 'save') {
      await _saveDraft(silent: true);
      return true;
    }
    if (action == 'discard') {
      await Provider.of<DraftService>(context, listen: false).clear();
      return true;
    }
    return false;
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;

      final report = FieldReport(
        id: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
        userId: user?.uid, userName: _fullNameController.text,
        focalPerson: FocalPerson(fullName: _fullNameController.text, phoneNumber: _phoneController.text, email: _emailController.text, zone: _selectedZone, visitDate: _visitDate, visitTypes: _selectedVisitTypes),
        trainingCentre: TrainingCentre(hub: _effectiveHub, community: _selectedCommunity.isNotEmpty ? _selectedCommunity : _communityController.text, centreName: _centreNameController.text, centreAddress: _centreAddressController.text, contactPerson: _contactPersonController.text, contactPhone: _contactPhoneController.text, timeArrived: _timeArrived != null ? DateTime(2026, 1, 1, _timeArrived!.hour, _timeArrived!.minute) : null, timeDeparted: _timeDeparted != null ? DateTime(2026, 1, 1, _timeDeparted!.hour, _timeDeparted!.minute) : null),
        attendance: Attendance(youngMenPresent: _youngMen, youngWomenPresent: _youngWomen, personsWithDisability: _pwd, hubStaffOnDuty: _staff, trainersPresent: _trainers),
        employmentOutcome: EmploymentOutcome(placedInFormalEmployment: _formalJobs, placedInInternships: _internships, joinedCooperatives: _cooperatives, referredForFurtherTraining: _furtherTraining, employerNames: _employerController.text.isNotEmpty ? [_employerController.text] : []),
        courseEnrolledIn: _courseController.text, successStory: _successStoryController.text, youthVoice: _youthVoiceController.text,
        overallRating: _rating, qualityIndicators: _selectedQuality, issuesFlagged: _selectedIssues, facilitiesAvailable: _selectedFacilities, activitiesObserved: _selectedActivities,
        challengesObserved: _challengesController.text, recommendations: _recommendationsController.text, urgencyOfAction: _urgency, followUpBy: _followUpController.text,
        partnerCompanies: [],
        safeguarding: Safeguarding(consentObtained: _consentObtained, twoAdultRule: _twoAdultRule, policyVisible: _policyVisible, noDiscrimination: _noDiscrimination, reportingMechanismCommunicated: _reportingMechanism, idBadgeWorn: _idBadgeWorn, noPersonalContacts: _noPersonalContacts, giftsFollowGuidelines: _giftsGuidelines, concernIdentified: _concernIdentified, concernDescription: _concernDescriptionController.text, actionTaken: _actionTakenController.text, reportedTo: _reportedToController.text),
        finalNotes: _finalNotesController.text,
        photoPaths: _photos,
        videoPaths: _videos,
        attendanceSheetPaths: _attendanceSheets,
        financialDocPaths: _financialDocs,
        mouPaths: _mous,
        trackingSheetPaths: _trackingSheets,
      );

      final reportService = Provider.of<ReportService>(context, listen: false);
      await reportService.createReport(report: report);
      final warnings = reportService.lastSubmitWarnings;

      // Submitted - the draft is no longer needed.
      _autoSaveTimer?.cancel();
      if (!mounted) return;
      await Provider.of<DraftService>(context, listen: false).clear();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(warnings.isEmpty ? 'Success! ✅' : 'Submitted with warnings ⚠️'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(warnings.isEmpty
                      ? 'Your field report has been submitted successfully.'
                      : 'Your report WAS saved and sent. These parts did not '
                          'complete:'),
                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...warnings.map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!w.trimLeft().startsWith('•'))
                                const Padding(
                                  padding: EdgeInsets.only(top: 2, right: 6),
                                  child: Icon(Icons.warning_amber_rounded,
                                      size: 16, color: AppColors.warning),
                                ),
                              Expanded(
                                child: SelectableText(
                                  w,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                    const Text(
                      'Nothing you did is wrong — these are server settings '
                      'your project admin needs to enable. Tap "Copy details" '
                      'and send it to them.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                  if (_totalAttachments > 0) ...[
                    const SizedBox(height: 8),
                    Text('$_totalAttachments file(s) attached to the email.',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (warnings.isNotEmpty)
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: warnings.join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Details copied to clipboard'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
                child: const Text('Copy details'),
              ),
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      setState(() { _isSubmitting = false; });
    }
  }
}
