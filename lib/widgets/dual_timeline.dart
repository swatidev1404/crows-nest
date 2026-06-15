import 'dart:async';
import 'package:flutter/material.dart';
import '../models/calendar_entry.dart';

class DualTimeline extends StatefulWidget {
  final List<CalendarEntry> entries;
  final Function(CalendarEntry) onEntryTap;
  final VoidCallback onEmptyTap;

  const DualTimeline({
    super.key,
    required this.entries,
    required this.onEntryTap,
    required this.onEmptyTap,
  });

  @override
  State<DualTimeline> createState() => _DualTimelineState();
}

class _DualTimelineState extends State<DualTimeline> {
  static const double _pixelsPerMinute = 3.5; // 210px per hour
  static const double _hourHeight = 60 * _pixelsPerMinute;
  static const double _timeColumnWidth = 60.0;
  static const double _horizontalPadding = 16.0;

  late Timer _timer;
  DateTime _now = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentMinutes = _now.hour * 60 + _now.minute;
      final targetOffset = (currentMinutes * _pixelsPerMinute) - (MediaQuery.of(context).size.height / 3);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(targetOffset.clamp(0.0, 24 * _hourHeight));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: GestureDetector(
        onTap: widget.onEmptyTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 24 * _hourHeight,
          child: Stack(
            children: [
              _buildBackgroundLines(),
              _buildCenterAxis(),
              _buildEntries(context),
              _buildCurrentTimeLine(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundLines() {
    return Column(
      children: List.generate(24, (index) {
        return Container(
          height: _hourHeight,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
          ),
        );
      }),
    );
  }

  Widget _buildCenterAxis() {
    return Positioned.fill(
      child: Row(
        children: [
          Expanded(child: Container()),
          SizedBox(
            width: _timeColumnWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: Container(width: 1, color: Colors.grey.withValues(alpha: 0.3))),
                ...List.generate(24, (index) {
                  return Positioned(
                    top: index * _hourHeight - 8,
                    left: 0,
                    right: 0,
                    child: Text(
                      '${index.toString().padLeft(2, '0')}:00',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeLine() {
    final minutes = _now.hour * 60 + _now.minute;
    final top = minutes * _pixelsPerMinute;
    return Positioned(
      top: top - 4, // Center the dot
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            Expanded(child: Container(height: 1, color: Colors.red.withValues(alpha: 0.5))),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
            Expanded(child: Container(height: 1, color: Colors.red.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildEntries(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - _timeColumnWidth - (_horizontalPadding * 2)) / 2;
        
        return Stack(
          children: widget.entries.expand((entry) {
            final widgets = <Widget>[];
            
            // Planned Block (Left)
            final plannedTop = entry.plannedStartMinutes * _pixelsPerMinute;
            final plannedHeight = entry.plannedDurationMinutes * _pixelsPerMinute;
            final isNow = entry.status == EntryStatus.inProgress;
            
            widgets.add(Positioned(
              top: plannedTop,
              left: _horizontalPadding,
              width: columnWidth,
              height: plannedHeight,
              child: _buildCard(entry, isPlanned: true, isNow: isNow),
            ));

            // Executed Block (Right)
            if (entry.status == EntryStatus.completed || entry.status == EntryStatus.inProgress) {
              final actualStart = entry.actualStartMinutes ?? entry.plannedStartMinutes;
              final actualEnd = entry.status == EntryStatus.completed
                  ? (entry.actualEndMinutes ?? (actualStart + entry.plannedDurationMinutes))
                  : (_now.hour * 60 + _now.minute);
              final actualHeight = ((actualEnd - actualStart) * _pixelsPerMinute).clamp(20.0, double.infinity);
              
              widgets.add(Positioned(
                top: actualStart * _pixelsPerMinute,
                right: _horizontalPadding,
                width: columnWidth,
                height: actualHeight,
                child: _buildCard(entry, isPlanned: false, isNow: isNow),
              ));
            }
            
            return widgets;
          }).toList(),
        );
      },
    );
  }

  Widget _buildCard(CalendarEntry entry, {required bool isPlanned, required bool isNow}) {
    Color bgColor;
    Color textColor;
    Color iconColor;
    
    if (isNow) {
      bgColor = const Color(0xFFFFF7ED); // Pale Orange
      textColor = const Color(0xFF9A3412);
      iconColor = const Color(0xFFEA580C);
    } else if (isPlanned) {
      bgColor = const Color(0xFFF8FAFC); // Very light slate/blue
      textColor = const Color(0xFF334155);
      iconColor = const Color(0xFF0369A1);
    } else {
      bgColor = const Color(0xFFF0FDF4); // Pale green
      textColor = const Color(0xFF166534);
      iconColor = const Color(0xFF16A34A);
    }

    return GestureDetector(
      onTap: () => widget.onEntryTap(entry),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(isPlanned ? Icons.work_outline : Icons.check_circle, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Expanded(child: Text(entry.blockName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (isNow && isPlanned) 
                  Text('NOW', style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              isPlanned 
                ? '${entry.plannedStartLabel} - ${entry.plannedEndLabel}'
                : '${entry.actualStartLabel} - ${entry.actualEndLabel ?? "..."}',
              style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
