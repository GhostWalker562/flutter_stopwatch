import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StopwatchProvider extends ChangeNotifier {
  //* Static values and constants
  static const Duration kTimerSpeed = Duration(milliseconds: 10);
  static const String kPreviousDateTime = 'previousDateTime';
  static const String kPreviousLapTime = 'previousLapTime';
  static const String kPreviousTime = 'previousTime';
  static const String kPreviousLaps = 'previousLaps';
  static const String kIsRunning = 'isRunning';
  static late SharedPreferences prefs;

  StopwatchProvider() {
    _refreshSp();
  }

  //* Preferences Begin

  /// When the app is opened, it will create the provider and call this function.
  /// This function retrieves all values needed to return the stopwatch to its
  /// previous state before the app has been detached.
  void _refreshSp() async {
    prefs = await SharedPreferences.getInstance();
    // retrieve values
    String? previousDateTime = prefs.getString(kPreviousDateTime);
    String? previousLapTime = prefs.getString(kPreviousLapTime);
    String? previousTime = prefs.getString(kPreviousTime);
    List<String>? previousLaps = prefs.getStringList(kPreviousLaps);
    bool? isRunning = prefs.getBool(kIsRunning);
    // If all values are available, then we proceed with refreshing the state.
    if (previousDateTime != null &&
        previousLapTime != null &&
        previousTime != null &&
        previousLaps != null) {
      // We take the duration from when the app was detached and add it to the
      // previous durations.
      Duration dur =
          DateTime.now().difference(DateTime.parse(previousDateTime));

      // If the timer was running, we will continue to run the timer. Otherwise
      // we set dur to zero because we don't want to add the time.
      if (isRunning ?? false) {
        runTimer();
      } else {
        dur = Duration.zero;
      }

      // Add the time and refresh the laps.
      time = Duration(milliseconds: int.parse(previousTime)) + dur;
      lapTime = Duration(milliseconds: int.parse(previousLapTime)) + dur;
      for (String lap in previousLaps) {
        laps.add(Duration(milliseconds: int.parse(lap)));
      }

      notifyListeners();
    }
  }

  /// Save all stopwatch values.
  void saveSp() async {
    // save dateTime
    await prefs.setString(kPreviousDateTime, DateTime.now().toString());
    // save time
    await prefs.setString(kPreviousTime, time.inMilliseconds.toString());
    // save lap time
    await prefs.setString(kPreviousLapTime, lapTime.inMilliseconds.toString());
    // save laps
    await prefs.setStringList(
        kPreviousLaps, laps.map((e) => e.inMilliseconds.toString()).toList());
    // save isRunning
    await prefs.setBool(kIsRunning, _timer?.isActive ?? false);
  }

  /// Clear all stopwatch values.
  void resetSp() async => await prefs.clear();

  //* Timing Begin

  Timer? _timer;

  /// Returns whether the timer is still active.
  bool get running => _timer?.isActive ?? false;

  /// [Time] is the primary time of the stopwatch. [lapTime] is the secondary time
  /// that will reset whenever a lap is recoreded.
  Duration time = Duration.zero, lapTime = Duration.zero;

  /// Laps recorded by the user.
  final List<Duration> laps = [];

  /// Returns the shortest lap in [laps] if [laps] has two or more laps.
  Duration? get shortestLap {
    if (laps.length < 2) return null;
    Duration temp = laps[0];
    for (Duration lap in laps) {
      if (lap < temp) temp = lap;
    }
    return temp;
  }

  /// Returns the longest lap in [laps] if [laps] has two or more laps.
  Duration? get longestLap {
    if (laps.length < 2) return null;
    Duration temp = laps[0];
    for (Duration lap in laps) {
      if (lap > temp) temp = lap;
    }
    return temp;
  }

  /// Increment the [time] and [lapTime]. This will be called whenever [_timer] ticks.
  /// Will also save when the Platform is not iOS or Android so that it can support
  /// desktop because desktop has no detached state.
  void _incrementTime(Timer timer) => notify(() {
        time += kTimerSpeed;
        lapTime += kTimerSpeed;
        // I would check for iOS but I don't hardware to test it. Better safe
        // than sorry.
        if (!(Platform.isAndroid)) saveSp();
      });

  /// Start the timer.
  void runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(kTimerSpeed, _incrementTime);
  }

  /// Stop the timer.
  void stopTimer() => notify(() {
        _timer?.cancel();
        saveSp();
      });

  /// Reset the timer and clear Sp.
  void resetTimer() => notify(() {
        time = Duration.zero;
        lapTime = Duration.zero;
        laps.clear();
        resetSp();
      });

  /// Record a lap into [laps] and reset [lapTime].
  void recordLap() => notify(() {
        laps.add(lapTime);
        lapTime = Duration.zero;
        saveSp();
      });

  /// Helper function to notify listeners.
  void notify([VoidCallback? action]) {
    action?.call();
    notifyListeners();
  }
}

class StopwatchProviderWrapper extends StatelessWidget {
  /// Provider and consumer wrapper for [StopwatchProvider] notifier.
  const StopwatchProviderWrapper({
    Key? key,
    required this.builder,
    this.provider,
    this.child,
  }) : super(key: key);

  /// [child] contained by this widget.
  final Widget? child;

  /// Build a widget tree based on [StopwatchProvider].
  final Widget Function(BuildContext, StopwatchProvider, Widget?) builder;

  /// Helper function to access the provider created.
  final void Function(StopwatchProvider provider)? provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final e = StopwatchProvider();
        provider?.call(e);
        return e;
      },
      builder: (context, child) => Consumer<StopwatchProvider>(
        builder: builder,
        child: child,
      ),
    );
  }
}
