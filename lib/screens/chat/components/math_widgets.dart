import 'package:flutter/material.dart';

class FractionWidget extends StatefulWidget {
  final Function(String) onNumeratorChanged;
  final Function(String) onDenominatorChanged;
  final String initialNumerator;
  final String initialDenominator;

  const FractionWidget({
    super.key,
    required this.onNumeratorChanged,
    required this.onDenominatorChanged,
    this.initialNumerator = '',
    this.initialDenominator = '',
  });

  @override
  State<FractionWidget> createState() => _FractionWidgetState();
}

class _FractionWidgetState extends State<FractionWidget> {
  late TextEditingController _numeratorController;
  late TextEditingController _denominatorController;
  FocusNode? _currentFocus;

  @override
  void initState() {
    super.initState();
    _numeratorController = TextEditingController(text: widget.initialNumerator);
    _denominatorController = TextEditingController(text: widget.initialDenominator);
  }

  @override
  void dispose() {
    _numeratorController.dispose();
    _denominatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Numerator
          Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 24),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              color: Colors.white,
            ),
            child: TextField(
              controller: _numeratorController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: '□',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: widget.onNumeratorChanged,
              onTap: () {
                setState(() {
                  _currentFocus = null;
                });
              },
            ),
          ),
          // Fraction line
          Container(
            height: 2,
            constraints: const BoxConstraints(minWidth: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF7553F6),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          // Denominator
          Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 24),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              color: Colors.white,
            ),
            child: TextField(
              controller: _denominatorController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: '□',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: widget.onDenominatorChanged,
              onTap: () {
                setState(() {
                  _currentFocus = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InlineFractionWidget extends StatelessWidget {
  final String numerator;
  final String denominator;
  final double size;

  const InlineFractionWidget({
    super.key,
    required this.numerator,
    required this.denominator,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Numerator
          Text(
            numerator.isEmpty ? '□' : numerator,
            style: TextStyle(
              fontSize: size * 0.8,
              color: numerator.isEmpty ? Colors.grey : const Color(0xFF7553F6),
            ),
            textAlign: TextAlign.center,
          ),
          // Fraction line
          Container(
            height: 1,
            constraints: BoxConstraints(minWidth: size * 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF7553F6),
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
          // Denominator
          Text(
            denominator.isEmpty ? '□' : denominator,
            style: TextStyle(
              fontSize: size * 0.8,
              color: denominator.isEmpty ? Colors.grey : const Color(0xFF7553F6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}