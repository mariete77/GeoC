import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/match.dart';

/// Card widget displaying a single match in the history list.
class MatchCard extends StatelessWidget {
  final GameMatch match;
  final String currentUserId;

  const MatchCard({
    super.key,
    required this.match,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final result = match.result;
    final isWin = result?.winnerId == currentUserId;
    final isDraw = result?.isDraw ?? false;
    final opponentId = match.getOpponentId(currentUserId);

    // Get ELO change for current user
    final eloChange = result?.eloChanges[currentUserId] ?? 0;
    final newElo = result?.newElo[currentUserId] ?? 0;

    // Get scores
    final myScore = result?.scores[currentUserId] ?? 0;
    final opponentScore = result?.scores[opponentId] ?? 0;

    // Format date
    final dateStr = DateFormat('dd MMM yyyy • HH:mm', 'es_ES').format(match.finishedAt ?? match.createdAt);

    // Mode and type labels
    final modeLabel = match.mode == MatchMode.realtime ? 'Tiempo Real' : ' Asíncrono';
    final typeLabel = match.type == MatchType.ranked ? 'Ranked' : 'Casual';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top row: result badge + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildResultBadge(isWin, isDraw),
                Text(
                  dateStr,
                  style: GoogleFonts.workSans(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Score row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$myScore',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isWin ? AppColors.primary : AppColors.onSurface,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '-',
                    style: GoogleFonts.workSans(
                      fontSize: 20,
                      color: AppColors.outlineVariant,
                    ),
                  ),
                ),
                Text(
                  '$opponentScore',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: !isWin && !isDraw ? AppColors.error : AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom row: mode, type, ELO change
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mode and type
                Row(
                  children: [
                    _buildTag(typeLabel, match.type == MatchType.ranked
                        ? AppColors.tertiaryContainer
                        : AppColors.surfaceContainerHigh),
                    const SizedBox(width: 6),
                    _buildTag(modeLabel, AppColors.surfaceContainerHigh),
                  ],
                ),
                // ELO change
                if (eloChange != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: eloChange > 0
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          eloChange > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: eloChange > 0 ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$eloChange',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: eloChange > 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($newElo)',
                          style: GoogleFonts.workSans(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBadge(bool isWin, bool isDraw) {
    final label = isDraw ? 'EMPATE' : (isWin ? 'VICTORIA' : 'DERROTA');
    final bgColor = isDraw
        ? AppColors.tertiaryContainer.withOpacity(0.3)
        : (isWin ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15));
    final textColor = isDraw ? AppColors.tertiary : (isWin ? AppColors.success : AppColors.error);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: GoogleFonts.workSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: GoogleFonts.workSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
