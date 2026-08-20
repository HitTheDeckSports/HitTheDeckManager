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
  });

  final String id;
  final String name;

  final double pageWidthInches;
  final double pageHeightInches;

  final double labelWidthInches;
  final double labelHeightInches;

  final int columns;
  final int rows;

  int get labelsPerSheet => columns * rows;

  bool isValidStartingPosition(int position) {
    return position >= 1 && position <= labelsPerSheet;
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
  );
}
