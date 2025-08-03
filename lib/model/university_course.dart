import 'package:flutter/material.dart';

class UniversityCourse {
  final String title, description;
  final IconData icon;
  final Color color;

  UniversityCourse({
    required this.title,
    required this.description,
    required this.icon,
    this.color = const Color(0xFF7553F6),
  });
}

final List<UniversityCourse> universityCourses = [
  UniversityCourse(
    title: "Small Things",
    description: "Explore literature through analysis of short stories, novellas, and character studies",
    icon: Icons.book,
    color: const Color(0xFFFF6B6B),
  ),
  UniversityCourse(
    title: "Poems",
    description: "Dive into poetry analysis, interpretation, and creative writing",
    icon: Icons.create,
    color: const Color(0xFF4ECDC4),
  ),
  UniversityCourse(
    title: "Short Stories",
    description: "Master the art of short story writing and literary analysis",
    icon: Icons.article,
    color: const Color(0xFF45B7D1),
  ),
];