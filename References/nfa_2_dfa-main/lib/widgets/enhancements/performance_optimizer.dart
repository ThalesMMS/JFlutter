import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  final PerformanceMonitor _monitor = PerformanceMonitor();
  final CacheManager _cache = CacheManager();
  final LODManager _lodManager = LODManager();
  final VirtualScrollManager _virtualScroll = VirtualScrollManager();
  final RenderOptimizer _renderOptimizer = RenderOptimizer();
  final MemoryOptimizer _memoryOptimizer = MemoryOptimizer();

  PerformanceMonitor get monitor => _monitor;
  CacheManager get cache => _cache;
  LODManager get lodManager => _lodManager;
  VirtualScrollManager get virtualScroll => _virtualScroll;
  RenderOptimizer get renderOptimizer => _renderOptimizer;
  MemoryOptimizer get memoryOptimizer => _memoryOptimizer;

  /// تنظیم عمومی بهینه‌سازی بر اساس دستگاه
  void configureForDevice() {
    final bool isLowEndDevice = _isLowEndDevice();
    final bool isMobile = _isMobile();
    
    _lodManager.configure(
      maxNodes: isLowEndDevice ? 50 : 200,
      simplificationLevel: isLowEndDevice ? 0.7 : 0.3,
      enableAdaptiveLOD: true,
    );

    _cache.configure(
      maxCacheSize: isLowEndDevice ? 50 : 200,
      maxTextureSize: isLowEndDevice ? 1024 : 2048,
      enablePreloading: !isLowEndDevice,
    );

    _renderOptimizer.configure(
      enableCulling: true,
      enableBatching: true,
      maxFPS: isMobile ? 60 : 120,
      enableVSync: true,
    );

    _memoryOptimizer.configure(
      gcThreshold: isLowEndDevice ? 0.7 : 0.8,
      autoCleanup: true,
      aggressiveMode: isLowEndDevice,
    );
  }

  bool _isLowEndDevice() {
    return false;
  }

  bool _isMobile() {
    return defaultTargetPlatform == TargetPlatform.android || 
           defaultTargetPlatform == TargetPlatform.iOS;
  }

  void dispose() {
    _monitor.dispose();
    _cache.dispose();
    _lodManager.dispose();
    _virtualScroll.dispose();
    _renderOptimizer.dispose();
    _memoryOptimizer.dispose();
  }
}

class PerformanceMonitor {
  final Queue<FrameMetrics> _frameMetrics = Queue<FrameMetrics>();
  final Queue<MemoryMetrics> _memoryMetrics = Queue<MemoryMetrics>();
  final Queue<RenderMetrics> _renderMetrics = Queue<RenderMetrics>();

  Timer? _monitoringTimer;
  late final Stopwatch _frameStopwatch;
  int _frameCount = 0;
  int _droppedFrames = 0;
  double _averageFPS = 60.0;

  final StreamController<PerformanceReport> _reportController =
  StreamController<PerformanceReport>.broadcast();

  Stream<PerformanceReport> get reports => _reportController.stream;

