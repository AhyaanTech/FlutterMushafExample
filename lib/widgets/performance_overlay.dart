/// Performance monitoring widget for rendering performance analysis
///
/// Tracks and logs rendering performance for both TextSpan and Glyph approaches.
/// Used for debugging and profiling purposes only - disabled in release builds.
///
/// Usage:
/// ```dart
/// // Wrap any widget with performance monitoring
/// RenderingPerformanceMonitor(
///   mode: RenderingMode.textspan,
///   tag: 'word_${word.id}',
///   child: MushafWordTextSpan(...),
/// )
///
/// // Or use the extension helper
/// child: MushafWordTextSpan(...).withPerformanceMonitoring(
///   mode: RenderingMode.textspan,
///   tag: 'word_${word.id}',
/// )
///
/// // Show performance overlay
/// PerformanceOverlay(
///   mode: RenderingMode.textspan,
///   child: YourWidget(),
/// )
///
/// // Print accumulated stats
/// RenderingPerformanceMonitor.printStats();
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/tajweed_models.dart';

/// Performance statistics for a single rendering mode
class _ModeStats {
  int buildCount = 0;
  int totalBuildTimeMicroseconds = 0;

  double get averageBuildTimeMicroseconds =>
      buildCount > 0 ? totalBuildTimeMicroseconds / buildCount : 0;

  void recordBuild(int microseconds) {
    buildCount++;
    totalBuildTimeMicroseconds += microseconds;
  }
}

/// A widget that monitors and logs rendering performance for debugging
///
/// Wraps a child widget and measures its build time. Results are logged
/// to the debug console using debugPrint(). Statistics are accumulated
/// in static maps for analysis.
///
/// This widget is lightweight and has no impact in release builds when
/// assertions are disabled.
class RenderingPerformanceMonitor extends StatelessWidget {
  /// The child widget to monitor
  final Widget child;

  /// The rendering mode being monitored (textspan or glyph)
  final RenderingMode mode;

  /// Optional tag for identifying specific widget instances
  final String? tag;

  /// Static map to track build counts per mode
  static final Map<RenderingMode, _ModeStats> _stats = {
    RenderingMode.textspan: _ModeStats(),
    RenderingMode.glyph: _ModeStats(),
  };

  /// Static map to track the last render time per mode
  static final Map<RenderingMode, int> _lastRenderTime = {
    RenderingMode.textspan: 0,
    RenderingMode.glyph: 0,
  };

  /// Creates a performance monitor for the given child widget
  const RenderingPerformanceMonitor({
    super.key,
    required this.child,
    required this.mode,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    // Only track in debug and profile mode, not release
    if (kReleaseMode) {
      return child;
    }

    final stopwatch = Stopwatch()..start();

    // Build the child widget
    final result = child;

    stopwatch.stop();

    final microseconds = stopwatch.elapsedMicroseconds;
    final modeName = mode.name;
    final tagStr = tag ?? 'unnamed';

    // Update stats
    _stats[mode]?.recordBuild(microseconds);
    _lastRenderTime[mode] = microseconds;

    // Log the build time
    debugPrint('[$modeName] Build time: $microsecondsμs (tag: $tagStr)');

    return result;
  }

  /// Returns the build count for the specified rendering mode
  static int getBuildCount(RenderingMode mode) {
    return _stats[mode]?.buildCount ?? 0;
  }

  /// Returns the total build time in microseconds for the specified mode
  static int getTotalBuildTime(RenderingMode mode) {
    return _stats[mode]?.totalBuildTimeMicroseconds ?? 0;
  }

  /// Returns the average build time in microseconds for the specified mode
  static double getAverageBuildTime(RenderingMode mode) {
    return _stats[mode]?.averageBuildTimeMicroseconds ?? 0;
  }

  /// Returns the last recorded render time in microseconds for the specified mode
  static int getLastRenderTime(RenderingMode mode) {
    return _lastRenderTime[mode] ?? 0;
  }

  /// Resets all accumulated statistics
  static void resetStats() {
    for (final stats in _stats.values) {
      stats.buildCount = 0;
      stats.totalBuildTimeMicroseconds = 0;
    }
    _lastRenderTime[RenderingMode.textspan] = 0;
    _lastRenderTime[RenderingMode.glyph] = 0;
  }

  /// Prints accumulated statistics for all rendering modes
  ///
  /// Output format:
  /// ```
  /// === Rendering Performance Statistics ===
  /// [textspan] Builds: 150, Total: 12500μs, Avg: 83.3μs
  /// [glyph] Builds: 150, Total: 23400μs, Avg: 156.0μs
  /// =========================================
  /// ```
  static void printStats() {
    if (kReleaseMode) {
      debugPrint('Performance monitoring disabled in release mode');
      return;
    }

    debugPrint('=== Rendering Performance Statistics ===');

    for (final mode in RenderingMode.values) {
      final stats = _stats[mode];
      if (stats != null && stats.buildCount > 0) {
        final avg = stats.averageBuildTimeMicroseconds.toStringAsFixed(1);
        debugPrint(
          '[${mode.name}] '
          'Builds: ${stats.buildCount}, '
          'Total: ${stats.totalBuildTimeMicroseconds}μs, '
          'Avg: $avgμs',
        );
      } else {
        debugPrint('[${mode.name}] No builds recorded');
      }
    }

    // Calculate comparison if both modes have data
    final textspanStats = _stats[RenderingMode.textspan];
    final glyphStats = _stats[RenderingMode.glyph];

    if (textspanStats != null &&
        glyphStats != null &&
        textspanStats.buildCount > 0 &&
        glyphStats.buildCount > 0) {
      final textspanAvg = textspanStats.averageBuildTimeMicroseconds;
      final glyphAvg = glyphStats.averageBuildTimeMicroseconds;
      final ratio = glyphAvg / textspanAvg;
      final faster = ratio > 1 ? 'TextSpan' : 'Glyph';
      final speedup = ratio > 1 ? ratio : 1 / ratio;

      debugPrint('---');
      debugPrint(
        '$faster is ${speedup.toStringAsFixed(2)}x faster on average',
      );
    }

    debugPrint('=========================================');
  }
}

/// A visual overlay that displays current FPS/render time information
///
/// Shows a small overlay in the top-right corner of the screen with:
/// - Current rendering mode
/// - Last render time in microseconds
/// - Visual indicator for performance (green/yellow/red)
///
/// Usage:
/// ```dart
/// PerformanceOverlay(
///   mode: RenderingMode.textspan,
///   child: YourMainWidget(),
/// )
/// ```
class PerformanceOverlay extends StatelessWidget {
  /// The main content widget
  final Widget child;

