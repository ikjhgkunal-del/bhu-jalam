import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:auto_size_text/auto_size_text.dart'; // 🔹 for adaptive text
import 'package:fl_chart/fl_chart.dart'; // 🔹 client-side chart rendering
import 'services/api_services.dart';

class AnalyticsPage extends StatefulWidget {
  final String district;
  final String block;

  const AnalyticsPage({super.key, required this.district, required this.block});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _extras;
  List<Map<String, dynamic>>? _chartData;
  bool _loading = true;
  String? _fatalError;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final extras = await ApiService.getExtras(widget.district, widget.block);
      final plotData =
          await ApiService.getPlotData(widget.district, widget.block);

      if (!mounted) return;
      setState(() {
        _extras = extras.isNotEmpty ? extras : null;
        _chartData = plotData;
        _loading = false;
        _fatalError = null;
      });

      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _extras = null;
        _chartData = null;
        _loading = false;
        _fatalError = e.toString();
      });
    }
  }

  // ---------- Chart Builder ----------
  Widget _buildWaterLevelChart() {
    if (_chartData == null || _chartData!.isEmpty) {
      return const Center(
        child: Text("⚠️ No graph available",
            style: TextStyle(color: Colors.white70)),
      );
    }

    // Convert data points to FlSpot list
    final spots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < _chartData!.length; i++) {
      final point = _chartData![i];
      final value = (point['value'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));

      // Extract short date label (e.g., "02 Sep")
      final dateStr = point['date'] as String? ?? '';
      if (dateStr.length >= 10) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final monthIdx = int.tryParse(parts[1]) ?? 0;
          labels.add('${parts[2]} ${monthIdx > 0 && monthIdx <= 12 ? months[monthIdx] : parts[1]}');
        } else {
          labels.add(dateStr);
        }
      } else {
        labels.add(dateStr);
      }
    }

    // Calculate min/max for Y-axis range
    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY).abs() * 0.15;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const Text('');
                  // Show every other label to avoid crowding
                  if (labels.length > 5 && idx % 2 != 0) return const Text('');
                  return Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      labels[idx],
                      style: const TextStyle(color: Colors.white54, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFF00C6FF),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF00C6FF),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00C6FF).withOpacity(0.3),
                    const Color(0xFF00C6FF).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.spotIndex;
                  final label = idx < labels.length ? labels[idx] : '';
                  return LineTooltipItem(
                    '$label\n${spot.y.toStringAsFixed(2)} m',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Helpers ----------
  Widget _buildShimmerBox({double height = 100, double width = double.infinity}) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.2),
      highlightColor: Colors.white.withOpacity(0.4),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAnimatedStat(String label, dynamic value,
      {required IconData icon, String suffix = ""}) {
    final target = (value is num) ? value.toDouble() : 0.0;

    return Expanded( // 🔹 ensures equal width for all stat cards
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final display =
                (target * _animController.value).toStringAsFixed(1);
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "$display$suffix",
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, String? title, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              children: [
                if (icon != null) Icon(icon, color: Colors.white, size: 18),
                if (icon != null) const SizedBox(width: 6),
                Expanded(
                  child: AutoSizeText(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    minFontSize: 12, // 🔹 shrink text if space is tight
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (title != null) const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 Full gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: _loading
                ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _buildShimmerBox(height: 20, width: 150),
                  ]),
                  const SizedBox(height: 20),
                  _buildCard(child: _buildShimmerBox(height: 200)),
                  Row(
                    children: [
                      Expanded(
                          child: _buildShimmerBox(
                              height: 120, width: double.infinity)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: _buildShimmerBox(
                              height: 120, width: double.infinity)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: _buildShimmerBox(
                              height: 120, width: double.infinity)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildShimmerBox(
                            height: 20, width: double.infinity),
                        const SizedBox(height: 10),
                        _buildShimmerBox(
                            height: 20, width: double.infinity),
                      ],
                    ),
                  ),
                ],
              ),
            )
                : _fatalError != null
                ? Center(
              child: Text(
                "❌ Error: $_fatalError",
                style: const TextStyle(
                    color: Colors.red, fontSize: 16),
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text("Uttar Pradesh",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            Text(
                              "${widget.district}, ${widget.block}",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Graph — now rendered with fl_chart
                  _buildCard(
                    title: "Mean Water Levels (Last 10 days)",
                    icon: Icons.show_chart,
                    child: _buildWaterLevelChart(),
                  ),

                  // Stats row (aligned & equal)
                  Row(
                    children: [
                      _buildAnimatedStat(
                          "Rainfall", _extras?['rainfall_mm'],
                          icon: Icons.cloud, suffix: " mm"),
                      _buildAnimatedStat(
                          "Water Table", _extras?['last_water_level'],
                          icon: Icons.water_drop, suffix: " m"),
                      _buildAnimatedStat(
                          "Score", _extras?['final_score_pct'],
                          icon: Icons.speed, suffix: "%"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Detailed Info
                  if (_extras != null)
                    _buildCard(
                      title: "Detailed Info",
                      icon: Icons.info,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📅 Last Date: ${_extras?['last_date']}",
                              style: const TextStyle(
                                  color: Colors.white70)),
                          Text("🪨 Aquifer: ${_extras?['aquifer_type']}",
                              style: const TextStyle(
                                  color: Colors.white70)),
                          Text(
                              "📈 Fluctuation: ${_extras?['daily_fluctuation']}",
                              style: const TextStyle(
                                  color: Colors.white70)),
                          const SizedBox(height: 8),
                          const Text("🌱 Yield:",
                              style:
                              TextStyle(color: Colors.white70)),
                          Text(_extras?['yield']?.toString() ?? "N/A",
                              style: const TextStyle(
                                  color: Colors.white)),
                        ],
                      ),
                    ),

                  // Water Quality
                  if (_extras != null &&
                      _extras!['water_quality'] != null)
                    _buildCard(
                      title: "Water Quality",
                      icon: Icons.water_drop,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (_extras!['water_quality']
                        as Map<String, dynamic>)
                            .entries
                            .map(
                              (e) => Text("${e.key}: ${e.value}",
                              style: const TextStyle(
                                  color: Colors.white70)),
                        )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}
