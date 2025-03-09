import 'package:flutter/material.dart';
import 'monitor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? spfValue;
  String? skinTypeValue;
  bool isDemo = false;

  @override
  void initState() {
    super.initState();
    spfValue = null;
    skinTypeValue = null;
  }

  bool get isButtonEnabled => spfValue != null && skinTypeValue != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCE26),
        title: const Center(
          child: Text(
            'SUNSENSE',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFFFFCE26),
              ),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: Text('Demo Mode'),
              trailing: Checkbox(
                value: isDemo,
                onChanged: (bool? value) {
                  setState(() {
                    isDemo = value ?? false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: screenHeight * 0.40,
                  child: Image.asset(
                    'assets/images/image.png',
                    width: screenWidth * 0.80,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Sun Protection Factor (SPF)',
                  ),
                  items: <String>['15', '30', '50', '70'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      spfValue = newValue;
                    });
                  },
                ),
                SizedBox(height: screenHeight * 0.04),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Skin Phototype',
                  ),
                  items: <String>[
                    'Type 0 - Test',
                    'Type I - Very Fair',
                    'Type II - Fair',
                    'Type III - Medium Fair',
                    'Type IV - Medium Dark',
                    'Type V - Dark',
                    'Type VI - Very Dark'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      skinTypeValue = newValue;
                    });
                  },
                ),
                SizedBox(height: screenHeight * 0.06),
                ElevatedButton(
                  onPressed: isButtonEnabled
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MonitorScreen(
                                isDemo: isDemo,
                                spf: double.parse(spfValue!),
                                skinType: skinTypeValue!,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isButtonEnabled ? const Color(0xFF77347A) : null,
                    side: const BorderSide(
                      color: Color(0xFF77347A),
                      width: 2,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.15,
                      vertical: screenHeight * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Start Monitoring',
                    style: TextStyle(
                      color: isButtonEnabled
                          ? Colors.white
                          : const Color(0xFF77347A),
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
