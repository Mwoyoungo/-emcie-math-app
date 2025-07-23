import 'package:flutter/material.dart' show Color;

class Course {
  final String title, description, iconSrc;
  final Color color;

  Course({
    required this.title,
    this.description = 'Build and animate an iOS app from scratch',
    this.iconSrc = "assets/icons/ios.svg",
    this.color = const Color(0xFF7553F6),
  });
}

final List<Course> courses = [
  Course(
    title: "Functions",
    description: "Linear, Quadratic, Exponential & Trigonometric",
    iconSrc: "assets/icons/code.svg",
    color: const Color(0xFF7553F6),
  ),
  Course(
    title: "Number Patterns, Sequences & Series",
    description: "Arithmetic & Geometric Progressions",  
    iconSrc: "assets/icons/ios.svg",
    color: const Color(0xFF80A4FF),
  ),
  Course(
    title: "Algebra",
    description: "Equations, Inequalities & Manipulation",
    iconSrc: "assets/icons/code.svg", 
    color: const Color(0xFF9CC5FF),
  ),
  Course(
    title: "Finance, Growth & Decay",
    description: "Compound Interest & Exponential Models",
    iconSrc: "assets/icons/ios.svg",
    color: const Color(0xFFFF6B6B),
  ),
  Course(
    title: "Trigonometry", 
    description: "Angles, Ratios, Identities & Applications",
    iconSrc: "assets/icons/code.svg",
    color: const Color(0xFF4ECDC4),
  ),
  Course(
    title: "Analytical Geometry",
    description: "Coordinate Geometry & Transformations",
    iconSrc: "assets/icons/ios.svg",
    color: const Color(0xFFFFB74D),
  ),
  Course(
    title: "Statistics",
    description: "Data Analysis, Probability & Distributions",
    iconSrc: "assets/icons/code.svg",
    color: const Color(0xFFE57373),
  ),
  Course(
    title: "Probability",
    description: "Chance, Events & Statistical Inference", 
    iconSrc: "assets/icons/ios.svg",
    color: const Color(0xFF81C784),
  ),
  Course(
    title: "Calculus",
    description: "Limits, Derivatives & Integration",
    iconSrc: "assets/icons/code.svg",
    color: const Color(0xFFBA68C8),
  ),
  Course(
    title: "Euclidean Geometry",
    description: "Theorems, Proofs & Geometric Properties",
    iconSrc: "assets/icons/ios.svg", 
    color: const Color(0xFF4DB6AC),
  ),
];

final List<Course> recentCourses = [
  Course(
    title: "Quadratic Functions",
    description: "Recently practiced - Vertex form and graphing",
    color: const Color(0xFF7553F6),
    iconSrc: "assets/icons/code.svg",
  ),
  Course(
    title: "Sine & Cosine Rules",
    description: "Last session - Triangle calculations",
    color: const Color(0xFF80A4FF),
    iconSrc: "assets/icons/ios.svg",
  ),
  Course(
    title: "Linear Programming",
    description: "Optimization problems practice",
    color: const Color(0xFF9CC5FF),
    iconSrc: "assets/icons/code.svg",
  ),
  Course(
    title: "Normal Distribution",
    description: "Statistics - Bell curve properties",
    color: const Color(0xFFFF6B6B),
    iconSrc: "assets/icons/ios.svg",
  ),
];
