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
                      _buildTimer(gameProvider.timeElapsed),
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
              int row = index ~/ 9;
              int col = index % 9;
              return _buildCell(row, col, gameProvider);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col, GameProvider gameProvider) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isFixed = gameProvider.fixedCells[row][col];
    int value = gameProvider.board[row][col];
    bool isValid = value == 0 || gameProvider.isValidMove(row, col, value);
    
    return GestureDetector(
      onTap: () {
        if (!isFixed && !gameProvider.isGameOver) {
          if (_selectedNumber == 0) {
            gameProvider.makeMove(row, col, 0);
          } else {
            gameProvider.makeMove(row, col, _selectedNumber);
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: (col + 1) % 3 == 0 ? Colors.black : Colors.grey.shade300,
              width: (col + 1) % 3 == 0 ? 2.0 : 1.0,
            ),
            bottom: BorderSide(
              color: (row + 1) % 3 == 0 ? Colors.black : Colors.grey.shade300,
              width: (row + 1) % 3 == 0 ? 2.0 : 1.0,
            ),
            left: BorderSide(
              color: col % 3 == 0 ? Colors.black : Colors.grey.shade300,
              width: col % 3 == 0 ? 2.0 : 1.0,
            ),
            top: BorderSide(
              color: row % 3 == 0 ? Colors.black : Colors.grey.shade300,
              width: row % 3 == 0 ? 2.0 : 1.0,
            ),
          ),
          color: isFixed 
            ? (themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey.shade100)
            : (themeProvider.isDarkMode ? Colors.grey[900] : Colors.white),
        ),
        child: Center(
          child: Text(
            value == 0 ? '' : value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: isFixed ? FontWeight.bold : FontWeight.normal,
              color: isFixed 
                ? (themeProvider.isDarkMode ? Colors.white : Colors.black87)
                : (isValid ? Colors.blue : Colors.red),
            ),
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
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedNumber = number;
        });
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