  PerformanceMonitor() {
    _frameStopwatch = Stopwatch()..start();
    _startMonitoring();
  }

  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _collectMetrics();
      _analyzePerformance();
    });

    WidgetsBinding.instance.addPersistentFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    _frameCount++;

    final double frameTime = _frameStopwatch.elapsedMilliseconds.toDouble(); // تبدیل int به double
    _frameStopwatch.reset();

    if (frameTime > 16.67) {
      _droppedFrames++;
    }

    _frameMetrics.add(FrameMetrics(
      timestamp: timestamp,
      frameTime: frameTime,
      isDropped: frameTime > 16.67,
    ));

    // حفظ حداکثر ۱۰۰ فریم در تاریخچه
    if (_frameMetrics.length > 100) {
      _frameMetrics.removeFirst();
    }
  }

  void _collectMetrics() {
    // جمع‌آوری معیارهای حافظه
    final memoryUsage = _getMemoryUsage();
    _memoryMetrics.add(MemoryMetrics(
      timestamp: DateTime.now(),
      heapUsage: memoryUsage.heapUsage,
      totalMemory: memoryUsage.totalMemory,
      gcCount: memoryUsage.gcCount,
    ));

    if (_memoryMetrics.length > 60) {
      _memoryMetrics.removeFirst();
    }

    // محاسبه FPS میانگین - اصلاح خطای تبدیل نوع
    if (_frameCount > 0 && _frameMetrics.isNotEmpty) {
      final double totalFrameTime = _frameMetrics
          .map((f) => f.frameTime)
          .reduce((a, b) => a + b);
      final double averageFrameTime = totalFrameTime / _frameMetrics.length.toDouble(); // تبدیل int به double
      _averageFPS = 1000.0 / averageFrameTime;
    }
  }

  MemoryUsageInfo _getMemoryUsage() {
    return MemoryUsageInfo(
      heapUsage: 50.0, // MB
      totalMemory: 4096.0, // MB
      gcCount: 10,
    );
  }

  void _analyzePerformance() {
    final report = PerformanceReport(
      averageFPS: _averageFPS,
      droppedFrames: _droppedFrames,
      memoryUsage: _memoryMetrics.isNotEmpty ? _memoryMetrics.last.heapUsage : 0.0,
      recommendations: _generateRecommendations(),
      severity: _calculateSeverity(),
    );

    _reportController.add(report);
    _resetCounters();
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    if (_averageFPS < 30) {
      recommendations.add('کاهش تعداد نودهای نمایش داده شده');
      recommendations.add('فعال‌سازی Level of Detail (LOD)');
    }

    if (_droppedFrames > 10) {
      recommendations.add('بهینه‌سازی انیمیشن‌ها');
      recommendations.add('استفاده از Virtual Scrolling');
    }

    if (_memoryMetrics.isNotEmpty && _memoryMetrics.last.heapUsage > 200) {
      recommendations.add('پاکسازی cache');
      recommendations.add('کاهش کیفیت textures');
    }

    return recommendations;
  }

  PerformanceSeverity _calculateSeverity() {
    if (_averageFPS < 15 || _droppedFrames > 30) {
      return PerformanceSeverity.critical;
    } else if (_averageFPS < 30 || _droppedFrames > 15) {
      return PerformanceSeverity.warning;
    }
    return PerformanceSeverity.good;
  }

  void _resetCounters() {
    _frameCount = 0;
    _droppedFrames = 0;
  }

  void recordRenderMetrics(RenderMetrics metrics) {
    _renderMetrics.add(metrics);
    if (_renderMetrics.length > 50) {
      _renderMetrics.removeFirst();
    }
  }

  void dispose() {
    _monitoringTimer?.cancel();
    _reportController.close();
    WidgetsBinding.instance.removeObserver(_FrameObserver());
  }
}

/// مدیریت کش هوشمند
class CacheManager {
  final Map<String, CachedNode> _nodeCache = {};
  final Map<String, CachedTexture> _textureCache = {};
  final Map<String, CachedPath> _pathCache = {};
  final LRUCache<String, ui.Image> _imageCache = LRUCache<String, ui.Image>(100);
  
  int _maxCacheSize = 200;
  int _maxTextureSize = 2048;
  bool _enablePreloading = true;
  
  Timer? _cleanupTimer;

  CacheManager() {
    _setupPeriodicCleanup();
  }

  void configure({
    int? maxCacheSize,
    int? maxTextureSize,
    bool? enablePreloading,
  }) {
    _maxCacheSize = maxCacheSize ?? _maxCacheSize;
    _maxTextureSize = maxTextureSize ?? _maxTextureSize;
    _enablePreloading = enablePreloading ?? _enablePreloading;
  }

