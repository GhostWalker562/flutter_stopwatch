import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stopwatch/stopwatch/provider/stopwatch_provider.dart';
import '../../utils/utils.dart';

class StopwatchPage extends StatefulWidget {
  /// Simple stopwatch page that laps, start, stop, and resets. The page is inspired
  /// by iOS's stopwatch.
  const StopwatchPage({Key? key}) : super(key: key);

  @override
  _StopwatchPageState createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage>
    with WidgetsBindingObserver {
  final ScrollController controller = ScrollController();
  late StopwatchProvider provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  /// We save when the app is about to be detached so that when it is reopened it
  /// can refresh the state of the app. Even when it's running, and the time.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => provider.saveSp();

  /// Format [dur] to 'min:seconds.milliseconds'.
  /// Right now this function does not support any value over an hour.
  String _formatDuration(Duration dur) {
    String temp = '';
    // Pad and retrieve minutes.
    temp += '${dur.inMinutes.toString().padLeft(2, '0')}:';
    // Pad and retrieve remaining seconds.
    temp += '${(dur.inSeconds % 60).toString().padLeft(2, '0')}.';
    // Pad and retrieve remaining milliseconds.
    temp +=
        (dur.inMilliseconds % 1000).toString().padLeft(2, '0').substring(0, 2);
    return temp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StopwatchProviderWrapper(
          // We use this provider to access saving to SharedPreferences.
          provider: (e) => provider = e,
          builder: (context, model, child) {
            String time = _formatDuration(model.time);
            return Column(
              children: <Widget>[
                // Title
                Expanded(
                  // FittedBox is used to have the text be responsive to the 
                  // width of the screen.
                  child: FittedBox(
                    child: Text(
                      time,
                      style: const TextStyle(fontWeight: FontWeight.w200),
                    ),
                  ),
                ),
                // Controls
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //* Reset and lap button
                          _CircularBorderButton(
                            key: const ValueKey('lapResetButton'),
                            textColor: context.colorScheme.onSurface,
                            backgroundColor: context.colorScheme.surface,
                            text: model.running ? 'Lap' : 'Reset',
                            onPressed: model.running
                                ? model.recordLap
                                : () {
                                    model.resetTimer();
                                    // When we lap, we jump to the top of the ListView
                                    // because it will retain its position without this.
                                    controller.jumpTo(0);
                                  },
                          ),
                          //* Stop and start button
                          _CircularBorderButton(
                            key: const ValueKey('startStopButton'),
                            textColor: model.running
                                ? context.colorScheme.onSecondary
                                : context.colorScheme.onPrimary,
                            backgroundColor: model.running
                                ? context.colorScheme.secondary
                                : context.colorScheme.primary,
                            text: model.running ? 'Stop' : 'Start',
                            onPressed: model.running
                                ? model.stopTimer
                                : model.runTimer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      //* Laps
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          controller: controller,
                          // On iOS, there are dividers without laps. We
                          // also have to render those too.
                          itemCount: max(20, model.laps.length + 1),
                          itemBuilder: (context, index) {
                            // We can't reverse the ListView itself because
                            // it will put the laps at the bottom of the screen.
                            // We have to manually reverse the index.
                            int reversedIndex = model.laps.length - index;

                            // These are plain dividers without laps.
                            // We use the invisible text to size the tile.
                            if (reversedIndex.isNegative) {
                              return const _LapTile(
                                child: Opacity(
                                  opacity: 0,
                                  child: Text('Lap'),
                                ),
                              );
                            }

                            // This is the current lap that is being recorded.
                            // This will continue to increment until the next lap.
                            // lapTime should be differentiated from the primary
                            // time.
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

                            // declare values
                            final val = model.laps[reversedIndex];
                            final style = TextStyle(
                              // When the lap matches the longest lap or the
                              // shortest lap, iOS has automatically colors your
                              // best and worst times. Best being the shortest
                              // and worst being your longest lap.
                              color: (val == model.longestLap)
                                  ? context.colorScheme.onSecondary
                                  : (val == model.shortestLap)
                                      ? context.colorScheme.onPrimary
                                      : null,
                            );
                            
                            // Render out a normal lap with the style declared
                            // above.
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
  /// A simple tile used for laps.
  const _LapTile({Key? key, required this.child}) : super(key: key);

  /// The [child] contained by this widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
  /// Circular button with a border and text. Follows the same behavior
  /// to a CupertinoButton.
  const _CircularBorderButton({
    Key? key,
    this.textColor,
    required this.backgroundColor,
    required this.text,
    this.onPressed,
  }) : super(key: key);

  /// The color of the button and its border. The color will be rendered with a 
  /// `0.8` opacity.
  final Color backgroundColor;

  /// The color of the text on the button. If there is [TextColor] is null then
  /// it will default to the color of the `TextTheme`.
  final Color? textColor;

  /// The text displayed on top of the button.
  final String text;

  /// The callback when the button has been pressed.
  /// If set to null, the button will be disabled.
  final VoidCallback? onPressed;

  @override
  __CircularBorderButtonState createState() => __CircularBorderButtonState();
}

class __CircularBorderButtonState extends State<_CircularBorderButton> {
  @override
  Widget build(BuildContext context) {
    // declare colors
    final backgroundColor = widget.backgroundColor.withOpacity(0.8);
    final foregroundColor = widget.textColor;

    return CupertinoButton(
      onPressed: widget.onPressed,
      padding: EdgeInsets.zero,
      minSize: 0,
      child: Container(
        // Height is odd so that it can center the text.
        height: 59,
        decoration: BoxDecoration(
          border: Border.all(color: backgroundColor, width: 1.5),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(1.5),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: context.textTheme.caption!.copyWith(
                  color: foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
