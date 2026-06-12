import 'package:flutter/material.dart';

// =====================
// App Colors
// =====================
const kPrimaryColor = Color(0xFF4DB6AC);
const kSecondaryColor = Color(0xFFE0F2F1);
const kCardShadowColor = Colors.black12;
const kDisabledColor = Colors.grey;

// =====================
// Service Colors
// =====================
final Map<String, Color> serviceColors = {
  "Massage": Colors.green.shade200,
  "Haircut": Colors.blue.shade200,
  "Spa": Colors.purple.shade200,
  "Facial": Colors.orange.shade200,
  "Manicure": Colors.pink.shade200,
};

// =====================
// Services
// =====================
const List<String> serviceNames = [
  "Massage",
  "Haircut",
  "Spa",
  "Facial",
  "Manicure",
];

final Map<String, IconData> serviceIcons = {
  "Massage": Icons.self_improvement,
  "Haircut": Icons.content_cut,
  "Spa": Icons.hot_tub,
  "Facial": Icons.face_retouching_natural,
  "Manicure": Icons.back_hand,
};

// =====================
// Service Types
// =====================
final Map<String, List<String>> serviceTypes = {
  "Massage": ["Full Body", "Facial", "Head & Neck"],
  "Haircut": ["Men", "Women", "Kids"],
  "Spa": ["Hot Stone", "Aromatherapy", "Detox"],
  "Facial": ["Anti-Aging", "Brightening", "Hydrating"],
  "Manicure": ["Classic", "Gel", "French"],
};

// =====================
// Scheduling
// =====================
const List<int> slotDurationOptions = [15, 30, 45, 60, 90, 120];