  /// The current rendering mode being used
  final RenderingMode mode;

  /// Position of the overlay (default: top-right)
  final Alignment alignment;

  /// Creates a performance overlay
  const PerformanceOverlay({
    super.key,
    required this.child,
    required this.mode,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show overlay in release mode
    if (kReleaseMode) {
      return child;
    }

    return Stack(
      children: [
        child,
        Align(
          alignment: alignment,
          child: _PerformanceIndicator(mode: mode),
        ),
      ],
    );
  }
}

/// Internal widget that displays the performance indicator
class _PerformanceIndicator extends StatelessWidget {
  final RenderingMode mode;

  const _PerformanceIndicator({required this.mode});

  @override
  Widget build(BuildContext context) {
    final lastRenderTime = RenderingPerformanceMonitor.getLastRenderTime(mode);

    // Determine color based on render time
    // < 100μs: Green (fast)
    // 100-500μs: Yellow (moderate)
    // > 500μs: Red (slow)
    Color indicatorColor;
    if (lastRenderTime < 100) {
      indicatorColor = Colors.green;
    } else if (lastRenderTime < 500) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Mode name
          Text(
            mode.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          // Render time
          Text(
            '$lastRenderTimeμs',
            style: TextStyle(
              color: indicatorColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontFamilyFallback: const ['Menlo', 'Consolas', 'Courier'],
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension methods to easily wrap widgets with performance monitoring
extension PerformanceMonitoringExtension on Widget {
  /// Wraps this widget with a [RenderingPerformanceMonitor]
  ///
  /// Example:
  /// ```dart
  /// return MushafWordTextSpan(
  ///   word: word,
  ///   ...
  /// ).withPerformanceMonitoring(
  ///   mode: RenderingMode.textspan,
  ///   tag: 'word_${word.id}',
  /// );
  /// ```
  Widget withPerformanceMonitoring({
    required RenderingMode mode,
    String? tag,
  }) {
    return RenderingPerformanceMonitor(
      mode: mode,
      tag: tag,
      child: this,
    );
  }

  /// Wraps this widget with a [PerformanceOverlay]
  ///
  /// Example:
  /// ```dart
  /// return MushafPageWidget(
  ///   ...
  /// ).withPerformanceOverlay(
  ///   mode: RenderingMode.textspan,
  /// );
  /// ```
  Widget withPerformanceOverlay({
    required RenderingMode mode,
    Alignment alignment = Alignment.topRight,
  }) {
    return PerformanceOverlay(
      mode: mode,
      alignment: alignment,
      child: this,
    );
  }
}

/// A mixin that can be added to StatefulWidgets for performance tracking
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget>
///     with PerformanceTrackingMixin<MyWidget> {
///   @override
///   RenderingMode get performanceMode => RenderingMode.textspan;
///
///   @override
///   String? get performanceTag => 'my_widget';
///
///   @override
///   Widget build(BuildContext context) {
///     return trackBuild(() {
///       return Container(...);
///     });
///   }
/// }
/// ```
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  /// Override this to specify the rendering mode
  RenderingMode get performanceMode;

  /// Override this to provide an optional tag
  String? get performanceTag => null;

  /// Call this method in build() to track performance
  Widget trackBuild(Widget Function() builder) {
    return RenderingPerformanceMonitor(
      mode: performanceMode,
      tag: performanceTag,
      child: builder(),
    );
  }
}
