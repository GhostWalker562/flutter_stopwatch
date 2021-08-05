import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StopwatchProvider extends ChangeNotifier {
  final kTimerSpeed = const Duration(milliseconds: 10);

  Timer? _timer;
  bool get running => _timer?.isActive ?? false;
  

  Duration time = Duration.zero;
  Duration lapTime = Duration.zero;

  final List<Duration> laps = [];
  Duration? get shortestLap {
    if (laps.length < 2) return null; 
    Duration temp = laps[0];
    for (Duration lap in laps) {
      if (lap < temp) {
        temp = lap;
      }
    }
    return temp;
  }
  Duration? get longestLap {
    if (laps.length < 2) return null; 
    Duration temp = laps[0];
    for (Duration lap in laps) {
      if (lap > temp) {
        temp = lap;
      }
    }
    return temp;
  }

  void _incrementTime(Timer timer) => notify(() {
        time += kTimerSpeed;
        lapTime += kTimerSpeed;
      });

  void runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(kTimerSpeed, _incrementTime);
  }

  void stopTimer() => notify(_timer?.cancel);

  void resetTimer() => notify(() {
        time = Duration.zero;
        lapTime = Duration.zero;
        laps.clear();
      });

  void recordLap() => notify(() {
        laps.add(lapTime);
        lapTime = Duration.zero;
      });

  void notify([VoidCallback? action]) {
    action?.call();
    notifyListeners();
  }
}

class StopwatchProviderWrapper extends StatelessWidget {
  const StopwatchProviderWrapper({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final Widget? child;
  final Widget Function(BuildContext, StopwatchProvider, Widget?) builder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StopwatchProvider(),
      builder: (context, child) => Consumer<StopwatchProvider>(
        builder: builder,
        child: child,
      ),
    );
  }
}
