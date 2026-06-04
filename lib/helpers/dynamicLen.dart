double calculatePercentage(double staticLength, double completedLength) {
  if (staticLength <= 0 || completedLength <= 0) {
    // Handle invalid input to avoid division by zero
    return 0.0;
  }

  // Calculate the percentage
  double percentage = (completedLength / staticLength) * 100.0;

  // Ensure the percentage is within a valid range (0 to 100)
  return percentage.clamp(0.0, 100.0);
}
