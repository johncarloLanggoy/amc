// lib/widgets/persona_switcher.dart - Enhanced with better visuals
import 'package:flutter/material.dart';
import '../models/expert.dart';

class PersonaSwitcher extends StatelessWidget {
  final List<Expert> experts;
  final Expert currentExpert;
  final Function(Expert) onExpertChanged;
  final bool isMobile;

  const PersonaSwitcher({
    super.key,
    required this.experts,
    required this.currentExpert,
    required this.onExpertChanged,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isMobile) {
      return _buildMobileSwitcher(context, isDark);
    } else {
      return _buildDesktopSwitcher(context, isDark);
    }
  }

  Widget _buildMobileSwitcher(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showMobilePersonaSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                currentExpert.color,
                Color.lerp(currentExpert.color, Colors.white, 0.3)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: currentExpert.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.switch_account_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSwitcher(BuildContext context, bool isDark) {
    return PopupMenuButton<Expert>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      offset: const Offset(0, 48),
      elevation: 8,
      icon: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  currentExpert.color,
                  Color.lerp(currentExpert.color, Colors.white, 0.3)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: currentExpert.color.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: currentExpert.color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.switch_account_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
      tooltip: 'Switch AI Persona',
      onSelected: onExpertChanged,
      itemBuilder: (context) => experts.map((expert) {
        final isCurrent = expert.id == currentExpert.id;
        return PopupMenuItem<Expert>(
          value: expert,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expert.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent ? expert.color : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expert.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: expert.color,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showMobilePersonaSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.switch_account_rounded,
                      color: currentExpert.color,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Switch Persona',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Experts List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: experts.length,
                  itemBuilder: (context, index) {
                    final expert = experts[index];
                    final isCurrent = expert.id == currentExpert.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isCurrent
                            ? expert.color.withOpacity(isDark ? 0.15 : 0.1)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            onExpertChanged(expert);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent
                                    ? expert.color.withOpacity(0.3)
                                    : isDark
                                    ? const Color(0xFF334155)
                                    : Colors.grey.shade200,
                                width: isCurrent ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
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
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expert.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isCurrent ? expert.color : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        expert.description,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: expert.color,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}