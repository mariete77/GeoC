import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';
import '../../../../core/theme/app_colors.dart';

class QuestionCard extends StatelessWidget {
  final Question question;

  const QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _buildQuestionContent(),
    );
  }

  Widget _buildQuestionContent() {
    switch (question.type) {
      case QuestionType.flag:
        return _buildFlagQuestion();
      case QuestionType.silhouette:
        return _buildSilhouetteQuestion();
      case QuestionType.capital:
        return _buildCapitalQuestion();
      case QuestionType.population:
        return _buildPopulationQuestion();
      case QuestionType.river:
        return _buildRiverQuestion();
      case QuestionType.cityPhoto:
        return _buildCityPhotoQuestion();
      case QuestionType.area:
        return _buildAreaQuestion();
      case QuestionType.language:
        return _buildLanguageQuestion();
      case QuestionType.currency:
        return _buildCurrencyQuestion();
      case QuestionType.region:
        return _buildRegionQuestion();
    }
  }

  Widget _buildFlagQuestion() {
    final flagUrl = question.imageUrl ??
        (question.extraData?['countryCode'] != null
            ? 'https://flagcdn.com/w320/${question.extraData!['countryCode']}.png'
            : null);

    return Column(
      children: [
        if (flagUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: CachedNetworkImage(
              imageUrl: flagUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                height: 150,
                color: AppColors.surfaceVariant.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              errorWidget: (context, url, error) => Container(
                height: 150,
                color: AppColors.surfaceVariant.withOpacity(0.3),
                child: const Center(child: Icon(Icons.flag, size: 60, color: AppColors.outline)),
              ),
            ),
          ),
        if (flagUrl == null)
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Center(child: Icon(Icons.flag, size: 60, color: AppColors.outline)),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildDifficultyBadge(),
              const SizedBox(height: 16),
              Text(
                question.questionText ?? '¿De qué país es esta bandera?',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSilhouetteQuestion() {
    return Column(
      children: [
        if (question.imageUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
              child: CachedNetworkImage(
                imageUrl: question.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: AppColors.surfaceVariant.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: AppColors.surfaceVariant.withOpacity(0.3),
                  child: const Center(child: Icon(Icons.place, size: 60, color: AppColors.outline)),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildDifficultyBadge(),
              const SizedBox(height: 16),
              Text(
                question.questionText ?? '¿Qué país es este?',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapitalQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.location_city, size: 80, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Cuál es la capital de este país?',
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPopulationQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.groups, size: 80, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Qué país tiene más población?',
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRiverQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.water, size: 80, color: AppColors.secondary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Por qué país pasa este río?',
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCityPhotoQuestion() {
    return Column(
      children: [
        if (question.imageUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: CachedNetworkImage(
              imageUrl: question.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: AppColors.surfaceVariant.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: AppColors.surfaceVariant.withOpacity(0.3),
                child: const Center(child: Icon(Icons.photo_camera, size: 60, color: AppColors.outline)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildDifficultyBadge(),
              const SizedBox(height: 16),
              Text(
                question.questionText ?? '¿Qué ciudad se muestra en esta foto?',
                style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAreaQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.map, size: 80, color: AppColors.primaryContainer.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Qué país es más extenso?',
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.translate, size: 80, color: AppColors.secondary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Cuál es el idioma oficial?',
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.monetization_on, size: 80, color: AppColors.tertiary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Cuál es la moneda de este país?',
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegionQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.public, size: 80, color: AppColors.secondaryContainer.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿En qué región se encuentra este país?',
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    Color badgeColor;
    String badgeText;

    switch (question.difficulty) {
      case Difficulty.easy:
        badgeColor = AppColors.primary;
        badgeText = 'FÁCIL';
      case Difficulty.medium:
        badgeColor = AppColors.tertiary;
        badgeText = 'MEDIO';
      case Difficulty.hard:
        badgeColor = AppColors.error;
        badgeText = 'DIFÍCIL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        badgeText,
        style: GoogleFonts.workSans(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}