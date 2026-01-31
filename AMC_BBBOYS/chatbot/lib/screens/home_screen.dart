import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // For controlling the visibility of chat screen
  bool _showChat = false;

  void _openChat() {
    setState(() {
      _showChat = true;
    });
  }

  void _closeChat() {
    setState(() {
      _showChat = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main home content
      body: Stack(
        children: [
          // Your main home screen content
          _buildHomeContent(),

          // Chat overlay
          if (_showChat) _buildChatOverlay(),
        ],
      ),

      // Floating Action Button to open chat
      floatingActionButton: !_showChat
          ? FloatingActionButton.extended(
        onPressed: _openChat,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Chat with AI'),
      )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHomeContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
            const Color(0xFF0F172A),
            const Color(0xFF1E293B),
          ]
              : [
            const Color(0xFFF0F2F5),
            const Color(0xFFE3E8F0),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Welcome Text
              Text(
                'Welcome to AI Assistant',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'Your Flutter & Dart expert companion.\nTap the chat button below to get started!',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Features List
              _buildFeatureList(theme),

              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList(ThemeData theme) {
    final features = [
      {'icon': Icons.code, 'title': 'Flutter Expertise', 'desc': 'Widgets, UI, State Management'},
      {'icon': Icons.bolt, 'title': 'Fast Responses', 'desc': 'Powered by Gemini AI'},
      {'icon': Icons.help_outline, 'title': 'Always Available', 'desc': '24/7 Assistance'},
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: theme.colorScheme.primary,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['desc'] as String,
                        style: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Stack(
          children: [
            // Chat Screen
            Positioned(
              right: 16,
              left: 16,
              top: 60,
              bottom: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ChatScreen(onClose: _closeChat),
              ),
            ),

            // Close button
            Positioned(
              top: 80,
              right: 36,
              child: FloatingActionButton.small(
                onPressed: _closeChat,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                child: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}