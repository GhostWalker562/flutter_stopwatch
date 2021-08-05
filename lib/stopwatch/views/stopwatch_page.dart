import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stopwatch/stopwatch/provider/stopwatch_provider.dart';
import '../../utils/utils.dart';

class StopwatchPage extends StatefulWidget {
  StopwatchPage({Key? key}) : super(key: key);

  @override
  _StopwatchPageState createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  final ScrollController controller = ScrollController();

  String _formatDuration(Duration dur) {
    String temp = '';

    temp += '${dur.inMinutes.toString().padLeft(2, '0')}:';
    temp += '${(dur.inSeconds % 60).toString().padLeft(2, '0')}.';
    temp +=
        '${(dur.inMilliseconds % 1000).toString().padLeft(2, '0').substring(0, 2)}';

    return temp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StopwatchProviderWrapper(
          builder: (context, model, child) {
            String time = _formatDuration(model.time);

            return Column(
              children: <Widget>[
                // Title
                Expanded(
                  child: FittedBox(
                    child: Text(time),
                  ),
                ),
                // Controls
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CircularBorderButton(
                            textColor: Colors.white,
                            backgroundColor: Color(0xFF313131),
                            text: model.running ? 'Lap' : 'Reset',
                            onPressed: model.running
                                ? model.recordLap
                                : () {
                                    model.resetTimer();
                                    controller.jumpTo(0);
                                  },
                          ),
                          _CircularBorderButton(
                            textColor: model.running
                                ? Color(0xFFEB4D44)
                                : Color(0xFF61FF7A),
                            backgroundColor: model.running
                                ? Color(0xFF2D0F0D)
                                : Color(0xFF18331D),
                            text: model.running ? 'Stop' : 'Start',
                            onPressed: model.running
                                ? model.stopTimer
                                : model.runTimer,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: max(20, model.laps.length + 1),
                          itemBuilder: (context, index) {
                            int reversedIndex = model.laps.length - index;

                            if (reversedIndex == model.laps.length) {
                              return _LapTile(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Lap ${reversedIndex + 1}'),
                                    Text(_formatDuration(model.lapTime)),
                                  ],
                                ),
                              );
                            }

                            if (reversedIndex.isNegative) {
                              return _LapTile(
                                child: Opacity(
                                  opacity: 0,
                                  child: Text('Lap'),
                                ),
                              );
                            }

                            final val = model.laps[reversedIndex];
                            final style = TextStyle(
                              color: (val == model.longestLap)
                                  ? Colors.red
                                  : (val == model.shortestLap)
                                      ? Colors.green
                                      : null,
                            );

                            return _LapTile(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Lap ${reversedIndex + 1}',
                                    style: style,
                                  ),
                                  Text(
                                    _formatDuration(val),
                                    style: style,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LapTile extends StatelessWidget {
  const _LapTile({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 1, color: context.theme.dividerColor),
        ),
      ),
      child: child,
    );
  }
}

class _CircularBorderButton extends StatefulWidget {
  const _CircularBorderButton({
    Key? key,
    required this.textColor,
    required this.backgroundColor,
    required this.text,
    this.onPressed,
  }) : super(key: key);

  final Color backgroundColor;
  final Color textColor;
  final String text;
  final VoidCallback? onPressed;

  @override
  __CircularBorderButtonState createState() => __CircularBorderButtonState();
}

class __CircularBorderButtonState extends State<_CircularBorderButton> {
  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor.withOpacity(0.8);
    final foregroundColor = widget.textColor;

    return CupertinoButton(
      padding: EdgeInsets.all(0),
      minSize: 0,
      child: Container(
        height: 57,
        width: 57,
        decoration: BoxDecoration(
          border: Border.all(color: backgroundColor, width: 1.5),
          shape: BoxShape.circle,
        ),
        padding: EdgeInsets.all(1.5),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.text,
              style: context.textTheme.caption!.copyWith(
                color: foregroundColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      onPressed: widget.onPressed,
    );
  }
}