  void _setupPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performCleanup();
    });
  }

  /// کش کردن نود
  void cacheNode(String nodeId, Widget nodeWidget, Rect bounds) {
    if (_nodeCache.length >= _maxCacheSize) {
      _evictLeastRecentlyUsed();
    }

    _nodeCache[nodeId] = CachedNode(
      nodeId: nodeId,
      widget: nodeWidget,
      bounds: bounds,
      lastAccessed: DateTime.now(),
      accessCount: 1,
    );
  }

  /// دریافت نود از کش
  CachedNode? getCachedNode(String nodeId) {
    final cached = _nodeCache[nodeId];
    if (cached != null) {
      cached.lastAccessed = DateTime.now();
      cached.accessCount++;
    }
    return cached;
  }

  /// کش کردن texture
  Future<void> cacheTexture(String key, ui.Image image) async {
    if (image.width > _maxTextureSize || image.height > _maxTextureSize) {
      // کاهش سایز texture
      final resized = await _resizeImage(image, _maxTextureSize);
      _textureCache[key] = CachedTexture(
        key: key,
        image: resized,
        lastAccessed: DateTime.now(),
        size: Size(resized.width.toDouble(), resized.height.toDouble()),
      );
    } else {
      _textureCache[key] = CachedTexture(
        key: key,
        image: image,
        lastAccessed: DateTime.now(),
        size: Size(image.width.toDouble(), image.height.toDouble()),
      );
    }
  }

  Future<ui.Image> _resizeImage(ui.Image original, int maxSize) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final scale = math.min(
      maxSize / original.width,
      maxSize / original.height,
    );
    
    final newWidth = (original.width * scale).round();
    final newHeight = (original.height * scale).round();
    
    canvas.scale(scale);
    canvas.drawImage(original, Offset.zero, Paint());
    
    final picture = recorder.endRecording();
    return await picture.toImage(newWidth, newHeight);
  }

  /// preload نودهای مورد نیاز
  Future<void> preloadNodes(List<String> nodeIds) async {
    if (!_enablePreloading) return;

    for (final nodeId in nodeIds) {
      if (!_nodeCache.containsKey(nodeId)) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }
  }

  /// کش کردن مسیر
  void cachePath(String key, Path path, Paint paint) {
    _pathCache[key] = CachedPath(
      key: key,
      path: path,
      paint: paint,
      lastAccessed: DateTime.now(),
    );
  }

  CachedPath? getCachedPath(String key) {
    final cached = _pathCache[key];
    if (cached != null) {
      cached.lastAccessed = DateTime.now();
    }
    return cached;
  }

  void _evictLeastRecentlyUsed() {
    if (_nodeCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _nodeCache.entries) {
      if (oldestTime == null || entry.value.lastAccessed.isBefore(oldestTime)) {
        oldestTime = entry.value.lastAccessed;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _nodeCache.remove(oldestKey);
    }
  }

  void _performCleanup() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 10));

    // پاکسازی نودهای قدیمی
    _nodeCache.removeWhere((key, cached) => 
        cached.lastAccessed.isBefore(cutoff) && cached.accessCount < 3);

    // پاکسازی textures
    _textureCache.removeWhere((key, cached) => 
        cached.lastAccessed.isBefore(cutoff));

    // پاکسازی paths
    _pathCache.removeWhere((key, cached) => 
        cached.lastAccessed.isBefore(cutoff));

    // پاکسازی images
    _imageCache.clear();
  }

  void invalidateNode(String nodeId) {
    _nodeCache.remove(nodeId);
  }

  void clear() {
    _nodeCache.clear();
    _textureCache.clear();
    _pathCache.clear();
    _imageCache.clear();
  }

  CacheStatistics getStatistics() {
    return CacheStatistics(
      nodeCacheSize: _nodeCache.length,
      textureCacheSize: _textureCache.length,
      pathCacheSize: _pathCache.length,
      imageCacheSize: _imageCache.length,
      hitRate: _calculateHitRate(),
      memoryUsage: _calculateMemoryUsage(),
    );
  }

  double _calculateHitRate() {
    // محاسبه نرخ hit cache
    final totalAccess = _nodeCache.values.fold(0, (sum, node) => sum + node.accessCount);
    return totalAccess > 0 ? _nodeCache.length / totalAccess : 0.0;
  }

  double _calculateMemoryUsage() {
    // تخمین استفاده از حافظه (MB)
    return (_nodeCache.length * 0.1) + 
           (_textureCache.length * 0.5) + 
           (_pathCache.length * 0.05);
  }

  void dispose() {
    _cleanupTimer?.cancel();
    clear();
  }
}

/// مدیریت Level of Detail (LOD)
class LODManager {
  int _maxNodes = 200;
  double _simplificationLevel = 0.3;
  bool _enableAdaptiveLOD = true;
  
  final Map<int, LODLevel> _lodLevels = {};

  LODManager() {
    _initializeLODLevels();
  }

  void configure({
    int? maxNodes,
    double? simplificationLevel,
    bool? enableAdaptiveLOD,
  }) {
    _maxNodes = maxNodes ?? _maxNodes;
    _simplificationLevel = simplificationLevel ?? _simplificationLevel;
    _enableAdaptiveLOD = enableAdaptiveLOD ?? _enableAdaptiveLOD;
    
    _initializeLODLevels();
  }

