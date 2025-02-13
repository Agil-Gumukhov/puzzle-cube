import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_cube/privacypolicyscreen.dart';
import 'package:puzzle_cube/termsofservices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool soundOn = true;
  bool vibrationOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Ses dosyalarını önceden hafızaya yüklüyoruz.
  }

  // Ayarları SharedPreferences'dan yükleme
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      soundOn = prefs.getBool('soundOn') ?? true;
      vibrationOn = prefs.getBool('vibrationOn') ?? true;
    });
  }

  // Ayarları SharedPreferences'a kaydetme
  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundOn', soundOn);
    await prefs.setBool('vibrationOn', vibrationOn);
  }

  // playSound fonksiyonunu AudioCache üzerinden tanımlıyoruz
  Future<void> playSound(String assetName) async {
    if (!soundOn) return;
    AudioPlayer player = AudioPlayer();
    await player.play(AssetSource(assetName));
  }

  int _currentRating = 0;

  void _submitRating() {
    // Burada rating değerini backend'e gönderebilir, SharedPreferences ile kaydedebilir ya da sadece teşekkür mesajı gösterebilirsiniz.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Thank you for rating us $_currentRating stars!")),
    );
    // İsteğe bağlı olarak, kullanıcıyı önceki sayfaya yönlendirebilirsiniz.
    Navigator.of(context).pop();
  }

  void _rateUs() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Dialog içerisinde kullanılacak yerel rating değişkeni
        int dialogRating = _currentRating;
        return StatefulBuilder(
          builder: (BuildContext context,
              void Function(void Function()) setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16213E), Color(0xFF0F3460)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      spreadRadius: 5,
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "How many stars would you give Puzzle Cube?",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          IconData iconData = index < dialogRating
                              ? Icons.star
                              : Icons.star_border;
                          return IconButton(
                            icon: Icon(iconData, color: Colors.amber, size: 40),
                            onPressed: () {
                              setStateDialog(() {
                                dialogRating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Güncel rating'i ana state'e aktarabilirsiniz.
                          setState(() {
                            _currentRating = dialogRating;
                          });
                          _submitRating();
                        },
                        child: const Text("Submit"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TermsOfServiceScreen(),
      ),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivacyPolicyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              spreadRadius: 5,
              blurRadius: 10,
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık ve kapatma butonunun bulunduğu satır
              Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Menu",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () async {
                      await playSound('sounds/toggle_on.mp3');
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 1.5, color: Colors.white38),
              const SizedBox(height: 10),
              // Sound toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Sound",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: soundOn,
                    activeColor: Colors.amber,
                    onChanged: (value) async {
                      setState(() {
                        soundOn = value;
                      });
                      await _saveSettings();
                      if (value) {
                        await playSound('sounds/toggle_on.mp3');
                      } else {
                        await playSound('sounds/toggle_on.mp3');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(thickness: 1.5, color: Colors.white38),
              const SizedBox(height: 10),
              // Vibration toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Vibration",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: vibrationOn,
                    activeColor: Colors.amber,
                    onChanged: (value) async {
                      setState(() {
                        vibrationOn = value;
                      });
                      await _saveSettings();
                      if (await Vibration.hasVibrator() ?? false) {
                        Vibration.vibrate(duration: 100);
                      }
                      if (value) {
                        await playSound('sounds/toggle_on.mp3');
                      } else {
                        await playSound('sounds/toggle_on.mp3');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(thickness: 1.5, color: Colors.white38),
              const SizedBox(height: 10),
              // Diğer menü seçenekleri
              _buildMenuOption(
                icon: Icons.star,
                label: "Rate Us",
                onTap: () async {
                  _rateUs();
                  // Rate Us action
                  await playSound('sounds/toggle_on.mp3');
                },
              ),
              _buildMenuOption(
                icon: Icons.description,
                label: "Terms of Service",
                onTap: () async {
                  _openTerms();
                  // Terms of Service action
                  await playSound('sounds/toggle_on.mp3');
                },
              ),
              _buildMenuOption(
                icon: Icons.privacy_tip,
                label: "Privacy Policy",
                onTap: () async {
                  _openPrivacyPolicy();
                  // Privacy Policy action
                  await playSound('sounds/toggle_on.mp3');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: Colors.amber,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 16,
    );
  }
}
