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
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C1B).withOpacity(0.04),
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
      case QuestionType.city:
        return _buildCityQuestion();
      case QuestionType.mountain:
        return _buildMountainQuestion();
      case QuestionType.lake:
        return _buildLakeQuestion();
      case QuestionType.border:
        return _buildBorderQuestion();
      case QuestionType.monumentImage:
        return _buildMonumentImageQuestion();
      case QuestionType.monumentCountry:
        return _buildMonumentCountryQuestion();
      case QuestionType.monumentCity:
        return _buildMonumentCityQuestion();
      case QuestionType.historicBuilding:
        return _buildHistoricBuildingQuestion();
    }
  }

  /// Helper to build an image container with proper full-border support.
  /// Uses a white background behind BoxFit.contain images so the border
  /// is visible on all sides, not just top/bottom.
  Widget _buildImageSection({
    required String imageUrl,
    required double height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
    Widget? errorWidget,
    bool isAsset = false,
    bool isNetwork = true,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(31)),
        child: isAsset
            ? Image.asset(
                imageUrl,
                height: height,
                width: double.infinity,
                fit: fit,
                errorBuilder: (context, error, stackTrace) =>
                    errorWidget ??
                    Container(
                      height: height,
                      color: AppColors.surfaceVariant.withOpacity(0.3),
                      child: const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 60, color: AppColors.outline)),
                    ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                height: height,
                width: double.infinity,
                fit: fit,
                placeholder: (context, url) =>
                    placeholder ??
                    Container(
                      color: AppColors.surfaceVariant.withOpacity(0.3),
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    ),
                errorWidget: (context, url, error) =>
                    errorWidget ??
                    Container(
                      color: AppColors.surfaceVariant.withOpacity(0.3),
                      child: const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 60, color: AppColors.outline)),
                    ),
              ),
      ),
    );
  }

  Widget _buildFlagQuestion() {
    final flagUrl = question.imageUrl ??
        (question.extraData?['countryCode'] != null
            ? 'https://flagcdn.com/w320/${question.extraData!['countryCode']}.png'
            : null);

    return Column(
      children: [
        if (flagUrl != null)
          _buildImageSection(
            imageUrl: flagUrl,
            height: 150,
            fit: BoxFit.contain,
            errorWidget: Container(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              child: const Center(
                  child: Icon(Icons.flag, size: 60, color: AppColors.outline)),
            ),
          ),
        if (flagUrl == null)
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32)),
              border:
                  Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
            ),
            child: const Center(
                child: Icon(Icons.flag, size: 60, color: AppColors.outline)),
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
    final isAsset =
        question.imageUrl != null && !question.imageUrl!.startsWith('http');

    return Column(
      children: [
        if (question.imageUrl != null)
          _buildImageSection(
            imageUrl: question.imageUrl!,
            height: 180,
            fit: BoxFit.contain,
            isAsset: isAsset,
            isNetwork: !isAsset,
            errorWidget: Container(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              child: const Center(
                  child:
                      Icon(Icons.place, size: 60, color: AppColors.outline)),
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
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 20),
          Icon(Icons.location_city,
              size: 80, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(height: 28),
          Text(
            question.questionText ?? '¿Cuál es la capital de este país?',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5,
            ),
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
          Icon(Icons.groups,
              size: 80, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Qué país tiene más población?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
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
          Icon(Icons.water,
              size: 80, color: AppColors.secondary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Por qué país pasa este río?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
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
          _buildImageSection(
            imageUrl: question.imageUrl!,
            height: 200,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              child: const Center(
                  child: Icon(Icons.photo_camera,
                      size: 60, color: AppColors.outline)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildDifficultyBadge(),
              const SizedBox(height: 16),
              Text(
                question.questionText ??
                    '¿Qué ciudad se muestra en esta foto?',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
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
          Icon(Icons.map,
              size: 80, color: AppColors.primaryContainer.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Qué país es más extenso?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
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
          Icon(Icons.translate,
              size: 80, color: AppColors.secondary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Cuál es el idioma oficial?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
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
          Icon(Icons.monetization_on,
              size: 80, color: AppColors.tertiary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Cuál es la moneda de este país?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
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
          Icon(Icons.public,
              size: 80,
              color: AppColors.secondaryContainer.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ??
                '¿En qué región se encuentra este país?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCityQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.location_city,
              size: 80, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ??
                '¿En qué país se encuentra esta ciudad?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMountainQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.terrain,
              size: 80,
              color: AppColors.tertiaryContainer.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ??
                '¿En qué país se encuentra esta montaña?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLakeQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.water,
              size: 80, color: AppColors.secondary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ??
                '¿En qué país se encuentra este lago?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBorderQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.compare_arrows,
              size: 80, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ??
                '¿Qué países comparten esta frontera?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonumentImageQuestion() {
    return Column(
      children: [
        if (question.imageUrl != null)
          _buildImageSection(
            imageUrl: question.imageUrl!,
            height: 200,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              child: const Center(
                  child: Icon(Icons.photo_camera,
                      size: 60, color: AppColors.outline)),
            ),
          ),
        if (question.imageUrl == null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border:
                  Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
            ),
            child: const Center(
                child: Icon(Icons.account_balance,
                    size: 60, color: AppColors.outline)),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildDifficultyBadge(),
              const SizedBox(height: 16),
              Text(
                question.questionText ??
                    '¿Qué monumento o edificio es este?',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonumentCountryQuestion() {
    final monumentName =
        question.extraData?['monumentName'] as String?;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.account_balance,
              size: 80, color: AppColors.tertiary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ??
                (monumentName != null
                    ? '¿De qué país es $monumentName?'
                    : '¿De qué país es este monumento?'),
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonumentCityQuestion() {
    final monumentName =
        question.extraData?['monumentName'] as String?;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.location_city,
              size: 80, color: AppColors.secondary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ??
                (monumentName != null
                    ? '¿En qué ciudad está $monumentName?'
                    : '¿En qué ciudad está este monumento?'),
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricBuildingQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDifficultyBadge(),
          const SizedBox(height: 16),
          Icon(Icons.account_balance,
              size: 80, color: AppColors.tertiary.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            question.questionText ??
                '¿En qué ciudad se encuentra este edificio histórico?',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700),
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