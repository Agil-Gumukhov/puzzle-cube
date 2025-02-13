import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_cube/settingpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_cube/levels/levelScreen.dart';
import 'package:puzzle_cube/oyungiris.dart'; // Giriş sayfası

class Levels extends StatefulWidget {
  const Levels({super.key});

  @override
  _LevelsState createState() => _LevelsState();
}

class _LevelsState extends State<Levels> {
  int currentUnlockedLevel = 1;
  bool soundOn = true;
  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadSettings();
    // resetProgress(); // İlerlemeyi sıfırlamak için
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      soundOn = prefs.getBool('soundOn') ?? true;
    });
  }

  // İlerleme bilgisini SharedPreferences'dan yükle
  Future<void> _loadProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUnlockedLevel = prefs.getInt('currentUnlockedLevel') ?? 1;
    });
  }

  // playSound fonksiyonunu tanımlıyoruz
  Future<void> playSound(String assetName) async {
    if (!soundOn) return; // Eğer ses kapalıysa hiçbir şey yapma
    AudioPlayer player = AudioPlayer();
    await player.play(AssetSource(assetName));
  }

  Future<void> resetProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // İlerleme verisini sıfırlamak için:
    await prefs.setInt('currentUnlockedLevel', 1);
    // Eğer diğer veriler de varsa hepsini temizlemek isterseniz:
    // await prefs.clear();
  }

  // İlerleme bilgisini güncelle ve SharedPreferences'a kaydet
  Future<void> _updateProgress(int newLevel) async {
    // Sadece yeni seviye, mevcut ilerlemeden yüksekse güncelleme yap
    if (newLevel > currentUnlockedLevel) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentUnlockedLevel', newLevel);
      //  widget artık ağaçta değilse, geri kalan kodu çalıştırmadan fonksiyonu sonlandırır.
      if (!mounted) return;
      setState(() {
        currentUnlockedLevel = newLevel;
      });
    }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Levels',
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedSettingsButton(
              onPressed: () async {
                _navigateToSettings();
                AudioPlayer player = AudioPlayer();
                await playSound('sounds/toggle_on.mp3');
              },
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const PuzzleEntrancePage()),
            );
          },
        ),
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
        child: Padding(
          padding:
              const EdgeInsets.only(top: 40, left: 12, right: 12, bottom: 12),
          child: GridView.builder(
            itemCount: 50,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // 5 sütun
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final level = index + 1;
              // Seviye 1'den 100'e kadar zorluk (renk geçişi)
              final difficulty = (level - 1) / 50;
              final tileColor =
                  Color.lerp(Colors.lightGreen, Colors.deepOrange, difficulty)!;
              // Seviye kilit durumu:
              final bool isUnlocked = level <= currentUnlockedLevel;

              return InkWell(
                onTap: () async {
                  await playSound('sounds/toggle_on.mp3');
                  if (isUnlocked) {
                    final result = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LevelScreen(level: level)),
                    );
                    if (result != null) {
                      await _updateProgress(result);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("This level is locked.")),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tileColor.withOpacity(0.8),
                        tileColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isUnlocked
                        ? Text(
                            '$level',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          )
                        : const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 30,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
