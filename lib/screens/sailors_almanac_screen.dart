import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/screens/weather_report_screen.dart';
import 'package:crows_nest/screens/add_entry_dialog.dart';
import 'package:crows_nest/screens/add_note_dialog.dart';
import 'package:crows_nest/screens/export_import_dialog.dart';

class SailorsAlmanacScreen extends StatelessWidget {
  const SailorsAlmanacScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.explore_rounded, size: 24),
            SizedBox(width: 8),
            Text("Sailor's Almanac"),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // 1. Hero Compass Banner
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [colorScheme.primaryContainer, colorScheme.surfaceContainerHighest]
                    : [colorScheme.primaryContainer, colorScheme.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.sailing_rounded, color: colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome Aboard, Captain!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Master the art of charting daily time & weather",
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  "Crow's Nest is built on the philosophy of nautical navigation: intentions change with the weather, focus requires real-time calibration, and every moment is worth logging in your captain's logbook.",
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Section Header: Navigational Pillars
          Row(
            children: [
              Icon(Icons.navigation_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Navigational Pillars",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Guide Card 1: Charting the Course & Weather Tags
          _buildGuideCard(
            context: context,
            icon: Icons.wb_sunny_rounded,
            accentColor: Colors.amber,
            tag: "Step 1",
            title: "Chart the Course (Weather Tags)",
            description:
                "Every morning has its own conditions. Select tags like 'Remote Work', 'High Energy', or 'Meetings Day'. Crow's Nest automatically matches your recurring blueprints to today's weather conditions.",
            actionButtonLabel: "Try Charting Course",
            actionButtonIcon: Icons.explore_rounded,
            onAction: () {
              showDialog(
                context: context,
                builder: (_) => const WeatherReportScreen(isDialog: true),
              );
            },
          ),
          const SizedBox(height: 12),

          // Guide Card 2: Dual Timeline (Plan vs. Execution)
          _buildGuideCard(
            context: context,
            icon: Icons.splitscreen_rounded,
            accentColor: colorScheme.primary,
            tag: "Core Concept",
            title: "Dual Timeline (Plan vs. Reality)",
            description:
                "• Left Column (Planned Course): Blocks you scheduled ahead of time.\n• Right Column (Real Voyage): Actual tracked sessions showing where your focus really sailed.\n• Compare both sides to build realistic forecasting over time.",
            actionButtonLabel: "View Live Timeline",
            actionButtonIcon: Icons.view_timeline_rounded,
            onAction: () => context.go('/'),
          ),
          const SizedBox(height: 12),

          // Guide Card 3: Captain's Log (Timestamped Journal)
          _buildGuideCard(
            context: context,
            icon: Icons.edit_note_rounded,
            accentColor: Colors.teal,
            tag: "Captain's Log",
            title: "Timestamped Journal & Live Notes",
            description:
                "Never lose a fleeting insight or blocker. Tap the [💬 Log] button on the red current-time indicator line or the bottom bar to drop a note directly onto your timeline without cluttering your blocks.",
            actionButtonLabel: "Drop a Quick Note",
            actionButtonIcon: Icons.add_comment_rounded,
            onAction: () {
              final provider = Provider.of<CalendarProvider>(context, listen: false);
              showDialog(
                context: context,
                builder: (_) => AddNoteDialog(provider: provider),
              );
            },
          ),
          const SizedBox(height: 12),

          // Guide Card 4: Blueprints & Dynamic Scheduling
          _buildGuideCard(
            context: context,
            icon: Icons.view_agenda_rounded,
            accentColor: Colors.purple,
            tag: "Automation",
            title: "Blueprints (Routine Templates)",
            description:
                "Create master templates for Deep Work, Workouts, or Admin hours. Link them to specific weather tags (e.g. only apply on 'Remote Work' days) so your schedule builds itself each morning.",
            actionButtonLabel: "Manage Blueprints",
            actionButtonIcon: Icons.auto_awesome_rounded,
            onAction: () => context.go('/blocks'),
          ),
          const SizedBox(height: 12),

          // Guide Card 5: Solar Tides, Chronometer & 6 Themes
          _buildGuideCard(
            context: context,
            icon: Icons.wb_sunny_outlined,
            accentColor: Colors.orange,
            tag: "Atmosphere",
            title: "Solar Tides, Chronometer & 6 Themes",
            description:
                "Crow's Nest includes 6 crafted themes, plus 2 smart rotation modes:\n• Solar Tides ☀️: Changes across the day in your exact custom sequence: Nordic (Morning) ➔ Golden (Midday) ➔ Midnight Oceanic (Afternoon) ➔ Cyber (Twilight) ➔ Crimson (Late Night) ➔ Emerald (Abyss).\n• Chronometer Shift ⏱️: Auto-rotates through all 6 themes every 2 hours with the nautical watch!",
            actionButtonLabel: "Explore Themes in Settings",
            actionButtonIcon: Icons.palette_rounded,
            onAction: () => context.go('/settings'),
          ),
          const SizedBox(height: 12),

          // Guide Card 6: Data Portability (Export & Import JSON)
          _buildGuideCard(
            context: context,
            icon: Icons.storage_rounded,
            accentColor: Colors.indigo,
            tag: "Data Portability",
            title: "JSON Backup & Restore (Full Data Portability)",
            description:
                "Your captain's data is 100% yours with zero lock-in:\n• Export: Dumps your entire database (time blocks, tasks, execution logs, blueprints, weather history, and journal notes) into a single clean JSON payload.\n• Import: Restore your backup onto any device with 1 tap, with options to either replace or merge into your existing logbook.",
            actionButtonLabel: "Open Export / Import Modal",
            actionButtonIcon: Icons.import_export_rounded,
            onAction: () {
              showDialog(
                context: context,
                builder: (_) => const ExportImportDialog(),
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. Step-by-Step Backup & Restore Guide
          Row(
            children: [
              Icon(Icons.shield_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Safe Harbor: How to Backup & Restore",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepRow(
                    stepNumber: "1",
                    title: "Exporting Your Voyage Data",
                    description:
                        "Open Settings > 'Export / Import JSON' (or tap the button above). Under the 'Export' tab, tap 'Copy JSON' to copy your complete logbook to your clipboard, or save it to your favorite notes app or cloud storage.",
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 20),
                  _buildStepRow(
                    stepNumber: "2",
                    title: "Restoring or Migrating to a New Device",
                    description:
                        "Switch to the 'Import' tab, paste your JSON text (or tap 'Paste from Clipboard'), choose 'Replace' or 'Merge', and tap 'Restore Data'. All your schedules, blueprints, and logs will reappear instantly!",
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Sailor's Glossary
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Sailor's Glossary",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildGlossaryItem("Set Sail", "Lock in today's weather tags and chart your time blocks.", Icons.flag_circle_rounded, colorScheme),
                  const Divider(height: 16),
                  _buildGlossaryItem("Planned Course", "Your planned time blocks on the left column.", Icons.schedule_rounded, colorScheme),
                  const Divider(height: 16),
                  _buildGlossaryItem("Real Voyage", "Actual tracked execution blocks on the right column.", Icons.track_changes_rounded, colorScheme),
                  const Divider(height: 16),
                  _buildGlossaryItem("Captain's Log", "Chronological timestamped notes pinned across the day.", Icons.chat_bubble_outline_rounded, colorScheme),
                  const Divider(height: 16),
                  _buildGlossaryItem("Chronometer", "Auto-theme mode cycling every 2 hours with the day's tides.", Icons.access_time_filled_rounded, colorScheme),
                  const Divider(height: 16),
                  _buildGlossaryItem("JSON Portability", "Complete open backup & restore of your entire database with zero lock-in.", Icons.import_export_rounded, colorScheme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required BuildContext context,
    required IconData icon,
    required Color accentColor,
    required String tag,
    required String title,
    required String description,
    required String actionButtonLabel,
    required IconData actionButtonIcon,
    required VoidCallback onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onAction,
                icon: Icon(actionButtonIcon, size: 16),
                label: Text(actionButtonLabel, style: const TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlossaryItem(String term, String definition, IconData icon, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
              children: [
                TextSpan(
                  text: "$term: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: definition,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required String description,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            stepNumber,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