  void _initializeLODLevels() {
    _lodLevels.clear();
    
    // سطح ۰: جزئیات کامل
    _lodLevels[0] = LODLevel(
      level: 0,
      maxNodes: _maxNodes,
      nodeSize: 1.0,
      showLabels: true,
      showTransitions: true,
      animationQuality: 1.0,
    );

    // سطح ۱: جزئیات متوسط
    _lodLevels[1] = LODLevel(
      level: 1,
      maxNodes: (_maxNodes * 0.7).round(),
      nodeSize: 0.8,
      showLabels: true,
      showTransitions: false,
      animationQuality: 0.7,
    );

    // سطح ۲: جزئیات کم
    _lodLevels[2] = LODLevel(
      level: 2,
      maxNodes: (_maxNodes * 0.4).round(),
      nodeSize: 0.6,
      showLabels: false,
      showTransitions: false,
      animationQuality: 0.3,
    );

    // سطح ۳: حداقل جزئیات
    _lodLevels[3] = LODLevel(
      level: 3,
      maxNodes: (_maxNodes * 0.2).round(),
      nodeSize: 0.4,
      showLabels: false,
      showTransitions: false,
      animationQuality: 0.0,
    );
  }

  /// تعیین سطح LOD بر اساس تعداد نودها و عملکرد
  int calculateLODLevel(int totalNodes, double currentFPS, bool isZoomedOut) {
    if (!_enableAdaptiveLOD) return 0;

    // بر اساس تعداد نودها
    int lodByCount = 0;
    if (totalNodes > _maxNodes * 2) lodByCount = 3;
    else if (totalNodes > _maxNodes * 1.5) lodByCount = 2;
    else if (totalNodes > _maxNodes) lodByCount = 1;

    // بر اساس عملکرد
    int lodByPerformance = 0;
    if (currentFPS < 15) lodByPerformance = 3;
    else if (currentFPS < 30) lodByPerformance = 2;
    else if (currentFPS < 45) lodByPerformance = 1;

    // بر اساس zoom
    int lodByZoom = isZoomedOut ? 2 : 0;

    // انتخاب بالاترین سطح LOD
    return math.max(lodByCount, math.max(lodByPerformance, lodByZoom));
  }

  LODLevel getLODLevel(int level) {
    return _lodLevels[level] ?? _lodLevels[0]!;
  }

  /// فیلتر کردن نودها بر اساس اهمیت
  List<String> filterNodesByImportance(List<String> allNodes, int targetCount, 
      {Set<String>? importantNodes, Set<String>? finalStates, String? startState}) {
    
    if (allNodes.length <= targetCount) return allNodes;

    final filtered = <String>[];
    final priorities = <String, int>{};

    // اولویت‌بندی نودها
    for (final node in allNodes) {
      int priority = 0;
      
      if (node == startState) priority += 100;
      if (finalStates?.contains(node) == true) priority += 50;
      if (importantNodes?.contains(node) == true) priority += 25;
      
      priorities[node] = priority;
    }

    // مرتب‌سازی بر اساس اولویت
    final sortedNodes = allNodes.toList()
      ..sort((a, b) => priorities[b]!.compareTo(priorities[a]!));

    return sortedNodes.take(targetCount).toList();
  }

  void dispose() {
    _lodLevels.clear();
  }
}

/// مدیریت Virtual Scrolling
class VirtualScrollManager {
  Rect _viewport = Rect.zero;
  double _padding = 100.0;
  final Map<String, Rect> _nodeBounds = {};
  final Set<String> _visibleNodes = {};
  final Set<String> _culledNodes = {};

  void updateViewport(Rect viewport) {
    _viewport = viewport;
    _updateVisibility();
  }

  void setNodeBounds(String nodeId, Rect bounds) {
    _nodeBounds[nodeId] = bounds;
    _updateVisibility();
  }

  void _updateVisibility() {
    _visibleNodes.clear();
    _culledNodes.clear();

    final expandedViewport = _viewport.inflate(_padding);

    for (final entry in _nodeBounds.entries) {
      if (expandedViewport.overlaps(entry.value)) {
        _visibleNodes.add(entry.key);
      } else {
        _culledNodes.add(entry.key);
      }
    }
  }

  bool isNodeVisible(String nodeId) {
    return _visibleNodes.contains(nodeId);
  }

  bool isNodeCulled(String nodeId) {
    return _culledNodes.contains(nodeId);
  }

  Set<String> getVisibleNodes() => Set.from(_visibleNodes);
  Set<String> getCulledNodes() => Set.from(_culledNodes);

  /// محاسبه نودهای لازم برای preload
  Set<String> getNodesForPreload() {
    final preloadBounds = _viewport.inflate(_padding * 2);
    final preloadNodes = <String>{};

    for (final entry in _nodeBounds.entries) {
      if (preloadBounds.overlaps(entry.value)) {
        preloadNodes.add(entry.key);
      }
    }

    return preloadNodes;
  }

