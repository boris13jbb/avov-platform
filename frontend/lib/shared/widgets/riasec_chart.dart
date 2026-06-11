import 'package:flutter/material.dart';

/// Puntajes RIASEC normalizados para visualización.
class RiasecScores {
  const RiasecScores({
    required this.scoreR,
    required this.scoreI,
    required this.scoreA,
    required this.scoreS,
    required this.scoreE,
    required this.scoreC,
    this.dominantProfile,
    this.secondaryProfile,
  });

  final int scoreR;
  final int scoreI;
  final int scoreA;
  final int scoreS;
  final int scoreE;
  final int scoreC;
  final String? dominantProfile;
  final String? secondaryProfile;

  factory RiasecScores.fromMap(Map<String, dynamic> json) {
    return RiasecScores(
      scoreR: (json['score_r'] as num?)?.toInt() ?? 0,
      scoreI: (json['score_i'] as num?)?.toInt() ?? 0,
      scoreA: (json['score_a'] as num?)?.toInt() ?? 0,
      scoreS: (json['score_s'] as num?)?.toInt() ?? 0,
      scoreE: (json['score_e'] as num?)?.toInt() ?? 0,
      scoreC: (json['score_c'] as num?)?.toInt() ?? 0,
      dominantProfile: json['dominant_profile'] as String?,
      secondaryProfile: json['secondary_profile'] as String?,
    );
  }

  List<RiasecBarEntry> get bars => [
        RiasecBarEntry('R', 'Realista', scoreR),
        RiasecBarEntry('I', 'Investigador', scoreI),
        RiasecBarEntry('A', 'Artístico', scoreA),
        RiasecBarEntry('S', 'Social', scoreS),
        RiasecBarEntry('E', 'Emprendedor', scoreE),
        RiasecBarEntry('C', 'Convencional', scoreC),
      ];

  int get maxScore {
    final values = [scoreR, scoreI, scoreA, scoreS, scoreE, scoreC];
    final peak = values.reduce((a, b) => a > b ? a : b);
    return peak > 0 ? peak : 50;
  }

  bool isHighlighted(String code) {
    final dominant = dominantProfile?.trim().toUpperCase();
    final secondary = secondaryProfile?.trim().toUpperCase();
    final normalized = code.toUpperCase();
    return normalized == dominant || normalized == secondary;
  }
}

class RiasecBarEntry {
  const RiasecBarEntry(this.code, this.label, this.score);

  final String code;
  final String label;
  final int score;
}

/// Gráfico de barras horizontales para el perfil RIASEC.
class RiasecChart extends StatelessWidget {
  const RiasecChart({
    super.key,
    required this.scores,
    this.showLegend = true,
  });

  final RiasecScores scores;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxScore = scores.maxScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLegend) ...[
          Text(
            'Distribución de puntajes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...scores.bars.map((bar) {
          final highlighted = scores.isHighlighted(bar.code);
          final color = highlighted
              ? theme.colorScheme.primary
              : theme.colorScheme.primaryContainer;
          final fraction = bar.score / maxScore;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        bar.code,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight:
                              highlighted ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bar.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              highlighted ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '${bar.score}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
