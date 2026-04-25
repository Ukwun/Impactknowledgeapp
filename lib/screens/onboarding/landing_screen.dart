import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/service_locator.dart';
import '../../services/api/api_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late final Future<Map<String, dynamic>> _landingContent;

  @override
  void initState() {
    super.initState();
    _landingContent = _loadLandingContent();
  }

  Future<Map<String, dynamic>> _loadLandingContent() async {
    try {
      final response = await getIt<ApiService>().getLandingContent();
      if (response['success'] == true &&
          response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
    } catch (_) {}

    return {
      'impactNumbers': {'learners': 0, 'courses': 0, 'institutions': 0},
      'partners': <Map<String, dynamic>>[],
      'testimonials': <Map<String, dynamic>>[],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 20,
                right: -40,
                child: _BlurBubble(
                  size: 180,
                  color: AppTheme.primary500.withValues(alpha: 0.22),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -55,
                child: _BlurBubble(
                  size: 220,
                  color: AppTheme.secondary500.withValues(alpha: 0.14),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 210,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: AppTheme.primary500.withValues(alpha: 0.18),
                        border: Border.all(
                          color: AppTheme.primary400.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Powered by NCDF & London School of Social Enterprise',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFB6F5DD),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool compact = constraints.maxWidth < 380;
                        return Text(
                          'From Knowledge to Opportunity',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: compact ? 42 : 48,
                                height: compact ? (50 / 42) : (56 / 48),
                                letterSpacing: -0.6,
                              ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'A structured platform for learning, growth, and real-world progress.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFD4DAE6),
                        fontSize: 18,
                        height: 28 / 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For those ready to learn, build, and grow.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFA3A8B3),
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _landingContent,
                      builder: (context, snapshot) {
                        final data =
                            snapshot.data ??
                            {
                              'impactNumbers': {
                                'learners': 0,
                                'courses': 0,
                                'institutions': 0,
                              },
                            };
                        final impact =
                            data['impactNumbers'] as Map<String, dynamic>;
                        return _MetricRow(
                          learners: impact['learners'] ?? 0,
                          courses: impact['courses'] ?? 0,
                          institutions: impact['institutions'] ?? 0,
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    _SectionCard(
                      title: 'Our Ecosystem',
                      subtitle:
                          'Choose your learning pathway in the same integrated ecosystem as the web platform.',
                      children: const [
                        _Bullet(
                          label: 'ImpactSchool',
                          value: 'Financial literacy foundations',
                        ),
                        _Bullet(
                          label: 'ImpactUni',
                          value: 'Innovation and venture readiness',
                        ),
                        _Bullet(
                          label: 'ImpactCircle',
                          value: 'Community and peer learning',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'How It Works',
                      subtitle: 'Clear. Structured. Practical.',
                      children: const [
                        _StepRow(step: '1', text: 'Choose your pathway'),
                        _StepRow(step: '2', text: 'Build relevant knowledge'),
                        _StepRow(
                          step: '3',
                          text: 'Apply through real-world thinking',
                        ),
                        _StepRow(step: '4', text: 'Progress with purpose'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'The Challenge',
                      subtitle:
                          'Knowledge gaps limit opportunity. ImpactKnowledge closes that gap with practical guidance.',
                      children: [
                        Text(
                          'Many people are expected to make important decisions about money, work, and leadership without practical support. We turn knowledge into structured action.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFFD4DAE6),
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _landingContent,
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? {};
                        final testimonials =
                            (data['testimonials'] as List?)
                                ?.map(
                                  (e) => Map<String, dynamic>.from(e as Map),
                                )
                                .toList() ??
                            <Map<String, dynamic>>[];

                        return _SectionCard(
                          title: 'Real Stories, Real Impact',
                          subtitle:
                              'Learners, mentors, and founders use this platform to move from learning to outcomes.',
                          children: testimonials.isEmpty
                              ? const [
                                  _QuoteCard(
                                    quote:
                                        'Impact stories will appear here as learner outcomes are published.',
                                    author: 'ImpactKnowledge',
                                  ),
                                ]
                              : testimonials
                                    .take(3)
                                    .map(
                                      (t) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: _QuoteCard(
                                          quote: t['quote']?.toString() ?? '',
                                          author:
                                              t['author_name']?.toString() ??
                                              t['authorName']?.toString() ??
                                              'Learner',
                                        ),
                                      ),
                                    )
                                    .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _landingContent,
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? {};
                        final partners =
                            (data['partners'] as List?)
                                ?.map(
                                  (e) => Map<String, dynamic>.from(e as Map),
                                )
                                .toList() ??
                            <Map<String, dynamic>>[];

                        return _SectionCard(
                          title: 'Trusted by Leaders',
                          subtitle:
                              'Backed by institutional partners and an ecosystem built for scale.',
                          children: partners.isEmpty
                              ? const [_Pill(label: 'Partner data unavailable')]
                              : partners
                                    .take(6)
                                    .map(
                                      (p) => _Pill(
                                        label:
                                            p['name']?.toString() ?? 'Partner',
                                      ),
                                    )
                                    .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.login),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Get Started'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                height: 1,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed(AppRoutes.signup),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                height: 1,
                                letterSpacing: 0.5,
                              ),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFAAB3C5)),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String label;
  final String value;

  const _Bullet({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: Color(0xFF7ED8B7)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(color: Color(0xFFD4DAE6)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String step;
  final String text;

  const _StepRow({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppTheme.primary500.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFD4DAE6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String quote;
  final String author;

  const _QuoteCard({required this.quote, required this.author});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$quote"',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            author,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF9ED8FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFFDDE5F5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BlurBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 70, spreadRadius: 6)],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final int learners;
  final int courses;
  final int institutions;

  const _MetricRow({
    required this.learners,
    required this.courses,
    required this.institutions,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      fontSize: 30,
      height: 1,
    );

    return Container(
      padding: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MetricItem(
            value: '${learners.toString()}+',
            label: 'Learners',
            valueStyle: style,
          ),
          _MetricItem(
            value: '${courses.toString()}+',
            label: 'Courses',
            valueStyle: style,
          ),
          _MetricItem(
            value: '${institutions.toString()}+',
            label: 'Institutions',
            valueStyle: style,
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String value;
  final String label;
  final TextStyle? valueStyle;

  const _MetricItem({
    required this.value,
    required this.label,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: valueStyle),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFFA3A8B3),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
