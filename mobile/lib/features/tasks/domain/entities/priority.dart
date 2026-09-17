enum Priority {
  low,
  medium,
  high,
  urgent;

  static Priority fromString(String val) {
    switch (val.toUpperCase()) {
      case 'LOW':
        return Priority.low;
      case 'MEDIUM':
        return Priority.medium;
      case 'HIGH':
        return Priority.high;
      case 'URGENT':
        return Priority.urgent;
      default:
        return Priority.medium;
    }
  }

  String toServerString() {
    switch (this) {
      case Priority.low:
        return 'LOW';
      case Priority.medium:
        return 'MEDIUM';
      case Priority.high:
        return 'HIGH';
      case Priority.urgent:
        return 'URGENT';
    }
  }

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }
}
