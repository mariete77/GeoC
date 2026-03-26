import 'package:flutter/material.dart';

class GameResultWidget extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final double averageTime;
  final VoidCallback onPlayAgain;
  final VoidCallback onGoHome;

  const GameResultWidget({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.averageTime,
    required this.onPlayAgain,
    required this.onGoHome,
  });

  @override
  State<GameResultWidget> createState() => _GameResultWidgetState();
}

class _GameResultWidgetState extends State<GameResultWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = (widget.correctAnswers / widget.totalQuestions) * 100;
    final rank = _getRank(accuracy, widget.score);
    final rankColor = _getRankColor(rank);

    return Container(
      color: const Color(0xFF1A1A2E),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Rank badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: rankColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: rankColor.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      rank,
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Main score
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'YOUR SCORE',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.orange,
                              blurRadius: 20,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle,
                        label: 'Correct',
                        value: '${widget.correctAnswers}/${widget.totalQuestions}',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.timeline,
                        label: 'Avg Time',
                        value: '${widget.averageTime.toStringAsFixed(1)}s',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.percent,
                        label: 'Accuracy',
                        value: '${accuracy.toStringAsFixed(0)}%',
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.star,
                        label: 'Avg Score/Q',
                        value: '${(widget.score / widget.totalQuestions).round()}',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Performance message
                Center(
                  child: Text(
                    _getPerformanceMessage(accuracy),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                // Buttons
                ElevatedButton.icon(
                  onPressed: widget.onPlayAgain,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: widget.onGoHome,
                  icon: const Icon(Icons.home),
                  label: const Text(
                    'BACK TO HOME',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getRank(double accuracy, int score) {
    if (accuracy >= 90 && score >= 1500) return 'LEGENDARY';
    if (accuracy >= 80 && score >= 1200) return 'MASTER';
    if (accuracy >= 70 && score >= 900) return 'EXPERT';
    if (accuracy >= 60 && score >= 600) return 'SKILLED';
    if (accuracy >= 50) return 'BEGINNER';
    return 'ROOKIE';
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'LEGENDARY':
        return const Color(0xFFFFD700); // Gold
      case 'MASTER':
        return const Color(0xFFC0C0C0); // Silver
      case 'EXPERT':
        return const Color(0xFFCD7F32); // Bronze
      case 'SKILLED':
        return Colors.green;
      case 'BEGINNER':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPerformanceMessage(double accuracy) {
    if (accuracy >= 90) return '🎯 Incredible! You\'re a geography master!';
    if (accuracy >= 80) return '🌟 Great job! Keep up the good work!';
    if (accuracy >= 70) return '👏 Nice! You\'re getting better!';
    if (accuracy >= 60) return '💪 Good effort! Practice makes perfect!';
    return '📚 Keep learning! Every game counts!';
  }
}
