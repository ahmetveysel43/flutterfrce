// lib/presentation/widgets/results/enhanced_results_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/test_constants.dart';
import '../../../core/algorithms/phase_detector.dart';
import '../../../domain/entities/test_result_entity.dart';

class EnhancedResultsWidget extends StatefulWidget {
  final TestResultEntity testResult;
  final bool showTurkish;

  const EnhancedResultsWidget({
    super.key,
    required this.testResult,
    this.showTurkish = true,
  });

  @override
  State<EnhancedResultsWidget> createState() => _EnhancedResultsWidgetState();
}

class _EnhancedResultsWidgetState extends State<EnhancedResultsWidget>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _metricsAnimationController;
  late AnimationController _chartsAnimationController;
  late AnimationController _performanceAnimationController;
  
  late Animation<double> _metricsAnimation;
  late Animation<double> _chartsAnimation;
  late Animation<double> _performanceAnimation;
  
  String? _normKey;
  Map<String, PerformanceLevel> _performanceLevels = {};

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupNormativeData();
    _calculatePerformanceLevels();
    _startAnimations();
  }

  void _setupAnimations() {
    _tabController = TabController(length: 4, vsync: this);
    
    _metricsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _metricsAnimation = CurvedAnimation(
      parent: _metricsAnimationController,
      curve: Curves.easeOutBack,
    );
    
    _chartsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartsAnimation = CurvedAnimation(
      parent: _chartsAnimationController,
      curve: Curves.easeInOut,
    );
    
    _performanceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _performanceAnimation = CurvedAnimation(
      parent: _performanceAnimationController,
      curve: Curves.elasticOut,
    );
  }

  void _setupNormativeData() {
    final athlete = widget.testResult.athlete;
    _normKey = TestConstants.getTurkishNormKey(
      athlete.gender,
      athlete.age,
      athlete.sport,
    );
  }

  void _calculatePerformanceLevels() {
    final metrics = widget.testResult.metrics;
    
    // Jump height performance
    if (metrics.jumpHeight != null && _normKey != null) {
      _performanceLevels['jumpHeight'] = TestConstants.getJumpPerformanceLevel(
        metrics.jumpHeight!,
        _normKey!,
      );
    }
    
    // Force performance
    if (metrics.peakForce != null && _normKey != null) {
      _performanceLevels['peakForce'] = TestConstants.getForcePerformanceLevel(
        metrics.peakForce!,
        _normKey!,
      );
    }
    
    // Asymmetry assessment
    if (metrics.asymmetryIndex != null) {
      final asymmetry = metrics.asymmetryIndex!;
      if (asymmetry <= TestConstants.excellentAsymmetryThreshold) {
        _performanceLevels['asymmetry'] = PerformanceLevel.mukemmel;
      } else if (asymmetry <= TestConstants.goodAsymmetryThreshold) {
        _performanceLevels['asymmetry'] = PerformanceLevel.ortalamaUstu;
      } else if (asymmetry <= TestConstants.asymmetryThreshold) {
        _performanceLevels['asymmetry'] = PerformanceLevel.ortalama;
      } else {
        _performanceLevels['asymmetry'] = PerformanceLevel.zayif;
      }
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _metricsAnimationController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 600), () {
      _chartsAnimationController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 900), () {
      _performanceAnimationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildResultsHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDetailedMetricsTab(),
                _buildAnalysisTab(),
                _buildRecommendationsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.showTurkish ? 'Test Sonuçları' : 'Test Results',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: TestConstants.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () => _shareResults(),
          icon: const Icon(Icons.share),
        ),
        IconButton(
          onPressed: () => _exportResults(),
          icon: const Icon(Icons.download),
        ),
        IconButton(
          onPressed: () => _printResults(),
          icon: const Icon(Icons.print),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    final protocol = TestConstants.getProtocol(widget.testResult.testType)!;
    final overallPerformance = _calculateOverallPerformance();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TestConstants.primaryBlue,
            TestConstants.secondaryBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Test Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getTestIcon(widget.testResult.testType),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Test Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TestConstants.getTestName(widget.testResult.testType, turkish: widget.showTurkish),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.testResult.athlete.fullName} • ${_formatDate(widget.testResult.timestamp)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Overall Performance
              AnimatedBuilder(
                animation: _performanceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _performanceAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: overallPerformance.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            overallPerformance.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            overallPerformance.turkishName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Quick Stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final metrics = widget.testResult.metrics;
    
    return Row(
      children: [
        if (metrics.jumpHeight != null)
          Expanded(
            child: _buildQuickStatCard(
              label: widget.showTurkish ? 'Sıçrama' : 'Jump Height',
              value: '${metrics.jumpHeight!.toStringAsFixed(1)} cm',
              icon: Icons.height,
              performance: _performanceLevels['jumpHeight'],
            ),
          ),
        
        if (metrics.peakForce != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickStatCard(
              label: widget.showTurkish ? 'Zirve Kuvvet' : 'Peak Force',
              value: '${metrics.peakForce!.toStringAsFixed(0)} N',
              icon: Icons.trending_up,
              performance: _performanceLevels['peakForce'],
            ),
          ),
        ],
        
        if (metrics.asymmetryIndex != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickStatCard(
              label: widget.showTurkish ? 'Asimetri' : 'Asymmetry',
              value: '${metrics.asymmetryIndex!.toStringAsFixed(1)}%',
              icon: Icons.balance,
              performance: _performanceLevels['asymmetry'],
            ),
          ),
        ],
        
        if (metrics.rfdMax != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickStatCard(
              label: 'RFD',
              value: '${metrics.rfdMax!.toStringAsFixed(0)} N/s',
              icon: Icons.speed,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickStatCard({
    required String label,
    required String value,
    required IconData icon,
    PerformanceLevel? performance,
  }) {
    return AnimatedBuilder(
      animation: _metricsAnimation,
      builder: (context, child) {
        return Transform.translateY(
          offset: Offset(0, 50 * (1 - _metricsAnimation.value)),
          child: Opacity(
            opacity: _metricsAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: performance?.color ?? Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: performance?.color ?? Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (performance != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      performance.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: TestConstants.primaryBlue,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: TestConstants.primaryBlue,
        indicatorWeight: 3,
        tabs: [
          Tab(
            icon: const Icon(Icons.dashboard),
            text: widget.showTurkish ? 'Genel Bakış' : 'Overview',
          ),
          Tab(
            icon: const Icon(Icons.analytics),
            text: widget.showTurkish ? 'Detaylı' : 'Detailed',
          ),
          Tab(
            icon: const Icon(Icons.insights),
            text: widget.showTurkish ? 'Analiz' : 'Analysis',
          ),
          Tab(
            icon: const Icon(Icons.lightbulb),
            text: widget.showTurkish ? 'Öneriler' : 'Recommendations',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performance Summary
          _buildPerformanceSummaryCard(),
          
          const SizedBox(height: 16),
          
          // Key Metrics Grid
          _buildKeyMetricsGrid(),
          
          const SizedBox(height: 16),
          
          // Force-Time Chart
          _buildForceTimeChart(),
          
          const SizedBox(height: 16),
          
          // Normative Comparison
          _buildNormativeComparisonCard(),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummaryCard() {
    final overallPerformance = _calculateOverallPerformance();
    
    return AnimatedBuilder(
      animation: _metricsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _metricsAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  widget.showTurkish ? 'Genel Performans' : 'Overall Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TestConstants.primaryBlue,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        overallPerformance.color.withValues(alpha: 0.2),
                        overallPerformance.color.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: overallPerformance.color,
                      width: 4,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        overallPerformance.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        overallPerformance.turkishName,
                        style: TextStyle(
                          color: overallPerformance.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  _getPerformanceDescription(overallPerformance),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeyMetricsGrid() {
    final metrics = widget.testResult.metrics;
    final protocol = TestConstants.getProtocol(widget.testResult.testType)!;
    
    return AnimatedBuilder(
      animation: _metricsAnimation,
      builder: (context, child) {
        return Transform.translateY(
          offset: Offset(0, 100 * (1 - _metricsAnimation.value)),
          child: Opacity(
            opacity: _metricsAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.showTurkish ? 'Anahtar Metrikler' : 'Key Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TestConstants.primaryBlue,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: _buildMetricCards(metrics, protocol),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildMetricCards(TestMetrics metrics, TestProtocol protocol) {
    final cards = <Widget>[];
    
    // Jump Height
    if (metrics.jumpHeight != null) {
      cards.add(_buildMetricCard(
        title: widget.showTurkish ? 'Sıçrama Yüksekliği' : 'Jump Height',
        value: '${metrics.jumpHeight!.toStringAsFixed(1)} cm',
        icon: Icons.height,
        color: TestConstants.successGreen,
        performance: _performanceLevels['jumpHeight'],
      ));
    }
    
    // Peak Force
    if (metrics.peakForce != null) {
      cards.add(_buildMetricCard(
        title: widget.showTurkish ? 'Zirve Kuvvet' : 'Peak Force',
        value: '${metrics.peakForce!.toStringAsFixed(0)} N',
        icon: Icons.trending_up,
        color: TestConstants.primaryBlue,
        performance: _performanceLevels['peakForce'],
      ));
    }
    
    // RFD Max
    if (metrics.rfdMax != null) {
      cards.add(_buildMetricCard(
        title: widget.showTurkish ? 'Maksimum RFD' : 'Max RFD',
        value: '${metrics.rfdMax!.toStringAsFixed(0)} N/s',
        icon: Icons.speed,
        color: TestConstants.warningOrange,
      ));
    }
    
    // Asymmetry
    if (metrics.asymmetryIndex != null) {
      cards.add(_buildMetricCard(
        title: widget.showTurkish ? 'Asimetri İndeksi' : 'Asymmetry Index',
        value: '${metrics.asymmetryIndex!.toStringAsFixed(1)}%',
        icon: Icons.balance,
        color: _getAsymmetryColor(metrics.asymmetryIndex!),
        performance: _performanceLevels['asymmetry'],
      ));
    }
    
    // Flight Time
    if (metrics.flightTime != null) {
      cards.add(_buildMetricCard(
        title: widget.showTurkish ? 'Uçuş Süresi' : 'Flight Time',
        value: '${metrics.flightTime!.toStringAsFixed(0)} ms',
        icon: Icons.flight,
        color: Colors.purple,
      ));
    }
    
    // Contact Time (if available)
    if (metrics.contactTime != null) {
      cards.add(_buildMetricCard(
        title: widget.showTurkish ? 'Temas Süresi' : 'Contact Time',
        value: '${metrics.contactTime!.toStringAsFixed(0)} ms',
        icon: Icons.touch_app,
        color: Colors.teal,
      ));
    }
    
    return cards;
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    PerformanceLevel? performance,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              if (performance != null) ...[
                const SizedBox(width: 8),
                Text(performance.emoji, style: const TextStyle(fontSize: 20)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForceTimeChart() {
    return AnimatedBuilder(
      animation: _chartsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartsAnimation.value,
          child: Opacity(
            opacity: _chartsAnimation.value,
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.showTurkish ? 'Kuvvet-Zaman Eğrisi' : 'Force-Time Curve',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TestConstants.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildForceChart(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForceChart() {
    final forceData = widget.testResult.forceTimeData;
    
    if (forceData.isEmpty) {
      return Center(
        child: Text(
          widget.showTurkish ? 'Kuvvet verisi bulunamadı' : 'No force data available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    final spots = forceData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(index / 100.0, data.totalGRF); // 100Hz data
    }).toList();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) => Text(
                '${(value / 1000).toStringAsFixed(1)}k',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(1)}s',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: TestConstants.primaryBlue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: TestConstants.primaryBlue.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormativeComparisonCard() {
    if (_normKey == null) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: _chartsAnimation,
      builder: (context, child) {
        return Transform.translateY(
          offset: Offset(0, 100 * (1 - _chartsAnimation.value)),
          child: Opacity(
            opacity: _chartsAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.showTurkish ? 'Türk Popülasyonu Karşılaştırması' : 'Turkish Population Comparison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TestConstants.primaryBlue,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildNormativeChart(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNormativeChart() {
    final jumpHeight = widget.testResult.metrics.jumpHeight;
    if (jumpHeight == null || _normKey == null) {
      return const SizedBox.shrink();
    }
    
    final norms = TestConstants.turkishJumpNorms[_normKey!]!;
    final userLevel = _performanceLevels['jumpHeight']!;
    
    return Container(
      height: 200,
      child: Column(
        children: [
          // Performance levels bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  TestConstants.performanceColors[PerformanceLevel.zayif]!,
                  TestConstants.performanceColors[PerformanceLevel.ortalamaAlti]!,
                  TestConstants.performanceColors[PerformanceLevel.ortalama]!,
                  TestConstants.performanceColors[PerformanceLevel.ortalamaUstu]!,
                  TestConstants.performanceColors[PerformanceLevel.mukemmel]!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // User position indicator
                Positioned(
                  left: _calculateUserPosition(jumpHeight, norms) * 
                        (MediaQuery.of(context).size.width - 80),
                  top: 5,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: userLevel.color, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        userLevel.emoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Performance level labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: PerformanceLevel.values.map((level) {
              return Column(
                children: [
                  Text(
                    level.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.turkishName,
                    style: TextStyle(
                      fontSize: 10,
                      color: level.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Your result
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: userLevel.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: userLevel.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userLevel.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      widget.showTurkish ? 'Sizin Sonucunuz' : 'Your Result',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${jumpHeight.toStringAsFixed(1)} cm',
                      style: TextStyle(
                        color: userLevel.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userLevel.turkishName,
                      style: TextStyle(
                        color: userLevel.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetricsTab() {
    // Detailed metrics implementation
    return Center(
      child: Text(
        widget.showTurkish ? 'Detaylı metrikler yakında...' : 'Detailed metrics coming soon...',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    // Analysis implementation
    return Center(
      child: Text(
        widget.showTurkish ? 'Analiz yakında...' : 'Analysis coming soon...',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    // Recommendations implementation
    return Center(
      child: Text(
        widget.showTurkish ? 'Öneriler yakında...' : 'Recommendations coming soon...',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "compare",
          onPressed: () => _compareResults(),
          backgroundColor: TestConstants.secondaryBlue,
          child: const Icon(Icons.compare_arrows, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "save",
          onPressed: () => _saveResults(),
          backgroundColor: TestConstants.primaryBlue,
          child: const Icon(Icons.save, color: Colors.white),
        ),
      ],
    );
  }

  // Helper methods
  PerformanceLevel _calculateOverallPerformance() {
    if (_performanceLevels.isEmpty) return PerformanceLevel.ortalama;
    
    final levels = _performanceLevels.values.toList();
    final averageIndex = levels.map((l) => l.index).reduce((a, b) => a + b) / levels.length;
    
    return PerformanceLevel.values[averageIndex.round().clamp(0, PerformanceLevel.values.length - 1)];
  }

  String _getPerformanceDescription(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.mukemmel:
        return widget.showTurkish 
            ? 'Mükemmel performans! Elite seviyede sonuçlar.'
            : 'Excellent performance! Elite level results.';
      case PerformanceLevel.ortalamaUstu:
        return widget.showTurkish
            ? 'İyi performans. Hedeflerinize yaklaşıyorsunuz.'
            : 'Good performance. You\'re approaching your goals.';
      case PerformanceLevel.ortalama:
        return widget.showTurkish
            ? 'Ortalama performans. Gelişim için potansiyel var.'
            : 'Average performance. There\'s potential for improvement.';
      case PerformanceLevel.ortalamaAlti:
        return widget.showTurkish
            ? 'Gelişim gerekli. Antrenman planınızı gözden geçirin.'
            : 'Improvement needed. Review your training plan.';
      case PerformanceLevel.zayif:
        return widget.showTurkish
            ? 'Yoğun antrenman gerekli. Uzmandan destek alın.'
            : 'Intensive training needed. Consider expert guidance.';
    }
  }

  Color _getAsymmetryColor(double asymmetry) {
    if (asymmetry <= TestConstants.excellentAsymmetryThreshold) {
      return TestConstants.successGreen;
    } else if (asymmetry <= TestConstants.goodAsymmetryThreshold) {
      return TestConstants.warningOrange;
    } else {
      return TestConstants.errorRed;
    }
  }

  double _calculateUserPosition(double userValue, JumpNorms norms) {
    final min = norms.zayif - 5;
    final max = norms.mukemmel + 5;
    return ((userValue - min) / (max - min)).clamp(0.0, 1.0);
  }

  IconData _getTestIcon(TestType testType) {
    switch (testType) {
      case TestType.counterMovementJump:
        return Icons.trending_up;
      case TestType.squatJump:
        return Icons.arrow_upward;
      case TestType.dropJump:
        return Icons.arrow_downward;
      default:
        return Icons.analytics;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _shareResults() {
    // Share implementation
  }

  void _exportResults() {
    // Export implementation
  }

  void _printResults() {
    // Print implementation
  }

  void _compareResults() {
    // Compare implementation
  }

  void _saveResults() {
    // Save implementation
  }

  @override
  void dispose() {
    _tabController.dispose();
    _metricsAnimationController.dispose();
    _chartsAnimationController.dispose();
    _performanceAnimationController.dispose();
    super.dispose();
  }
}

// =================== SUPPORTING CLASSES ===================

class TestResultEntity {
  final String id;
  final TestType testType;
  final AthleteEntity athlete;
  final TestMetrics metrics;
  final DateTime timestamp;
  final Duration testDuration;
  final List<ForceData> forceTimeData;
  final Map<String, dynamic> additionalData;

  const TestResultEntity({
    required this.id,
    required this.testType,
    required this.athlete,
    required this.metrics,
    required this.timestamp,
    required this.testDuration,
    required this.forceTimeData,
    this.additionalData = const {},
  });
}

class AthleteEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String gender;
  final int? age;
  final String? sport;
  final String? team;
  final double? height;
  final double? weight;

  const AthleteEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.age,
    this.sport,
    this.team,
    this.height,
    this.weight,
  });

  String get fullName => '$firstName $lastName';
}

class TestMetrics {
  final double? jumpHeight;
  final double? peakForce;
  final double? averageForce;
  final double? rfdMax;
  final double? rfd100ms;
  final double? rfd200ms;
  final double? impulse;
  final double? takeoffVelocity;
  final double? flightTime;
  final double? contactTime;
  final double? reactiveStrengthIndex;
  final double? asymmetryIndex;
  final double? leftPeakForce;
  final double? rightPeakForce;
  final double? bodyWeight;
  final Map<String, double> additionalMetrics;

  const TestMetrics({
    this.jumpHeight,
    this.peakForce,
    this.averageForce,
    this.rfdMax,
    this.rfd100ms,
    this.rfd200ms,
    this.impulse,
    this.takeoffVelocity,
    this.flightTime,
    this.contactTime,
    this.reactiveStrengthIndex,
    this.asymmetryIndex,
    this.leftPeakForce,
    this.rightPeakForce,
    this.bodyWeight,
    this.additionalMetrics = const {},
  });
}

class ForceData {
  final double timestamp;
  final double leftGRF;
  final double rightGRF;
  final double totalGRF;
  final double asymmetryIndex;

  const ForceData({
    required this.timestamp,
    required this.leftGRF,
    required this.rightGRF,
    required this.totalGRF,
    required this.asymmetryIndex,
  });
}