  void dispose() {
    _nodeBounds.clear();
    _visibleNodes.clear();
    _culledNodes.clear();
  }
}

/// بهینه‌ساز رندرینگ
class RenderOptimizer {
  bool _enableCulling = true;
  bool _enableBatching = true;
  int _maxFPS = 60;
  bool _enableVSync = true;
  
  final List<RenderBatch> _renderBatches = [];
  int _currentBatchId = 0;

  void configure({
    bool? enableCulling,
    bool? enableBatching,
    int? maxFPS,
    bool? enableVSync,
  }) {
    _enableCulling = enableCulling ?? _enableCulling;
    _enableBatching = enableBatching ?? _enableBatching;
    _maxFPS = maxFPS ?? _maxFPS;
    _enableVSync = enableVSync ?? _enableVSync;
  }

  /// بهینه‌سازی فرایند رندر
  RenderInstructions optimizeRender(List<RenderCommand> commands, Rect viewport) {
    final optimized = <RenderCommand>[];
    
    // مرحله ۱: Culling
    if (_enableCulling) {
      for (final command in commands) {
        if (_shouldRenderCommand(command, viewport)) {
          optimized.add(command);
        }
      }
    } else {
      optimized.addAll(commands);
    }

    // مرحله ۲: Batching
    List<RenderBatch> batches;
    if (_enableBatching) {
      batches = _batchCommands(optimized);
    } else {
      batches = optimized.map((cmd) => RenderBatch(id: _currentBatchId++, commands: [cmd])).toList();
    }

    // مرحله ۳: اولویت‌بندی
    batches.sort((a, b) => a.priority.compareTo(b.priority));

    return RenderInstructions(
      batches: batches,
      culledCount: commands.length - optimized.length,
      estimatedRenderTime: _estimateRenderTime(batches),
    );
  }

  bool _shouldRenderCommand(RenderCommand command, Rect viewport) {
    // بررسی تداخل با viewport
    if (command.bounds != null && !viewport.overlaps(command.bounds!)) {
      return false;
    }

    // بررسی شفافیت
    if (command.opacity <= 0.01) {
      return false;
    }

    return true;
  }

  List<RenderBatch> _batchCommands(List<RenderCommand> commands) {
    final batches = <RenderBatch>[];
    final groupedCommands = <String, List<RenderCommand>>{};

    // گروه‌بندی commands بر اساس نوع
    for (final command in commands) {
      groupedCommands.putIfAbsent(command.type, () => []).add(command);
    }

    // ایجاد batch برای هر گروه
    for (final entry in groupedCommands.entries) {
      batches.add(RenderBatch(
        id: _currentBatchId++,
        commands: entry.value,
        type: entry.key,
        priority: _getTypePriority(entry.key),
      ));
    }

    return batches;
  }

  int _getTypePriority(String type) {
    switch (type) {
      case 'background': return 0;
      case 'grid': return 1;
      case 'edge': return 2;
      case 'node': return 3;
      case 'label': return 4;
      case 'overlay': return 5;
      default: return 3;
    }
  }

  double _estimateRenderTime(List<RenderBatch> batches) {
    // تخمین زمان رندر بر اساس تعداد و پیچیدگی commands
    double totalTime = 0.0;
    
    for (final batch in batches) {
      totalTime += batch.commands.length * 0.1; // ۰.۱ میلی‌ثانیه به ازای هر command
    }
    
    return totalTime;
  }

  /// بهینه‌سازی انیمیشن
  AnimationSettings optimizeAnimation(int nodeCount, double currentFPS) {
    final settings = AnimationSettings();

    if (currentFPS < 30 || nodeCount > 100) {
      settings.enableAnimations = false;
      settings.duration = Duration.zero;
    } else if (currentFPS < 45 || nodeCount > 50) {
      settings.enableAnimations = true;
      settings.duration = const Duration(milliseconds: 200);
      settings.quality = 0.5;
    } else {
      settings.enableAnimations = true;
      settings.duration = const Duration(milliseconds: 500);
      settings.quality = 1.0;
    }

    return settings;
  }

  void dispose() {
    _renderBatches.clear();
  }
}

/// بهینه‌ساز حافظه
class MemoryOptimizer {
  double _gcThreshold = 0.8;
  bool _autoCleanup = true;
  bool _aggressiveMode = false;
  
  Timer? _cleanupTimer;
  final List<WeakReference<Object>> _managedObjects = [];

