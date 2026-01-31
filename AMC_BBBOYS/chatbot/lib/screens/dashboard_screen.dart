import 'package:flutter/material.dart';
import 'chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(ThemeMode)? onChangeTheme;
  final ThemeMode? currentThemeMode;

  const DashboardScreen({
    super.key,
    this.onChangeTheme,
    this.currentThemeMode,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showChat = false;
  String? _selectedExpert;

  // Updated 5 easy personas
  final List<Expert> experts = [
    Expert(
      id: 'mayor',
      name: 'Mayor Isko Moreno',
      description: 'Public service & governance expert',
      icon: Icons.account_balance_rounded,
      color: const Color(0xFF2196F3), // Blue for government
      prompt: '''You are Mayor Isko Moreno, a charismatic public servant from Manila. You provide guidance on:
• Public service and governance
• Urban development projects
• Community engagement strategies
• Crisis management
• Leadership and decision-making

Speak in a friendly, approachable, and solution-oriented manner. Use real-life examples from your experience as Mayor.''',
    ),
    Expert(
      id: 'health',
      name: 'Dr. Health Expert',
      description: 'Medical advice & wellness tips',
      icon: Icons.medical_services_rounded,
      color: const Color(0xFF4CAF50), // Green for health
      prompt: '''You are a friendly medical doctor specializing in general health and wellness. You provide guidance on:
• Basic medical advice (non-emergency)
• Healthy lifestyle tips
• Nutrition and exercise
• Mental wellness
• Preventive healthcare

IMPORTANT: Always clarify this is general advice, not a substitute for professional medical consultation. Refer to doctors for serious concerns.''',
    ),
    Expert(
      id: 'money',
      name: 'Finance Coach',
      description: 'Budgeting & money management',
      icon: Icons.attach_money_rounded,
      color: const Color(0xFFFF9800), // Orange for finance
      prompt: '''You are a practical finance coach who helps people with everyday money management. You provide guidance on:
• Personal budgeting tips
• Saving strategies
• Basic investment knowledge
• Debt management
• Financial goal setting

Keep advice simple, actionable, and suitable for regular people. Avoid complex financial jargon.''',
    ),
    Expert(
      id: 'study',
      name: 'Study Buddy',
      description: 'Learning tips & exam help',
      icon: Icons.school_rounded,
      color: const Color(0xFF9C27B0), // Purple for education
      prompt: '''You are a helpful study companion who makes learning easier. You provide guidance on:
• Effective study techniques
• Time management for students
• Exam preparation tips
• Note-taking methods
• Overcoming study challenges

Be encouraging, practical, and focus on techniques that work for different learning styles.''',
    ),
    Expert(
      id: 'tech',
      name: 'Tech Helper',
      description: 'Simple tech support & tips',
      icon: Icons.phone_iphone_rounded,
      color: const Color(0xFF607D8B), // Blue-grey for tech
      prompt: '''You are a patient tech support assistant who explains things simply. You provide guidance on:
• Basic smartphone/computer troubleshooting
• App recommendations
• Digital safety tips
• Social media guidance
• Everyday tech problems

Break down technical terms into simple language. Focus on step-by-step solutions that anyone can follow.''',
    ),
  ];

  void _openChat(Expert expert) {
    setState(() {
      _selectedExpert = expert.id;
      _showChat = true;
    });
  }

  void _closeChat() {
    setState(() {
      _showChat = false;
      _selectedExpert = null;
    });
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => ThemeDialog(
        currentThemeMode: widget.currentThemeMode ?? ThemeMode.system,
        onThemeChanged: widget.onChangeTheme,
      ),
    );
  }

  Expert? get selectedExpert {
    if (_selectedExpert == null) return null;
    return experts.firstWhere(
          (e) => e.id == _selectedExpert,
      orElse: () => experts.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main Dashboard
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              _buildAppBar(theme, isDark),

              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    children: [
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Choose Your Expert',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Main Heading
                      Text(
                        'Personal Assistants',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: colorScheme.onBackground,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        'Who do you need help from today?',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Expert Cards Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: experts.length,
                        itemBuilder: (context, index) {
                          return _buildExpertCard(experts[index], theme, isDark);
                        },
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Chat Overlay
          if (_showChat && selectedExpert != null)
            _buildChatOverlay(selectedExpert!, theme),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(
        top: 60,
        left: 20,
        right: 20,
        bottom: 20,
      ),
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
          // Logo/Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat Assist',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'AI Assistant Platform',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Theme Switcher Button
          IconButton(
            onPressed: _showThemeDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withOpacity(0.8)
                    : const Color(0xFFE8F0FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? Colors.amber[300] : const Color(0xFFFF9800),
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF475569) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34A853).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Available',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.green[300] : const Color(0xFF1A73E8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertCard(Expert expert, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => _openChat(expert),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: expert.color.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  expert.icon,
                  color: expert.color,
                  size: 24,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                expert.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                expert.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Availability Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF475569) : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to chat',
                      style: TextStyle(
                        fontSize: 11,
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

  Widget _buildChatOverlay(Expert expert, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Chat Window
              Expanded(
                flex: 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                        blurRadius: 40,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ChatScreen(
                      expert: expert,
                      onClose: _closeChat,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class Expert {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String prompt;

  const Expert({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.prompt,
  });
}

// Theme Dialog Widget (keep this same as before)
class ThemeDialog extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode)? onThemeChanged;

  const ThemeDialog({
    super.key,
    required this.currentThemeMode,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Theme',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 20),

            // Light Theme Option
            _ThemeOption(
              title: 'Light Theme',
              icon: Icons.light_mode_rounded,
              iconColor: const Color(0xFFFF9800),
              isSelected: currentThemeMode == ThemeMode.light,
              onTap: () => onThemeChanged?.call(ThemeMode.light),
            ),

            const SizedBox(height: 12),

            // Dark Theme Option
            _ThemeOption(
              title: 'Dark Theme',
              icon: Icons.dark_mode_rounded,
              iconColor: Colors.amber,
              isSelected: currentThemeMode == ThemeMode.dark,
              onTap: () => onThemeChanged?.call(ThemeMode.dark),
            ),

            const SizedBox(height: 12),

            // System Default Option
            _ThemeOption(
              title: 'System Default',
              icon: Icons.settings_display_rounded,
              iconColor: Colors.blue,
              isSelected: currentThemeMode == ThemeMode.system,
              onTap: () => onThemeChanged?.call(ThemeMode.system),
            ),

            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : Colors.grey[100],
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2563EB) : const Color(0xFFE8F0FE))
              : (isDark ? const Color(0xFF334155) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.blue[300]! : const Color(0xFF1A73E8))
                : (isDark ? const Color(0xFF475569) : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),

            const SizedBox(width: 16),

            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),

            const Spacer(),

            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: isDark ? Colors.blue[300] : const Color(0xFF1A73E8),
              ),
          ],
        ),
      ),
    );
  }
}