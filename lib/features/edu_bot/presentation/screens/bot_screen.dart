import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/bot_remote_service.dart';
import '../../data/repositories/bot_repository.dart';
import '../controllers/bot_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/empty_state.dart';

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  late final BotController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final remoteService = BotRemoteService();
    final repository = BotRepository(remoteService);
    _controller = BotController(repository);
    
    _controller.addListener(_scrollToBottomIfNeed);
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollToBottomIfNeed);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToBottomIfNeed() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _unfocus() => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Edu Bot',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.messages.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.cleaning_services_rounded, color: AppColors.textSecondary, size: 22),
                onPressed: () => _controller.clearChat(),
                tooltip: 'مسح المحادثة',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border.withOpacity(0.5), 
            height: 1,
            boxShadow: [
               BoxShadow(color: AppColors.textPrimary.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onTap: _unfocus,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              children: [
                Expanded(
                  child: _controller.messages.isEmpty && !_controller.isSending
                      ? EmptyState(
                          onSuggestionTap: (suggestion) => _controller.sendMessage(suggestion),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          itemCount: _controller.messages.length + (_controller.isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _controller.messages.length) {
                              return const TypingIndicator();
                            }
                            return MessageBubble(
                              message: _controller.messages[index],
                              onRetry: () => _controller.retryMessage(_controller.messages[index].id),
                            );
                          },
                        ),
                ),
                MessageInput(
                  onSend: _controller.sendMessage,
                  isSending: _controller.isSending,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
