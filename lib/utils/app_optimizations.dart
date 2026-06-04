import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AppPerformanceMonitor {
  static bool _isInitialized = false;
  static DateTime? _lastFrameTime;

  static void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        if (timing.buildDuration.inMilliseconds > 16) {
          debugPrint('Slow frame: ${timing.buildDuration.inMilliseconds}ms');
        }
      }
    });
  }

  static void logFrame() {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final diff = now.difference(_lastFrameTime!).inMilliseconds;
      if (diff > 100) {
        debugPrint('Jank detected: $diff ms since last frame');
      }
    }
    _lastFrameTime = now;
  }
}

class LazyLoader<T> {
  final T Function() _loader;
  T? _value;
  bool _isLoaded = false;
  bool _isLoading = false;

  LazyLoader(this._loader);

  Future<T> get value async {
    if (_isLoaded) return _value as T;
    if (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      return value;
    }

    _isLoading = true;
    try {
      _value = _loader();
      _isLoaded = true;
      _isLoading = false;
      return _value as T;
    } catch (e) {
      _isLoading = false;
      rethrow;
    }
  }

  void reset() {
    _value = null;
    _isLoaded = false;
    _isLoading = false;
  }
}

class WidgetCache {
  static final Map<String, Widget> _cache = {};
  static const int _maxSize = 50;

  static void cache(String key, Widget widget) {
    if (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = widget;
  }

  static Widget? get(String key) => _cache[key];

  static void clear() => _cache.clear();

  static void remove(String key) => _cache.remove(key);
}

class Debouncer {
  final int milliseconds;
  VoidCallback? _action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      _action?.call();
      _action = null;
    });
  }

  void cancel() {
    _timer?.cancel();
    _action = null;
  }

  void dispose() {
    cancel();
    _timer = null;
  }
}

class Throttler {
  final int milliseconds;
  DateTime? _lastRun;

  Throttler({required this.milliseconds});

  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!).inMilliseconds >= milliseconds) {
      _lastRun = now;
      action();
    }
  }

  void reset() => _lastRun = null;
}

class ImageCacheManager {
  static void optimize() {
    // Increase cache sizes for better performance
    imageCache.maximumSize = 200;
    imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
  }
}

class MemoryAwareWidget extends StatelessWidget {
  final Widget child;
  final double memoryThreshold;

  const MemoryAwareWidget({
    super.key,
    required this.child,
    this.memoryThreshold = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class EfficientListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const EfficientListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (separatorBuilder != null) {
      return ListView.separated(
        itemCount: itemCount,
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        separatorBuilder: (context, index) => separatorBuilder!,
        itemBuilder: itemBuilder,
      );
    }

    return ListView.builder(
      itemCount: itemCount,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemBuilder: itemBuilder,
    );
  }
}

class ComputedValue<T> extends ChangeNotifier {
  T _value;
  final T Function() _compute;
  bool _isDirty = true;

  ComputedValue(this._compute) : _value = _compute();

  T get value {
    if (_isDirty) {
      _value = _compute();
      _isDirty = false;
    }
    return _value;
  }

  void markDirty() {
    if (!_isDirty) {
      _isDirty = true;
      notifyListeners();
    }
  }

  void refresh() {
    markDirty();
    notifyListeners();
  }
}

class WidgetRebuilder extends StatefulWidget {
  final Widget Function(BuildContext, void Function()) builder;

  const WidgetRebuilder({
    super.key,
    required this.builder,
  });

  @override
  State<WidgetRebuilder> createState() => _WidgetRebuilderState();
}

class _WidgetRebuilderState extends State<WidgetRebuilder> {
  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context, _rebuild);
}

final imageCache = PaintingBinding.instance.imageCache;
