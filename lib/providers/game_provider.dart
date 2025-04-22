import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  List<List<int>> _board = List.generate(9, (_) => List<int>.filled(9, 0));
  List<List<int>> _solution = List.generate(9, (_) => List<int>.filled(9, 0));
  List<List<bool>> _fixedCells = List.generate(9, (_) => List<bool>.filled(9, false));
  List<List<List<bool>>> _notes = List.generate(9, (_) => 
    List.generate(9, (_) => List<bool>.filled(9, false)));
  String _difficulty = 'Easy';
  int _timeElapsed = 0;
  bool _isGameComplete = false;
  int _errorCount = 0;
  bool _isGameOver = false;
  Map<String, int> _highScores = {'Easy': 9999, 'Medium': 9999, 'Hard': 9999};
  int _maxRecursionDepth = 0;
  bool _isLoading = false;
  bool _isNotesMode = false;

  List<List<int>> get board => _board;
  List<List<bool>> get fixedCells => _fixedCells;
  List<List<List<bool>>> get notes => _notes;
  String get difficulty => _difficulty;
  int get timeElapsed => _timeElapsed;
  bool get isGameComplete => _isGameComplete;
  int get errorCount => _errorCount;
  bool get isGameOver => _isGameOver;
  Map<String, int> get highScores => _highScores;
  bool get isLoading => _isLoading;
  bool get isNotesMode => _isNotesMode;

  GameProvider({required SharedPreferences prefs}) : _prefs = prefs {
    _loadHighScores();
    _board = List.generate(9, (_) => List<int>.filled(9, 0));
    _solution = List.generate(9, (_) => List<int>.filled(9, 0));
    _fixedCells = List.generate(9, (_) => List<bool>.filled(9, false));
    _notes = List.generate(9, (_) => 
      List.generate(9, (_) => List<bool>.filled(9, false)));
  }

  void _loadHighScores() {
    _highScores['Easy'] = _prefs.getInt('highScore_Easy') ?? 9999;
    _highScores['Medium'] = _prefs.getInt('highScore_Medium') ?? 9999;
    _highScores['Hard'] = _prefs.getInt('highScore_Hard') ?? 9999;
    notifyListeners();
  }

  Future<void> _saveHighScores() async {
    await _prefs.setInt('highScore_Easy', _highScores['Easy']!);
    await _prefs.setInt('highScore_Medium', _highScores['Medium']!);
    await _prefs.setInt('highScore_Hard', _highScores['Hard']!);
  }

  void setDifficulty(String difficulty) {
    _difficulty = difficulty;
    generateNewPuzzle();
  }

  void updateTime(int time) {
    if (!_isGameComplete) {
      _timeElapsed = time;
      notifyListeners();
    }
  }

  bool isValidMove(int row, int col, int value) {
    if (value == 0) return true;
    
    // Check row
    for (int i = 0; i < 9; i++) {
      if (i != col && _board[row][i] == value) return false;
    }
    
    // Check column
    for (int i = 0; i < 9; i++) {
      if (i != row && _board[i][col] == value) return false;
    }
    
    // Check 3x3 box
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (i != row && j != col && _board[i][j] == value) return false;
      }
    }
    
    return true;
  }

  void toggleNotesMode() {
    _isNotesMode = !_isNotesMode;
    notifyListeners();
  }

  void toggleNote(int row, int col, int number) {
    if (!_fixedCells[row][col] && !_isGameOver) {
      _notes[row][col][number - 1] = !_notes[row][col][number - 1];
      notifyListeners();
    }
  }

  void clearNotes(int row, int col) {
    if (!_fixedCells[row][col] && !_isGameOver) {
      _notes[row][col] = List<bool>.filled(9, false);
      notifyListeners();
    }
  }

  void makeMove(int row, int col, int value) {
    if (!_fixedCells[row][col] && !_isGameOver) {
      if (_isNotesMode) {
        toggleNote(row, col, value);
      } else {
        _board[row][col] = value;
        // Clear notes when making a move
        _notes[row][col] = List<bool>.filled(9, false);
        
        // Check if the move is valid
        if (value != 0 && !isValidMove(row, col, value)) {
          _errorCount++;
          if (_errorCount >= 3) {
            _isGameOver = true;
            _isGameComplete = true;
          }
        }
        
        notifyListeners();
        if (!_isGameOver) {
          _checkCompletion();
        }
      }
    }
  }

  void _checkCompletion() {
    if (_isGameOver) return;

    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_board[i][j] != _solution[i][j]) {
          _isGameComplete = false;
          return;
        }
      }
    }
    _isGameComplete = true;
    if (_timeElapsed < _highScores[_difficulty]!) {
      _highScores[_difficulty] = _timeElapsed;
      _saveHighScores();
    }
    notifyListeners();
  }

  Future<void> startNewGame() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await generateNewPuzzle();
    } catch (e) {
      debugPrint('Error generating puzzle: $e');
      _board = List.generate(9, (_) => List<int>.filled(9, 0));
      _solution = List.generate(9, (_) => List<int>.filled(9, 0));
      _fixedCells = List.generate(9, (_) => List<bool>.filled(9, false));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateNewPuzzle() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.microtask(() {
        _generateValidSolution();
        _createPuzzle();
      });
      _timeElapsed = 0;
      _isGameComplete = false;
      _errorCount = 0;
      _isGameOver = false;
      _notes = List.generate(9, (_) => 
        List.generate(9, (_) => List<bool>.filled(9, false)));
      _isNotesMode = false;
    } catch (e) {
      debugPrint('Error generating puzzle: $e');
      _board = List.generate(9, (_) => List<int>.filled(9, 0));
      _fixedCells = List.generate(9, (_) => List<bool>.filled(9, false));
      _solution = List.generate(9, (_) => List<int>.filled(9, 0));
      _notes = List.generate(9, (_) => 
        List.generate(9, (_) => List<bool>.filled(9, false)));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _generateValidSolution() {
    _solution = List.generate(9, (_) => List<int>.filled(9, 0));
    
    // Fill diagonal boxes first (they are independent)
    for (int box = 0; box < 9; box += 3) {
      _fillBox(box, box);
    }
    
    // Solve the rest of the puzzle
    _solveSudoku();
  }

  void _fillBox(int row, int col) {
    List<int> numbers = List.generate(9, (index) => index + 1)..shuffle();
    int index = 0;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        _solution[row + i][col + j] = numbers[index++];
      }
    }
  }

  bool _solveSudoku() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_solution[row][col] == 0) {
          List<int> possibleNumbers = _getPossibleNumbers(row, col);
          for (int num in possibleNumbers) {
            _solution[row][col] = num;
            if (_solveSudoku()) {
              return true;
            }
            _solution[row][col] = 0;
          }
          return false;
        }
      }
    }
    return true;
  }

  List<int> _getPossibleNumbers(int row, int col) {
    List<int> possible = List.generate(9, (index) => index + 1);
    
    // Check row
    for (int i = 0; i < 9; i++) {
      if (_solution[row][i] != 0) {
        possible.remove(_solution[row][i]);
      }
    }
    
    // Check column
    for (int i = 0; i < 9; i++) {
      if (_solution[i][col] != 0) {
        possible.remove(_solution[i][col]);
      }
    }
    
    // Check 3x3 box
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (_solution[i][j] != 0) {
          possible.remove(_solution[i][j]);
        }
      }
    }
    
    return possible;
  }

  void _createPuzzle() {
    // Copy solution to board
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        _board[i][j] = _solution[i][j];
        _fixedCells[i][j] = true;
      }
    }

    // Determine how many cells to remove based on difficulty
    int cellsToRemove = _difficulty == 'Easy' ? 30 : (_difficulty == 'Medium' ? 40 : 50);
    int removed = 0;
    
    // Create a list of all positions and shuffle it
    List<int> positions = List.generate(81, (index) => index)..shuffle();
    
    for (int pos in positions) {
      if (removed >= cellsToRemove) break;
      
      int row = pos ~/ 9;
      int col = pos % 9;
      
      // Store the current number
      int temp = _board[row][col];
      
      // Try removing the number
      _board[row][col] = 0;
      _fixedCells[row][col] = false;
      
      // Check if the puzzle still has a unique solution
      if (_hasUniqueSolution()) {
        removed++;
      } else {
        // If not unique, put the number back
        _board[row][col] = temp;
        _fixedCells[row][col] = true;
      }
    }
  }

  bool _hasUniqueSolution() {
    List<List<int>> tempBoard = List.generate(9, (i) => List<int>.from(_board[i]));
    return _countSolutions(tempBoard, 0, 0) == 1;
  }

  int _countSolutions(List<List<int>> board, int row, int col) {
    if (row == 9) {
      return 1;
    }
    
    if (col == 9) {
      return _countSolutions(board, row + 1, 0);
    }
    
    if (board[row][col] != 0) {
      return _countSolutions(board, row, col + 1);
    }
    
    List<int> possibleNumbers = _getPossibleNumbersForBoard(board, row, col);
    int totalSolutions = 0;
    
    for (int num in possibleNumbers) {
      board[row][col] = num;
      totalSolutions += _countSolutions(board, row, col + 1);
      if (totalSolutions > 1) {
        board[row][col] = 0;
        return totalSolutions;
      }
      board[row][col] = 0;
    }
    
    return totalSolutions;
  }

  List<int> _getPossibleNumbersForBoard(List<List<int>> board, int row, int col) {
    List<int> possible = List.generate(9, (index) => index + 1);
    
    // Check row
    for (int i = 0; i < 9; i++) {
      if (board[row][i] != 0) {
        possible.remove(board[row][i]);
      }
    }
    
    // Check column
    for (int i = 0; i < 9; i++) {
      if (board[i][col] != 0) {
        possible.remove(board[i][col]);
      }
    }
    
    // Check 3x3 box
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (board[i][j] != 0) {
          possible.remove(board[i][j]);
        }
      }
    }
    
    return possible;
  }
} 