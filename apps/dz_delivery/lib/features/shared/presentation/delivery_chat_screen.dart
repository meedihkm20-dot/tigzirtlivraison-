import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/theme/app_colors.dart';
import '../../../core/design_system/theme/app_typography.dart';
import '../../../core/design_system/theme/app_spacing.dart';
import '../../../core/services/delivery_chat_service.dart';

/// Écran de chat pour la communication livreur-client
class DeliveryChatScreen extends StatefulWidget {
  final String orderId;
  final String userType; // 'livreur' ou 'customer'
  final String? otherUserName;
  
  const DeliveryChatScreen({
    super.key,
    required this.orderId,
    required this.userType,
    this.otherUserName,
  });

  @override
  State<DeliveryChatScreen> createState() => _DeliveryChatScreenState();
}

class _DeliveryChatScreenState extends State<DeliveryChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<DeliveryMessage> _messages = [];
  StreamSubscription? _messagesSubscription;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToMessages();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await DeliveryChatService.getMessageHistory(widget.orderId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToMessages() {
    _messagesSubscription = DeliveryChatService.listenToMessages(widget.orderId)
        .listen((messages) {
      if (mounted) {
        setState(() => _messages = messages);
        _scrollToBottom();
        _markMessagesAsRead();
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    await DeliveryChatService.markMessagesAsRead(
      orderId: widget.orderId,
      userType: widget.userType,
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    
    try {
      await DeliveryChatService.sendMessage(
        orderId: widget.orderId,
        message: message.trim(),
        senderType: widget.userType,
      );
      
      _messageController.clear();
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur envoi message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLivreur = widget.userType == 'livreur';
    final primaryColor = isLivreur ? AppColors.livreurPrimary : AppColors.clientPrimary;
    final otherUserName = widget.otherUserName ?? (isLivreur ? 'Client' : 'Livreur');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat avec $otherUserName',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            Text(
              'Commande #${widget.orderId.substring(0, 8)}',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showChatInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: AppSpacing.screen,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                      ),
          ),
          
          // Messages rapides
          _buildQuickMessages(),
          
          // Zone de saisie
          _buildMessageInput(primaryColor),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: AppTypography.titleMedium.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez la conversation avec ${widget.userType == 'livreur' ? 'le client' : 'votre livreur'}',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DeliveryMessage message) {
    final isMyMessage = message.senderType == widget.userType;
    final primaryColor = widget.userType == 'livreur' ? AppColors.livreurPrimary : AppColors.clientPrimary;

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMyMessage ? primaryColor : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                  bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: AppTypography.bodyMedium.copyWith(
                  color: isMyMessage ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.formattedTime,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
                if (isMyMessage) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead ? primaryColor : AppColors.textTertiary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMessages() {
    final quickMessages = widget.userType == 'livreur' 
        ? DeliveryChatService.quickMessages
        : DeliveryChatService.customerQuickMessages;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickMessages.length,
        itemBuilder: (context, index) {
          final message = quickMessages[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                message,
                style: AppTypography.bodySmall,
              ),
              onPressed: () => _sendMessage(message),
              backgroundColor: AppColors.surfaceVariant,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput(Color primaryColor) {
    return Container(
      padding: AppSpacing.screen,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tapez votre message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Informations du chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commande: #${widget.orderId.substring(0, 8)}'),
            const SizedBox(height: 8),
            Text('Messages: ${_messages.length}'),
            const SizedBox(height: 16),
            const Text(
              'Conseils:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Soyez poli et respectueux'),
            const Text('• Utilisez les messages rapides'),
            const Text('• Communiquez clairement'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}