import 'package:flutter/material.dart';
import 'groundwater.dart';
import 'comparison.dart';
import 'info.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedCard(Widget card, int index) {
    final delay = index * 200;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double value = (_controller.value * 1000).clamp(0, 1200);
        if (value < delay) return const SizedBox();
        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(position: _slideAnim, child: child),
        );
      },
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], // same as splash
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔹 Logo + Title
                Column(
                  children: [
                    Image.asset("assets/cgwb_logo.png",
                        width: 100, height: 120),
                    const SizedBox(height: 10),
                    const Text(
                      "BHU-JALAM",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        color: Colors.white,
                        letterSpacing: 1.5,
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
                  ],
                ),

                const SizedBox(height: 18),

                // 🔹 Dashboard Header
                Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "DASHBOARD",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 🔹 Main Content (scrollable if small screen)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildAnimatedCard(
                          NavCard(
                            icon: Icons.water_drop,
                            title: "Ground Water Data",
                            subtitle: "Explore levels, rainfall & more",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const GroundWaterPage()),
                            ),
                            height: 105,
                          ),
                          0,
                        ),
                        const SizedBox(height: 16), // ✅ uniform spacing
                        _buildAnimatedCard(
                          NavCard(
                            icon: Icons.compare_arrows,
                            title: "Comparison Dashboard",
                            subtitle: "Compare districts & blocks",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const ComparisonSelectionPage()),
                            ),
                            height: 105,
                          ),
                          1,
                        ),
                        const SizedBox(height: 16), // ✅ uniform spacing
                        _buildAnimatedCard(
                          NavCard(
                            icon: Icons.info_outline,
                            title: "General Information",
                            subtitle: "Learn more about the project",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const InfoPage()),
                            ),
                            height: 105,
                          ),
                          2,
                        ),
                        const SizedBox(height: 24), // ✅ gap before stats row

                        // 🔹 Stats Cards (Animated Counter)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            AnimatedStatCard(label: "Districts", value: 32),
                            AnimatedStatCard(label: "Blocks", value: 335),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final double height;

  const NavCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.height,
  });

  @override
  State<NavCard> createState() => _NavCardState();
}

class _NavCardState extends State<NavCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 100), widget.onTap);
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(4, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                child: Icon(widget.icon, size: 28, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 6),
                    Text(widget.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        )),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedStatCard extends StatefulWidget {
  final String label;
  final int value;

  const AnimatedStatCard({super.key, required this.label, required this.value});

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _counterAnim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _counterAnim = IntTween(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _counterAnim,
            builder: (context, child) => Text(
              _counterAnim.value.toString(),
              style: const TextStyle(
                fontFamily: "Montserrat",
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(widget.label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              )),
        ],
      ),
    );
  }
}
