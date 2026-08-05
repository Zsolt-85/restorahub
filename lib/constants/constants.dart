import 'package:flutter/material.dart';

final Map<String, Color> serviceColors = {
  'Massage': Colors.green.shade200,
  'Haircut': Colors.blue.shade200,
  'Spa': Colors.purple.shade200,
  'Facial': Colors.orange.shade200,
  'Manicure': Colors.pink.shade200,
};

const List<String> serviceNames = [
  'Massage',
  'Haircut',
  'Spa',
  'Facial',
  'Manicure',
];

final Map<String, IconData> serviceIcons = {
  'Massage': Icons.self_improvement,
  'Haircut': Icons.content_cut,
  'Spa': Icons.hot_tub,
  'Facial': Icons.face_retouching_natural,
  'Manicure': Icons.back_hand,
};

final Map<String, List<String>> serviceTypes = {
  'Massage': ['Full Body', 'Facial', 'Head & Neck'],
  'Haircut': ['Men', 'Women', 'Kids'],
  'Spa': ['Hot Stone', 'Aromatherapy', 'Detox'],
  'Facial': ['Anti-Aging', 'Brightening', 'Hydrating'],
  'Manicure': ['Classic', 'Gel', 'French'],
};

const List<int> slotDurationOptions = [15, 30, 45, 60, 90, 120];

const List<int> bufferTimeOptions = [0, 10, 15, 30];

const kSecondaryColor = Color(0xFFE0F2F1);
