import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/providers/calendar_provider.dart';

class ExportImportDialog extends StatefulWidget {
  const ExportImportDialog({Key? key}) : super(key: key);

  @override
  State<ExportImportDialog> createState() => _ExportImportDialogState();
}

class _ExportImportDialogState extends State<ExportImportDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _exportedJson = '';
  bool _isLoadingExport = true;
  final TextEditingController _importController = TextEditingController();
  bool _replaceExisting = true;
  String? _importErrorMessage;
  Map<String, dynamic>? _parsedImportData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  Future<void> _loadExportData() async {
    setState(() => _isLoadingExport = true);
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final jsonStr = await provider.exportDataJsonString();
    if (mounted) {
      setState(() {
        _exportedJson = jsonStr;
        _isLoadingExport = false;
      });
    }
  }

  void _onImportTextChanged(String text) {
    setState(() {
      _importErrorMessage = null;
      _parsedImportData = null;
      if (text.trim().isEmpty) return;

      try {
        final decoded = jsonDecode(text.trim());
        if (decoded is Map<String, dynamic>) {
          _parsedImportData = decoded;
        } else {
          _importErrorMessage = "Invalid format: Root JSON must be an object.";
        }
      } catch (e) {
        _importErrorMessage = "Invalid JSON syntax. Please check the pasted text.";
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _importController.text = data.text!;
      _onImportTextChanged(data.text!);
    }
  }

  Future<void> _performImport() async {
    if (_parsedImportData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste valid JSON data to import.')),
      );
      return;
    }

    final provider = Provider.of<CalendarProvider>(context, listen: false);
    try {
      final summary = await provider.importDataJsonString(
        _importController.text.trim(),
        replace: _replaceExisting,
      );

      if (!mounted) return;

      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 36),
          title: const Text('Import Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your captain data has been restored:'),
              const SizedBox(height: 10),
              _buildSummaryRow('Time Blocks', summary['blocks'] ?? 0),
              _buildSummaryRow('Tasks', summary['tasks'] ?? 0),
              _buildSummaryRow('Execution Sessions', summary['execution_sessions'] ?? 0),
              _buildSummaryRow('Weather Tags', summary['weather_tags'] ?? 0),
              _buildSummaryRow('Charted Days', summary['day_weather'] ?? 0),
              _buildSummaryRow('Blueprints', summary['block_blueprints'] ?? 0),
              _buildSummaryRow('Journal Notes', summary['journal_notes'] ?? 0),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Great!'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildSummaryRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text('$count items', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 620),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.import_export_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export & Import Data',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Backup or restore complete JSON logbook',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.file_download_rounded, size: 18), text: 'Export (Backup)'),
                Tab(icon: Icon(Icons.file_upload_rounded, size: 18), text: 'Import (Restore)'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Export View
                  _buildExportTab(colorScheme, isDark),

                  // Tab 2: Import View
                  _buildImportTab(colorScheme, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab(ColorScheme colorScheme, bool isDark) {
    if (_isLoadingExport) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: colorScheme.primary, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Includes all blocks, tasks, sessions, tags, blueprints & notes.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _exportedJson,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _loadExportData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _exportedJson));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('JSON copied to clipboard!'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy JSON'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportTab(ColorScheme colorScheme, bool isDark) {
    final previewData = _parsedImportData?['data'] is Map
        ? _parsedImportData!['data'] as Map
        : _parsedImportData;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paste JSON Data:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste_rounded, size: 16),
                label: const Text('Paste from Clipboard', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TextField(
              controller: _importController,
              onChanged: _onImportTextChanged,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: InputDecoration(
                hintText: '{\n  "app": "crows_nest",\n  "version": 1,\n  "data": { ... }\n}',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          if (_importErrorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                _importErrorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          if (previewData != null && _importErrorMessage == null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Valid backup found (${_countItems(previewData)} total records)',
                      style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _replaceExisting,
                onChanged: (val) => setState(() => _replaceExisting = val ?? true),
              ),
              const Expanded(
                child: Text(
                  'Replace existing data (uncheck to merge)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _parsedImportData != null ? _performImport : null,
              icon: const Icon(Icons.cloud_download_rounded),
              label: Text(_replaceExisting ? 'Restore & Replace All Data' : 'Merge Data into Logbook'),
              style: FilledButton.styleFrom(
                backgroundColor: _replaceExisting ? Colors.redAccent : colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countItems(Map data) {
    int count = 0;
    for (var val in data.values) {
      if (val is List) count += val.length;
    }
    return count;
  }
}
