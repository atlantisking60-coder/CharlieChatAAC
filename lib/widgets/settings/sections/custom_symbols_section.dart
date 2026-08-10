// ignore_for_file: deprecated_member_use
// file_picker 12.x is still in beta and the static pickFiles API parameters
// (allowMultiple, withData, bytes) are deprecated without a stable replacement.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../services/settings_service.dart';
import '../../../services/external_symbol_service.dart';
import '../settings_widgets.dart';

class CustomSymbolsSection extends StatefulWidget {
  const CustomSymbolsSection({super.key, required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  State<CustomSymbolsSection> createState() => _CustomSymbolsSectionState();
}

class _CustomSymbolsSectionState extends State<CustomSymbolsSection> {
  final _externalSymbolService = ExternalSymbolService();
  List<ExternalSymbol> _customSymbols = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomSymbols();
  }

  Future<void> _loadCustomSymbols() async {
    setState(() => _loading = true);
    try {
      // Search specifically in the Custom category if possible, or just search all assets
      final results = await _externalSymbolService.searchAssets('');
      setState(() {
        _customSymbols = results.where((s) => s.imageUrl.contains('/Custom/')).toList();
      });
    } catch (e) {
      debugPrint('Error loading custom symbols: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadSymbols() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      int successCount = 0;
      for (final file in result.files) {
        if (file.bytes != null && file.name.isNotEmpty) {
          final uploadedPath = await _mirrorImageToProject(file.name, file.bytes!);
          if (uploadedPath != null) {
            successCount++;
          }
        }
      }

      if (successCount > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully uploaded $successCount symbols.')),
          );
        }
        _loadCustomSymbols();
      }
    } catch (e) {
      debugPrint('Error uploading symbols: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading symbols: $e')),
        );
      }
    }
  }

  Future<String?> _mirrorImageToProject(String filename, List<int> bytes) async {
    try {
      final uri = Uri.parse('http://localhost:8787/saveImage');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'filename': filename,
          'data': base64Encode(bytes),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['path'] as String?;
      }
    } catch (e) {
      debugPrint('Error mirroring image to project: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.add_photo_alternate_outlined,
          title: 'Custom Symbols',
          subtitle: 'Upload your own images to use as symbols in your boards.',
        ),

        SettingsGroup(
          title: 'Upload New',
          children: [
            SettingsTile(
              icon: Icons.upload_file_rounded,
              title: 'Pick Images from PC',
              subtitle: 'Images will be saved to assets/symbols/Custom/',
              trailing: const Icon(Icons.chevron_right),
              onTap: _uploadSymbols,
              showDivider: false,
            ),
          ],
        ),

        SettingsGroup(
          title: 'Your Library (${_customSymbols.length})',
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_customSymbols.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No custom symbols uploaded yet.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _customSymbols.length,
                itemBuilder: (context, index) {
                  final symbol = _customSymbols[index];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(symbol.imageUrl, fit: BoxFit.contain),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                          ),
                          child: Text(
                            symbol.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),

        // Dev Server Warning
        if (kIsWeb)
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(14),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ensure the Dev Save Server is running to persist uploads to your project folder.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
