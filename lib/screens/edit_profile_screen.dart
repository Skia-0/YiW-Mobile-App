import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yiw_field_report/config/app_config.dart';
import 'package:yiw_field_report/services/auth_service.dart';
import 'package:yiw_field_report/theme/colors.dart';

/// Lets a signed-in user edit their own profile.
///
/// Everything is freely editable except the display name, which is limited to
/// one change every 30 days (enforced in AuthService, mirrored in the UI so
/// the restriction is visible before the user types).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String _zone = '';

  String? _localPhotoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().appUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _zone = user?.zone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        // A profile picture never needs to be full camera resolution.
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _localPhotoPath = picked.path);
      }
    } catch (e) {
      _snack('Could not open ${source == ImageSource.camera ? "camera" : "gallery"}: $e',
          AppColors.error);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Profile picture',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_localPhotoPath != null)
              ListTile(
                leading: const Icon(Icons.close, color: AppColors.error),
                title: const Text('Remove selected photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _localPhotoPath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _snack(String message, Color colour) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: colour),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final user = auth.appUser;
    if (user == null) return;

    final newName = _nameController.text.trim();
    final nameChanged = newName != user.fullName;

    // Confirm, because the 30-day lock starts immediately.
    if (nameChanged) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Change your name?'),
          content: Text(
            'Your name will change from "${user.fullName}" to "$newName".\n\n'
            'You will not be able to change it again for 30 days.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Change name'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      String? photoUrl;
      if (_localPhotoPath != null) {
        photoUrl = await auth.uploadProfilePhoto(_localPhotoPath!);
      }

      await auth.updateProfile(
        fullName: nameChanged ? newName : null,
        phoneNumber: _phoneController.text.trim(),
        zone: _zone.isEmpty ? null : _zone,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      _snack('Profile updated', AppColors.success);
      Navigator.pop(context);
    } on ProfileUpdateException catch (e) {
      // Photo upload can fail on its own; save the rest anyway rather than
      // discarding what the user typed.
      if (_localPhotoPath != null && e.message.contains('Photo upload')) {
        try {
          await auth.updateProfile(
            fullName: nameChanged ? newName : null,
            phoneNumber: _phoneController.text.trim(),
            zone: _zone.isEmpty ? null : _zone,
          );
          if (!mounted) return;
          _snack('Details saved, but the photo could not be uploaded.',
              AppColors.warning);
          Navigator.pop(context);
          return;
        } catch (_) {
          // fall through to the error below
        }
      }
      _snack(e.message, AppColors.error);
    } catch (e) {
      _snack('Could not save: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().appUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You are not signed in.')),
      );
    }

    final canChangeName = user.canChangeName;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Photo ----
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.primary,
                    backgroundImage: _localPhotoPath != null
                        ? FileImage(File(_localPhotoPath!)) as ImageProvider
                        : (user.photoUrl != null && user.photoUrl!.isNotEmpty
                            ? NetworkImage(user.photoUrl!)
                            : null),
                    child: (_localPhotoPath == null &&
                            (user.photoUrl == null || user.photoUrl!.isEmpty))
                        ? Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: AppColors.secondary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _showPhotoOptions,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.camera_alt,
                              size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _showPhotoOptions,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Change photo'),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Name (cooldown) ----
            TextFormField(
              controller: _nameController,
              enabled: canChangeName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full name',
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: canChangeName
                    ? null
                    : const Icon(Icons.lock_outline, size: 18),
                helperMaxLines: 3,
                helperText: canChangeName
                    ? 'Can only be changed once every 30 days.'
                    : 'Locked for ${user.daysUntilNameChange} more day(s) '
                        '(next change ${_formatDate(user.nameChangeAvailableOn!)}).',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 3) return 'Name is too short';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ---- Phone ----
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (v.trim().length < 9) return 'Phone number looks too short';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ---- Zone ----
            DropdownButtonFormField<String>(
              initialValue: _zone.isEmpty ? null : _zone,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Zone / Region',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: AppConfig.zones
                  .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                  .toList(),
              onChanged: (v) => setState(() => _zone = v ?? ''),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please select your zone' : null,
            ),
            const SizedBox(height: 16),

            // ---- Read-only ----
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(user.email),
                    trailing: const Icon(Icons.lock_outline, size: 18),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Role'),
                    subtitle: Text(user.role.isEmpty
                        ? 'Field Officer'
                        : user.role),
                    trailing: const Icon(Icons.lock_outline, size: 18),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Email and role can only be changed by an administrator.',
                style:
                    TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save changes'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
