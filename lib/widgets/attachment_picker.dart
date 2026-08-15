import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yiw_field_report/theme/colors.dart';

/// Reusable "scan / browse" attachment row, mirroring the Docs and Media
/// sections of the YiW web report form.
///
/// Holds only local file paths; uploading happens in ReportService at submit.
class AttachmentPicker extends StatelessWidget {
  final String label;
  final String browseHint;
  final IconData icon;
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;

  /// Camera captures a photo (documents, photos) vs a video.
  final bool isVideo;

  /// Allow non-image files via the file browser.
  final bool allowDocuments;

  const AttachmentPicker({
    super.key,
    required this.label,
    required this.paths,
    required this.onChanged,
    this.icon = Icons.attach_file,
    this.browseHint = 'PDF or Image',
    this.isVideo = false,
    this.allowDocuments = true,
  });

  Future<void> _capture(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? file = isVideo
          ? await picker.pickVideo(source: ImageSource.camera)
          : await picker.pickImage(
              source: ImageSource.camera,
              // Compress on capture: full-res phone photos are ~5MB each and
              // would blow through Firebase Storage quota.
              imageQuality: 70,
              maxWidth: 1600,
            );
      if (file != null) onChanged([...paths, file.path]);
    } catch (e) {
      _error(context, 'Camera unavailable: $e');
    }
  }

  Future<void> _browse(BuildContext context) async {
    try {
      if (allowDocuments) {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.any,
        );
        if (result != null) {
          final picked =
              result.paths.whereType<String>().toList(growable: false);
          if (picked.isNotEmpty) onChanged([...paths, ...picked]);
        }
      } else {
        final picker = ImagePicker();
        if (isVideo) {
          final f = await picker.pickVideo(source: ImageSource.gallery);
          if (f != null) onChanged([...paths, f.path]);
        } else {
          final files = await picker.pickMultiImage(
            imageQuality: 70,
            maxWidth: 1600,
          );
          if (files.isNotEmpty) {
            onChanged([...paths, ...files.map((f) => f.path)]);
          }
        }
      }
    } catch (e) {
      _error(context, 'Could not open file browser: $e');
    }
  }

  void _error(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _remove(int index) {
    final next = [...paths]..removeAt(index);
    onChanged(next);
  }

  String _fileName(String path) =>
      path.split(Platform.pathSeparator).last.split('/').last;

  String _fileSize(String path) {
    try {
      final bytes = File(path).lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  bool _isImage(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (paths.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${paths.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _capture(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Column(
                  children: [
                    Icon(isVideo ? Icons.videocam : Icons.camera_alt, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      isVideo ? 'Record Video' : 'Scan / Take Photo',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Opens Camera',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _browse(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.folder_open, size: 22),
                    const SizedBox(height: 4),
                    const Text('Browse Files', style: TextStyle(fontSize: 12)),
                    Text(
                      browseHint,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (paths.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...paths.asMap().entries.map((entry) {
            final i = entry.key;
            final path = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
              // Material (not a coloured Container) so ink splashes render.
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                leading: _isImage(path)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(path),
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 28),
                        ),
                      )
                    : Icon(
                        isVideo
                            ? Icons.play_circle_outline
                            : Icons.insert_drive_file_outlined,
                        color: AppColors.primary,
                      ),
                title: Text(
                  _fileName(path),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _fileSize(path),
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.error,
                  onPressed: () => _remove(i),
                  tooltip: 'Remove',
                ),
              ),
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
