/// Registration Status Enum
/// Represents the different states of a seller registration request
enum RegistrationStatus {
  pending('PENDING', 'Pending Review'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected'),
  requestMoreInfo('REQUEST_MORE_INFO', 'More Info Needed');

  final String value;
  final String displayName;

  const RegistrationStatus(this.value, this.displayName);

  /// Convert string value to enum
  static RegistrationStatus fromString(String value) {
    return RegistrationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RegistrationStatus.pending,
    );
  }

  /// Check if registration is pending
  bool get isPending => this == RegistrationStatus.pending;

  /// Check if registration is approved
  bool get isApproved => this == RegistrationStatus.approved;

  /// Check if registration is rejected
  bool get isRejected => this == RegistrationStatus.rejected;

  /// Check if more information is requested
  bool get isInfoRequested => this == RegistrationStatus.requestMoreInfo;

  /// Get user-friendly message based on status
  String getMessage() {
    switch (this) {
      case RegistrationStatus.pending:
        return 'Your application is being reviewed. You will be notified once a decision is made.';
      case RegistrationStatus.approved:
        return 'Congratulations! Your seller registration has been approved. You can now start selling.';
      case RegistrationStatus.rejected:
        return 'Your registration was not approved. Please review the rejection reason and reapply.';
      case RegistrationStatus.requestMoreInfo:
        return 'We need more information to process your registration. Please submit the requested documents.';
    }
  }

  /// Get status color for UI display
  int getColorValue() {
    switch (this) {
      case RegistrationStatus.pending:
        return 0xFFFFA500; // Orange
      case RegistrationStatus.approved:
        return 0xFF00B464; // Green
      case RegistrationStatus.rejected:
        return 0xFFE74C3C; // Red
      case RegistrationStatus.requestMoreInfo:
        return 0xFF3498DB; // Blue
    }
  }
}
