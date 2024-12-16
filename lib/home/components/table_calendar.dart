import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWithUnavailableDates extends StatefulWidget {
  final List<DateTimeRange> unavailableDates;
  const CalendarWithUnavailableDates(
      {required this.unavailableDates, super.key});

  @override
  _CalendarWithUnavailableDatesState createState() =>
      _CalendarWithUnavailableDatesState();
}

class _CalendarWithUnavailableDatesState
    extends State<CalendarWithUnavailableDates> {
  late Set<DateTime> unavailableDays;

  @override
  void initState() {
    super.initState();
    unavailableDays = _generateUnavailableDays(widget.unavailableDates);
    print('The unavailable dates are: $unavailableDays');
  }

  // Normalize DateTime by setting time to midnight
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Set<DateTime> _generateUnavailableDays(List<DateTimeRange> ranges) {
    final Set<DateTime> days = {};
    for (final range in ranges) {
      for (int i = 0; i <= range.end.difference(range.start).inDays; i++) {
        DateTime day = DateTime(
          range.start.year,
          range.start.month,
          range.start.day + i,
        );
        days.add(_normalizeDate(day)); // Normalize each date
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Unavailable Dates"),
      ),
      body: TableCalendar(
        focusedDay: DateTime.now(),
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            DateTime normalizedDay = _normalizeDate(day);
            if (unavailableDays.contains(normalizedDay)) {
              return Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            }
            return null;
          },
        ),
        onDaySelected: (selectedDay, focusedDay) {
          DateTime normalizedSelectedDay = _normalizeDate(selectedDay);
          if (unavailableDays.contains(normalizedSelectedDay)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This date is unavailable.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You selected: $selectedDay')),
            );
          }
        },
      ),
    );
  }
}


// void main() {
//   runApp(MaterialApp(
//     home: CalendarWithUnavailableDates(
//       unavailableDates: [
//         DateTimeRange(
//           start: DateTime(2024, 12, 20),
//           end: DateTime(2024, 12, 25),
//         ),
//         DateTimeRange(
//           start: DateTime(2024, 12, 30),
//           end: DateTime(2024, 12, 31),
//         ),
//       ],
//     ),
//   ));
// }
