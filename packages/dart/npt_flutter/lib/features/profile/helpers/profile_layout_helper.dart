class ProfileLayoutHelper {
  static const int columnCount = 5; // Number of columns
  static const double gapWidth = 10.0; // Width of each gap
  static const double horizontalPadding = 16.0; // Total horizontal padding

  static double calculateColumnWidth(double totalWidth) {
    const gapCount = columnCount - 1;
    final availableWidth =
        totalWidth - (gapCount * gapWidth) - horizontalPadding;
    return availableWidth / columnCount;
  }
}
