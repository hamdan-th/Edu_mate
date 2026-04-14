import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EmptyState extends StatefulWidget {
  final Function(String) onSuggestionTap;
  final String? sourceScreen;

  const EmptyState({super.key, required this.onSuggestionTap, this.sourceScreen});

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
                       padding: const EdgeInsets.all(24),
                       decoration: BoxDecoration(
                         color: const Color(0xFF16161A),
                         shape: BoxShape.circle,
                         border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
                         boxShadow: [
                           BoxShadow(
                             color: const Color(0xFFD4AF37).withOpacity(0.1 + (_pulseController.value * 0.15)),
                             blurRadius: 20 + (_pulseController.value * 15),
                             spreadRadius: 2 + (_pulseController.value * 4),
                             offset: const Offset(0, 8),
                           ),
                         ],
                       ),
                       child: const Icon(Icons.smart_toy_outlined, size: 48, color: Color(0xFFD4AF37)),
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
                Builder(
                  builder: (context) {
                    String title = 'شروحات عامة';
                    IconData icon = Icons.lightbulb_outline_rounded;
                    List<String> suggestions = [
                      'عرفني على Edu Mate',
                      'كيف أبدأ باستخدام التطبيق؟',
                      'ما الذي يمكنك مساعدتي فيه؟',
                    ];

                    if (widget.sourceScreen == 'feed_screen') {
                      title = 'اقتراحات للفيد العام';
                      icon = Icons.dynamic_feed_rounded;
                      suggestions = [
                        'ما الفرق بين الفيد والمجموعات؟',
                        'كيف أستفيد من الفيد العام؟',
                        'ماذا يمكنني أن أفعل هنا؟',
                      ];
                    } else if (widget.sourceScreen == 'library_screen' || widget.sourceScreen == 'my_library_screen') {
                      title = 'اقتراحات للمكتبة الجامعية';
                      icon = Icons.library_books_rounded;
                      suggestions = [
                        'كيف أبحث عن ملف؟',
                        'كيف أرفع ملف؟',
                        'كيف أستفيد من المكتبة؟',
                      ];
                    } else if (widget.sourceScreen == 'groups_screen' || widget.sourceScreen == 'group_chat_screen' || widget.sourceScreen == 'group_details_screen') {
                      title = 'اقتراحات للمجموعات';
                      icon = Icons.group_work_rounded;
                      suggestions = [
                        'كيف أستخدم المجموعة؟',
                        'ما الفرق بين الدردشة والنشر العام؟',
                        'كيف أستفيد من الرسائل المثبتة؟',
                      ];
                    }

                    return _buildCategoryBox(title, icon, suggestions);
                  }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
