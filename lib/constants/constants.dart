import 'package:flutter/material.dart';

@Deprecated('Load service descriptions from Firestore per-tenant catalog instead')
final Map<String, String> serviceDescriptions = {
  'Massage': 'Therapeutic bodywork tailored to your needs',
  'Haircut': 'Precision cuts and professional styling',
  'Spa': 'Rejuvenating treatments for total relaxation',
  'Facial': 'Advanced skincare for a radiant complexion',
  'Manicure': 'Expert nail care and artistic finishing',
};

@Deprecated('Load service names from Firestore per-tenant catalog instead')
const List<String> serviceNames = [
  'Massage',
  'Haircut',
  'Spa',
  'Facial',
  'Manicure',
];

@Deprecated('Load service icons from tenant branding config instead')
final Map<String, IconData> serviceIcons = {
  'Massage': Icons.self_improvement,
  'Haircut': Icons.content_cut,
  'Spa': Icons.hot_tub,
  'Facial': Icons.face_retouching_natural,
  'Manicure': Icons.back_hand,
};

@Deprecated('Load service variants from Firestore per-tenant catalog instead')
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
