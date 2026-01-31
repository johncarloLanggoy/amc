import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _showEmoji ? Icons.keyboard : Icons.sentiment_satisfied_alt_outlined,
                  color: isDark ? Colors.blue[300]! : colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _showEmoji = !_showEmoji;
                    if (_showEmoji) _focusNode.unfocus();
                  });
                },
              ),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(28),
                    border: isDark
                        ? Border.all(color: const Color(0xFF334155))
                        : null,
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500]! : Colors.grey[600]!,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              CircleAvatar(
                backgroundColor: _isHasText
                    ? (isDark ? const Color(0xFF2563EB) : colorScheme.primary)
                    : (isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _isHasText ? _sendMessage : null,
                ),
              ),
            ],
          ),
        ),

        // Emoji Picker
        Offstage(
          offstage: !_showEmoji,
          child: SizedBox(
            height: 250,
            child: EmojiPicker(
              textEditingController: _textController,
              config: Config(
                height: 256,
                checkPlatformCompatibility: true,
                viewOrderConfig: const ViewOrderConfig(),
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1.0),
                  columns: 7,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : theme.colorScheme.surface,
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : theme.colorScheme.surface,
                  indicatorColor: isDark ? Colors.blue[300]! : colorScheme.primary,
                  iconColorSelected: isDark ? Colors.blue[300]! : colorScheme.primary,
                  iconColor: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  enabled: false,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : theme.colorScheme.surface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}