import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../models/expert.dart';

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
  Expert? _selectedExpert;
  String? _selectedConversationId;

  final List<Expert> experts = [
    Expert(
      id: 'mayor',
      name: 'Mayor Isko Moreno',
      description: 'Public service & governance expert',
      icon: Icons.account_balance_rounded,
      color: const Color(0xFF2196F3),
      prompt: '''You are Mayor Isko Moreno...''',
    ),
    Expert(
      id: 'health',
      name: 'Dr. Health Expert',
      description: 'Medical advice & wellness tips',
      icon: Icons.medical_services_rounded,
      color: const Color(0xFF4CAF50),
      prompt: '''You are a friendly medical doctor...''',
    ),
    Expert(
      id: 'money',
      name: 'Finance Coach',
      description: 'Budgeting & money management',
      icon: Icons.attach_money_rounded,
      color: const Color(0xFFFF9800),
      prompt: '''You are a practical finance coach...''',
    ),
    Expert(
      id: 'study',
      name: 'Study Buddy',
      description: 'Learning tips & exam help',
      icon: Icons.school_rounded,
      color: const Color(0xFF9C27B0),
      prompt: '''You are a helpful study companion...''',
    ),
    Expert(
      id: 'tech',
      name: 'Tech Helper',
      description: 'Simple tech support & tips',
      icon: Icons.phone_iphone_rounded,
      color: const Color(0xFF607D8B),
      prompt: '''You are a patient tech support assistant...''',
    ),
  ];

  void _openChat(Expert expert, {String? conversationId}) {
    setState(() {
      _selectedExpert = expert;
      _selectedConversationId = conversationId;
      _showChat = true;
    });
  }

  void _closeChat() {
    setState(() {
      _showChat = false;
      _selectedExpert = null;
      _selectedConversationId = null;
    });
  }

  void _handleExpertChanged(Expert newExpert) {
    setState(() {
      _selectedExpert = newExpert;
    });
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildThemeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isVerySmall = screenWidth < 350; // Extra small screens

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main Dashboard
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F172A),
                  const Color(0xFF1E293B),
                ],
              )
                  : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  const Color(0xFFF8FAFD),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar
                  _buildAppBar(theme, isDark, isMobile, isVerySmall),

                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmall ? 12 : (isMobile ? 16 : 32),
                        vertical: isVerySmall ? 12 : (isMobile ? 12 : 24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome section
                          _buildWelcomeSection(theme, isDark, isMobile, isVerySmall),

                          SizedBox(height: isVerySmall ? 16 : (isMobile ? 20 : 32)),

                          // Expert Cards Grid
                          _buildExpertGrid(isMobile, isVerySmall, theme, isDark),

                          SizedBox(height: isVerySmall ? 40 : (isMobile ? 60 : 80)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chat Overlay
          if (_showChat && _selectedExpert != null)
            _buildChatOverlay(_selectedExpert!, theme, isMobile),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDark, bool isMobile, bool isVerySmall) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.only(
        top: isVerySmall ? 12 : (isMobile ? 14 : 20),
        left: isVerySmall ? 12 : (isMobile ? 16 : 24),
        right: isVerySmall ? 12 : (isMobile ? 16 : 24),
        bottom: isVerySmall ? 14 : (isMobile ? 16 : 20),
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155).withOpacity(0.5) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo/Title
          Flexible(
            child: Row(
              children: [
                Container(
                  width: isVerySmall ? 28 : (isMobile ? 32 : 40),
                  height: isVerySmall ? 28 : (isMobile ? 32 : 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isVerySmall ? 8 : (isMobile ? 10 : 12)),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: isVerySmall ? 16 : (isMobile ? 18 : 22),
                  ),
                ),
                SizedBox(width: isVerySmall ? 6 : (isMobile ? 8 : 12)),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chat Assist',
                        style: TextStyle(
                          fontSize: isVerySmall ? 18 : (isMobile ? 20 : 24),
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onBackground,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isVerySmall ? 1 : 2),
                      Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontSize: isVerySmall ? 9 : (isMobile ? 10 : 12),
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Theme Switcher Button - Show on desktop, hide on very small mobile
          if ((!isMobile || screenWidth > 400) && widget.onChangeTheme != null)
            Padding(
              padding: EdgeInsets.only(right: isVerySmall ? 4 : (isMobile ? 6 : 8)),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _showThemeDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(isVerySmall ? 6 : (isMobile ? 8 : 10)),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withOpacity(0.8)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDark ? Colors.amber.shade300 : const Color(0xFFFF9800),
                      size: isVerySmall ? 16 : (isMobile ? 18 : 20),
                    ),
                  ),
                ),
              ),
            ),

          // Status Indicator - Hide on very small screens if needed
          if (!isVerySmall || screenWidth > 300)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isVerySmall ? 8 : (isMobile ? 10 : 14),
                vertical: isVerySmall ? 4 : (isMobile ? 5 : 7),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF34A853), const Color(0xFF0D9C56)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF10B981) : const Color(0xFF34A853))
                        .withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: isVerySmall ? 3 : (isMobile ? 4 : 6)),
                  Text(
                    'Available',
                    style: TextStyle(
                      fontSize: isVerySmall ? 9 : (isMobile ? 10 : 12),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(ThemeData theme, bool isDark, bool isMobile, bool isVerySmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmall ? 8 : 10,
            vertical: isVerySmall ? 4 : 5,
          ),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.primary.withOpacity(0.1) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(isVerySmall ? 8 : 10),
          ),
          child: Text(
            'Choose Expert',
            style: TextStyle(
              fontSize: isVerySmall ? 10 : (isMobile ? 11 : 12),
              fontWeight: FontWeight.w600,
              color: isDark ? theme.colorScheme.primary : const Color(0xFF1A73E8),
            ),
          ),
        ),
        SizedBox(height: isVerySmall ? 8 : (isMobile ? 10 : 14)),
        Text(
          'AI Assistants',
          style: TextStyle(
            fontSize: isVerySmall ? 20 : (isMobile ? 24 : 32),
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: theme.colorScheme.onBackground,
          ),
        ),
        SizedBox(height: isVerySmall ? 4 : (isMobile ? 6 : 8)),
        Text(
          'Who can help you today?',
          style: TextStyle(
            fontSize: isVerySmall ? 12 : (isMobile ? 14 : 16),
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildExpertGrid(bool isMobile, bool isVerySmall, ThemeData theme, bool isDark) {
    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: experts.length,
        separatorBuilder: (context, index) => SizedBox(height: isVerySmall ? 12 : 16),
        itemBuilder: (context, index) {
          return _buildExpertCard(experts[index], theme, isDark, isMobile, isVerySmall);
        },
      );
    } else {
      final screenWidth = MediaQuery.of(context).size.width;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth < 1000 ? 2 : 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: screenWidth < 1000 ? 1 : 1.1,
        ),
        itemCount: experts.length,
        itemBuilder: (context, index) {
          return _buildExpertCard(experts[index], theme, isDark, isMobile, isVerySmall);
        },
      );
    }
  }

  Widget _buildExpertCard(Expert expert, ThemeData theme, bool isDark, bool isMobile, bool isVerySmall) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openChat(expert),
        child: Container(
          constraints: BoxConstraints(
            minHeight: isVerySmall ? 120 : (isMobile ? 140 : 160),
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(isVerySmall ? 12 : (isMobile ? 14 : 18)),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                blurRadius: isVerySmall ? 6 : (isMobile ? 8 : 12),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isVerySmall ? 12 : (isMobile ? 14 : 18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon
                Container(
                  width: isVerySmall ? 40 : (isMobile ? 44 : 52),
                  height: isVerySmall ? 40 : (isMobile ? 44 : 52),
                  decoration: BoxDecoration(
                    color: expert.color.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    expert.icon,
                    color: expert.color,
                    size: isVerySmall ? 18 : (isMobile ? 20 : 24),
                  ),
                ),
                SizedBox(height: isVerySmall ? 8 : (isMobile ? 10 : 14)),

                // Title
                Text(
                  expert.name,
                  style: TextStyle(
                    fontSize: isVerySmall ? 13 : (isMobile ? 14 : 16),
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onBackground,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isVerySmall ? 2 : (isMobile ? 3 : 4)),

                // Description
                Text(
                  expert.description,
                  style: TextStyle(
                    fontSize: isVerySmall ? 10 : (isMobile ? 11 : 12),
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isVerySmall ? 8 : (isMobile ? 10 : 14)),

                // Tap indicator
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmall ? 8 : (isMobile ? 10 : 12),
                    vertical: isVerySmall ? 4 : (isMobile ? 5 : 6),
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(isVerySmall ? 8 : (isMobile ? 10 : 12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: isVerySmall ? 3 : (isMobile ? 4 : 6)),
                      Text(
                        'Tap to chat',
                        style: TextStyle(
                          fontSize: isVerySmall ? 9 : (isMobile ? 10 : 11),
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatOverlay(Expert expert, ThemeData theme, bool isMobile) {
    final isDark = theme.brightness == Brightness.dark;

    if (isMobile) {
      return Positioned.fill(
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black,
                size: 24,
              ),
              onPressed: _closeChat,
            ),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        expert.color,
                        Color.lerp(expert.color, Colors.white, 0.3)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    expert.icon,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Text(
                    expert.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            elevation: 0,
          ),
          body: ChatScreen(
            expert: expert,
            allExperts: experts,
            onExpertChanged: _handleExpertChanged,
            onClose: _closeChat,
            initialConversationId: _selectedConversationId,
          ),
        ),
      );
    } else {
      return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 1),
                Expanded(
                  flex: 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: ChatScreen(
                        expert: expert,
                        allExperts: experts,
                        onExpertChanged: _handleExpertChanged,
                        onClose: _closeChat,
                        initialConversationId: _selectedConversationId,
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

  Widget _buildThemeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isVerySmall = screenWidth < 350;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isVerySmall ? 16 : (isMobile ? 18 : 20)),
      ),
      insetPadding: EdgeInsets.all(isVerySmall ? 12 : (isMobile ? 16 : 24)),
      child: Padding(
        padding: EdgeInsets.all(isVerySmall ? 16 : (isMobile ? 20 : 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_rounded,
                  color: isDark ? Colors.white : Colors.black,
                  size: isVerySmall ? 18 : (isMobile ? 20 : 22),
                ),
                SizedBox(width: isVerySmall ? 8 : (isMobile ? 10 : 12)),
                Text(
                  'Choose Theme',
                  style: TextStyle(
                    fontSize: isVerySmall ? 16 : (isMobile ? 18 : 20),
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: isVerySmall ? 12 : (isMobile ? 16 : 20)),
            // Light Theme Option
            _buildThemeOption(
              title: 'Light Theme',
              icon: Icons.light_mode_rounded,
              iconColor: const Color(0xFFFF9800),
              isSelected: widget.currentThemeMode == ThemeMode.light,
              onTap: () => widget.onChangeTheme?.call(ThemeMode.light),
              isMobile: isMobile,
              isVerySmall: isVerySmall,
            ),
            SizedBox(height: isVerySmall ? 8 : (isMobile ? 10 : 12)),
            // Dark Theme Option
            _buildThemeOption(
              title: 'Dark Theme',
              icon: Icons.dark_mode_rounded,
              iconColor: Colors.amber,
              isSelected: widget.currentThemeMode == ThemeMode.dark,
              onTap: () => widget.onChangeTheme?.call(ThemeMode.dark),
              isMobile: isMobile,
              isVerySmall: isVerySmall,
            ),
            SizedBox(height: isVerySmall ? 8 : (isMobile ? 10 : 12)),
            // System Default Option
            _buildThemeOption(
              title: 'System Default',
              icon: Icons.settings_display_rounded,
              iconColor: Colors.blue,
              isSelected: widget.currentThemeMode == ThemeMode.system,
              onTap: () => widget.onChangeTheme?.call(ThemeMode.system),
              isMobile: isMobile,
              isVerySmall: isVerySmall,
            ),
            SizedBox(height: isVerySmall ? 16 : (isMobile ? 20 : 24)),
            // Close Button
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(isVerySmall ? 10 : (isMobile ? 12 : 14)),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(isVerySmall ? 10 : (isMobile ? 12 : 14)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isVerySmall ? 10 : (isMobile ? 12 : 14),
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(isVerySmall ? 10 : (isMobile ? 12 : 14)),
                    ),
                    child: Center(
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: isVerySmall ? 13 : (isMobile ? 14 : 15),
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isMobile,
    required bool isVerySmall,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isVerySmall ? 12 : (isMobile ? 14 : 16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isVerySmall ? 12 : (isMobile ? 14 : 16)),
        child: Container(
          padding: EdgeInsets.all(isVerySmall ? 12 : (isMobile ? 14 : 16)),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2563EB) : const Color(0xFFE8F0FE))
                : (isDark ? const Color(0xFF334155) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(isVerySmall ? 12 : (isMobile ? 14 : 16)),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.blue.shade300 : const Color(0xFF1A73E8))
                  : (isDark ? const Color(0xFF475569) : Colors.grey.shade200),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isVerySmall ? 8 : (isMobile ? 9 : 10)),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: isVerySmall ? 16 : (isMobile ? 18 : 20),
                ),
              ),
              SizedBox(width: isVerySmall ? 10 : (isMobile ? 12 : 14)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isVerySmall ? 14 : (isMobile ? 15 : 16),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: isDark ? Colors.blue.shade300 : const Color(0xFF1A73E8),
                  size: isVerySmall ? 18 : (isMobile ? 20 : 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}