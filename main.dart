import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Báo Thức App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AlarmPage(),
      debugShowCheckedModeBanner: false, // Disable the debug banner
    );
  }
}

class Alarm {
  final String id;
  final TimeOfDay time;
  bool isActive;

  Alarm({required this.id, required this.time, this.isActive = true});
}

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  List<Alarm> alarms = [];
  int alarmCount = 0;
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    tz.initializeTimeZones();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _setAlarm() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    String alarmId = 'alarm_${alarmCount++}';
    alarms.add(Alarm(id: alarmId, time: _selectedTime));

    await _notificationsPlugin.zonedSchedule(
      alarmId.hashCode,
      'Báo Thức',
      'Đến giờ báo thức!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          channelDescription: 'your_channel_description',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    setState(() {});
  }

  void _toggleAlarm(Alarm alarm) {
    setState(() {
      alarm.isActive = !alarm.isActive;
      if (!alarm.isActive) {
        _cancelAlarm(alarm);
      } else {
        _setAlarm();
      }
    });
  }

  Future<void> _cancelAlarm(Alarm alarm) async {
    await _notificationsPlugin.cancel(alarm.id.hashCode);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _deleteAlarm(Alarm alarm) {
    setState(() {
      _cancelAlarm(alarm); // Cancel the notification
      alarms.remove(alarm); // Remove the alarm from the list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Thức App'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chọn thời gian: ${_selectedTime.hour}:${_selectedTime.minute}'),
                ElevatedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTime = time;
                      });
                    }
                  },
                  child: const Text('Chọn Thời Gian'),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _setAlarm,
            child: const Text('Đặt Báo Thức'),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                return ListTile(
                  title: Text('Báo thức: ${_formatTime(alarm.time)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: alarm.isActive,
                        onChanged: (value) => _toggleAlarm(alarm),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAlarm(alarm),
                      ),
                    ],
                  ),
                  onLongPress: () => _deleteAlarm(alarm),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}