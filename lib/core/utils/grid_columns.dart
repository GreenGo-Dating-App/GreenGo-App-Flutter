import 'package:flutter/widgets.dart';

/// Grid column rules shared by every tile grid in the app.
///
/// Columns depend ONLY on the available width, never on web vs app: a phone
/// browser lays out exactly like the phone app, and a wide desktop window gets
/// denser grids.

/// Columns of the standard tile grids (events, partner events, experiences,
/// community experiences, attractions, network): 3 below 800 px, 4 from
/// 800 px, 6 from 1100 px.
int gridColumnsForWidth(double width) {
  if (width >= 1100) return 6;
  if (width >= 800) return 4;
  return 3;
}

/// [gridColumnsForWidth] for the current screen width.
int gridColumnsOf(BuildContext context) =>
    gridColumnsForWidth(MediaQuery.sizeOf(context).width);

/// Discovery grid "auto" mode: 2/3/4/6/8 columns at <300 / <450 / <800 /
/// <1200 px / wider.
int discoveryAutoColumns(double width) {
  if (width < 300) return 2;
  if (width < 450) return 3;
  if (width < 800) return 4;
  if (width < 1200) return 6;
  return 8;
}

/// Choices offered by the Discovery column picker at screen [width]
/// (0 = auto). Wide screens can also pick denser grids (6 / 8 columns).
List<int> discoveryColumnChoices(double width) =>
    width >= 800 ? const [0, 2, 3, 4, 6, 8] : const [0, 2, 3, 4];

/// The picker choice actually in effect: a [selected] value no longer offered
/// at [screenWidth] (e.g. 8 after the window shrank) falls back to auto (0).
int discoveryEffectiveChoice(int selected, double screenWidth) =>
    discoveryColumnChoices(screenWidth).contains(selected) ? selected : 0;

/// Columns the Discovery grid renders: the effective picker choice, or
/// [discoveryAutoColumns] of [gridWidth] in auto mode.
int discoveryColumns({
  required int selected,
  required double screenWidth,
  required double gridWidth,
}) {
  final choice = discoveryEffectiveChoice(selected, screenWidth);
  return choice == 0 ? discoveryAutoColumns(gridWidth) : choice;
}
