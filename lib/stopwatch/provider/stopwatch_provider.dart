import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StopwatchProvider extends ChangeNotifier {
  //* Static values and constants
  static const Duration kTimerSpeed = Duration(milliseconds: 10);
  static const String kPreviousPrimaryDuration = 'previousPrimaryDuration';
  static const String kPreviousLapDuration = 'previousLapDuration';
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
    int? previousPrimaryDuration = prefs.getInt(kPreviousPrimaryDuration);
    int? previousLapDuration = prefs.getInt(kPreviousLapDuration);
    String? previousLapTime = prefs.getString(kPreviousLapTime);
    String? previousTime = prefs.getString(kPreviousTime);
    List<String>? previousLaps = prefs.getStringList(kPreviousLaps);
    // If all values are available, then we proceed with refreshing the state.
    if (previousPrimaryDuration != null &&
        previousLapDuration != null &&
        previousLaps != null) {
      // Refresh the laps.
      for (String lap in previousLaps) {
        laps.add(Duration(milliseconds: int.parse(lap)));
      }
      _lapDuration += Duration(milliseconds: previousLapDuration);
      _primaryDuration += Duration(milliseconds: previousPrimaryDuration);

      // If the timer was running, we will continue to run the timer. Otherwise
      // we set dur to zero because we don't want to add the time.
      if (previousLapTime != null && previousTime != null) {
        runTimer();
        _lapTime = DateTime.parse(previousLapTime);
        _startTime = DateTime.parse(previousTime);
      }

      notifyListeners();
    }
  }

  /// Save all stopwatch values.
  void saveSp() async {
    // save dateTime
    await prefs.setInt(
        kPreviousPrimaryDuration, _primaryDuration.inMilliseconds);
    // save dateTime
    await prefs.setInt(kPreviousLapDuration, _lapDuration.inMilliseconds);
    // save time
    await prefs.setString(kPreviousTime, _startTime.toString());
    // save lap time
    await prefs.setString(kPreviousLapTime, _lapTime.toString());
    // save laps
    await prefs.setStringList(
        kPreviousLaps, laps.map((e) => e.inMilliseconds.toString()).toList());
  }

  /// Clear all stopwatch values.
  void resetSp() async => await prefs.clear();

  //* Timing Begin

  Timer? _timer;

  /// Returns whether the timer is still active.
  bool get running => _timer?.isActive ?? false;

  /// [Time] is the primary time of the stopwatch. [lapTime] is the secondary time
  /// that will reset whenever a lap is recoreded.
  DateTime? _startTime, _lapTime;
  Duration _primaryDuration = Duration.zero, _lapDuration = Duration.zero;

  Duration get time =>
      _primaryDuration +
      DateTime.now().difference(_startTime ?? DateTime.now());
  Duration get lapTime =>
      _lapDuration + DateTime.now().difference(_lapTime ?? DateTime.now());

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
  void _incrementTime(Timer timer) => notify();

  /// Start the timer.
  void runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(kTimerSpeed, _incrementTime);
    _startTime ??= DateTime.now();
    _lapTime ??= DateTime.now();
    saveSp();
  }

  /// Stop the timer.
  void stopTimer() => notify(() {
        _timer?.cancel();
        _primaryDuration = time;
        _lapDuration = lapTime;
        _startTime = null;
        _lapTime = null;
        saveSp();
      });

  /// Reset the timer and clear Sp.
  void resetTimer() => notify(() {
        _startTime = null;
        _lapTime = null;
        _primaryDuration = Duration.zero;
        _lapDuration = Duration.zero;
        laps.clear();
        resetSp();
      });

  /// Record a lap into [laps] and reset [lapTime].
  void recordLap() => notify(() {
        laps.add(lapTime);
        _lapTime = DateTime.now();
        _lapDuration = Duration.zero;
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
