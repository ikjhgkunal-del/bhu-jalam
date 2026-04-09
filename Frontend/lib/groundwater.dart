import 'dart:async';
import 'package:flutter/material.dart';
import 'services/api_services.dart';
import 'AnalyticsPage.dart';

class GroundWaterPage extends StatefulWidget {
  const GroundWaterPage({super.key});

  @override
  State<GroundWaterPage> createState() => _GroundWaterPageState();
}

class _GroundWaterPageState extends State<GroundWaterPage> {
  final String _state = "Uttar Pradesh";
  List<String> _districts = [];
  List<String> _blocks = [];

  String? _selectedDistrict;
  String? _selectedBlock;

  bool _loadingDistricts = true;
  bool _loadingBlocks = false;
  String? _errorMsg;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _fetchDistricts();
  }

  Future<void> _fetchDistricts() async {
    try {
      final districts =
      await ApiService.getDistricts().timeout(const Duration(seconds: 10));
      setState(() {
        _districts = districts;
        _loadingDistricts = false;
      });
    } catch (e) {
      setState(() {
        _districts = [];
        _loadingDistricts = false;
        _errorMsg = "❌ Could not load districts: $e";
      });
    }
  }

  Future<void> _fetchBlocks(String district) async {
    setState(() {
      _loadingBlocks = true;
      _blocks = [];
      _selectedBlock = null;
    });

    try {
      final blocks = await ApiService.getBlocks(district)
          .timeout(const Duration(seconds: 10));
      setState(() {
        _blocks = blocks;
        _loadingBlocks = false;
      });
    } catch (e) {
      setState(() {
        _loadingBlocks = false;
        _errorMsg = "❌ Could not load blocks: $e";
      });
    }
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 65,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(label, style: const TextStyle(color: Colors.white70)),
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E3C72),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          onChanged: (val) {
            if (items.isNotEmpty) {
              onChanged(val);
            }
          },
          items: items.isEmpty
              ? [
            const DropdownMenuItem(
              value: null,
              child: Text("No options available",
                  style: TextStyle(color: Colors.grey)),
            )
          ]
              : items
              .map((e) => DropdownMenuItem<String>(
            value: e,
            child: Text(
              e,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16, color: Colors.white),
            ),
          ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 30), // 🔹 Move content higher
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo + Title
                  Image.asset("assets/cgwb_logo.png", width: 100, height: 120),
                  const SizedBox(height: 10),
                  const Text(
                    "BHU-JALAM",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Bharat Hydro Underground\nJal Analytics Mapping",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Title
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "GROUNDWATER DATA",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Dropdowns
                  _buildDropdown(
                    label: "Select State",
                    value: _state,
                    items: [_state],
                    onChanged: (_) {},
                  ),
                  _buildDropdown(
                    label: "Select District",
                    value: _selectedDistrict,
                    items: _districts,
                    isLoading: _loadingDistricts,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDistrict = value);
                        _fetchBlocks(value);
                      }
                    },
                  ),
                  _buildDropdown(
                    label: "Select Block",
                    value: _selectedBlock,
                    items: _blocks,
                    isLoading: _loadingBlocks,
                    onChanged: (value) {
                      setState(() => _selectedBlock = value);
                    },
                  ),
                  const SizedBox(height: 30),

                  // Button / Success Animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _success
                        ? const Icon(Icons.check_circle,
                        key: ValueKey("success"),
                        color: Colors.greenAccent,
                        size: 60)
                        : ElevatedButton(
                      key: const ValueKey("button"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C6FF),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _selectedDistrict != null &&
                          _selectedBlock != null
                          ? () {
                        setState(() => _success = true);
                        Future.delayed(const Duration(seconds: 1),
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnalyticsPage(
                                    district: _selectedDistrict!,
                                    block: _selectedBlock!,
                                  ),
                                ),
                              ).then((_) {
                                setState(() => _success = false);
                              });
                            });
                      }
                          : null,
                      child: const Text("Get Data",
                          style: TextStyle(
                              fontSize: 18, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
