import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/expert.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_bar.dart';
import '../widgets/chat_history_sidebar.dart';
import '../services/gemini_service.dart';
import '../services/chat_history_service.dart';
import '../widgets/persona_switcher.dart';
import '../widgets/persona_switch_dialog.dart';

class ChatScreen extends StatefulWidget {
  final Expert? expert;
  final VoidCallback? onClose;
  final String? initialConversationId;
  final List<Expert>? allExperts;
  final Function(Expert)? onExpertChanged;

  const ChatScreen({
    super.key,
    this.expert,
    this.onClose,
    this.initialConversationId,
    this.allExperts,
    this.onExpertChanged,
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
  bool _isLoadingConversations = true;

  String? _currentConversationId;
  bool _showHistorySidebar = true;
  List<Conversation> _conversations = [];

  // Editing state
  int? _editingMessageIndex;
  final TextEditingController _editTextController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.initialConversationId;
    _loadConversations().then((_) {
      if (_currentConversationId == null && widget.expert != null) {
        _openLatestConversation();
      } else {
        _loadChatHistory();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    _editTextController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    if (widget.expert == null) {
      setState(() => _isLoadingConversations = false);
      return;
    }

    setState(() => _isLoadingConversations = true);
    final conversations = await ChatHistoryService.getConversationsByExpert(widget.expert!.id);
    if (mounted) {
      setState(() {
        _conversations = conversations;
        _isLoadingConversations = false;
      });
    }
  }

  Future<void> _openLatestConversation() async {
    if (widget.expert == null || _conversations.isEmpty) {
      setState(() => _isLoadingHistory = false);
      _addWelcomeMessage();
      return;
    }

    final latestConversation = _conversations.firstWhere(
          (c) => c.expertId == widget.expert!.id,
      orElse: () => _conversations.isNotEmpty ? _conversations.first : Conversation(
        id: '',
        expertId: widget.expert!.id,
        title: 'New Chat',
        lastMessageTime: DateTime.now(),
        lastMessagePreview: '',
        messageCount: 0,
      ),
    );

    if (latestConversation.id.isNotEmpty) {
      await _switchConversation(latestConversation.id);
    } else {
      setState(() => _isLoadingHistory = false);
      _addWelcomeMessage();
    }
  }

  Future<void> _loadChatHistory() async {
    if (widget.expert == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      if (_currentConversationId != null) {
        final savedMessages = await ChatHistoryService.loadChat(
          widget.expert!.id,
          _currentConversationId!,
        );

        if (mounted) {
          setState(() {
            messages.clear();
            messages.addAll(savedMessages);
            _isLoadingHistory = false;
          });

          if (savedMessages.isEmpty) {
            _addWelcomeMessage();
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              scrollToBottom();
            });
          }
        }
      } else {
        setState(() => _isLoadingHistory = false);
        _addWelcomeMessage();
      }
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() => _isLoadingHistory = false);
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() async {
    if (messages.isNotEmpty && messages.any((m) => m.text.contains("Hello! I'm your"))) {
      return;
    }

    final welcomeMessage = '''
👋 Hello! I'm your ${widget.expert!.name.toLowerCase()}.

${widget.expert!.description}

How can I assist you today?''';

    addMessage(welcomeMessage, "model", isInitialMessage: true);
  }

  Future<void> addMessage(String text, String role, {bool isInitialMessage = false, bool skipSave = false}) async {
    if (!mounted) return;

    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

    setState(() {
      messages.add(ChatMessage(
        text: text,
        role: role,
        timestamp: DateTime.now(),
        id: messageId,
        isEdited: false,
      ));
    });

    scrollToBottom();

    if (!skipSave && widget.expert != null && messages.isNotEmpty) {
      final conversation = await ChatHistoryService.saveChat(
        widget.expert!.id,
        messages,
        conversationId: _currentConversationId,
      );

      if (_currentConversationId == null) {
        setState(() {
          _currentConversationId = conversation.id;
        });
      }

      await _loadConversations();
    }
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

  Future<void> _switchToNewPersona(Expert newExpert) async {
    if (newExpert.id == widget.expert?.id) return;

    await _saveCurrentConversation();

    PersonaSwitchChoice? choice = PersonaSwitchChoice.continueChat;

    if (messages.isNotEmpty && messages.any((m) => m.isUserMessage)) {
      choice = await showDialog<PersonaSwitchChoice>(
        context: context,
        builder: (context) => PersonaSwitchDialog(
          currentExpert: widget.expert!,
          newExpert: newExpert,
        ),
      );
    }

    if (choice == null) return;

    if (choice == PersonaSwitchChoice.newChat) {
      setState(() {
        messages.clear();
      });
      _addWelcomeMessageForExpert(newExpert);
    } else {
      if (messages.isNotEmpty && messages.last.isUserMessage) {
        await _getResponseWithNewPersona(newExpert);
      }
    }

    widget.onExpertChanged?.call(newExpert);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${newExpert.name}'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            widget.onExpertChanged?.call(widget.expert!);
          },
        ),
      ),
    );
  }

