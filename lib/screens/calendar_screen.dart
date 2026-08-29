import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart' hide Block;
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/models/block.dart';
import 'package:crows_nest/models/day_weather.dart';
import 'package:crows_nest/models/weather_tag.dart';
import 'package:crows_nest/models/execution_session.dart';
import 'package:crows_nest/services/database_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseService _db = DatabaseService();
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  bool _isLoadingMonth = true;
  Set<String> _chartedDates = {};
  Map<String, int> _blockCounts = {};

  bool _isLoadingDay = true;
  DayWeather? _selectedDayWeather;
  List<Block> _selectedDayBlocks = [];
  List<ExecutionSession> _selectedDaySessions = [];
  List<WeatherTag> _allWeatherTags = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    _selectedDate = DateTime(
      provider.currentDate.year,
      provider.currentDate.month,
      provider.currentDate.day,
    );
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);

    _loadMonthData();
    _loadSelectedDayData();
  }

  Future<void> _loadMonthData() async {
    setState(() => _isLoadingMonth = true);
    final charted = await _db.getChartedDatesInMonth(_focusedMonth.year, _focusedMonth.month);
    final counts = await _db.getBlockCountsByDateInMonth(_focusedMonth.year, _focusedMonth.month);
    final tags = await _db.getWeatherTags();

    if (mounted) {
      setState(() {
        _chartedDates = charted;
        _blockCounts = counts;
        _allWeatherTags = tags;
        _isLoadingMonth = false;
      });
    }
  }

  Future<void> _loadSelectedDayData() async {
    setState(() => _isLoadingDay = true);
    final weather = await _db.getDayWeather(_selectedDate);
    final blocks = await _db.getBlocksForDate(_selectedDate);
    final sessions = await _db.getExecutionSessionsForDate(_selectedDate);

    if (mounted) {
      setState(() {
        _selectedDayWeather = weather;
        _selectedDayBlocks = blocks;
        _selectedDaySessions = sessions;
        _isLoadingDay = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
    _loadMonthData();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
    _loadMonthData();
  }

  void _goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _selectedDate = today;
      _focusedMonth = DateTime(today.year, today.month, 1);
    });
    _loadMonthData();
    _loadSelectedDayData();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (date.month != _focusedMonth.month || date.year != _focusedMonth.year) {
        _focusedMonth = DateTime(date.year, date.month, 1);
        _loadMonthData();
      }
    });
    _loadSelectedDayData();
  }

  void _openDayInTimeline(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    provider.setDate(_selectedDate);
    GoRouter.of(context).go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  _buildMonthHeader(theme, today, colorScheme),
                  const SizedBox(height: 12),
                  _buildWeekdayHeader(colorScheme),
                  const SizedBox(height: 6),
                  _buildCalendarGrid(today, colorScheme),
                  const SizedBox(height: 16),
                  _buildDayPreviewCard(theme, today, colorScheme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(ThemeData theme, DateTime today, ColorScheme colorScheme) {
    final monthFormat = DateFormat('MMMM yyyy');
    final isCurrentMonth = _focusedMonth.year == today.year && _focusedMonth.month == today.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: colorScheme.primary),
            onPressed: _previousMonth,
            tooltip: 'Previous Month',
          ),
          Row(
            children: [
              Text(
                monthFormat.format(_focusedMonth),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (!isCurrentMonth) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _goToToday,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
            onPressed: _nextMonth,
            tooltip: 'Next Month',
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(ColorScheme colorScheme) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(DateTime today, ColorScheme colorScheme) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday;
    final prevMonthDays = DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;
    final totalCells = ((startingWeekday - 1 + daysInMonth) / 7.0).ceil() * 7;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: _isLoadingMonth
          ? const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                DateTime cellDate;
                bool isCurrentMonthCell = true;

                if (index < startingWeekday - 1) {
                  final dayNum = prevMonthDays - (startingWeekday - 2 - index);
                  cellDate = DateTime(_focusedMonth.year, _focusedMonth.month - 1, dayNum);
                  isCurrentMonthCell = false;
                } else if (index >= startingWeekday - 1 + daysInMonth) {
                  final dayNum = index - (startingWeekday - 1 + daysInMonth) + 1;
                  cellDate = DateTime(_focusedMonth.year, _focusedMonth.month + 1, dayNum);
                  isCurrentMonthCell = false;
                } else {
                  final dayNum = index - (startingWeekday - 1) + 1;
                  cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                }

                final isToday = cellDate.year == today.year &&
                    cellDate.month == today.month &&
                    cellDate.day == today.day;
                final isSelected = cellDate.year == _selectedDate.year &&
                    cellDate.month == _selectedDate.month &&
                    cellDate.day == _selectedDate.day;

                final dateKey = DateFormat('yyyy-MM-dd').format(cellDate);
                final isCharted = _chartedDates.contains(dateKey);
                final blockCount = _blockCounts[dateKey] ?? 0;

                return _buildDayCell(
                  cellDate: cellDate,
                  isCurrentMonth: isCurrentMonthCell,
                  isToday: isToday,
                  isSelected: isSelected,
                  isCharted: isCharted,
                  blockCount: blockCount,
                  colorScheme: colorScheme,
                );
              },
            ),
    );
  }

  Widget _buildDayCell({
    required DateTime cellDate,
    required bool isCurrentMonth,
    required bool isToday,
    required bool isSelected,
    required bool isCharted,
    required int blockCount,
    required ColorScheme colorScheme,
  }) {
    Color? backgroundColor;
    Border? border;

    if (isSelected) {
      backgroundColor = colorScheme.primary;
    } else if (isToday) {
      backgroundColor = colorScheme.primaryContainer.withOpacity(0.5);
      border = Border.all(color: colorScheme.primary, width: 1.5);
    }

    Color textColor;
    if (isSelected) {
      textColor = colorScheme.onPrimary;
    } else if (!isCurrentMonth) {
      textColor = colorScheme.onSurfaceVariant.withOpacity(0.35);
    } else if (isToday) {
      textColor = colorScheme.primary;
    } else {
      textColor = colorScheme.onSurface;
    }

    return InkWell(
      onTap: () => _onDateSelected(cellDate),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${cellDate.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCharted)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.onPrimary : colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (blockCount > 0)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.onPrimary.withOpacity(0.7) : colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPreviewCard(ThemeData theme, DateTime today, ColorScheme colorScheme) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    final isCharted = _selectedDayWeather != null;

    int totalLoggedMinutes = 0;
    for (var session in _selectedDaySessions) {
      final end = session.endTime ?? (isToday ? DateTime.now() : session.startTime);
      totalLoggedMinutes += end.difference(session.startTime).inMinutes;
    }
    final loggedHours = totalLoggedMinutes ~/ 60;
    final loggedRemMinutes = totalLoggedMinutes % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isLoadingDay
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              dateFormat.format(_selectedDate),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'TODAY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCharted ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCharted ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCharted ? Icons.check_circle_outline_rounded : Icons.explore_off_outlined,
                            size: 14,
                            color: isCharted ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCharted ? 'Charted' : 'Uncharted',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCharted ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                if (isCharted && _selectedDayWeather!.activeTagIds.isNotEmpty) ...[
                  Text(
                    'Daily Weather',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedDayWeather!.activeTagIds.map((tagId) {
                      final tag = _allWeatherTags.firstWhere(
                        (t) => t.id == tagId,
                        orElse: () => WeatherTag(name: 'Tag #$tagId', recurrenceRule: '{}'),
                      );
                      return Chip(
                        avatar: Icon(Icons.tag_rounded, size: 14, color: colorScheme.primary),
                        label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Planned Blocks (${_selectedDayBlocks.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (totalLoggedMinutes > 0)
                      Text(
                        'Logged: ' + (loggedHours > 0 ? '${loggedHours}h ' : '') + '${loggedRemMinutes}m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_selectedDayBlocks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        isCharted
                            ? 'No time blocks planned for this day.'
                            : 'Course has not been charted yet.',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedDayBlocks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final block = _selectedDayBlocks[index];
                      final timeFormat = DateFormat('h:mm a');
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(block.colorValue).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: Color(block.colorValue),
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    block.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${timeFormat.format(block.startTime)} – ${timeFormat.format(block.endTime)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (block.tasks.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${block.tasks.where((t) => t.completedPlan).length}/${block.tasks.length} tasks',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _openDayInTimeline(context),
                    icon: Icon(
                      isCharted ? Icons.timeline_rounded : Icons.sailing_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isCharted ? 'Open Dual Timeline' : 'Chart Course For This Day',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}