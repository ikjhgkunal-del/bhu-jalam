import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'services/api_services.dart';
import 'ComparisonPage.dart';

class ComparisonSelectionPage extends StatefulWidget {
  const ComparisonSelectionPage({super.key});

  @override
  State<ComparisonSelectionPage> createState() =>
      _ComparisonSelectionPageState();
}

class _ComparisonSelectionPageState extends State<ComparisonSelectionPage>
    with TickerProviderStateMixin {
  List<String> _districts = [];
  List<String> _blocks = [];
  String? _selectedDistrict;
  String? _selectedBlock;

  final List<Map<String, String>> _selectedPairs = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  bool _loadingDistricts = true;
  bool _loadingBlocks = false;

  late AnimationController _btnController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _fetchDistricts();

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnim = CurvedAnimation(parent: _btnController, curve: Curves.easeOut);
  }

  Future<void> _fetchDistricts() async {
    try {
      final districts = await ApiService.getDistricts();
      setState(() {
        _districts = districts;
        _loadingDistricts = false;
      });
    } catch (e) {
      debugPrint("❌ Failed to fetch districts: $e");
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _fetchBlocks(String district) async {
    setState(() {
      _loadingBlocks = true;
      _blocks = [];
      _selectedBlock = null;
    });

    try {
      final blocks = await ApiService.getBlocks(district);
      setState(() {
        _blocks = blocks;
        _loadingBlocks = false;
      });
    } catch (e) {
      debugPrint("❌ Failed to fetch blocks: $e");
      setState(() => _loadingBlocks = false);
    }
  }

  void _addPair() {
    if (_selectedDistrict != null && _selectedBlock != null) {
      final newPair = {
        "district": _selectedDistrict!,
        "block": _selectedBlock!,
      };

      if (!_selectedPairs.contains(newPair)) {
        setState(() {
          _selectedPairs.add(newPair);
        });
        _listKey.currentState?.insertItem(_selectedPairs.length - 1);
      }
    }
  }

  void _removePair(int index) {
    final removedItem = _selectedPairs[index];
    _listKey.currentState?.removeItem(
      index,
          (context, animation) =>
          _buildAnimatedPair(removedItem, index, animation),
      duration: const Duration(milliseconds: 300),
    );
    setState(() {
      _selectedPairs.removeAt(index);
    });
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1E3F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF0B1E3F),
          hint: Text(label, style: const TextStyle(color: Colors.white70)),
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          isExpanded: true,
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem<String>(
            value: e,
            child: Text(
              e,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAnimatedPair(
      Map<String, String> pair, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1E3F).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "${pair['district']} - ${pair['block']}",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _removePair(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _btnController.dispose();
    _shimmerController.dispose();
    super.dispose();
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      Image.asset("assets/cgwb_logo.png",
                          width: 110, height: 150),
                      const SizedBox(height: 10),
                      const Text(
                        "BHU-JALAM",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Bharat Hydro Underground\nJal Analytics Mapping",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AutoSizeText(
                          "COMPARISON DASHBOARD",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 30),

                      _buildDropdown(
                        label: "Select District",
                        value: _selectedDistrict,
                        items: _districts,
                        isLoading: _loadingDistricts,
                        onChanged: (val) {
                          setState(() => _selectedDistrict = val);
                          if (val != null) _fetchBlocks(val);
                        },
                      ),

                      _buildDropdown(
                        label: "Select Block",
                        value: _selectedBlock,
                        items: _blocks,
                        isLoading: _loadingBlocks,
                        onChanged: (val) => setState(() => _selectedBlock = val),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: _addPair,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Location"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (_selectedPairs.isNotEmpty)
                        AnimatedList(
                          key: _listKey,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          initialItemCount: _selectedPairs.length,
                          itemBuilder: (context, index, animation) {
                            final pair = _selectedPairs[index];
                            return _buildAnimatedPair(pair, index, animation);
                          },
                        ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // 🔹 Compare Button pinned at bottom
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: GestureDetector(
                  onTapDown: (_) => _btnController.reverse(),
                  onTapUp: (_) {
                    _btnController.forward();
                    if (_selectedPairs.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ComparisonPage(selectedPairs: _selectedPairs),
                        ),
                      );
                    }
                  },
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        final shimmerValue =
                            0.5 + (0.5 * _shimmerController.value);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 40),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent.withOpacity(shimmerValue),
                                Colors.lightBlueAccent.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(2, 4),
                              )
                            ],
                          ),
                          child: const Text(
                            "COMPARE",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
