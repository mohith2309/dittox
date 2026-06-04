double calculateDynamicFontSize({
  required double totalScreenHeight,
  required double totalScreenWidth,
  required double currentFontSize,
  // required bool heightSpecific,
}) {
  double dynamicFontSize;

  // if (heightSpecific) {
  //   dynamicFontSize = totalScreenHeight * (currentFontSize / totalScreenHeight);
  // } else {
  //   dynamicFontSize = totalScreenWidth * (currentFontSize / totalScreenHeight);
  // }
  dynamicFontSize = totalScreenWidth * (currentFontSize / totalScreenHeight);
  return dynamicFontSize;
}
