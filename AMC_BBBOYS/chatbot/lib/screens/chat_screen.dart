import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_bar.dart';
import '../services/gemini_service.dart';
import '../services/chat_history_service.dart'; // Add this import
import 'dashboard_screen.dart';

class ChatScreen extends StatefulWidget {
  final Expert? expert;
  final VoidCallback? onClose;

  const ChatScreen({
    super.key,
    this.expert,
    this.onClose,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> messages = [];
  final ScrollController scrollController = ScrollController();
  bool _isLoading = false;
  int? _hoveredMessageIndex;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // Load chat history when opening chat
  Future<void> _loadChatHistory() async {
    if (widget.expert == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      final savedMessages = await ChatHistoryService.loadChat(widget.expert!.id);

      if (mounted) {
        setState(() {
          messages.addAll(savedMessages);
          _isLoadingHistory = false;
        });

        // Only add welcome message if no history exists
        if (savedMessages.isEmpty) {
          _addWelcomeMessage();
        } else {
          // Scroll to bottom if there's existing chat
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToBottom();
          });
        }
      }
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() => _isLoadingHistory = false);
      _addWelcomeMessage();
    }
  }

  // Save chat history whenever messages change
  Future<void> _saveChatHistory() async {
    if (widget.expert != null && messages.isNotEmpty) {
      await ChatHistoryService.saveChat(widget.expert!.id, messages);
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = '''
👋 Hello! I'm your ${widget.expert!.name.toLowerCase()}.

${widget.expert!.description}

How can I assist you today?''';

    addMessage(welcomeMessage, "model");
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void addMessage(String text, String role) {
    if (!mounted) return;
    setState(() {
      messages.add(ChatMessage(
        text: text,
        role: role,
        timestamp: DateTime.now(),
      ));
    });
    scrollToBottom();
    // Save after adding message
    _saveChatHistory();
  }

  void deleteMessage(int index) {
    if (index < 0 || index >= messages.length) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (mounted) {
                setState(() {
                  messages.removeAt(index);
                });
                // Save after deletion
                await _saveChatHistory();
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> handleSend(String text) async {
    if (text.trim().isEmpty) return;

    addMessage(text, "user");
    setState(() => _isLoading = true);

    try {
      // Include expert prompt + all messages for context
      final fullMessages = [
        if (widget.expert != null)
          ChatMessage(
            text: widget.expert!.prompt,
            role: "user",
            timestamp: DateTime.now(),
          ),
        ...messages,
      ];

      final aiResponse = await GeminiService.sendMultiTurnMessage(fullMessages);
      addMessage(aiResponse, "model");
    } catch (e) {
      addMessage('❌ Error: $e', "model");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Clear all messages for current expert
  Future<void> _clearAllMessages() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Messages'),
        content: const Text('Are you sure you want to delete all messages in this chat? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (mounted) {
                setState(() {
                  messages.clear();
                });
                // Clear from storage
                if (widget.expert != null) {
                  await ChatHistoryService.clearChat(widget.expert!.id);
                }
                // Add welcome message
                if (widget.expert != null) {
                  _addWelcomeMessage();
                }
              }
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final hasExpert = widget.expert != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        leading: widget.onClose != null
            ? IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () async {
            // Save before closing
            await _saveChatHistory();
            widget.onClose?.call();
          },
        )
            : null,
        title: hasExpert
            ? Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.expert!.color.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.expert!.icon,
                size: 18,
                color: widget.expert!.color,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.expert!.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  widget.expert!.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        )
            : Text(
          '🤖 AI Assistant',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          // Clear All Button
          if (messages.isNotEmpty && !_isLoadingHistory)
            IconButton(
              onPressed: _clearAllMessages,
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              tooltip: 'Clear all messages',
            ),

          const SizedBox(width: 8),

          if (hasExpert)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF475569) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isLoadingHistory ? Colors.amber : const Color(0xFF34A853),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isLoadingHistory ? Colors.amber : const Color(0xFF34A853))
                              .withOpacity(isDark ? 0.8 : 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isLoadingHistory ? 'Loading...' : 'Saved',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _isLoadingHistory
                          ? Colors.amber
                          : (isDark ? Colors.green[300] : const Color(0xFF1A73E8)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? _buildLoadingHistory(isDark)
                : (messages.isEmpty && hasExpert
                ? _buildEmptyState(isDark)
                : Container(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onLongPress: () => deleteMessage(index),
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hoveredMessageIndex = index),
                      onExit: (_) => setState(() => _hoveredMessageIndex = null),
                      child: MessageBubble(
                        message: messages[index],
                        onDelete: () => deleteMessage(index),
                        showDelete: _hoveredMessageIndex == index,
                      ),
                    ),
                  );
                },
              ),
            )),
          ),

          if (_isLoading) _buildLoadingIndicator(isDark),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: InputBar(onSendMessage: handleSend),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHistory(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: widget.expert?.color ?? const Color(0xFF1A73E8),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading chat history...',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    if (widget.expert == null) {
      return const Center(
        child: Text('No expert selected'),
      );
    }

    return Container(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: widget.expert!.color.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.expert!.icon,
                  size: 48,
                  color: widget.expert!.color,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.expert!.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.expert!.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF475569) : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Chat ID: ${widget.expert!.id}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chat automatically saves!',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
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

  Widget _buildLoadingIndicator(bool isDark) {
    final expertName = widget.expert?.name.split(' ').first ?? 'AI';
    final color = widget.expert?.color ?? const Color(0xFF1A73E8);

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(2),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$expertName is thinking...',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey[300] : color,
            ),
          ),
        ],
      ),
    );
  }
}