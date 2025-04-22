import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _timer;
  int _selectedNumber = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      try {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        if (!gameProvider.isGameOver) {
          gameProvider.updateTime(timer.tick);
        }
      } catch (e) {
        debugPrint('Error updating time: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          Consumer<GameProvider>(
            builder: (context, gameProvider, child) => IconButton(
              icon: Icon(
                gameProvider.isNotesMode ? Icons.edit : Icons.edit_outlined,
                color: gameProvider.isNotesMode ? Colors.blue : null,
              ),
              onPressed: () {
                gameProvider.toggleNotesMode();
              },
              tooltip: 'Notes Mode',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            if (gameProvider.isGameComplete) {
              _timer?.cancel();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (gameProvider.isGameOver) {
                  _showGameOverDialog(context);
                } else {
                  _showCompletionDialog(context, gameProvider.timeElapsed);
                }
              });
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Difficulty: ${gameProvider.difficulty}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Time: ${gameProvider.timeElapsed ~/ 60}:${(gameProvider.timeElapsed % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      _buildErrorCounter(gameProvider.errorCount),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildBoard(gameProvider),
                  ),
                ),
                _buildNumberPad(context, gameProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorCounter(int errorCount) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Text(
          '$errorCount/3',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  void _showGameOverDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: const Text('You made 3 errors. Better luck next time!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBoard(GameProvider gameProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
              childAspectRatio: 1.0,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              final row = index ~/ 9;
              final col = index % 9;
              final cellValue = gameProvider.board[row][col];
              final isFixed = gameProvider.fixedCells[row][col];
              final notes = gameProvider.notes[row][col];
              final isValid = cellValue == 0 || gameProvider.isValidMove(row, col, cellValue);

              return GestureDetector(
                onTap: () {
                  if (!isFixed && !gameProvider.isGameOver) {
                    if (_selectedNumber == 0) {
                      // Clear the cell and its notes
                      gameProvider.makeMove(row, col, 0);
                      gameProvider.clearNotes(row, col);
                    } else {
                      gameProvider.makeMove(row, col, _selectedNumber);
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: (col + 1) % 3 == 0 ? Colors.black : Colors.grey,
                        width: (col + 1) % 3 == 0 ? 2.0 : 1.0,
                      ),
                      bottom: BorderSide(
                        color: (row + 1) % 3 == 0 ? Colors.black : Colors.grey,
                        width: (row + 1) % 3 == 0 ? 2.0 : 1.0,
                      ),
                    ),
                    color: isFixed ? Colors.grey[200] : null,
                  ),
                  child: cellValue != 0
                      ? Center(
                          child: Text(
                            cellValue.toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isFixed 
                                ? Colors.black 
                                : (isValid ? Colors.blue : Colors.red),
                            ),
                          ),
                        )
                      : GridView.count(
                          crossAxisCount: 3,
                          children: List.generate(9, (index) {
                            return Center(
                              child: Text(
                                notes[index] ? (index + 1).toString() : '',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad(BuildContext context, GameProvider gameProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1.0,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            if (index == 9) {
              return _buildNumberButton(0, 'Clear');
            }
            return _buildNumberButton(index + 1, (index + 1).toString());
          },
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number, String label) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) => ElevatedButton(
        onPressed: () {
          if (gameProvider.isGameOver) return;
          
          setState(() {
            _selectedNumber = number;
          });
          
          // For clear button (number 0)
          if (number == 0) {
            // Find the selected cell
            final selectedCell = context.findRenderObject() as RenderBox?;
            if (selectedCell != null) {
              final position = selectedCell.localToGlobal(Offset.zero);
              final size = selectedCell.size;
              
              // Find the cell that was tapped
              final cell = context.findRenderObject() as RenderBox?;
              if (cell != null) {
                final cellPosition = cell.localToGlobal(Offset.zero);
                final cellSize = cell.size;
                
                // Calculate row and col based on position
                final row = ((cellPosition.dy - position.dy) / cellSize.height).round();
                final col = ((cellPosition.dx - position.dx) / cellSize.width).round();
                
                if (row >= 0 && row < 9 && col >= 0 && col < 9) {
                  // Clear the cell
                  gameProvider.makeMove(row, col, 0);
                  // Clear any notes
                  gameProvider.clearNotes(row, col);
                }
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedNumber == number ? Colors.blue : null,
          foregroundColor: _selectedNumber == number ? Colors.white : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, int timeElapsed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Text('You completed the puzzle in ${_formatTime(timeElapsed)}!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
} 