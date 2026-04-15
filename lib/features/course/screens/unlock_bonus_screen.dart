import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_czech/core/theme/app_colors.dart';
import 'package:app_czech/core/theme/app_radius.dart';
import 'package:app_czech/core/theme/app_typography.dart';
import 'package:app_czech/shared/widgets/responsive_page_container.dart';

/// Unlock bonus practice screen — matches unlock_bonus.html Stitch design.
class UnlockBonusScreen extends StatelessWidget {
  const UnlockBonusScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withOpacity(0.6),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onBackground.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.primary,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mở khóa luyện tập',
                    style: AppTypography.headlineSmall.copyWith(fontSize: 22),
                  ),
                  const Spacer(),
                  // XP balance chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '1,240 XP',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: ResponsivePageContainer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Hero
                _HeroSection(),
                const SizedBox(height: 40),

                // Benefits bento
                _BenefitsGrid(),
                const SizedBox(height: 48),

                // Transaction card
                _TransactionCard(onUnlock: () => context.pop()),
                const SizedBox(height: 32),

                // Motivational quote
                Text(
                  '"Sự chuẩn bị tốt nhất cho ngày mai là làm hết sức mình trong ngày hôm nay."',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero Section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lock icon container
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onBackground.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            // Pulse dot
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Text(
          'Luyện nghe chuyên sâu - Chủ đề Gia đình',
          style: AppTypography.headlineLarge.copyWith(
            fontSize: 36,
            height: 1.25,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Bài tập nâng cao giúp bạn làm quen với các giọng địa phương và tốc độ nói thực tế trong kỳ thi.',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Benefits Grid ─────────────────────────────────────────────────────────────

class _BenefitsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final benefits = [
      (Icons.menu_book_rounded, 'Từ vựng',
          'Học được 50+ từ vựng chuyên sâu về chủ đề gia đình và xã hội.'),
      (Icons.verified_user_rounded, 'Đề thực tế',
          'Mô phỏng 100% đề thi thực tế với cấu trúc âm thanh đa dạng.'),
      (Icons.analytics_rounded, 'Dự đoán',
          'Dự đoán điểm số chính xác hơn thông qua thuật toán phân tích.'),
    ];

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: benefits.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, title, desc) = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i > 0 ? 12 : 0,
                right: i < benefits.length - 1 ? 12 : 0,
                top: i == 1 ? 16 : 0,
              ),
              child: _BenefitCard(icon: icon, title: title, desc: desc),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: benefits.map((b) {
        final (icon, title, desc) = b;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _BenefitCard(icon: icon, title: title, desc: desc),
        );
      }).toList(),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction Card ──────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 448),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onBackground.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cost display
          const Icon(Icons.payments_rounded,
              color: AppColors.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            '500 XP',
            style: AppTypography.headlineLarge.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              'PHÍ MỞ KHÓA',
              style: AppTypography.labelUppercase.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats table
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Số dư hiện tại',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.onSurfaceVariant)),
              Text('1,240 XP',
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sau khi mở khóa',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.onSurfaceVariant)),
              Text('740 XP',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 24),

          // Unlock button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onUnlock,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_open_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Mở khóa ngay',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Skip button
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Làm sau',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
