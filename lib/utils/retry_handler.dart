import 'dart:async';

enum RetryStrategy {
  none,
  linear,
  exponential,
  fibonacci,
}

class RetryConfig {
  final int maxRetries;
  final int initialDelayMs;
  final int maxDelayMs;
  final RetryStrategy strategy;
  final bool useJitter;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelayMs = 1000,
    this.maxDelayMs = 30000,
    this.strategy = RetryStrategy.exponential,
    this.useJitter = true,
  });

  Duration getDelay(int attempt) {
    int delay;
    
    switch (strategy) {
      case RetryStrategy.linear:
        delay = initialDelayMs * attempt;
        break;
      case RetryStrategy.exponential:
        delay = initialDelayMs * (1 << (attempt - 1));
        break;
      case RetryStrategy.fibonacci:
        delay = _fibonacci(attempt) * initialDelayMs;
        break;
      case RetryStrategy.none:
        delay = initialDelayMs;
        break;
    }
    
    if (delay > maxDelayMs) delay = maxDelayMs;
    
    if (useJitter) {
      delay = (delay * (0.5 + (DateTime.now().microsecond / 1000000.0))).toInt();
    }
    
    return Duration(milliseconds: delay);
  }

  int _fibonacci(int n) {
    if (n <= 1) return 1;
    return _fibonacci(n - 1) + _fibonacci(n - 2);
  }
}

class RetryHandler {
  final RetryConfig config;

  RetryHandler({this.config = const RetryConfig()});

  Future<T> execute<T>({
    required Future<T> Function() operation,
    required bool Function(dynamic error) shouldRetry,
    void Function(dynamic error, int attempt)? onRetry,
    void Function(dynamic error)? onFailed,
    Future<void> Function()? cleanup,
  }) async {
    dynamic lastError;
    
    for (int attempt = 1; attempt <= config.maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        
        if (attempt >= config.maxRetries || !shouldRetry(e)) {
          onFailed?.call(e);
          rethrow;
        }
        
        onRetry?.call(e, attempt);
        
        if (cleanup != null && attempt < config.maxRetries) {
          try {
            await cleanup();
          } catch (_) {}
        }
        
        await Future.delayed(config.getDelay(attempt));
      }
    }
    
    throw lastError ?? Exception('Retry exhausted');
  }
}

class NetworkRetryHandler extends RetryHandler {
  NetworkRetryHandler()
      : super(
          config: const RetryConfig(
            maxRetries: 3,
            initialDelayMs: 1000,
            maxDelayMs: 10000,
            strategy: RetryStrategy.exponential,
          ),
        );

  static bool isRetryable(dynamic error) {
    if (error is TimeoutException) return true;
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('socketexception')) return true;
    if (errorStr.contains('connection refused')) return true;
    if (errorStr.contains('network')) return true;
    return false;
  }
}

class PrintJobRetryHandler extends RetryHandler {
  PrintJobRetryHandler()
      : super(
          config: const RetryConfig(
            maxRetries: 3,
            initialDelayMs: 2000,
            maxDelayMs: 30000,
            strategy: RetryStrategy.exponential,
            useJitter: true,
          ),
        );

  static bool shouldRetryPrintJob(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('timeout')) return true;
    if (errorStr.contains('connection')) return true;
    if (errorStr.contains('network')) return true;
    if (errorStr.contains('printer busy')) return true;
    if (errorStr.contains('paper jam')) return false;
    if (errorStr.contains('out of paper')) return false;
    if (errorStr.contains('print failed')) return true;
    if (errorStr.contains('spooler')) return true;
    
    return false;
  }
}

class GracefulDegradation {
  static T fallback<T>({
    required T Function() primary,
    required T Function() fallback,
    required bool Function(dynamic error) shouldFallback,
  }) {
    try {
      return primary();
    } catch (e) {
      if (shouldFallback(e)) {
        return fallback();
      }
      rethrow;
    }
  }

  static Future<T> fallbackAsync<T>({
    required Future<T> Function() primary,
    required T Function() fallback,
    required bool Function(dynamic error) shouldFallback,
  }) async {
    try {
      return await primary();
    } catch (e) {
      if (shouldFallback(e)) {
        return fallback();
      }
      rethrow;
    }
  }
}
