// lib/widgets/message_bubble.dart - Enhanced with better visuals
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool showDelete;
  final bool isMobile;

  const MessageBubble({
    Key? key,
    required this.message,
    this.onDelete,
    this.onEdit,
    this.showDelete = false,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = message.isUserMessage;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 14 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser && !isMobile)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                      : [const Color(0xFFE8F0FE), const Color(0xFFD2E3FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: isDark ? colorScheme.primary : const Color(0xFF1A73E8),
              ),
            ),

          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Message Container
                Stack(
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? MediaQuery.of(context).size.width * 0.82 : 680,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 14,
                        horizontal: isMobile ? 16 : 18,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUser
                              ? isDark
                              ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                              : [const Color(0xFF1A73E8), const Color(0xFF0D62FF)]
                              : isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [Colors.white, const Color(0xFFF8FAFD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : (isMobile ? 10 : 6)),
                          bottomRight: Radius.circular(isUser ? (isMobile ? 10 : 6) : 20),
                        ),
                        border: Border.all(
                          color: isDark && !isUser
                              ? const Color(0xFF334155)
                              : isUser
                              ? Colors.transparent
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          isUser
                              ? Text(
                            message.text,
                            style: TextStyle(
                              fontSize: isMobile ? 14.5 : 15.5,
                              height: 1.6,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                              : SelectionArea(
                            child: Text(
                              message.text,
                              style: TextStyle(
                                fontSize: isMobile ? 14.5 : 15.5,
                                height: 1.6,
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          if (message.isEdited)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '(edited)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: isUser
                                      ? Colors.white.withOpacity(0.7)
                                      : (isDark ? Colors.grey[400] : Colors.grey[500]),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Action buttons
                    if (showDelete && (onDelete != null || onEdit != null) && !isMobile)
                      Positioned(
                        top: 6,
                        right: isUser ? 6 : null,
                        left: isUser ? null : 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withOpacity(0.6) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              if (onEdit != null && isUser)
                                _buildActionButton(
                                  context: context,
                                  icon: Icons.edit_rounded,
                                  onTap: onEdit!,
                                  isDark: isDark,
                                  tooltip: 'Edit',
                                ),
                              if (onEdit != null && onDelete != null) const SizedBox(width: 2),
                              if (onDelete != null)
                                _buildActionButton(
                                  context: context,
                                  icon: Icons.delete_outline_rounded,
                                  onTap: onDelete!,
                                  isDark: isDark,
                                  tooltip: 'Delete',
                                ),
                              if (!isUser)
                                _buildActionButton(
                                  context: context,
                                  icon: Icons.content_copy_rounded,
                                  onTap: () => _copyToClipboard(context, message.text),
                                  isDark: isDark,
                                  tooltip: 'Copy',
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Timestamp and inline actions
                Padding(
                  padding: EdgeInsets.only(right: isUser ? (isMobile ? 6 : 10) : 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('h:mm a').format(message.timestamp),
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Inline action buttons for mobile
                      if ((onDelete != null || onEdit != null) && (showDelete || isMobile))
                        Row(
                          children: [
                            const SizedBox(width: 6),
                            if (onEdit != null && isUser)
                              _buildInlineActionButton(
                                icon: Icons.edit_outlined,
                                onTap: onEdit,
                                isDark: isDark,
                                isMobile: isMobile,
                              ),
                            if (onDelete != null)
                              _buildInlineActionButton(
                                icon: Icons.delete_outline_rounded,
                                onTap: onDelete,
                                isDark: isDark,
                                isMobile: isMobile,
                              ),
                            if (!isUser)
                              _buildInlineActionButton(
                                icon: Icons.content_copy_outlined,
                                onTap: () => _copyToClipboard(context, message.text),
                                isDark: isDark,
                                isMobile: isMobile,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isUser && !isMobile)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                      : [const Color(0xFFE8F0FE), const Color(0xFFD2E3FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: isDark ? colorScheme.primary : const Color(0xFF1A73E8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
    required bool isMobile,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: EdgeInsets.all(isMobile ? 3 : 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: isMobile ? 12 : 13,
          color: isDark ? Colors.grey[300] : Colors.grey[600],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));

    // Enhanced snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 20),
            const SizedBox(width: 8),
            const Text('Copied to clipboard'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 8,
      ),
    );
  }
}