  void configure({
    double? gcThreshold,
    bool? autoCleanup,
    bool? aggressiveMode,
  }) {
    _gcThreshold = gcThreshold ?? _gcThreshold;
    _autoCleanup = autoCleanup ?? _autoCleanup;
    _aggressiveMode = aggressiveMode ?? _aggressiveMode;

    if (_autoCleanup) {
      _setupAutoCleanup();
    }
  }

  void _setupAutoCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      Duration(seconds: _aggressiveMode ? 30 : 60),
      (timer) => performCleanup(),
    );
  }

  /// اجرای پاکسازی حافظه
  void performCleanup() {
    // پاکسازی weak references
    _managedObjects.removeWhere((ref) => ref.target == null);

    // اجرای garbage collection در صورت نیاز
    final memoryPressure = _getMemoryPressure();
    if (memoryPressure > _gcThreshold) {
      // Force garbage collection
      _forceGC();
    }
  }

  double _getMemoryPressure() {
    // در حالت واقعی، از platform channels برای دریافت اطلاعات حافظه
    return 0.5; // مقدار شبیه‌سازی شده
  }

  void _forceGC() {
    // شبیه‌سازی garbage collection
    // در Dart، نمی‌توان مستقیماً GC را اجرا کرد
  }

  /// register کردن object برای مدیریت
  void registerObject(Object object) {
    _managedObjects.add(WeakReference(object));
  }

  /// تخمین استفاده از حافظه
  MemoryEstimation estimateMemoryUsage(int nodeCount, int edgeCount) {
    final nodeMemory = nodeCount * 0.5; // KB per node
    final edgeMemory = edgeCount * 0.2; // KB per edge
    final cacheMemory = (nodeCount * 0.1) + (edgeCount * 0.05); // Cache overhead
    
    final totalMemory = nodeMemory + edgeMemory + cacheMemory;
    
    return MemoryEstimation(
      nodeMemory: nodeMemory,
      edgeMemory: edgeMemory,
      cacheMemory: cacheMemory,
      totalMemory: totalMemory,
      isWithinLimits: totalMemory < 100, // 100 MB limit
    );
  }

  /// بهینه‌سازی برای موبایل
  MobileOptimizations getMobileOptimizations() {
    return MobileOptimizations(
      reducedAnimations: _aggressiveMode,
      simplifiedRendering: _aggressiveMode,
      aggressiveCaching: true,
      lowMemoryMode: _aggressiveMode,
      batteryOptimization: true,
    );
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _managedObjects.clear();
  }
}

/// کلاس LRU Cache
class LRUCache<K, V> {
  final int _maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  LRUCache(this._maxSize);

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  int get length => _cache.length;
  
  void clear() => _cache.clear();
}

/// کلاس‌های مدل و داده‌ای

class FrameMetrics {
  final Duration timestamp;
  final double frameTime;
  final bool isDropped;

  FrameMetrics({
    required this.timestamp,
    required this.frameTime,
    required this.isDropped,
  });
}

class MemoryMetrics {
  final DateTime timestamp;
  final double heapUsage;
  final double totalMemory;
  final int gcCount;

  MemoryMetrics({
    required this.timestamp,
    required this.heapUsage,
    required this.totalMemory,
    required this.gcCount,
  });
}

class RenderMetrics {
  final DateTime timestamp;
  final int renderedNodes;
  final int culledNodes;
  final double renderTime;
  final int batchCount;

  RenderMetrics({
    required this.timestamp,
    required this.renderedNodes,
    required this.culledNodes,
    required this.renderTime,
    required this.batchCount,
  });
}

class PerformanceReport {
  final double averageFPS;
  final int droppedFrames;
  final double memoryUsage;
  final List<String> recommendations;
  final PerformanceSeverity severity;

  PerformanceReport({
    required this.averageFPS,
    required this.droppedFrames,
    required this.memoryUsage,
    required this.recommendations,
    required this.severity,
  });
}

enum PerformanceSeverity { good, warning, critical }

class MemoryUsageInfo {
  final double heapUsage;
  final double totalMemory;
  final int gcCount;

  MemoryUsageInfo({
    required this.heapUsage,
    required this.totalMemory,
    required this.gcCount,
  });
}

class CachedNode {
  final String nodeId;
  final Widget widget;
  final Rect bounds;
  DateTime lastAccessed;
  int accessCount;

  CachedNode({
    required this.nodeId,
    required this.widget,
    required this.bounds,
    required this.lastAccessed,
    required this.accessCount,
  });
}

