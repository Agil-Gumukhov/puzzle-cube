import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_cube/animasyon.dart';
import 'package:puzzle_cube/bonusoverplay.dart';
import 'package:puzzle_cube/levels/levelScreen.dart';
import 'package:puzzle_cube/puzzleblock.dart';
import 'package:puzzle_cube/puzzleborad.dart';
import 'package:puzzle_cube/staticforms.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Boardview extends StatefulWidget {
  final int score;
  final ValueChanged<int> onScoreChanged;
  final int level;
  final int targetScore;
  const Boardview({
    super.key,
    required this.score,
    required this.onScoreChanged,
    required this.level,
    required this.targetScore,
  });

  @override
  State<Boardview> createState() => _BoardviewState();
}

class _BoardviewState extends State<Boardview> with TickerProviderStateMixin {
  List<BonusOverlay> bonusOverlays = [];
  late PuzzleBoard board;
  final random = Random();
  late List<PuzzleBlock> availableBlocks;
  Set<Offset> highlightCells = {};
  bool highlightValid = false;
  Set<Offset> explodingCells = {};
  bool isExplodingNow = false;

  late AnimationController explosionController;
  late Animation<double> explosionAnimation;

  final List<int> _rowsToClear = [];
  final List<int> _colsToClear = [];
  int localScore = 0; // Parent'tan gelen skor ile başlatılıyor

  bool _isResetting = false;
  bool soundOn = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    localScore = widget.score;
    _loadSettings();
    // Board'u 8x8 yapıyoruz.
    board = PuzzleBoard(rows: 8, cols: 8);

    // // Engel eklenmesi: Seviye numarasına göre engel sayısı belirleniyor.
    // int maxObstacles = 20;
    // int obstaclesToAdd = ((widget.level - 1) / 50 * maxObstacles).round();
    // board.addObstacles(obstaclesToAdd);

// Seviye numarasını seed olarak kullanarak sabit bir Random oluşturuyoruz.
    int maxObstacles = 20;
    Random seededRandom = Random(widget.level);
    int obstaclesToAdd = ((widget.level - 1) / 99 * maxObstacles).round();
    board.addObstacles(obstaclesToAdd, random: seededRandom);

    availableBlocks = _pick3RandomBlocks();

    explosionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    explosionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: explosionController, curve: Curves.easeOut),
    );

    // _explosionListener metodunu ekliyoruz.
    explosionController.addStatusListener(_explosionListener);
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      soundOn = prefs.getBool('soundOn') ?? true;
    });
  }

  // playSound fonksiyonunu tanımlıyoruz
  Future<void> playSound(String assetName) async {
    if (!soundOn) return; // Eğer ses kapalıysa hiçbir şey yapma
    AudioPlayer player = AudioPlayer();
    await player.play(AssetSource(assetName));
  }

  void _explosionListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (!mounted) return;

      // Build sırasında alacağınız değeri doğrudan burada kullanabilirsiniz.
      final screenWidth = MediaQuery.of(context).size.width;
      double cellSize = screenWidth / board.cols;

      setState(() {
        int points = _rowsToClear.length * 10 + _colsToClear.length * 5;
        localScore += points;
        widget.onScoreChanged(localScore);

        board.clearFullRows(_rowsToClear);
        board.clearFullCols(_colsToClear);

        // Bonus overlay ekleme
        for (int r in _rowsToClear) {
          bonusOverlays.add(
            BonusOverlay(
              position: Offset(screenWidth / 2, (r + 0.5) * cellSize),
              text: '+10',
            ),
          );
        }
        for (int c in _colsToClear) {
          bonusOverlays.add(
            BonusOverlay(
              position:
                  Offset((c + 0.5) * cellSize, (board.rows / 2) * cellSize),
              text: '+5',
            ),
          );
        }

        _rowsToClear.clear();
        _colsToClear.clear();
      });


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
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Listener'ı kaldırıyoruz ve controller'ı dispose ediyoruz.
    explosionController.removeStatusListener(_explosionListener);
    explosionController.dispose();
    super.dispose();
  }

  List<PuzzleBlock> _pick3RandomBlocks() {
    final copyList = List<PuzzleBlock>.from(allStaticForms);
    copyList.shuffle(random);
    return copyList.take(3).toList();
  }

  bool _isGameOver() {
    if (availableBlocks.isEmpty) return !_isAnyBlockPlaceable();
    for (PuzzleBlock block in availableBlocks) {
      for (int row = 0; row < board.rows; row++) {
        for (int col = 0; col < board.cols; col++) {
          if (board.canPlaceBlock(block, row, col)) return false;
        }
      }
    }
    return true;
  }

  bool _isAnyBlockPlaceable() {
    if (availableBlocks.isEmpty) return false;
    for (PuzzleBlock block in availableBlocks) {
      for (int row = 0; row < board.rows; row++) {
        for (int col = 0; col < board.cols; col++) {
          if (board.canPlaceBlock(block, row, col)) return true;
        }
      }
    }
    return false;
  }

  void _resetGame() {
    if (_isResetting) return;
    _isResetting = true;

    setState(() {
      board = PuzzleBoard(rows: 8, cols: 8);
      int maxObstacles = 20;
      int obstaclesToAdd = ((widget.level - 1) / 99 * maxObstacles).round();
      board.addObstacles(obstaclesToAdd);

      availableBlocks = _pick3RandomBlocks();

      localScore = 0;
      bonusOverlays.clear();
      highlightCells.clear();
      explodingCells.clear();

      widget.onScoreChanged(localScore);
      explosionController.reset();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _isResetting = false;
    });

    Navigator.of(context, rootNavigator: true).pop();
  }

  // Levels sayfasında (örneğin Levels.dart)
  void _openLevel(int level) async {
    final nextLevel = await Navigator.push<int>(
      context,
      MaterialPageRoute(
          builder: (context) => LevelScreen(
                level: level,
              )),
    );
    if (nextLevel != null) {
      // Eğer LevelScreen, widget.level + 1 döndürdüyse yeni seviye açılıyor.
      _openLevel(nextLevel);
    }
  }

  Future<void> _showNextLevelDialog() async {
    final nextLevel = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
              boxShadow: [
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
                  const Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'LEVEL PASSED!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Target Score Achieved',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Score: $localScore',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward, size: 24),
                    label: const Text(
                      'Next Level',
                      style: TextStyle(fontSize: 22),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94560),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      await playSound('sounds/toggle_on.mp3');
                      Navigator.of(context).pop(widget.level + 1);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (nextLevel != null) {
      // LevelScreen'den çıkıp sonucu geri Levels sayfasına gönderiyoruz.
      Navigator.pop(context, nextLevel);
    }
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
              gradient: const LinearGradient(
                colors: [Color(0xFF16213E), Color(0xFF0F3460)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
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
                  const Icon(
                    Icons.gamepad,
                    size: 80,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'GAME OVER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Final Score',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$localScore',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 24),
                    label: const Text(
                      'New Game',
                      style: TextStyle(fontSize: 22),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94560),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      _resetGame();

                      await playSound('sounds/toggle_on.mp3');
                    },
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
  Widget build(BuildContext context) {
    // Eğer skor hedefe ulaştıysa dialogu hemen gösterelim:
    if (!_isResetting && localScore >= widget.targetScore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNextLevelDialog();
      });
    }
    // Eğer oyun bitmişse ancak explosion animasyonu çalışmıyorsa game over dialogunu gösterelim
    else if (!_isResetting &&
        !explosionController.isAnimating && // animasyon devam ediyorsa bekle
        _isGameOver()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog();
      });
    }

    return AnimatedBuilder(
      animation: explosionController,
      builder: (context, child) {
        return Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: board.rows / board.cols,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: board.rows * board.cols,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: board.cols,
                          ),
                          itemBuilder: (context, index) {
                            final row = index ~/ board.cols;
                            final col = index % board.cols;

                            // Engel kontrolü: Eğer bu hücre bir engelse, özel Container ile göster.
                            if (board.isCellObstacle(row, col)) {
                              return Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }

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
                                          highlightCells.add(Offset(
                                              targetRow.toDouble(),
                                              targetCol.toDouble()));
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
                                final success = board.placeBlock(
                                    draggedBlock.data, row, col);
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
                                    explosionController.forward(from: 0.0);
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Yerleştirme başarısız!')),
                                  );
                                }
                              },
                              builder: (context, candidateData, rejectedData) {
                                final cellColor = board.grid[row][col];
                                final cellSize =
                                    MediaQuery.of(context).size.width /
                                        board.cols;
                                bool isHighlighted = highlightCells.contains(
                                    Offset(row.toDouble(), col.toDouble()));
                                bool isExploding = explodingCells.contains(
                                    Offset(row.toDouble(), col.toDouble()));
                                Color displayColor =
                                    Colors.grey.withOpacity(0.3);
                                if (cellColor != null) {
                                  displayColor = cellColor;
                                }
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
                                          offset: const Offset(0, 2),
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
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                      ...bonusOverlays.map((overlay) => Positioned(
                            left: overlay.position.dx,
                            top: overlay.position.dy,
                            child: Text(
                              overlay.text,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(255, 29, 29, 1),
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black38,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.2),
                      Colors.green.withOpacity(0.2)
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: block.shape
              .map((row) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: row
                        .map((filled) => Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color:
                                    filled ? block.color : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: filled
                                    ? [
                                        BoxShadow(
                                          color: block.color.withOpacity(0.5),
                                          offset: const Offset(2, 2),
                                          blurRadius: 4,
                                        )
                                      ]
                                    : [],
                              ),
                            ))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
