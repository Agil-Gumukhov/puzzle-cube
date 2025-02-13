import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_cube/animasyon.dart';
import 'package:puzzle_cube/bonusoverplay.dart';
import 'package:puzzle_cube/oyungiris.dart';
import 'package:puzzle_cube/puzzleblock.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:puzzle_cube/puzzleborad.dart';
import 'package:puzzle_cube/settingpage.dart';
import 'package:puzzle_cube/staticforms.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ana widget: PuzzleBlockGame
class PuzzleBlockGame extends StatefulWidget {
  const PuzzleBlockGame({super.key});

  @override
  State<PuzzleBlockGame> createState() => _PuzzleBlockGameState();
}

class _PuzzleBlockGameState extends State<PuzzleBlockGame>
    with TickerProviderStateMixin {
  List<BonusOverlay> bonusOverlays = [];
  int highScore = 0;
  late PuzzleBoard board;

  final random = Random();

  /// Rastgele 3 blok seç
  List<PuzzleBlock> _pick3RandomBlocks() {
    final copyList = List<PuzzleBlock>.from(allStaticForms);
    copyList.shuffle(random);
    return copyList.take(3).toList();
  }

  late List<PuzzleBlock> availableBlocks;

  // Sürükleme sırasında highlight için
  Set<Offset> highlightCells = {};
  bool highlightValid = false;

  // Patlama animasyonuna girecek hücreler
  Set<Offset> explodingCells = {};
  bool isExplodingNow = false;

  // Patlama animasyonu için AnimationController
  late AnimationController explosionController;
  late Animation<double> explosionAnimation;

  // Temizlenecek satır/sütun indekslerini saklamak için
  final List<int> _rowsToClear = [];
  final List<int> _colsToClear = [];
  bool soundOn = true;
  // Puan bilgisi
  int score = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _loadSettings();
    // Board'u 8x8 yapıyoruz
    board = PuzzleBoard(rows: 8, cols: 8);
    availableBlocks = _pick3RandomBlocks();

    // Patlama animasyonu süresi: 2 saniye
    explosionController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    explosionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: explosionController, curve: Curves.easeOut),
    );

    explosionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          int points = _rowsToClear.length * 10 + _colsToClear.length * 5;
          score += points;
          _updateHighScore(score);
          // Satır ve sütunları temizle
          board.clearFullRows(_rowsToClear);
          board.clearFullCols(_colsToClear);

          // Calculate cell size from board dimensions
          double cellSize = MediaQuery.of(context).size.width / board.cols;

          // For each cleared row, add a bonus overlay at the row's vertical center and screen horizontal center.
          for (int r in _rowsToClear) {
            double bonusX = MediaQuery.of(context).size.width / 2;
            double bonusY = (r + 0.5) * cellSize;
            bonusOverlays.add(
                BonusOverlay(position: Offset(bonusX, bonusY), text: '+10'));
          }

          // For each cleared column, add a bonus overlay at the column's horizontal center and board vertical center.
          for (int c in _colsToClear) {
            double bonusX = (c + 0.5) * cellSize;
            double bonusY = (board.rows / 2) * cellSize;
            bonusOverlays.add(
                BonusOverlay(position: Offset(bonusX, bonusY), text: '+5'));
          }

          // Clear the row/column lists after processing
          _rowsToClear.clear();
          _colsToClear.clear();
        });

        // Delay clearing explosion effect and bonus overlays so they remain visible for a short time.
        _timer = Timer(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            explodingCells.clear();
            isExplodingNow = false;
          });
          _timer = Timer(const Duration(seconds: 1), () {
            if (!mounted) return;
            setState(() {
              bonusOverlays.clear();
            });
          });
        });
      }
    });
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

  Future<void> _loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _updateHighScore(int newScore) async {
    if (newScore > highScore) {
      setState(() {
        highScore = newScore;
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', highScore);
    }
  }

  bool _isGameOver() {
    // Eğer availableBlocks boşsa veya hiçbir blok boarda yerleştirilemiyorsa, oyun biter.
    if (availableBlocks.isEmpty) return !_isAnyBlockPlaceable();

    for (PuzzleBlock block in availableBlocks) {
      for (int row = 0; row < board.rows; row++) {
        for (int col = 0; col < board.cols; col++) {
          if (board.canPlaceBlock(block, row, col)) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Eğer availableBlocks listesindeki hiçbir blok board’a yerleştirilemiyorsa, oyun biter.
  bool _isAnyBlockPlaceable() {
    if (availableBlocks.isEmpty) return false;
    for (PuzzleBlock block in availableBlocks) {
      for (int row = 0; row < board.rows; row++) {
        for (int col = 0; col < board.cols; col++) {
          if (board.canPlaceBlock(block, row, col)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _resetGame() {
    setState(() {
      board = PuzzleBoard(rows: 8, cols: 8);
      availableBlocks = _pick3RandomBlocks();
      score = 0;
    });
    Navigator.pop(context);
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF16213E), Color(0xFF0F3460)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 10,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gamepad, size: 60, color: Colors.white70),
                  SizedBox(height: 20),
                  Text('GAME OVER',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey)),
                  SizedBox(height: 15),
                  Text('Final Score',
                      style: TextStyle(fontSize: 18, color: Colors.white70)),
                  Text('$score',
                      style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey)),
                  SizedBox(height: 25),
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                    ),
                    label: Text(
                      'New Game',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE94560),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => _resetGame(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    explosionController.dispose();
    super.dispose();
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
    // Oyunun bitip bitmediğini kontrol et
    if (_isGameOver()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog();
      });
    }

    // AnimatedBuilder, explosion animasyonu sırasında UI güncellemelerini sağlar.
    return AnimatedBuilder(
      animation: explosionController,
      builder: (context, child) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(120),
            child: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PuzzleEntrancePage()),
                  );
                },
              ),
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
              toolbarHeight: 120,
              title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'BLOCK PUZZLE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            Color.fromARGB(255, 62, 219, 244),
                            Color.fromARGB(255, 33, 144, 255),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                      shadows: [
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Using trophy icon (emoji_events) as a crown substitute
                            Icon(Icons.emoji_events,
                                color: Colors.amber, size: 25),
                            const SizedBox(width: 4),
                            Text(
                              '$highScore',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 25),
                            const SizedBox(width: 4),
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              centerTitle: true,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2C3E50),
                      Color(0xFF4CA1AF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              elevation: 10,
            ),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Board ve explosion efektinin bulunduğu alan
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(children: [
                    AspectRatio(
                      aspectRatio: board.rows / board.cols,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: board.rows * board.cols,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: board.cols,
                        ),
                        itemBuilder: (context, index) {
                          final row = index ~/ board.cols;
                          final col = index % board.cols;
                          return DragTarget<PuzzleBlock>(
                            onWillAcceptWithDetails: (draggedBlock) {
                              bool canPlace = board.canPlaceBlock(
                                  draggedBlock.data, row, col);
                              setState(() {
                                highlightCells.clear();
                                highlightValid = canPlace;
                                for (int r = 0;
                                    r < draggedBlock.data.rows;
                                    r++) {
                                  for (int c = 0;
                                      c < draggedBlock.data.cols;
                                      c++) {
                                    if (draggedBlock.data.shape[r][c]) {
                                      final targetRow = row + r;
                                      final targetCol = col + c;
                                      if (targetRow >= 0 &&
                                          targetRow < board.rows &&
                                          targetCol >= 0 &&
                                          targetCol < board.cols) {
                                        highlightCells.add(
                                          Offset(targetRow.toDouble(),
                                              targetCol.toDouble()),
                                        );
                                      }
                                    }
                                  }
                                }
                              });
                              return true;
                            },
                            onLeave: (draggedBlock) {
                              setState(() {
                                highlightCells.clear();
                              });
                            },
                            onAcceptWithDetails: (draggedBlock) {
                              final success =
                                  board.placeBlock(draggedBlock.data, row, col);
                              setState(() {
                                highlightCells.clear();
                              });
                              if (success) {
                                setState(() {
                                  availableBlocks.remove(draggedBlock.data);
                                  if (availableBlocks.isEmpty) {
                                    availableBlocks = _pick3RandomBlocks();
                                  }
                                });
                                // Satır/Sütun kontrolü
                                final fullRows = board.findFullRows();
                                final fullCols = board.findFullCols();
                                if (fullRows.isNotEmpty ||
                                    fullCols.isNotEmpty) {
                                  explosionController.reset();
                                  _rowsToClear.clear();
                                  _colsToClear.clear();
                                  _rowsToClear.addAll(fullRows);
                                  _colsToClear.addAll(fullCols);
                                  explodingCells.clear();
                                  for (int r in fullRows) {
                                    for (int c = 0; c < board.cols; c++) {
                                      explodingCells.add(
                                          Offset(r.toDouble(), c.toDouble()));
                                    }
                                  }
                                  for (int c in fullCols) {
                                    for (int r = 0; r < board.rows; r++) {
                                      explodingCells.add(
                                          Offset(r.toDouble(), c.toDouble()));
                                    }
                                  }
                                  isExplodingNow = true;
                                  explosionController.forward(from: 0.0);
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Yerleştirme başarısız!')),
                                );
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              final cellColor = board.grid[row][col];
                              final cellSize =
                                  MediaQuery.of(context).size.width /
                                      board.cols;
                              bool isHighlighted = highlightCells.contains(
                                Offset(row.toDouble(), col.toDouble()),
                              );
                              bool isExploding = explodingCells.contains(
                                Offset(row.toDouble(), col.toDouble()),
                              );
                              Color displayColor = Colors.grey.withOpacity(0.3);
                              if (cellColor != null) {
                                displayColor = cellColor;
                              }
                              // Eğer patlama animasyonu devam ediyorsa, fade-out uygulayın.
                              if (isExploding && cellColor != null) {
                                double t = explosionAnimation.value;
                                double fade = 1.0 - t;
                                displayColor = cellColor.withOpacity(fade);
                              } else if (isHighlighted) {
                                displayColor = highlightValid
                                    ? Colors.green.withOpacity(0.4)
                                    : Colors.red.withOpacity(0.4);
                              }
                              return Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: displayColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    if (cellColor != null || isHighlighted)
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                  ],
                                  gradient: cellColor != null
                                      ? LinearGradient(
                                          colors: [
                                            displayColor,
                                            displayColor.withOpacity(0.7)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                ),
                                child: isExploding
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CustomPaint(
                                          painter: ExplosionPainter(
                                            animationValue:
                                                explosionAnimation.value,
                                            explodingCells: explodingCells,
                                            cellWidth: cellSize,
                                            cellHeight: cellSize,
                                          ),
                                        ),
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // Bonus overlays
                    ...bonusOverlays.map((overlay) {
                      return Positioned(
                        left: overlay
                            .position.dx, // Adjust these values as needed
                        top: overlay.position.dy,
                        child: Text(
                          overlay.text,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromRGBO(255, 29, 29, 1),
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black38,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ]),
                ),
              ),
              // Alt blok listesi
              Container(
                height: 120,
                // color: Colors.black12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.2),
                      Colors.green.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: availableBlocks.map((block) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Draggable<PuzzleBlock>(
                            data: block,
                            feedback:
                                _buildBlockWidget(block, isDragging: true),
                            childWhenDragging: Opacity(
                              opacity: 0.4,
                              child: _buildBlockWidget(block),
                            ),
                            child: _buildBlockWidget(block),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockWidget(PuzzleBlock block, {bool isDragging = false}) {
    return Transform.scale(
      scale: isDragging ? 1.1 : 1.0,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: block.shape.map((row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: row.map((filled) {
                return Container(
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: filled ? block.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: block.color.withOpacity(0.5),
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            )
                          ]
                        : [],
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
