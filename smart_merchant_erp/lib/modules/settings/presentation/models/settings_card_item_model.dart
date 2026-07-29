import 'package:flutter/material.dart';

class SettingsCardItemModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> stats;
  final Widget destinationView;

  const SettingsCardItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.stats,
    required this.destinationView,
  });
}

class SettingsGroupModel {
  final String title;
  final List<SettingsCardItemModel> cards;

  const SettingsGroupModel({
    required this.title,
    required this.cards,
  });
}
