import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_cube/PuzzleAnaSayfa.dart';
import 'package:puzzle_cube/levels/levelsMain.dart';
import 'package:puzzle_cube/settingpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PuzzleEntrancePage: Uygulama açıldığında gösterilen giriş ekranı.
class PuzzleEntrancePage extends StatefulWidget {
  const PuzzleEntrancePage({super.key});
  @override
  State<PuzzleEntrancePage> createState() => _PuzzleEntrancePageState();
}

class _PuzzleEntrancePageState extends State<PuzzleEntrancePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool soundOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // 2 saniyelik fade animasyonu oluşturuyoruz.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      soundOn = prefs.getBool('soundOn') ?? true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PuzzleBlockGame()),
    );
  }

  void _navigateToLevel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Levels()),
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

  // playSound fonksiyonunu tanımlıyoruz
  Future<void> playSound(String assetName) async {
    if (!soundOn) return; // Eğer ses kapalıysa hiçbir şey yapma
    AudioPlayer player = AudioPlayer();
    await player.play(AssetSource(assetName));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // AppBar'ın arka planı sayfa ile uyumlu olsun.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Sağ üstte modern görünümlü ayarlar butonu
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: AnimatedSettingsButton(
              onPressed: () async {
                _navigateToSettings();
                await playSound('sounds/toggle_on.mp3');
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF4CA1AF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Puzzle Cube",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Challenge your mind",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      _navigateToGame();
                      await playSound('sounds/toggle_on.mp3');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                    ),
                    child: const Text(
                      "Start Puzzle",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () async {
                      _navigateToLevel();
                      await playSound('sounds/toggle_on.mp3');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Levels",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AnimatedSettingsButton: Butona basıldığında scale (küçülme) animasyonu gösteren ayarlar butonu.
class AnimatedSettingsButton extends StatefulWidget {
  final VoidCallback onPressed;
  const AnimatedSettingsButton({super.key, required this.onPressed});

  @override
  State<AnimatedSettingsButton> createState() => _AnimatedSettingsButtonState();
}

class _AnimatedSettingsButtonState extends State<AnimatedSettingsButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.9;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.settings,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
