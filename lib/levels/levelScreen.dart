import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_cube/levels/boardView.dart';
import 'package:puzzle_cube/oyungiris.dart';
import 'package:puzzle_cube/settingpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelScreen extends StatefulWidget {
  final int level;
  const LevelScreen({super.key, required this.level});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  int currentScore = 0;
  late int targetScore; // Target skor burada tanımlanacak
  bool soundOn = true;
  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Örneğin, seviye 1 için target skor 10, seviye 2 için 20, seviye 3 için 30 şeklinde hesaplanıyor.
    targetScore = 10 + (widget.level - 1) * 5;
  }

  // playSound fonksiyonunu tanımlıyoruz
  Future<void> playSound(String assetName) async {
    if (!soundOn) return; // Eğer ses kapalıysa hiçbir şey yapma
    AudioPlayer player = AudioPlayer();
    await player.play(AssetSource(assetName));
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      soundOn = prefs.getBool('soundOn') ?? true;
    });
  }

  Widget _buildInfoTile(IconData iconData, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: Colors.amber, size: 25),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    showDialog(
      context: context,
      barrierColor: Colors.black
          .withOpacity(0.75), // Arka plan rengini değiştirebilirsiniz.
      builder: (context) => const SettingsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use PreferredSize to customize the AppBar height
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 120,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Level ${widget.level}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [
                        const Color.fromARGB(255, 62, 219, 244),
                        const Color.fromARGB(255, 33, 144, 255),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  shadows: const [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInfoTile(Icons.emoji_events, '$targetScore'),
                  const SizedBox(width: 12),
                  _buildInfoTile(Icons.star, '$currentScore'),
                ],
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: ()  {
           
              Navigator.pop(context, widget.level);
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: AnimatedSettingsButton(
                onPressed: () async {
                   await playSound('sounds/toggle_on.mp3');
                  _navigateToSettings();
                },
              ),
            ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2C3E50),
                  const Color(0xFF4CA1AF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),

      // Boardview'e mevcut skor ve seviye bilgisini gönderiyoruz.
      body: Boardview(
        level: widget.level,
        score: currentScore,
        onScoreChanged: (int newScore) {
          setState(() {
            currentScore = newScore;
          });
        },
        targetScore: targetScore,
      ),
    );
  }
}
