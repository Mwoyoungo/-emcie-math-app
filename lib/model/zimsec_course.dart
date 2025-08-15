import 'package:flutter/material.dart';

class ZimsecCourse {
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  ZimsecCourse({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class ZimsecCourses {
  static final List<ZimsecCourse> courses = [
    ZimsecCourse(
      title: "Real Numbers",
      icon: Icons.calculate,
      color: const Color(0xFF7553F6),
      description: "Number patterns, limits of accuracy, ratios, standard form",
    ),
    ZimsecCourse(
      title: "Financial Mathematics",
      icon: Icons.attach_money,
      color: const Color(0xFF4CAF50),
      description: "Compound interest, commission, hire purchase, VAT, PAYE",
    ),
    ZimsecCourse(
      title: "Measures and Mensuration",
      icon: Icons.straighten,
      color: const Color(0xFF2196F3),
      description: "Perimeter, area, volume, surface area, density",
    ),
    ZimsecCourse(
      title: "Graphs",
      icon: Icons.show_chart,
      color: const Color(0xFFFF9800),
      description: "Quadratic, cubic, inverse graphs, motion graphs",
    ),
    ZimsecCourse(
      title: "Variation",
      icon: Icons.trending_up,
      color: const Color(0xFF9C27B0),
      description: "Joint variation, partial variation",
    ),
    ZimsecCourse(
      title: "Algebra",
      icon: Icons.functions,
      color: const Color(0xFFE91E63),
      description: "Quadratic formula, inequalities, indices, logarithms",
    ),
    ZimsecCourse(
      title: "Geometry",
      icon: Icons.crop_square,
      color: const Color(0xFF00BCD4),
      description: "Circle theorems, similarity, congruency",
    ),
    ZimsecCourse(
      title: "Statistics",
      icon: Icons.bar_chart,
      color: const Color(0xFF795548),
      description: "Frequency tables, central tendency, dispersion",
    ),
    ZimsecCourse(
      title: "Trigonometry",
      icon: Icons.transform,
      color: const Color(0xFF607D8B),
      description: "Sine rule, cosine rule, obtuse angles, triangle area",
    ),
    ZimsecCourse(
      title: "Vectors",
      icon: Icons.arrow_forward,
      color: const Color(0xFF3F51B5),
      description: "Position vectors, vector operations, plane shapes",
    ),
    ZimsecCourse(
      title: "Matrices",
      icon: Icons.grid_view,
      color: const Color(0xFF8BC34A),
      description: "Determinants, inverse matrices, linear equations",
    ),
    ZimsecCourse(
      title: "Transformation Geometry",
      icon: Icons.rotate_right,
      color: const Color(0xFFFF5722),
      description: "Matrix transformations, reflection, rotation, enlargement",
    ),
    ZimsecCourse(
      title: "Probability",
      icon: Icons.casino,
      color: const Color(0xFF673AB7),
      description: "Tree diagrams, outcome tables, combined events",
    ),
  ];
}