class CachedTexture {
  final String key;
  final ui.Image image;
  DateTime lastAccessed;
  final Size size;

  CachedTexture({
    required this.key,
    required this.image,
    required this.lastAccessed,
    required this.size,
  });
}

class CachedPath {
  final String key;
  final Path path;
  final Paint paint;
  DateTime lastAccessed;

  CachedPath({
    required this.key,
    required this.path,
    required this.paint,
    required this.lastAccessed,
  });
}

class CacheStatistics {
  final int nodeCacheSize;
  final int textureCacheSize;
  final int pathCacheSize;
  final int imageCacheSize;
  final double hitRate;
  final double memoryUsage;

  CacheStatistics({
    required this.nodeCacheSize,
    required this.textureCacheSize,
    required this.pathCacheSize,
    required this.imageCacheSize,
    required this.hitRate,
    required this.memoryUsage,
  });
}

class LODLevel {
  final int level;
  final int maxNodes;
  final double nodeSize;
  final bool showLabels;
  final bool showTransitions;
  final double animationQuality;

  LODLevel({
    required this.level,
    required this.maxNodes,
    required this.nodeSize,
    required this.showLabels,
    required this.showTransitions,
    required this.animationQuality,
  });
}

class RenderCommand {
  final String type;
  final Rect? bounds;
  final double opacity;
  final Paint? paint;
  final Path? path;
  final String? text;

  RenderCommand({
    required this.type,
    this.bounds,
    this.opacity = 1.0,
    this.paint,
    this.path,
    this.text,
  });
}

class RenderBatch {
  final int id;
  final List<RenderCommand> commands;
  final String type;
  final int priority;

  RenderBatch({
    required this.id,
    required this.commands,
    this.type = 'default',
    this.priority = 0,
  });
}

class RenderInstructions {
  final List<RenderBatch> batches;
  final int culledCount;
  final double estimatedRenderTime;

  RenderInstructions({
    required this.batches,
    required this.culledCount,
    required this.estimatedRenderTime,
  });
}

class AnimationSettings {
  bool enableAnimations = true;
  Duration duration = const Duration(milliseconds: 500);
  double quality = 1.0;
  Curve curve = Curves.easeInOut;

  AnimationSettings({
    this.enableAnimations = true,
    this.duration = const Duration(milliseconds: 500),
    this.quality = 1.0,
    this.curve = Curves.easeInOut,
  });
}

class MemoryEstimation {
  final double nodeMemory;
  final double edgeMemory;
  final double cacheMemory;
  final double totalMemory;
  final bool isWithinLimits;

  MemoryEstimation({
    required this.nodeMemory,
    required this.edgeMemory,
    required this.cacheMemory,
    required this.totalMemory,
    required this.isWithinLimits,
  });
}

class MobileOptimizations {
  final bool reducedAnimations;
  final bool simplifiedRendering;
  final bool aggressiveCaching;
  final bool lowMemoryMode;
  final bool batteryOptimization;

  MobileOptimizations({
    required this.reducedAnimations,
    required this.simplifiedRendering,
    required this.aggressiveCaching,
    required this.lowMemoryMode,
    required this.batteryOptimization,
  });
}

/// Observer برای مانیتورینگ فریم‌ها
class _FrameObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        PerformanceOptimizer().memoryOptimizer.performCleanup();
        break;
      case AppLifecycleState.resumed:
        PerformanceOptimizer().configureForDevice();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}

/// Widget مدیریت عملکرد
class PerformanceManager extends StatefulWidget {
  final Widget child;
  final bool enableMonitoring;
  final VoidCallback? onPerformanceIssue;

  const PerformanceManager({
    super.key,
    required this.child,
    this.enableMonitoring = true,
    this.onPerformanceIssue,
  });

  @override
  State<PerformanceManager> createState() => _PerformanceManagerState();
}

class _PerformanceManagerState extends State<PerformanceManager> {
  late final StreamSubscription<PerformanceReport> _reportSubscription;
  PerformanceReport? _lastReport;

  @override
  void initState() {
    super.initState();
    
    if (widget.enableMonitoring) {
      PerformanceOptimizer().configureForDevice();
      
      _reportSubscription = PerformanceOptimizer()
          .monitor
          .reports
          .listen(_handlePerformanceReport);
    }
  }