  void _addWelcomeMessageForExpert(Expert expert) {
    final welcomeMessage = '''
👋 Hello! I'm your ${expert.name}.

${expert.description}

How can I assist you today?''';

    addMessage(welcomeMessage, "model", isInitialMessage: true, skipSave: true);
  }

  Future<void> _getResponseWithNewPersona(Expert newExpert) async {
    if (messages.isEmpty || !messages.last.isUserMessage) return;

    setState(() => _isLoading = true);

    try {
      final lastUserMessage = messages.last;
      final conversationHistory = [
        ChatMessage(
          text: newExpert.prompt,
          role: "user",
          timestamp: DateTime.now(),
        ),
        ...messages,
      ];

      final aiResponse = await GeminiService.sendMultiTurnMessage(conversationHistory);
      await addMessage(aiResponse, "model");
    } catch (e) {
      print('Error getting response with new persona: $e');
      await addMessage('I\'m now ${newExpert.name}. How can I help you?', "model");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEditingMessage(int index) {
    if (index < 0 || index >= messages.length) return;
    if (!messages[index].isUserMessage) return;

    final hasAIResponsesAfter = messages.asMap().entries.any(
            (entry) => entry.key > index && !entry.value.isUserMessage
    );

    if (hasAIResponsesAfter) {
      _showEditConfirmationDialog(index);
    } else {
      _startEditingDirectly(index);
    }
  }

  void _startEditingDirectly(int index) {
    setState(() {
      _editingMessageIndex = index;
      _editTextController.text = messages[index].text;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  void _showEditConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editing this message will:'),
            SizedBox(height: 8),
            Text('• Update your message'),
            Text('• Remove all AI responses after this point'),
            Text('• Generate new AI response'),
            SizedBox(height: 12),
            Text('Do you want to continue?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startEditingDirectly(index);
            },
            child: const Text('Edit & Regenerate'),
          ),
        ],
      ),
    );
  }

  void _saveEditedMessage() {
    if (_editingMessageIndex == null) return;

    final index = _editingMessageIndex!;
    final newText = _editTextController.text.trim();

    if (newText.isEmpty) {
      _cancelEditing();
      return;
    }

    if (messages[index].isUserMessage && newText != messages[index].text) {
      _regenerateAIResponseFromIndex(index, newText);
    } else {
      setState(() {
        messages[index] = messages[index].copyWith(
          text: newText,
          isEdited: true,
          timestamp: DateTime.now(),
        );
      });
      _saveCurrentConversation();
    }

    _cancelEditing();
  }

  Future<void> _regenerateAIResponseFromIndex(int editedMessageIndex, String newText) async {
    if (widget.expert == null) return;

    setState(() => _isLoading = true);

    try {
      messages[editedMessageIndex] = messages[editedMessageIndex].copyWith(
        text: newText,
        isEdited: true,
        timestamp: DateTime.now(),
      );

      int i = editedMessageIndex + 1;
      while (i < messages.length) {
        if (!messages[i].isUserMessage) {
          messages.removeAt(i);
        } else {
          i++;
        }
      }

      final conversationHistory = [
        ChatMessage(
          text: widget.expert!.prompt,
          role: "user",
          timestamp: DateTime.now(),
        ),
        ...messages,
      ];

      final aiResponse = await GeminiService.sendMultiTurnMessage(conversationHistory);
      await addMessage(aiResponse, "model");

      await _saveCurrentConversation();

    } catch (e) {
      print('Error regenerating AI response: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to regenerate AI response: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _editingMessageIndex = null;
      _editTextController.clear();
    });
    _editFocusNode.unfocus();
  }

