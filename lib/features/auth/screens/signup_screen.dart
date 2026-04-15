import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_czech/core/router/app_routes.dart';
import 'package:app_czech/core/theme/app_colors.dart';
import 'package:app_czech/core/theme/app_typography.dart';
import 'package:app_czech/core/theme/app_radius.dart';
import 'package:app_czech/shared/widgets/app_button.dart';
import 'package:app_czech/shared/widgets/app_text_field.dart';
import 'package:app_czech/features/mock_test/providers/exam_result_provider.dart';
import '../providers/auth_notifier.dart';
import 'login_screen.dart' show AuthAppBar, SocialButton;

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isSubmitting = authState.status == AuthFormStatus.submitting;

    ref.listen(authNotifierProvider, (_, next) async {
      if (next.status == AuthFormStatus.success) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await linkPendingAttempt(userId);
        }
        // Navigation handled by _RouterNotifier via onAuthStateChange redirect.
        // Do NOT call context.go here — causes redirect loop on iOS where
        // the session getter briefly returns null on the first redirect evaluation.
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AuthAppBar(
        onBack: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.landing),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              // Branding circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    // Form card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.outlineVariant.withOpacity(0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3A302A).withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Tạo tài khoản',
                            style: AppTypography.headlineLarge.copyWith(
                              color: AppColors.onBackground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lưu kết quả thi và theo dõi lộ trình học của bạn.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Name field
                          AppTextField(
                            controller: _nameCtrl,
                            label: 'Họ và tên',
                            hint: 'Nguyễn Văn A',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 20),

                          // Email field
                          AppTextField(
                            controller: _emailCtrl,
                            label: 'Email',
                            hint: 'example@domain.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.mail_outline_rounded,
                          ),
                          const SizedBox(height: 20),

                          // Password field
                          AppTextField(
                            controller: _passwordCtrl,
                            label: 'Mật khẩu',
                            hint: '••••••••',
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 20),

                          // Terms checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (v) => setState(
                                      () => _agreedToTerms = v ?? false),
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm / 2),
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _agreedToTerms = !_agreedToTerms),
                                  child: Wrap(
                                    children: [
                                      Text(
                                        'Tôi đồng ý với ',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      InlineLinkButton(
                                        label: 'Điều khoản dịch vụ',
                                        onTap: () {/* TODO: open terms */},
                                      ),
                                      Text(
                                        ' và ',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      InlineLinkButton(
                                        label: 'Chính sách bảo mật',
                                        onTap: () {/* TODO: open privacy */},
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Error message
                          if (authState.status == AuthFormStatus.authError ||
                              authState.status ==
                                  AuthFormStatus.validationError) ...[
                            const SizedBox(height: 12),
                            Text(
                              authState.errorMessage ?? '',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // Submit
                          AppButton(
                            label: 'Đăng ký ngay',
                            loading: isSubmitting,
                            onPressed: isSubmitting ? null : _submit,
                            icon: Icons.arrow_forward_rounded,
                          ),

                          const SizedBox(height: 32),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color:
                                      AppColors.outlineVariant.withOpacity(0.6),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Text(
                                  'HOẶC ĐĂNG KÝ BẰNG',
                                  style: AppTypography.labelUppercase.copyWith(
                                    color: AppColors.outline.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color:
                                      AppColors.outlineVariant.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Social options (2-col grid)
                          Row(
                            children: [
                              Expanded(
                                child: SocialButton(
                                  icon: Icons.g_mobiledata_rounded,
                                  label: 'Google',
                                  onTap: () {/* TODO */},
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SocialButton(
                                  icon: Icons.apple_rounded,
                                  label: 'Apple',
                                  onTap: () {/* TODO */},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        InlineLinkButton(
                          label: 'Đăng nhập',
                          onTap: () => context.push(AppRoutes.login),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng đồng ý với điều khoản sử dụng')),
      );
      return;
    }
    ref.read(authNotifierProvider.notifier).signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          displayName:
              _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        );
  }
}
