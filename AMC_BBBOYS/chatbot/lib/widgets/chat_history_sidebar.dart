// lib/widgets/chat_history_sidebar.dart
import 'package:flutter/material.dart';
import '../models/expert.dart';
import '../models/conversation.dart';

class ChatHistorySidebar extends StatefulWidget {
  final Expert expert;
  final Function(String) onSelectConversation;
  final String? currentConversationId;
  final VoidCallback onNewChat;
  final Function(String, String) onRenameConversation;
  final Function(String) onDeleteConversation;
  final List<Conversation> conversations;
  final bool isLoading;

  const ChatHistorySidebar({
    super.key,
    required this.expert,
    required this.onSelectConversation,
    this.currentConversationId,
    required this.onNewChat,
    required this.onRenameConversation,
    required this.onDeleteConversation,
    required this.conversations,
    required this.isLoading,
  });

  @override
  State<ChatHistorySidebar> createState() => _ChatHistorySidebarState();
}

class _ChatHistorySidebarState extends State<ChatHistorySidebar> {
  String? _editingConversationId;
  final TextEditingController _renameController = TextEditingController();
  final isMobile = false; // Will be overridden in build

  void _startRename(Conversation conversation) {
    setState(() {
      _editingConversationId = conversation.id;
      _renameController.text = conversation.title;
    });
  }

  void _saveRename() async {
    if (_editingConversationId != null && _renameController.text.trim().isNotEmpty) {
      await widget.onRenameConversation(_editingConversationId!, _renameController.text.trim());
      setState(() => _editingConversationId = null);
    }
  }

  void _cancelRename() {
    setState(() => _editingConversationId = null);
  }

  void _showDeleteDialog(String conversationId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.onDeleteConversation(conversationId);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      width: isMobile ? double.infinity : (screenWidth < 900 ? 280 : 300),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: isMobile ? 36 : 40,
                  height: isMobile ? 36 : 40,
                  decoration: BoxDecoration(
                    color: widget.expert.color.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.expert.icon,
                    size: isMobile ? 18 : 20,
                    color: widget.expert.color,
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.expert.name,
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.conversations.length} conversations',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // New Chat Button
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: ElevatedButton.icon(
              onPressed: widget.onNewChat,
              icon: Icon(Icons.add_rounded, size: isMobile ? 18 : 20),
              label: Text(
                'New Chat',
                style: TextStyle(fontSize: isMobile ? 14 : 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.expert.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 12 : 14,
                  horizontal: isMobile ? 16 : 20,
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ),

          // Conversations List
          Expanded(
            child: widget.isLoading
                ? Center(
              child: CircularProgressIndicator(color: widget.expert.color),
            )
                : widget.conversations.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: isMobile ? 40 : 48,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    'Start a new chat to begin!',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
              itemCount: widget.conversations.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
              ),
              itemBuilder: (context, index) {
                final conversation = widget.conversations[index];
                final isSelected = conversation.id == widget.currentConversationId;
                final isEditing = _editingConversationId == conversation.id;

                if (isEditing) {
                  return _buildEditingItem(conversation, isDark, isMobile);
                }

                return _buildConversationItem(
                  conversation,
                  isSelected,
                  isDark,
                  isMobile,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(
      Conversation conversation,
      bool isSelected,
      bool isDark,
      bool isMobile,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? widget.expert.color.withOpacity(isDark ? 0.2 : 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 6 : 8,
        ),
        onTap: () => widget.onSelectConversation(conversation.id),
        leading: Container(
          width: isMobile ? 32 : 36,
          height: isMobile ? 32 : 36,
          decoration: BoxDecoration(
            color: isSelected
                ? widget.expert.color
                : (isDark ? const Color(0xFF1E293B) : Colors.grey[100]),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            size: isMobile ? 14 : 16,
            color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
        title: Text(
          conversation.title,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? widget.expert.color : (isDark ? Colors.white : Colors.black),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isMobile ? 1 : 2),
            Text(
              conversation.lastMessagePreview,
              style: TextStyle(
                fontSize: isMobile ? 10 : 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Row(
              children: [
                Text(
                  _formatDate(conversation.lastMessageTime),
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 10,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                SizedBox(width: isMobile ? 4 : 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 4 : 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(isMobile ? 3 : 4),
                  ),
                  child: Text(
                    '${conversation.messageCount} ${conversation.messageCount == 1 ? 'message' : 'messages'}',
                    style: TextStyle(
                      fontSize: isMobile ? 8 : 9,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isMobile
            ? null
            : PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            size: isMobile ? 16 : 18,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, size: 18),
                  const SizedBox(width: 8),
                  const Text('Rename'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'rename') {
              _startRename(conversation);
            } else if (value == 'delete') {
              _showDeleteDialog(conversation.id, conversation.title);
            }
          },
        ),
        onLongPress: isMobile
            ? () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text('Rename Conversation'),
                    onTap: () {
                      Navigator.pop(context);
                      _startRename(conversation);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    title: const Text('Delete Conversation', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteDialog(conversation.id, conversation.title);
                    },
                  ),
                ],
              ),
            ),
          );
        }
            : null,
      ),
    );
  }

  Widget _buildEditingItem(Conversation conversation, bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: widget.expert.color.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
      ),
      child: Column(
        children: [
          TextField(
            controller: _renameController,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Enter conversation title...',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                borderSide: BorderSide(color: widget.expert.color),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                borderSide: BorderSide(color: widget.expert.color, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 12,
                vertical: isMobile ? 8 : 10,
              ),
            ),
            autofocus: true,
            onSubmitted: (_) => _saveRename(),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelRename,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 6 : 8),
              ElevatedButton(
                onPressed: _saveRename,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.expert.color,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Save',
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}