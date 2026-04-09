import 'package:flutter/material.dart';
import 'services/api_services.dart';

class ComparisonPage extends StatefulWidget {
  final List<Map<String, String>> selectedPairs;

  const ComparisonPage({super.key, required this.selectedPairs});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  Map<String, Map<String, dynamic>> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    Map<String, Map<String, dynamic>> results = {};
    for (var pair in widget.selectedPairs) {
      final district = pair["district"]!;
      final block = pair["block"]!;
      try {
        final extras = await ApiService.getExtras(district, block);
        results["$district - $block"] = extras;
      } catch (e) {
        results["$district - $block"] = {"error": e.toString()};
      }
    }
    setState(() {
      _data = results;
      _loading = false;
    });
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "--",
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, Map<String, dynamic> extras) {
    final hasError = extras.containsKey("error");

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08), // glass effect
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: hasError
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.redAccent),
          ),
          const SizedBox(height: 6),
          Text(
            extras["error"] ?? "Error fetching data",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      )
          : Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // remove divider lines
        ),
        child: ExpansionTile(
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              if (extras["final_score_pct"] != null)
                Chip(
                  backgroundColor: Colors.blue, // solid visible bg
                  label: Text(
                    "${extras["final_score_pct"]}%",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("📅 Last Date", extras["last_date"]),
                  _buildInfoRow("🪨 Aquifer", extras["aquifer_type"]),
                  _buildInfoRow("🌧 Rainfall (mm)", extras["rainfall_mm"]),
                  _buildInfoRow(
                      "📉 Water Level (m)", extras["last_water_level"]),
                  _buildInfoRow("📊 Score", extras["final_score_pct"]),
                  _buildInfoRow(
                      "📈 Daily Fluctuation", extras["daily_fluctuation"]),
                  _buildInfoRow("🌱 Yield (m³)", extras["yield"]),
                  const SizedBox(height: 12),
                  const Text(
                    "💧 Water Quality",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  if (extras["water_quality"] != null &&
                      extras["water_quality"] is Map<String, dynamic>)
                    ...((extras["water_quality"]
                    as Map<String, dynamic>)
                        .entries
                        .map((e) => _buildInfoRow(e.key, e.value))
                        .toList())
                  else
                    const Text("No water quality data",
                        style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
              child: CircularProgressIndicator(color: Colors.white))
              : _data.isEmpty
              ? const Center(
            child: Text(
              "No data found",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Image.asset("assets/cgwb_logo.png",
                    width: 100, height: 140),
                const SizedBox(height: 10),
                const Text(
                  "BHU-JALAM",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Comparison Dashboard",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  children: _data.entries
                      .map((entry) =>
                      _buildCard(entry.key, entry.value))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