  void deleteMessage(int index) {
    if (index < 0 || index >= messages.length) return;

    final isUserMessage = messages[index].isUserMessage;
    final hasAIResponsesAfter = messages.asMap().entries.any(
            (entry) => entry.key > index && !entry.value.isUserMessage
    );

    if (isUserMessage && hasAIResponsesAfter) {
      _showDeleteWithRegenerationDialog(index);
    } else {
      _showSimpleDeleteDialog(index);
    }
  }

  void _showDeleteWithRegenerationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deleting this user message will:'),
            SizedBox(height: 8),
            Text('• Remove this message'),
            Text('• Remove all AI responses after this point'),
            Text('• Continue from remaining conversation'),
            SizedBox(height: 12),
            Text('Do you want to continue?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMessageAndRegenerate(index);
            },
            child: const Text('Delete & Continue'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMessageAndClearAfter(index);
            },
            child: const Text('Delete All After'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showSimpleDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: Text('Are you sure you want to delete "${messages[index].text.length > 30 ? '${messages[index].text.substring(0, 30)}...' : messages[index].text}"?'),
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
                await _saveCurrentConversation();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Message deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
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

  Future<void> _deleteMessageAndRegenerate(int index) async {
    if (widget.expert == null) return;

    setState(() => _isLoading = true);

    try {
      messages.removeAt(index);

      int i = index;
      while (i < messages.length) {
        if (!messages[i].isUserMessage) {
          messages.removeAt(i);
        } else {
          i++;
        }
      }

      if (messages.isNotEmpty && messages.last.isUserMessage) {
        final conversationHistory = [
          ChatMessage(
            text: widget.expert!.prompt,
            role: "user",
            timestamp: DateTime.now(),
          ),
          ...messages,
        ];

        final aiResponse = await GeminiService.sendMultiTurnMessage(conversationHistory);
        await addMessage(aiResponse, "model");
      }

      await _saveCurrentConversation();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Message deleted and conversation updated'),
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      print('Error regenerating after delete: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteMessageAndClearAfter(int index) async {
    try {
      if (mounted) {
        setState(() {
          messages.removeRange(index, messages.length);
        });
        await _saveCurrentConversation();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Messages deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deleting messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _copyMessageText(int index) {
    if (index < 0 || index >= messages.length) return;

    final text = messages[index].text;

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Message copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                _copyMessageText(index);
              },
            ),

            if (messages[index].isUserMessage)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  _startEditingMessage(index);
                },
              ),

            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                deleteMessage(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleSend(String text) async {
    if (text.trim().isEmpty) return;

    await addMessage(text, "user");
    setState(() => _isLoading = true);

    try {
      final conversationHistory = [
        ChatMessage(
          text: widget.expert!.prompt,
          role: "user",
          timestamp: DateTime.now(),
        ),
        ...messages,
      ];

      final aiResponse = await GeminiService.sendMultiTurnMessage(conversationHistory);
      await addMessage(aiResponse, "model");
    } catch (e) {
      print('Error in handleSend: $e');
      await addMessage('❌ Error: $e', "model");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCurrentConversation() async {
    try {
      if (widget.expert != null && messages.isNotEmpty) {
        await ChatHistoryService.saveChat(
          widget.expert!.id,
          messages,
          conversationId: _currentConversationId,
        );
      } else if (messages.isEmpty && _currentConversationId != null && widget.expert != null) {
        await ChatHistoryService.saveChat(
          widget.expert!.id,
          [],
          conversationId: _currentConversationId,
        );
      }
    } catch (e) {
      print('❌ Error saving conversation: $e');
    }
  }

  Future<void> _switchConversation(String conversationId) async {
    if (conversationId == _currentConversationId) return;

    await _saveCurrentConversation();

    setState(() {
      messages.clear();
      _currentConversationId = conversationId;
      _isLoadingHistory = true;
    });

    await _loadChatHistory();
    await _loadConversations();
  }

  Future<void> _startNewChat() async {
    await _saveCurrentConversation();

    setState(() {
      messages.clear();
      _currentConversationId = null;
      _isLoadingHistory = false;
    });

    _addWelcomeMessage();
    await _loadConversations();
  }

  Future<void> _renameConversation(String conversationId, String newTitle) async {
    await ChatHistoryService.renameConversation(conversationId, newTitle);
    await _loadConversations();
  }

  Future<void> _deleteConversation(String conversationId) async {
    if (widget.expert == null) return;

    if (conversationId == _currentConversationId) {
      await _startNewChat();
    }

    await ChatHistoryService.deleteConversation(widget.expert!.id, conversationId);
    await _loadConversations();
  }

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
                await _saveCurrentConversation();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ All messages cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
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
    final hasExpert = widget.expert != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isVerySmall = screenWidth < 350;

    final isEditing = _editingMessageIndex != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1C) : const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A2236) : Colors.white,
        leading: widget.onClose != null && !isMobile
            ? Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A3448) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              size: 22,
            ),
            onPressed: () async {
              await _saveCurrentConversation();
              widget.onClose?.call();
            },
          ),
        )
            : null,
        title: hasExpert
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.expert!.color,
                    Color.lerp(widget.expert!.color, Colors.white, 0.3)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.expert!.color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.expert!.icon,
                size: 18,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.expert!.name,
                    style: TextStyle(
                      fontSize: isVerySmall ? 14 : (isMobile ? 15 : 16),
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (!isMobile && screenWidth > 450)
                    Text(
                      _currentConversationId != null && _conversations.isNotEmpty
                          ? _conversations
                          .firstWhere(
                            (c) => c.id == _currentConversationId,
                        orElse: () => Conversation(
                          id: '',
                          expertId: '',
                          title: 'New Chat',
                          lastMessageTime: DateTime.now(),
                          lastMessagePreview: '',
                          messageCount: 0,
                        ),
                      )
                          .title
                          : 'New Chat',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ],
        )
            : Text(
          '🤖 AI Assistant',
          style: TextStyle(
            fontSize: isMobile ? 17 : 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          // Cancel edit button
          if (isEditing)
            TextButton(
              onPressed: _cancelEditing,
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 12),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: isVerySmall ? 12 : 14,
                ),
              ),
            ),

          // Save edit button
          if (isEditing)
            TextButton(
              onPressed: _saveEditedMessage,
              style: TextButton.styleFrom(
                foregroundColor: widget.expert?.color ?? const Color(0xFF1A73E8),
                padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 12),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: isVerySmall ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Persona Switcher
          if (!isEditing && widget.allExperts != null && widget.allExperts!.isNotEmpty && hasExpert)
            Padding(
              padding: EdgeInsets.only(right: isVerySmall ? 4 : (isMobile ? 6 : 8)),
              child: PersonaSwitcher(
                experts: widget.allExperts!,
                currentExpert: widget.expert!,
                onExpertChanged: _switchToNewPersona,
                isMobile: isMobile,
              ),
            ),

          // History toggle button
          if (hasExpert && !isMobile && !isEditing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A3448) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _showHistorySidebar ? Icons.menu_open_rounded : Icons.menu_rounded,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showHistorySidebar = !_showHistorySidebar;
                  });
                },
                tooltip: _showHistorySidebar ? 'Hide history' : 'Show history',
                padding: EdgeInsets.all(isVerySmall ? 8 : 10),
              ),
            ),

          // Message count
          if (_currentConversationId != null && !isMobile && !isEditing)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A3448) : const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF3A4458) : const Color(0xFFD0DAF0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    size: 12,
                    color: widget.expert?.color,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${messages.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : widget.expert?.color,
                    ),
                  ),
                ],
              ),
            ),

          // Clear button
          if (messages.isNotEmpty && !_isLoadingHistory && !isMobile && !isEditing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A3448) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _clearAllMessages,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                tooltip: 'Clear all messages',
                padding: EdgeInsets.all(isVerySmall ? 8 : 10),
              ),
            ),
        ],
        toolbarHeight: isMobile ? 56 : 64,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0F1C),
              const Color(0xFF131A2D),
            ],
          )
              : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8FAFF),
              const Color(0xFFF0F5FF),
            ],
          ),
        ),
        child: Column(
          children: [
            // Editing bar
            if (isEditing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0FE),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFD0DAF0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: widget.expert?.color ?? const Color(0xFF1A73E8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing message...',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: Row(
                children: [
                  // Sidebar
                  if (_showHistorySidebar && hasExpert && !isMobile && !isEditing)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _showHistorySidebar ? (screenWidth < 900 ? 260 : 280) : 0,
                      child: ClipRRect(
                        child: ChatHistorySidebar(
                          expert: widget.expert!,
                          onSelectConversation: _switchConversation,
                          currentConversationId: _currentConversationId,
                          onNewChat: _startNewChat,
                          onRenameConversation: _renameConversation,
                          onDeleteConversation: _deleteConversation,
                          conversations: _conversations,
                          isLoading: _isLoadingConversations,
                        ),
                      ),
                    ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: !isMobile && _showHistorySidebar
                            ? Border(
                          left: BorderSide(
                            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                            width: 1,
                          ),
                        )
                            : null,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: _isLoadingHistory
                                ? _buildLoadingHistory(isDark)
                                : (messages.isEmpty && hasExpert && _currentConversationId == null
                                ? _buildEmptyState(isDark, isMobile, isVerySmall)
                                : Container(
                              child: Column(
                                children: [
                                  // Edit input field
                                  if (isEditing)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1A2236) : Colors.white,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: isDark ? const Color(0xFF2A3448) : Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0A0F1C) : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: widget.expert?.color ?? const Color(0xFF1A73E8),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (widget.expert?.color ?? const Color(0xFF1A73E8))
                                                  .withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _editTextController,
                                          focusNode: _editFocusNode,
                                          style: TextStyle(
                                            fontSize: isVerySmall ? 14 : 15,
                                            color: isDark ? Colors.white : Colors.black,
                                            height: 1.4,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Edit your message...',
                                            hintStyle: TextStyle(
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                Icons.send_rounded,
                                                color: widget.expert?.color ?? const Color(0xFF1A73E8),
                                                size: 20,
                                              ),
                                              onPressed: _saveEditedMessage,
                                              padding: const EdgeInsets.only(right: 12),
                                            ),
                                          ),
                                          maxLines: 3,
                                          minLines: 1,
                                          onSubmitted: (_) => _saveEditedMessage(),
                                        ),
                                      ),
                                    ),

                                  // Messages list
                                  Expanded(
                                    child: messages.isEmpty
                                        ? _buildEmptyChatState(isDark, isMobile)
                                        : Container(
                                      decoration: BoxDecoration(
                                        gradient: isDark
                                            ? LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.02),
                                          ],
                                        )
                                            : null,
                                      ),
                                      child: ListView.builder(
                                        controller: scrollController,
                                        padding: EdgeInsets.only(
                                          top: isVerySmall ? 12 : (isMobile ? 14 : 16),
                                          bottom: isVerySmall ? 12 : (isMobile ? 14 : 16),
                                          left: isVerySmall ? 8 : (isMobile ? 12 : 16),
                                          right: isVerySmall ? 8 : (isMobile ? 12 : 16),
                                        ),
                                        itemCount: messages.length,
                                        itemBuilder: (context, index) {
                                          final message = messages[index];
                                          final isEditingThis = isEditing && _editingMessageIndex == index;

                                          if (isEditingThis) {
                                            return Container();
                                          }

                                          return GestureDetector(
                                            onLongPress: () {
                                              _showMessageOptions(context, index);
                                            },
                                            child: MouseRegion(
                                              onEnter: (_) => !isMobile
                                                  ? setState(() => _hoveredMessageIndex = index)
                                                  : null,
                                              onExit: (_) => !isMobile
                                                  ? setState(() => _hoveredMessageIndex = null)
                                                  : null,
                                              child: MessageBubble(
                                                message: message,
                                                onDelete: () => deleteMessage(index),
                                                onEdit: message.isUserMessage
                                                    ? () => _startEditingMessage(index)
                                                    : null,
                                                showDelete: !isMobile && _hoveredMessageIndex == index,
                                                isMobile: isMobile,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ),
                          if (_isLoading && !isEditing)
                            _buildLoadingIndicator(isDark, isMobile, isVerySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Input bar
            if (!isEditing)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2236) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF2A3448) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: InputBar(onSendMessage: handleSend),
                ),
              ),
          ],
        ),
      ),

      // Mobile history drawer
      endDrawer: isMobile && hasExpert && !isEditing
          ? Drawer(
        width: screenWidth * 0.85,
        child: ChatHistorySidebar(
          expert: widget.expert!,
          onSelectConversation: (conversationId) {
            _switchConversation(conversationId);
            Navigator.pop(context);
          },
          currentConversationId: _currentConversationId,
          onNewChat: () {
            _startNewChat();
            Navigator.pop(context);
          },
          onRenameConversation: _renameConversation,
          onDeleteConversation: _deleteConversation,
          conversations: _conversations,
          isLoading: _isLoadingConversations,
        ),
      )
          : null,

      // Mobile floating action button for history
      floatingActionButton: isMobile && hasExpert && !isEditing
          ? FloatingActionButton(
        onPressed: () => Scaffold.of(context).openEndDrawer(),
        backgroundColor: widget.expert!.color,
        child: Icon(Icons.history_rounded, color: Colors.white, size: 22),
        elevation: 4,
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLoadingHistory(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A3448) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: widget.expert?.color ?? const Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading conversation...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool isMobile, bool isVerySmall) {
    if (widget.expert == null) {
      return const Center(
        child: Text('No expert selected'),
      );
    }

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 16 : (isMobile ? 24 : 32)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isVerySmall ? 80 : (isMobile ? 100 : 120),
              height: isVerySmall ? 80 : (isMobile ? 100 : 120),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.expert!.color,
                    Color.lerp(widget.expert!.color, Colors.white, 0.3)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.expert!.color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.expert!.icon,
                size: isVerySmall ? 32 : (isMobile ? 40 : 48),
                color: Colors.white,
              ),
            ),
            SizedBox(height: isVerySmall ? 16 : (isMobile ? 20 : 24)),
            Text(
              widget.expert!.name,
              style: TextStyle(
                fontSize: isVerySmall ? 20 : (isMobile ? 24 : 28),
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isVerySmall ? 8 : (isMobile ? 10 : 12)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A3448) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.expert!.description,
                style: TextStyle(
                  fontSize: isVerySmall ? 12 : (isMobile ? 13 : 14),
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: isVerySmall ? 24 : (isMobile ? 32 : 40)),
            Text(
              'Send a message to start chatting!',
              style: TextStyle(
                fontSize: isVerySmall ? 13 : (isMobile ? 14 : 15),
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatState(bool isDark, bool isMobile) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation below',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDark, bool isMobile, bool isVerySmall) {
    final expertName = widget.expert?.name.split(' ').first ?? 'AI';
    final color = widget.expert?.color ?? const Color(0xFF1A73E8);

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 10 : (isMobile ? 12 : 16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark ? const Color(0xFF131A2D).withOpacity(0.8) : const Color(0xFFF0F5FF).withOpacity(0.8),
            isDark ? const Color(0xFF0A0F1C) : const Color(0xFFF8FAFF),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A3448) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isVerySmall ? 14 : (isMobile ? 16 : 18),
            height: isVerySmall ? 14 : (isMobile ? 16 : 18),
            padding: EdgeInsets.all(isVerySmall ? 1 : 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: isVerySmall ? 1.5 : 2,
              color: color,
            ),
          ),
          SizedBox(width: isVerySmall ? 6 : (isMobile ? 8 : 12)),
          Text(
            '$expertName is thinking...',
            style: TextStyle(
              fontSize: isVerySmall ? 12 : (isMobile ? 13 : 14),
              fontStyle: FontStyle.italic,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}