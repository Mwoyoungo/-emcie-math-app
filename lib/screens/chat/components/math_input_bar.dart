import 'package:flutter/material.dart';

class MathInputBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final Function(String) onInsertSymbol;
  final VoidCallback onPickImage;
  final VoidCallback onTakePhoto;

  const MathInputBar({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onInsertSymbol,
    required this.onPickImage,
    required this.onTakePhoto,
  });

  @override
  State<MathInputBar> createState() => _MathInputBarState();
}

class _MathInputBarState extends State<MathInputBar> {
  bool _showMathSymbols = false;
  
  final List<Map<String, String>> _mathSymbols = [
    // Basic Operations
    {'symbol': '±', 'latex': '±'},
    {'symbol': '×', 'latex': '×'},
    {'symbol': '÷', 'latex': '÷'},
    {'symbol': '√', 'latex': '√'},
    {'symbol': '∛', 'latex': '∛'},
    {'symbol': '^', 'latex': '^'},
    {'symbol': '²', 'latex': '²'},
    {'symbol': '³', 'latex': '³'},
    
    // Fractions
    {'symbol': '½', 'latex': '½'},
    {'symbol': '⅓', 'latex': '⅓'},
    {'symbol': '¼', 'latex': '¼'},
    {'symbol': '¾', 'latex': '¾'},
    {'symbol': '/', 'latex': '/'},
    
    // Comparison
    {'symbol': '≤', 'latex': '≤'},
    {'symbol': '≥', 'latex': '≥'},
    {'symbol': '≠', 'latex': '≠'},
    {'symbol': '≈', 'latex': '≈'},
    {'symbol': '<', 'latex': '<'},
    {'symbol': '>', 'latex': '>'},
    
    // Greek Letters
    {'symbol': 'α', 'latex': 'α'},
    {'symbol': 'β', 'latex': 'β'},
    {'symbol': 'γ', 'latex': 'γ'},
    {'symbol': 'δ', 'latex': 'δ'},
    {'symbol': 'θ', 'latex': 'θ'},
    {'symbol': 'λ', 'latex': 'λ'},
    {'symbol': 'μ', 'latex': 'μ'},
    {'symbol': 'π', 'latex': 'π'},
    {'symbol': 'σ', 'latex': 'σ'},
    {'symbol': 'Σ', 'latex': 'Σ'},
    {'symbol': 'φ', 'latex': 'φ'},
    {'symbol': 'ω', 'latex': 'ω'},
    
    // Special Symbols
    {'symbol': '∞', 'latex': '∞'},
    {'symbol': '°', 'latex': '°'},
    {'symbol': '∑', 'latex': '∑'},
    {'symbol': '∏', 'latex': '∏'},
    {'symbol': '∫', 'latex': '∫'},
    {'symbol': '∆', 'latex': '∆'},
    {'symbol': '∇', 'latex': '∇'},
    {'symbol': '∂', 'latex': '∂'},
    
    // Logic & Sets
    {'symbol': '∈', 'latex': '∈'},
    {'symbol': '∉', 'latex': '∉'},
    {'symbol': '⊂', 'latex': '⊂'},
    {'symbol': '⊆', 'latex': '⊆'},
    {'symbol': '∪', 'latex': '∪'},
    {'symbol': '∩', 'latex': '∩'},
    {'symbol': '∅', 'latex': '∅'},
    {'symbol': '∀', 'latex': '∀'},
    {'symbol': '∃', 'latex': '∃'},
    
    // Brackets
    {'symbol': '(', 'latex': '('},
    {'symbol': ')', 'latex': ')'},
    {'symbol': '[', 'latex': '['},
    {'symbol': ']', 'latex': ']'},
    {'symbol': '{', 'latex': '{'},
    {'symbol': '}', 'latex': '}'},
    {'symbol': '|', 'latex': '|'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showMathSymbols) _buildMathSymbolsPanel(),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  _showImageOptions();
                },
                icon: const Icon(Icons.camera_alt),
                color: const Color(0xFF7553F6),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showMathSymbols = !_showMathSymbols;
                  });
                },
                icon: Icon(_showMathSymbols ? Icons.keyboard : Icons.functions),
                color: const Color(0xFF7553F6),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1F8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFDEE3F2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    decoration: const InputDecoration(
                      hintText: "Ask Mam Rose a math question...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        widget.onSendMessage(text);
                      }
                    },
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF7553F6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    final text = widget.controller.text;
                    if (text.trim().isNotEmpty) {
                      widget.onSendMessage(text);
                    }
                  },
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMathSymbolsPanel() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDEE3F2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.functions,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                "Math Symbols & Operators",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                "Tap to insert",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: _mathSymbols.length,
              itemBuilder: (context, index) {
                final symbol = _mathSymbols[index];
                return GestureDetector(
                  onTap: () {
                    widget.onInsertSymbol(symbol['symbol']!);
                    // Add haptic feedback
                    // HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFDEE3F2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        symbol['symbol']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7553F6),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Add Image",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () {
                      Navigator.pop(context);
                      widget.onTakePhoto();
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: "Gallery",
                    onTap: () {
                      Navigator.pop(context);
                      widget.onPickImage();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF1F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFDEE3F2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF7553F6),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}