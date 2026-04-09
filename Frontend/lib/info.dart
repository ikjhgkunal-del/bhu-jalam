import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], // pro gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // 🔹 Logo + Title
                Image.asset("assets/cgwb_logo.png", width: 100, height: 140),
                const SizedBox(height: 10),
                const Text(
                  "BHU-JALAM",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Central Ground Water Board",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 25),

                // 🔹 Section Header (always single line)
                Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AutoSizeText(
                    "GENERAL INFORMATION",
                    style: const TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    maxLines: 1,
                    minFontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 Info Cards
                _buildInfoCard(
                  title: "📊 Groundwater Sustainability Scoring System",
                  content: '''
The groundwater sustainability **score** is calculated by combining multiple weighted factors that reflect both **quantity** and **quality** of groundwater.

---

### 🔹 Factors considered:
• **Water Level Trend (30%)**  
   Indicates whether water levels are rising, stable, or declining.

• **Rainfall Contribution (20%)**  
   Recharge potential from rainfall.

• **Specific Yield (15%)**  
   The aquifer’s capacity to release groundwater.

• **Water Quality (20%)**  
   pH, EC, Chlorides, Fluoride, and Hardness — compared against standards.

• **Aquifer Type (15%)**  
   Alluvial aquifers recharge faster than hard rock aquifers.

---

### 🔹 Interpretation:
✅ **> 75% → Sustainable**  
⚠️ **50–75% → Moderate**  
❌ **< 50% → Critical**
''',
                ),

                _buildInfoCard(
                  title: "🌍 About Aquifers",
                  content: '''
An **aquifer** is an underground layer of permeable rock, sediment, or soil that stores and transmits groundwater. Aquifers are the primary source of water for drinking, irrigation, and industry.

---

### 🔹 Types of Aquifers:
1. **Unconfined Aquifers**  
   - Water table is open to direct recharge from rainfall and surface water.  
   - Found close to the ground surface.  

2. **Confined Aquifers**  
   - Sandwiched between impermeable layers (clay or rock).  
   - Usually under pressure and can produce artesian wells.  

3. **Alluvial Aquifers**  
   - Made of sand, silt, and gravel deposited by rivers.  
   - High storage and recharge potential.  

4. **Hard Rock Aquifers**  
   - Found in regions with granite, basalt, or crystalline rocks.  
   - Low storage, depend on fractures for water movement.  

---

### 🔹 Importance of Aquifers:
• Supply **~85% of rural drinking water** in India.  
• Support **over 60% of irrigation needs**.  
• Provide a natural **buffer against droughts**.  
• Sustain rivers, wetlands, and ecosystems.  
''',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08), // glassmorphism
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
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          trailing: const Icon(Icons.expand_more, color: Colors.white),
          title: AutoSizeText(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            minFontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                content,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
