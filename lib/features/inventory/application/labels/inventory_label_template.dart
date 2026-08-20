final class InventoryLabelSlot {
  const InventoryLabelSlot({
    required this.leftInches,
    required this.topInches,
    required this.widthInches,
    required this.heightInches,
  });

  final double leftInches;
  final double topInches;
  final double widthInches;
  final double heightInches;
}

final class InventoryLabelTemplate {
  const InventoryLabelTemplate({
    required this.id,
    required this.name,
    required this.pageWidthInches,
    required this.pageHeightInches,
    required this.labelWidthInches,
    required this.labelHeightInches,
    required this.columns,
    required this.rows,
    required this.leftMarginInches,
    required this.topMarginInches,
    required this.horizontalPitchInches,
    required this.verticalPitchInches,
  });

  final String id;
  final String name;

  final double pageWidthInches;
  final double pageHeightInches;

  final double labelWidthInches;
  final double labelHeightInches;

  final int columns;
  final int rows;

  final double leftMarginInches;
  final double topMarginInches;
  final double horizontalPitchInches;
  final double verticalPitchInches;

  int get labelsPerSheet => columns * rows;

  bool isValidStartingPosition(int position) {
    return position >= 1 && position <= labelsPerSheet;
  }

  InventoryLabelSlot slotForPosition(int position) {
    if (!isValidStartingPosition(position)) {
      throw RangeError.range(
        position,
        1,
        labelsPerSheet,
        'position',
        'Label position must be within this sheet.',
      );
    }

    final zeroBasedPosition = position - 1;
    final row = zeroBasedPosition ~/ columns;
    final column = zeroBasedPosition % columns;

    return InventoryLabelSlot(
      leftInches: leftMarginInches + (column * horizontalPitchInches),
      topInches: topMarginInches + (row * verticalPitchInches),
      widthInches: labelWidthInches,
      heightInches: labelHeightInches,
    );
  }

  static const InventoryLabelTemplate avery5366 = InventoryLabelTemplate(
    id: 'avery-5366',
    name: 'Avery 5366',
    pageWidthInches: 8.5,
    pageHeightInches: 11.0,
    labelWidthInches: 3.4375,
    labelHeightInches: 2 / 3,
    columns: 2,
    rows: 15,
    leftMarginInches: 0.53125,
    topMarginInches: 0.5,
    horizontalPitchInches: 4.0,
    verticalPitchInches: 2 / 3,
  );
}
