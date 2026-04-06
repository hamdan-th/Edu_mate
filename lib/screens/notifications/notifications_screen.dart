import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NotificationsPlaceholderScreen extends StatelessWidget {
  const NotificationsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_rounded, color: Colors.white.withOpacity(0.2), size: 64),
            const SizedBox(height: 16),
            Text('No notifications yet', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('We\'ll let you know when something happens.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
