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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  _buildMonthHeader(theme, today),
                  const SizedBox(height: 12),
                  _buildWeekdayHeader(),
                  const SizedBox(height: 6),
                  _buildCalendarGrid(today),
                  const SizedBox(height: 16),
                  _buildDayPreviewCard(theme, today),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(ThemeData theme, DateTime today) {
    final monthFormat = DateFormat('MMMM yyyy');
    final isCurrentMonth = _focusedMonth.year == today.year && _focusedMonth.month == today.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.blueGrey),
            onPressed: _previousMonth,
            tooltip: 'Previous Month',
          ),
          Row(
            children: [
              Text(
                monthFormat.format(_focusedMonth),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade900,
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
                      color: Colors.blueGrey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.blueGrey),
            onPressed: _nextMonth,
            tooltip: 'Next Month',
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
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
                color: Colors.blueGrey.shade400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(DateTime today) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday;
    final prevMonthDays = DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;
    final totalCells = ((startingWeekday - 1 + daysInMonth) / 7.0).ceil() * 7;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
  }) {
    Color? backgroundColor;
    Border? border;

    if (isSelected) {
      backgroundColor = Colors.blueGrey.shade800;
    } else if (isToday) {
      backgroundColor = Colors.blueGrey.shade100;
      border = Border.all(color: Colors.blueGrey.shade600, width: 1.5);
    }

    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (!isCurrentMonth) {
      textColor = Colors.grey.shade400;
    } else if (isToday) {
      textColor = Colors.blueGrey.shade900;
    } else {
      textColor = Colors.blueGrey.shade800;
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
              '',
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
                      color: isSelected ? Colors.amberAccent : Colors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (blockCount > 0)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.lightBlueAccent : Colors.blueGrey.shade400,
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

  Widget _buildDayPreviewCard(ThemeData theme, DateTime today) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
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
                        color: isCharted ? Colors.teal.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCharted ? Colors.teal.shade300 : Colors.orange.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCharted ? Icons.check_circle_outline : Icons.explore_off_outlined,
                            size: 14,
                            color: isCharted ? Colors.teal.shade800 : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCharted ? 'Charted' : 'Uncharted',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCharted ? Colors.teal.shade800 : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                if (isCharted && _selectedDayWeather!.activeTagIds.isNotEmpty) ...[
                  const Text(
                    'Daily Weather',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedDayWeather!.activeTagIds.map((tagId) {
                      final tag = _allWeatherTags.firstWhere(
                        (t) => t.id == tagId,
                        orElse: () => WeatherTag(name: 'Tag #', recurrenceRule: '{}'),
                      );
                      return Chip(
                        avatar: const Icon(Icons.tag, size: 14, color: Colors.blueGrey),
                        label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        backgroundColor: Colors.blueGrey.shade50,
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
                      'Planned Blocks ()',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    if (totalLoggedMinutes > 0)
                      Text(
                        'Logged: ' + (loggedHours > 0 ? 'h ' : '') + 'm',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade700,
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
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Text(
                        isCharted
                            ? 'No time blocks planned for this day.'
                            : 'Course has not been charted yet.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                          color: Color(block.colorValue).withValues(alpha: 0.12),
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
                                    ' – ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (block.tasks.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '/ tasks',
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
                      backgroundColor: Colors.blueGrey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _openDayInTimeline(context),
                    icon: Icon(
                      isCharted ? Icons.timeline : Icons.sailing,
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