import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the game after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startNewGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                );
              },
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Difficulty',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDifficultyButton(context, 'Easy'),
            _buildDifficultyButton(context, 'Medium'),
            _buildDifficultyButton(context, 'Hard'),
            const SizedBox(height: 40),
            _buildHighScores(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String difficulty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          final gameProvider = Provider.of<GameProvider>(context, listen: false);
          gameProvider.setDifficulty(difficulty);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GameScreen()),
          ).then((_) {
            // Reset game state when returning from game screen
            gameProvider.generateNewPuzzle();
          });
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(200, 50),
        ),
        child: Text(difficulty),
      ),
    );
  }

  Widget _buildHighScores(BuildContext context) {
    final highScores = Provider.of<GameProvider>(context).highScores;
    return Column(
      children: [
        const Text(
          'High Scores',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('Easy: ${_formatTime(highScores['Easy']!)}'),
        Text('Medium: ${_formatTime(highScores['Medium']!)}'),
        Text('Hard: ${_formatTime(highScores['Hard']!)}'),
      ],
    );
  }

  String _formatTime(int seconds) {
    if (seconds == 9999) return '--:--';
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
} 