  void _handlePerformanceReport(PerformanceReport report) {
    setState(() {
      _lastReport = report;
    });

    if (report.severity == PerformanceSeverity.critical) {
      widget.onPerformanceIssue?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enableMonitoring && _lastReport != null)
          _buildPerformanceOverlay(),
      ],
    );
  }

  Widget _buildPerformanceOverlay() {
    if (_lastReport == null) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FPS: ${_lastReport!.averageFPS.toStringAsFixed(1)}',
              style: TextStyle(
                color: _getFPSColor(_lastReport!.averageFPS),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Memory: ${_lastReport!.memoryUsage.toStringAsFixed(1)} MB',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            if (_lastReport!.droppedFrames > 0)
              Text(
                'Dropped: ${_lastReport!.droppedFrames}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getFPSColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 30) return Colors.yellow;
    return Colors.red;
  }

  @override
  void dispose() {
    if (widget.enableMonitoring) {
      _reportSubscription.cancel();
    }
    super.dispose();
  }
}

class AdvancedOptimizer {
  final PerformanceOptimizer _base = PerformanceOptimizer();

  /// تحلیل الگوهای استفاده
  UsagePattern analyzeUsagePattern(List<String> accessedNodes, Duration timeWindow) {
    final frequentNodes = <String, int>{};

    // تحلیل فرکانس دسترسی
    for (final node in accessedNodes) {
      frequentNodes[node] = (frequentNodes[node] ?? 0) + 1;
    }

    // تعیین نودهای پر استفاده
    final sortedByFrequency = frequentNodes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hotNodes = sortedByFrequency.take(10).map((e) => e.key).toSet();

    return UsagePattern(
      hotNodes: hotNodes,
      accessFrequency: frequentNodes,
      totalAccesses: accessedNodes.length,
      timeWindow: timeWindow,
    );
  }

  /// بهینه‌سازی پیش‌بینانه
  Future<void> performPredictiveOptimization(UsagePattern pattern) async {
    // Preload نودهای پر استفاده
    await _base.cache.preloadNodes(pattern.hotNodes.toList());
    
    // تنظیم LOD بر اساس الگوی استفاده
    final lodLevel = pattern.totalAccesses > 1000 ? 2 : 1;
    
    // بهینه‌سازی حافظه
    if (pattern.accessFrequency.length > 100) {
      _base.memoryOptimizer.performCleanup();
    }
  }

  /// تحلیل bottleneck ها
  List<PerformanceBottleneck> identifyBottlenecks(List<RenderMetrics> metrics) {
    final bottlenecks = <PerformanceBottleneck>[];

    // تحلیل زمان رندر
    final double avgRenderTime = metrics.isNotEmpty
        ? metrics.map((m) => m.renderTime).reduce((a, b) => a + b) / metrics.length.toDouble() // تبدیل int به double
        : 0.0;

    if (avgRenderTime > 16.67) {
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.rendering,
        severity: avgRenderTime > 33.33 ? PerformanceSeverity.critical : PerformanceSeverity.warning,
        description: 'رندرینگ کند (${avgRenderTime.toStringAsFixed(2)}ms)',
        suggestedFix: 'فعال‌سازی culling و batching',
      ));
    }

    // تحلیل تعداد نودهای رندر شده
    final double avgRenderedNodes = metrics.isNotEmpty
        ? metrics.map((m) => m.renderedNodes).reduce((a, b) => a + b) / metrics.length.toDouble() // تبدیل int به double
        : 0.0;

    if (avgRenderedNodes > 200) {
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.tooManyNodes,
        severity: avgRenderedNodes > 500 ? PerformanceSeverity.critical : PerformanceSeverity.warning,
        description: 'تعداد زیاد نودهای رندر شده (${avgRenderedNodes.round()})',
        suggestedFix: 'استفاده از Virtual Scrolling و LOD',
      ));
    }

    return bottlenecks;
  }
}

/// کلاس‌های کمکی اضافی

class UsagePattern {
  final Set<String> hotNodes;
  final Map<String, int> accessFrequency;
  final int totalAccesses;
  final Duration timeWindow;

  UsagePattern({
    required this.hotNodes,
    required this.accessFrequency,
    required this.totalAccesses,
    required this.timeWindow,
  });
}

class PerformanceBottleneck {
  final BottleneckType type;
  final PerformanceSeverity severity;
  final String description;
  final String suggestedFix;

  PerformanceBottleneck({
    required this.type,
    required this.severity,
    required this.description,
    required this.suggestedFix,
  });
}

enum BottleneckType {
  rendering,
  memory,
  tooManyNodes,
  heavyAnimations,
  inefficientCaching,
}