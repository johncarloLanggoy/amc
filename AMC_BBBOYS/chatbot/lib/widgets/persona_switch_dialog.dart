// lib/widgets/persona_switch_dialog.dart
import 'package:flutter/material.dart';
import '../models/expert.dart';

enum PersonaSwitchChoice { newChat, continueChat }

class PersonaSwitchDialog extends StatelessWidget {
  final Expert currentExpert;
  final Expert newExpert;

  const PersonaSwitchDialog({
    super.key,
    required this.currentExpert,
    required this.newExpert,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Switch AI Persona',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // Current and New Expert
            Row(
              children: [
                _buildExpertAvatar(currentExpert, isDark),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
                const SizedBox(width: 8),
                _buildExpertAvatar(newExpert, isDark),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'From ${currentExpert.name} to ${newExpert.name}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'What would you like to do?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 12),

            // Options
            _buildOption(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Start New Chat',
              subtitle: 'Begin fresh conversation with ${newExpert.name}',
              value: PersonaSwitchChoice.newChat,
              color: newExpert.color,
            ),

            const SizedBox(height: 12),

            _buildOption(
              context,
              icon: Icons.history_rounded,
              title: 'Continue Current Chat',
              subtitle: 'Keep existing messages, switch persona context',
              value: PersonaSwitchChoice.continueChat,
              color: newExpert.color,
            ),

            const SizedBox(height: 20),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.grey[300] : Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertAvatar(Expert expert, bool isDark) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: expert.color.withOpacity(isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            expert.icon,
            color: expert.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          expert.name.split(' ').first,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required PersonaSwitchChoice value,
        required Color color,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF334155) : Colors.grey[50],
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(context, value),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
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
}