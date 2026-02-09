// lib/widgets/input_bar.dart - Use default config first
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class InputBar extends StatefulWidget {
  final Function(String) onSendMessage;
  const InputBar({Key? key, required this.onSendMessage}) : super(key: key);

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _textController = TextEditingController();
  bool _isHasText = false;
  bool _showEmoji = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _isHasText = _textController.text.trim().isNotEmpty;
      });
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmoji = false);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Emoji button
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showEmoji = !_showEmoji;
                      if (_showEmoji) {
                        _focusNode.unfocus();
                      } else {
                        _focusNode.requestFocus();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: isMobile ? 44 : 48,
                    height: isMobile ? 44 : 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                      color: _showEmoji
                          ? (isDark ? colorScheme.primary : colorScheme.primary)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: isMobile ? 22 : 24,
                    ),
                  ),
                ),
              ),

              SizedBox(width: isMobile ? 8 : 12),

              // Text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: TextStyle(
                      fontSize: isMobile ? 15.5 : 16.5,
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        fontSize: isMobile ? 15.5 : 16.5,
                        color: isDark ? Colors.grey[400]! : Colors.grey[500]!,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 18 : 22,
                        vertical: isMobile ? 12 : 14,
                      ),
                      suffixIcon: _isHasText
                          ? IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: colorScheme.primary,
                          size: isMobile ? 20 : 22,
                        ),
                        onPressed: _sendMessage,
                        padding: EdgeInsets.only(right: isMobile ? 12 : 16),
                      )
                          : null,
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        _sendMessage();
                      }
                    },
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ),

              SizedBox(width: isMobile ? 8 : 12),

              // Send button (fallback)
              if (!_isHasText)
                Container(
                  width: isMobile ? 44 : 48,
                  height: isMobile ? 44 : 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                    border: Border.all(
                      color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    size: isMobile ? 20 : 22,
                  ),
                )
              else
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: isMobile ? 44 : 48,
                      height: isMobile ? 44 : 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                              : [const Color(0xFF1A73E8), const Color(0xFF0D62FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? const Color(0xFF2563EB) : const Color(0xFF1A73E8))
                                .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: isMobile ? 20 : 22,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Emoji Picker - Use default config first
        if (_showEmoji)
          SizedBox(
            height: isMobile ? 260 : 300,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                // Do something when emoji is selected
              },
              textEditingController: _textController,
              // Don't pass any config initially - use defaults
            ),
          ),
      ],
    );
  }
}