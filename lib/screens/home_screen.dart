import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/models/block.dart' as model;
import 'package:crows_nest/models/task.dart';
import 'package:crows_nest/models/execution_session.dart';
import 'package:crows_nest/models/journal_note.dart';
import 'package:crows_nest/screens/add_entry_dialog.dart';
import 'package:crows_nest/screens/add_task_dialog.dart';
import 'package:crows_nest/screens/add_note_dialog.dart';
import 'package:crows_nest/screens/weather_report_screen.dart';
import 'package:crows_nest/screens/block_details_dialog.dart';
import 'package:crows_nest/widgets/interactive_lookout_deck.dart';
import 'package:intl/intl.dart';
import 'dart:async';

const double hourHeight = 80.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _isBannerExpanded = true;
  bool _isBottomTrayExpanded = true;
  int _bottomTrayTab = 0; // 0: Inbox (Tasks), 1: Logbook (Notes)
  bool _isBriefingExpanded = true;
  final Set<int> _selectedWeatherTagIds = {};

  @override
  void initState() {
    super.initState();
    
    final now = DateTime.now();
    final offset = (now.hour * hourHeight) + (now.minute / 60 * hourHeight);
    
    double initialTarget = offset - (2.5 * hourHeight);
    if (initialTarget < 0) initialTarget = 0;
    
    _scrollController = ScrollController(initialScrollOffset: initialTarget);

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final offset = (now.hour * hourHeight) + (now.minute / 60 * hourHeight);
    
    double target = offset - (2.5 * hourHeight);
    if (target < 0) target = 0;

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _showAddEntryDialog(BuildContext context, CalendarProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AddEntryDialog(
          provider: provider,
          currentDate: provider.currentDate,
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, CalendarProvider provider, {int? initialBlockId}) {
    showDialog(
      context: context,
      builder: (context) {
        return AddTaskDialog(
          blocks: provider.blocks,
          initialBlockId: initialBlockId,
          onAdd: (task) {
            provider.addTask(task);
          },
        );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context, CalendarProvider provider, {JournalNote? initialNote, DateTime? defaultTime}) {
    showDialog(
      context: context,
      builder: (context) {
        return AddNoteDialog(
          provider: provider,
          initialNote: initialNote,
          defaultTime: defaultTime,
        );
      },
    );
  }

  void _showWeatherDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WeatherReportScreen(isDialog: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final isToday = provider.currentDate.year == now.year &&
            provider.currentDate.month == now.month &&
            provider.currentDate.day == now.day;
        final currentMinuteOffset = (now.hour * hourHeight) + (now.minute / 60.0 * hourHeight);

        return Scaffold(
          body: Column(
            children: [
              // Collapsible Daily Poster Banner
              _buildCollapsibleBanner(colorScheme),

              // Non-blocking Morning Briefing / Weather Bar
              _buildWeatherSection(provider, colorScheme),

              // 24h Dual Timeline
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    height: 24 * hourHeight,
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTimeGutter(colorScheme),
                            VerticalDivider(width: 1, thickness: 1, color: colorScheme.outline.withOpacity(0.2)),
                            Expanded(child: _buildColumn(provider, true, colorScheme)),
                            VerticalDivider(width: 1, thickness: 1, color: colorScheme.outline.withOpacity(0.2)),
                            Expanded(child: _buildColumn(provider, false, colorScheme)),
                          ],
                        ),
                        // Live Timeline Note Ribbons (Captain's Log Pins)
                        ...provider.journalNotes.map((note) {
                          final noteHour = note.timestamp.hour + (note.timestamp.minute / 60.0);
                          return Positioned(
                            top: (noteHour * hourHeight) - 10,
                            left: 54,
                            right: 8,
                            child: _buildTimelineNoteRibbon(note, provider, colorScheme),
                          );
                        }).toList(),

                        // Live Current Time Indicator Line
                        if (isToday) _buildCurrentTimeIndicator(currentMinuteOffset, colorScheme, provider),
                      ],
                    ),
                  ),
                ),
              ),

              // Collapsible Bottom Drawer (Inbox & Logbook)
              _buildCollapsibleBottomTray(provider, colorScheme),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isToday) ...[
                  FloatingActionButton.extended(
                    heroTag: 'jumpToNowBtn',
                    tooltip: 'Jump to Current Time',
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.primary,
                    elevation: 3,
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(
                      DateFormat('h:mm a').format(DateTime.now()),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: _scrollToCurrentTime,
                  ),
                  const SizedBox(width: 8),
                ],
                FloatingActionButton.small(
                  heroTag: 'addNoteBtn',
                  tooltip: 'Log Note at Current Time',
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  elevation: 3,
                  onPressed: () => _showAddNoteDialog(context, provider, defaultTime: DateTime.now()),
                  child: const Icon(Icons.edit_note_rounded, size: 22),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'addEntryBtn',
                  tooltip: 'Add Time Block',
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 4,
                  onPressed: () => _showAddEntryDialog(context, provider),
                  child: const Icon(Icons.add_rounded, size: 28),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherSection(CalendarProvider provider, ColorScheme colorScheme) {
    if (!provider.isDayCharted) {
      return _buildUnchartedBriefingCard(provider, colorScheme);
    } else {
      return _buildChartedStatusBar(provider, colorScheme);
    }
  }

  Widget _buildUnchartedBriefingCard(CalendarProvider provider, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _isBriefingExpanded = !_isBriefingExpanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.sailing_rounded, size: 16, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Morning Briefing',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Uncharted',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Calibrate weather conditions to set sail',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isBriefingExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_isBriefingExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 12),
                  if (provider.weatherTags.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'No weather tags defined. Ready for clear skies!',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: provider.weatherTags.map((tag) {
                        final isSelected = _selectedWeatherTagIds.contains(tag.id);
                        return FilterChip(
                          visualDensity: VisualDensity.compact,
                          selected: isSelected,
                          showCheckmark: true,
                          checkmarkColor: colorScheme.onPrimary,
                          label: Text(tag.name),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                          ),
                          selectedColor: colorScheme.primary,
                          backgroundColor: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedWeatherTagIds.add(tag.id!);
                              } else {
                                _selectedWeatherTagIds.remove(tag.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.explore_rounded, size: 16),
                          label: const Text('Set Sail', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            await provider.chartTheCourse(_selectedWeatherTagIds.toList());
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          await provider.chartTheCourse([]);
                        },
                        child: const Text('Clear Skies', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartedStatusBar(CalendarProvider provider, ColorScheme colorScheme) {
    final activeTagIds = provider.currentDayWeather?.activeTagIds ?? [];
    final activeTags = provider.weatherTags.where((t) => activeTagIds.contains(t.id)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'Charted:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: activeTags.isEmpty
                ? Text(
                    'Clear Skies',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: activeTags.map((tag) {
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          InkWell(
            onTap: () => _showWeatherDialog(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 12, color: colorScheme.primary),
                  const SizedBox(width: 3),
                  Text(
                    'Weather',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
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

  Widget _buildCollapsibleBanner(ColorScheme colorScheme) {
    return AnimatedCrossFade(
      firstChild: InteractiveLookoutDeck(
        onToggleCollapse: () => setState(() => _isBannerExpanded = false),
      ),
      secondChild: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () => setState(() => _isBannerExpanded = true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined, size: 13, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      "Show Lookout Deck 🦜",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more_rounded, size: 14, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      crossFadeState: _isBannerExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 250),
    );
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'Thought':
        return Colors.amber.shade600;
      case 'Focus':
        return Colors.purpleAccent.shade400;
      case 'Win':
        return Colors.green.shade600;
      case 'Break':
        return Colors.orange.shade600;
      case 'Blocker':
        return Colors.redAccent.shade400;
      case 'Log':
      default:
        return Colors.blue.shade600;
    }
  }

  IconData _getTagIcon(String tag) {
    switch (tag) {
      case 'Thought':
        return Icons.lightbulb_outline_rounded;
      case 'Focus':
        return Icons.bolt_rounded;
      case 'Win':
        return Icons.star_rounded;
      case 'Break':
        return Icons.coffee_rounded;
      case 'Blocker':
        return Icons.warning_amber_rounded;
      case 'Log':
      default:
        return Icons.notes_rounded;
    }
  }

  Widget _buildTimelineNoteRibbon(JournalNote note, CalendarProvider provider, ColorScheme colorScheme) {
    final tagColor = _getTagColor(note.tag);
    return GestureDetector(
      onTap: () => _showAddNoteDialog(context, provider, initialNote: note),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tagColor.withOpacity(0.6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getTagIcon(note.tag), size: 13, color: tagColor),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: tagColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                DateFormat('h:mm a').format(note.timestamp),
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: tagColor),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                note.content,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(double topOffset, ColorScheme colorScheme, CalendarProvider provider) {
    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          IgnorePointer(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(left: 48),
              color: Colors.redAccent,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  DateFormat('h:mm').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _showAddNoteDialog(context, provider, defaultTime: DateTime.now()),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_comment_rounded, size: 10, color: Colors.redAccent),
                      const SizedBox(width: 3),
                      Text(
                        'Log',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeGutter(ColorScheme colorScheme) {
    return SizedBox(
      width: 54,
      child: Stack(
        children: List.generate(24, (index) {
          final time = DateTime(2020, 1, 1, index);
          return Positioned(
            top: index * hourHeight,
            left: 0,
            right: 0,
            child: Container(
              height: hourHeight,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 6.0, top: 8.0),
              child: Text(
                DateFormat('ha').format(time).toLowerCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildColumn(CalendarProvider provider, bool isPlan, ColorScheme colorScheme) {
    return Stack(
      children: [
        // Background grid lines
        ...List.generate(24, (index) {
          return Positioned(
            top: index * hourHeight,
            left: 0,
            right: 0,
            child: Container(
              height: hourHeight,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.12),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          );
        }),
        // Column header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.85),
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPlan ? Icons.edit_calendar_rounded : Icons.play_arrow_rounded,
                  size: 14,
                  color: isPlan ? colorScheme.primary : colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  isPlan ? 'Plan' : 'Execution',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: isPlan ? colorScheme.primary : colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Render blocks
        if (isPlan)
          ...provider.blocks.map((block) {
            final startHour = block.startTime.hour + (block.startTime.minute / 60.0);
            final endHour = block.endTime.hour + (block.endTime.minute / 60.0);
            final duration = endHour - startHour;
            return Positioned(
              top: startHour * hourHeight,
              left: 4,
              right: 4,
              height: duration * hourHeight,
              child: _buildPlanBlockWidget(block, provider),
            );
          }).toList()
        else
          ...provider.executionSessions.map((session) {
            final block = provider.blocks.firstWhere(
              (b) => b.id == session.blockId,
              orElse: () => model.Block(
                title: 'Unknown',
                category: 'unknown',
                date: DateTime.now(),
                startTime: DateTime.now(),
                endTime: DateTime.now(),
                colorValue: Colors.grey.value,
              ),
            );
            final startHour = session.startTime.hour + (session.startTime.minute / 60.0);
            final end = session.endTime ?? DateTime.now();
            final endHour = end.hour + (end.minute / 60.0);
            double duration = endHour - startHour;
            if (duration < 0.25) duration = 0.25; // min height for visibility
            
            return Positioned(
              top: startHour * hourHeight,
              left: 4,
              right: 4,
              height: duration * hourHeight,
              child: _buildExecutionSessionWidget(session, block),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildPlanBlockWidget(model.Block block, CalendarProvider provider) {
    final isActive = provider.isBlockActive(block.id!);
    final blockColor = Color(block.colorValue);
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => BlockDetailsDialog(block: block, provider: provider),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: blockColor.withOpacity(0.22),
          border: Border(left: BorderSide(color: blockColor, width: 4)),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    block.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                InkResponse(
                  radius: 16,
                  onTap: () {
                    if (isActive) {
                      provider.stopBlock(block);
                    } else {
                      provider.startBlock(block);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      isActive ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      size: 20,
                      color: blockColor,
                    ),
                  ),
                )
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: block.tasks.where((t) => t.planned).map((task) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => provider.toggleTaskPlanCompletion(task),
                          child: Icon(
                            task.completedPlan ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            size: 13,
                            color: blockColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 10,
                              decoration: task.completedPlan ? TextDecoration.lineThrough : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionSessionWidget(ExecutionSession session, model.Block block) {
    final blockColor = Color(block.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: blockColor.withOpacity(0.38),
        border: Border(left: BorderSide(color: blockColor, width: 4)),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          if (session.endTime == null)
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const Text(
                  "In Progress...",
                  style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleBottomTray(CalendarProvider provider, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Tab 0: Tasks (Inbox)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _bottomTrayTab = 0;
                          _isBottomTrayExpanded = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _bottomTrayTab == 0
                              ? colorScheme.primary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 16,
                              color: _bottomTrayTab == 0 ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Tasks",
                              style: TextStyle(
                                fontWeight: _bottomTrayTab == 0 ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                                color: _bottomTrayTab == 0 ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: _bottomTrayTab == 0
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${provider.standaloneTasks.length}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _bottomTrayTab == 0
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Tab 1: Logbook (Notes)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _bottomTrayTab = 1;
                          _isBottomTrayExpanded = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _bottomTrayTab == 1
                              ? colorScheme.secondary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 16,
                              color: _bottomTrayTab == 1 ? colorScheme.secondary : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Logbook",
                              style: TextStyle(
                                fontWeight: _bottomTrayTab == 1 ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                                color: _bottomTrayTab == 1 ? colorScheme.secondary : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: _bottomTrayTab == 1
                                    ? colorScheme.secondaryContainer
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${provider.journalNotes.length}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _bottomTrayTab == 1
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add, size: 16),
                      visualDensity: VisualDensity.compact,
                      tooltip: _bottomTrayTab == 0 ? 'Add Task' : 'Log Note',
                      onPressed: () {
                        if (_bottomTrayTab == 0) {
                          _showAddTaskDialog(context, provider);
                        } else {
                          _showAddNoteDialog(context, provider, defaultTime: DateTime.now());
                        }
                      },
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: Icon(
                        _isBottomTrayExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _isBottomTrayExpanded = !_isBottomTrayExpanded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isBottomTrayExpanded)
            SizedBox(
              height: 120,
              child: _bottomTrayTab == 0
                  ? (provider.standaloneTasks.isEmpty
                      ? Center(
                          child: Text(
                            "No tasks in inbox.",
                            style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7), fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.standaloneTasks.length,
                          itemBuilder: (context, index) {
                            final task = provider.standaloneTasks[index];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: InkWell(
                                onTap: () => provider.toggleTaskPlanCompletion(task),
                                child: Icon(
                                  task.completedPlan ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: task.completedPlan ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                tooltip: 'Delete task',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => provider.deleteTask(task.id!),
                              ),
                              onTap: () => provider.toggleTaskPlanCompletion(task),
                            );
                          },
                        ))
                  : (provider.journalNotes.isEmpty
                      ? Center(
                          child: Text(
                            "No log entries today. Tap + to record a thought or note!",
                            style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7), fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.journalNotes.length,
                          itemBuilder: (context, index) {
                            final note = provider.journalNotes[index];
                            final tagColor = _getTagColor(note.tag);
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              onTap: () => _showAddNoteDialog(context, provider, initialNote: note),
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tagColor.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getTagIcon(note.tag), size: 12, color: tagColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      DateFormat('h:mm a').format(note.timestamp),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                note.content,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 16),
                            );
                          },
                        )),
            ),
        ],
      ),
    );
  }
}
