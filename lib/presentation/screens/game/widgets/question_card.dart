import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';

class QuestionCard extends StatelessWidget {
  final Question question;

  const QuestionCard({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
    }
  }

  Widget _buildFlagQuestion() {
    // Build flag URL from imageUrl or countryCode
    final flagUrl = question.imageUrl ??
        (question.extraData?['countryCode'] != null
            ? 'https://flagcdn.com/w320/${question.extraData!['countryCode']}.png'
            : null);

    return Column(
      children: [
        // Flag image
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
                color: Colors.grey.withOpacity(0.2),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 150,
                color: Colors.grey.withOpacity(0.2),
                child: const Center(
                  child: Icon(Icons.flag, size: 60, color: Colors.grey),
                ),
              ),
            ),
          ),
        if (flagUrl == null)
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Center(
              child: Icon(Icons.flag, size: 60, color: Colors.grey),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildDifficultyBadge(),
              const SizedBox(height: 16),
              Text(
                question.questionText ?? '¿De qué país es esta bandera?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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
        // Silhouette image
        if (question.imageUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
              child: CachedNetworkImage(
                imageUrl: question.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Center(
                    child: Icon(Icons.place, size: 60, color: Colors.grey),
                  ),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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
          Icon(
            Icons.location_city,
            size: 80,
            color: Colors.orange.withOpacity(0.8),
          ),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Cuál es la capital de este país?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
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
          Icon(
            Icons.groups,
            size: 80,
            color: Colors.orange.withOpacity(0.8),
          ),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Qué país tiene más población?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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
          Icon(
            Icons.water,
            size: 80,
            color: Colors.blue.withOpacity(0.8),
          ),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Por qué país pasa este río?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCityPhotoQuestion() {
    return Column(
      children: [
        // City photo
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
                color: Colors.grey.withOpacity(0.2),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey.withOpacity(0.2),
                child: const Center(
                  child: Icon(Icons.photo_camera, size: 60, color: Colors.grey),
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
                question.questionText ?? '¿Qué ciudad se muestra en esta foto?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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
          Icon(
            Icons.map,
            size: 80,
            color: Colors.green.withOpacity(0.8),
          ),
          const SizedBox(height: 24),
          Text(
            question.questionText ?? '¿Qué país es más extenso?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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
        badgeColor = Colors.green;
        badgeText = 'FÁCIL';
        break;
      case Difficulty.medium:
        badgeColor = Colors.orange;
        badgeText = 'MEDIO';
        break;
      case Difficulty.hard:
        badgeColor = Colors.red;
        badgeText = 'DIFÍCIL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}
