enum ConversionState {
  idle,
  loading,
  success,
  error,
}

class ConversionStatus {
  final ConversionState state;
  final String message;
  final double progress;
  final String? errorMessage;

  const ConversionStatus({
    required this.state,
    this.message = '',
    this.progress = 0.0,
    this.errorMessage,
  });

  ConversionStatus copyWith({
    ConversionState? state,
    String? message,
    double? progress,
    String? errorMessage,
  }) {
    return ConversionStatus(
      state: state ?? this.state,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => state == ConversionState.loading;
  bool get isSuccess => state == ConversionState.success;
  bool get isError => state == ConversionState.error;
  bool get isIdle => state == ConversionState.idle;
}