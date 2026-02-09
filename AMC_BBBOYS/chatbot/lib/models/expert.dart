// lib/models/expert.dart
import 'package:flutter/material.dart';

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Expert &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}