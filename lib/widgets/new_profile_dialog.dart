import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/profile_service.dart';

class NewProfileDialog extends StatefulWidget {
  final UserProfile activeProfile;

  const NewProfileDialog({super.key, required this.activeProfile});

  static Future<UserProfile?> show(BuildContext context, UserProfile activeProfile) {
    return showDialog<UserProfile?>(
      context: context,
      builder: (ctx) => NewProfileDialog(activeProfile: activeProfile),
    );
  }

  @override
  State<NewProfileDialog> createState() => _NewProfileDialogState();
}

class _NewProfileDialogState extends State<NewProfileDialog> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late String _imagePath;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.activeProfile.settings.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imagePath = 'data:image/png;base64,${base64Encode(bytes)}';
        });
      } else {
        setState(() {
          _imagePath = file.path!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
      }
    }
  }

  ImageProvider? _imageProvider() {
    if (_imagePath.isEmpty || _imagePath == 'assets/symbols/baycroft.png') return null;
    if (_imagePath.startsWith('data:')) {
      return MemoryImage(base64Decode(_imagePath.split(',').last));
    }
    if (_imagePath.startsWith('assets/')) return AssetImage(_imagePath);
    if (kIsWeb) return NetworkImage(_imagePath);
    return FileImage(File(_imagePath));
  }

  bool get _canCreate {
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    return name.isNotEmpty &&
        password.isNotEmpty &&
        password == confirm;
  }

  void _create() {
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final settings = widget.activeProfile.settings.copyWith(profileImage: _imagePath);
    final profile = UserProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      username: name,
      password: password,
      settings: settings,
      tabOrder: widget.activeProfile.tabOrder,
      preferredSymbolSets: widget.activeProfile.preferredSymbolSets,
      startingBoardId: widget.activeProfile.startingBoardId,
    );
    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Create Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: _imageProvider(),
                    child: _imageProvider() == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        child: Icon(Icons.edit, size: 14, color: cs.onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_camera_back, size: 18),
                label: const Text('Choose profile picture'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Profile name'),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              onChanged: (_) => setState(() {}),
            ),
            if (_passwordController.text.isNotEmpty &&
                _confirmController.text.isNotEmpty &&
                _passwordController.text != _confirmController.text)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Passwords do not match',
                    style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canCreate ? _create : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
