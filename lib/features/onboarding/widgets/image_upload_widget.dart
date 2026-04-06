import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUploadWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final File? image;
  final Function(File?) onImageSelected;
  final Function(String)? onImageUploaded;
  final String documentType;

  const ImageUploadWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onImageSelected,
    this.onImageUploaded,
    required this.documentType,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get hasImage => widget.image != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _errorMessage != null 
            ? Colors.red.withValues(alpha: 0.5)
            : widget.image != null 
              ? const Color(0xFFE91E63).withValues(alpha: 0.3)
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _errorMessage != null
                      ? Colors.red.withValues(alpha: 0.1)
                      : const Color(0xFFE91E63).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE91E63),
                        ),
                      )
                    : Icon(
                        _errorMessage != null 
                          ? Icons.error_outline
                          : widget.image != null 
                            ? Icons.check_circle 
                            : Icons.upload_file,
                        color: _errorMessage != null 
                          ? Colors.red
                          : widget.image != null 
                            ? Colors.green 
                            : const Color(0xFFE91E63),
                        size: 20,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _errorMessage ?? widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: _errorMessage != null 
                            ? Colors.red
                            : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasImage && _errorMessage == null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Selected',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Image Preview or Upload Area
          GestureDetector(
            onTap: _isLoading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: widget.image != null ? 200 : 120,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _errorMessage != null 
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.grey.shade200,
                  style: BorderStyle.solid,
                ),
              ),
              child: hasImage
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            widget.image!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _pickImage,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoading ? 'Processing...' : 'Tap to upload image',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG (Max 10MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      // Show bottom sheet to choose camera or gallery
      final ImageSource? source = await _showImageSourceBottomSheet();
      if (source == null) return; // User cancelled

      setState(() {
        _isLoading = true;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920, // Higher quality for documents
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Check file size (10MB limit - increased for documents)
        final int fileSizeInBytes = await imageFile.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

// TODO: Replace with proper logging - print('📸 Image selected: ${pickedFile.name}');
// TODO: Replace with proper logging - print('📸 File size: ${fileSizeInMB.toStringAsFixed(2)}MB');

        if (fileSizeInMB > 10) {
          setState(() {
            _errorMessage = 'File too large (${fileSizeInMB.toStringAsFixed(1)}MB). Max 10MB allowed.';
            _isLoading = false;
          });
          return;
        }

        // Validate file extension
        final String extension = pickedFile.path.toLowerCase();
        if (!extension.endsWith('.jpg') &&
            !extension.endsWith('.jpeg') &&
            !extension.endsWith('.png')) {
          setState(() {
            _errorMessage = 'Invalid file type. Please select JPG or PNG.';
            _isLoading = false;
          });
          return;
        }

        // Save to local storage for preview (upload will happen on form submit)
        try {
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String fileName = 'vendor_doc_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
          final String permanentPath = path.join(appDir.path, 'vendor_uploads', fileName);

          await Directory(path.dirname(permanentPath)).create(recursive: true);
          final File permanentFile = await imageFile.copy(permanentPath);

          if (!await permanentFile.exists()) {
            throw Exception('Failed to save image to persistent storage');
          }

          final persistentSize = await permanentFile.length();
          if (persistentSize == 0) {
            throw Exception('Image file became corrupted during save');
          }

// TODO: Replace with proper logging - print('📸 Image saved locally for preview: $permanentPath ($persistentSize bytes)');

          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });

          widget.onImageSelected(permanentFile);
// TODO: Replace with proper logging - print('📸 Image selection successful - will upload on form submit');
        } catch (localError) {
          setState(() {
            _errorMessage = 'Failed to save image. Please try again.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
// TODO: Replace with proper logging - print('📸 Error picking image: $e');
      setState(() {
        _errorMessage = 'Failed to select image. Please try again.';
        _isLoading = false;
      });
    }
  }


  Future<ImageSource?> _showImageSourceBottomSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Color(0xFFE91E63),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Camera',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Take a photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 40,
                              color: Color(0xFFE91E63),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Gallery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Choose from gallery',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 