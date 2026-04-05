import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/bot_controller.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final BotController controller;

  const ChatHistoryDrawer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
               child: Row(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                     ),
                     child: const Icon(Icons.forum_rounded, color: AppColors.primary, size: 20),
                   ),
                   const SizedBox(width: 14),
                   const Expanded(
                     child: Text(
                       'سجل المحادثات',
                       style: TextStyle(
                         color: AppColors.textPrimary,
                         fontWeight: FontWeight.w800,
                         fontSize: 18,
                       ),
                     ),
                   ),
                 ],
               ),
             ),
             Padding(
               padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
               child: InkWell(
                  onTap: () {
                     controller.createNewChat();
                     Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                     padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(
                         colors: [AppColors.primary, AppColors.blueGlow],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                       borderRadius: BorderRadius.circular(16),
                       boxShadow: [
                         BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                       ],
                     ),
                     child: const Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                             'محادثة جديدة',
                             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                       ],
                     ),
                  ),
               ),
             ),
             const Divider(height: 1, thickness: 1, color: AppColors.border),
             Expanded(
               child: AnimatedBuilder(
                 animation: controller,
                 builder: (context, _) {
                   final sessions = controller.sessions;
                   if (sessions.isEmpty) {
                     return const Center(
                       child: Text('لا توجد محادثات سابقة', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                     );
                   }

                   return ListView.separated(
                     padding: const EdgeInsets.all(16),
                     physics: const BouncingScrollPhysics(),
                     itemCount: sessions.length,
                     separatorBuilder: (context, index) => const SizedBox(height: 10),
                     itemBuilder: (context, index) {
                       final session = sessions[index];
                       final isActive = session.id == controller.activeSession?.id;

                       return Material(
                         color: Colors.transparent,
                         child: InkWell(
                           onTap: () {
                              controller.openChat(session.id);
                              Navigator.pop(context);
                           },
                           borderRadius: BorderRadius.circular(14),
                           child: AnimatedContainer(
                             duration: const Duration(milliseconds: 200),
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                             decoration: BoxDecoration(
                               color: isActive ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
                               borderRadius: BorderRadius.circular(14),
                               border: Border.all(
                                  color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.border.withOpacity(0.5),
                               ),
                             ),
                             child: Row(
                               children: [
                                 Icon(
                                    isActive ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                                    size: 18,
                                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                                 ),
                                 const SizedBox(width: 12),
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         session.title,
                                         maxLines: 1,
                                         overflow: TextOverflow.ellipsis,
                                         style: TextStyle(
                                           color: isActive ? AppColors.primary : AppColors.textPrimary,
                                           fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                           fontSize: 14,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                                 if (!isActive)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                      onPressed: () => controller.deleteChat(session.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                               ],
                             ),
                           ),
                         ),
                       );
                     },
                   );
                 },
               ),
             ),
          ],
        ),
      ),
    );
  }
}
