import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EmptyState extends StatefulWidget {
  final Function(String) onSuggestionTap;

  const EmptyState({super.key, required this.onSuggestionTap});

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildCategoryBox(String title, IconData icon, List<String> suggestions) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                 padding: const EdgeInsets.all(6),
                 decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                 child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: suggestions.map((text) => _buildSuggestionChip(text)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () => widget.onSuggestionTap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
          boxShadow: [
             BoxShadow(color: AppColors.textPrimary.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.primary.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                )
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                     return Container(
                       padding: const EdgeInsets.all(28),
                       decoration: BoxDecoration(
                         gradient: const LinearGradient(
                           colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                         ),
                         shape: BoxShape.circle,
                         boxShadow: [
                           BoxShadow(
                             color: const Color(0xFFD4AF37).withOpacity(0.3 + (_pulseController.value * 0.3)),
                             blurRadius: 30 + (_pulseController.value * 20),
                             spreadRadius: _pulseController.value * 8,
                             offset: const Offset(0, 10),
                           ),
                         ],
                       ),
                       child: const Icon(Icons.auto_awesome_rounded, size: 50, color: Colors.white),
                     );
                  }
                ),
                const SizedBox(height: 36),
                const Text(
                  'مرحباً بك في Edu Bot',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'أنا مساعدك الذكي المعزز بالذكاء الاصطناعي.\nاطرح أي سؤال حول دراستك أو التطبيق وسأساعدك فوراً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 15.5,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 54),
                _buildCategoryBox('شروحات سريعة', Icons.lightbulb_outline_rounded, [
                  'كيف أستفيد من مجموعات التطبيق؟',
                  'اشرح لي كيفية نشر ملف جديد',
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
