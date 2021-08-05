import 'package:flutter/material.dart';

class CustomScrollBehavior extends ScrollBehavior {
  /// CupertinoScrollBehavior without a default scroll bar.
  const CustomScrollBehavior();

  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}
