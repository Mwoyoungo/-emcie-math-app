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
  
  // Row 1: Powers, roots, logs, Greek letters, calculus
  final List<Map<String, dynamic>> _mathSymbolsRow1 = [
    {'symbol': 'x²', 'type': 'template', 'template': '□²'},
    {'symbol': 'xⁿ', 'type': 'template', 'template': '□^□'},
    {'symbol': '√', 'type': 'template', 'template': '√(□)'},
    {'symbol': 'ⁿ√□', 'type': 'template', 'template': '□√(□)'},
    {'symbol': 'logₐ', 'type': 'template', 'template': 'log_{□}(□)'},
    {'symbol': 'π', 'type': 'static'},
    {'symbol': 'θ', 'type': 'static'},
    {'symbol': '∞', 'type': 'static'},
    {'symbol': '∫', 'type': 'template', 'template': '∫_{□}^{□} (□) dx'},
    {'symbol': 'd/dx', 'type': 'template', 'template': 'd/dx (□)'},
    {'symbol': '|x|', 'type': 'template', 'template': '|□|'},
    {'symbol': 'x!', 'type': 'template', 'template': '□!'},
  ];

  // Row 2: Comparisons, operations, functions, fractions
  final List<Map<String, dynamic>> _mathSymbolsRow2 = [
    {'symbol': '≥', 'type': 'static'},
    {'symbol': '≤', 'type': 'static'},
    {'symbol': '≠', 'type': 'static'},
    {'symbol': '≈', 'type': 'static'},
    {'symbol': '±', 'type': 'static'},
    {'symbol': '·', 'type': 'static'},
    {'symbol': '÷', 'type': 'static'},
    {'symbol': 'a/b', 'type': 'template', 'template': '□/□'},
    {'symbol': '∘', 'type': 'static'},
    {'symbol': 'x̄', 'type': 'static'},
    {'symbol': '□', 'type': 'static'},
    {'symbol': 'ln', 'type': 'template', 'template': 'ln(□)'},
    {'symbol': 'eⁿ', 'type': 'template', 'template': 'e^□'},
  ];

  // Row 3: Advanced calculus, trigonometry, sets, brackets
  final List<Map<String, dynamic>> _mathSymbolsRow3 = [
    {'symbol': "(□)'", 'type': 'template', 'template': "(□)'"},
    {'symbol': '∂/∂x', 'type': 'template', 'template': '∂/∂x (□)'},
    {'symbol': '∮', 'type': 'template', 'template': '∮ (□) dx'},
    {'symbol': 'lim', 'type': 'template', 'template': 'lim_{x→□} (□)'},
    {'symbol': 'Σ', 'type': 'template', 'template': 'Σ_{n=□}^{□} (□)'},
    {'symbol': 'sin', 'type': 'template', 'template': 'sin(□)'},
    {'symbol': 'cos', 'type': 'template', 'template': 'cos(□)'},
    {'symbol': 'tan', 'type': 'template', 'template': 'tan(□)'},
    {'symbol': 'cot', 'type': 'template', 'template': 'cot(□)'},
    {'symbol': '∈', 'type': 'static'},
    {'symbol': '∅', 'type': 'static'},
    {'symbol': '()', 'type': 'template', 'template': '(□)'},
    {'symbol': '[]', 'type': 'template', 'template': '[□]'},
    {'symbol': '{}', 'type': 'template', 'template': '{□}'},
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
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    _showImageOptions();
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  color: const Color(0xFF7553F6),
                  padding: EdgeInsets.zero,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _showMathSymbols = !_showMathSymbols;
                    });
                  },
                  icon: Icon(
                    _showMathSymbols ? Icons.keyboard_hide : Icons.functions,
                    size: 18,
                  ),
                  color: const Color(0xFF7553F6),
                  padding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    decoration: InputDecoration(
                      hintText: "Ask Maam Rose a math question...",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      suffixIcon: _hasPlaceholders() ? IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        onPressed: _jumpToNextPlaceholder,
                        tooltip: 'Next placeholder',
                      ) : null,
                    ),
                    style: const TextStyle(fontSize: 16),
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
        mainAxisSize: MainAxisSize.min,
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
          
          // Row 1
          _buildSymbolRow(_mathSymbolsRow1),
          const SizedBox(height: 8),
          
          // Row 2  
          _buildSymbolRow(_mathSymbolsRow2),
          const SizedBox(height: 8),
          
          // Row 3
          _buildSymbolRow(_mathSymbolsRow3),
        ],
      ),
    );
  }

  Widget _buildSymbolRow(List<Map<String, dynamic>> symbols) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: symbols.length,
        itemBuilder: (context, index) {
          final symbol = symbols[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                _handleSmartSymbolInput(symbol['symbol']!);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7553F6),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSmartSymbolInput(String symbol) {
    // Find the symbol data to determine if it's static or template
    Map<String, dynamic>? symbolData;
    
    // Search through all rows to find the symbol
    for (final row in [_mathSymbolsRow1, _mathSymbolsRow2, _mathSymbolsRow3]) {
      symbolData = row.firstWhere(
        (item) => item['symbol'] == symbol,
        orElse: () => {},
      );
      if (symbolData.isNotEmpty) break;
    }

    if (symbolData == null || symbolData.isEmpty) return;

    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset;

    if (symbolData['type'] == 'static') {
      // Static symbols - just insert the symbol
      _insertText(symbolData['symbol']);
    } else if (symbolData['type'] == 'template') {
      // Template symbols - insert the template and position cursor at first placeholder
      final template = symbolData['template'] as String;
      _insertTemplate(template);
    }
  }

  void _insertText(String text) {
    final controller = widget.controller;
    final selection = controller.selection;
    final newText = controller.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    final newPosition = selection.start + text.length;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newPosition),
    );
  }

  void _insertTemplate(String template) {
    final controller = widget.controller;
    final selection = controller.selection;
    final newText = controller.text.replaceRange(
      selection.start,
      selection.end,
      template,
    );
    
    // Find the first placeholder (□) and position cursor there
    final firstPlaceholderIndex = template.indexOf('□');
    int newCursorPos;
    
    if (firstPlaceholderIndex != -1) {
      newCursorPos = selection.start + firstPlaceholderIndex;
      // Select the placeholder so user can immediately type to replace it
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: newCursorPos,
          extentOffset: newCursorPos + 1, // Select the □ character
        ),
      );
    } else {
      // No placeholder found, just position cursor at end
      newCursorPos = selection.start + template.length;
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );
    }
  }

  bool _hasPlaceholders() {
    return widget.controller.text.contains('□');
  }

  void _jumpToNextPlaceholder() {
    final text = widget.controller.text;
    final currentPos = widget.controller.selection.baseOffset;
    
    // Find the next placeholder after current cursor position
    final nextPlaceholderIndex = text.indexOf('□', currentPos);
    
    if (nextPlaceholderIndex != -1) {
      // Select the placeholder
      widget.controller.selection = TextSelection(
        baseOffset: nextPlaceholderIndex,
        extentOffset: nextPlaceholderIndex + 1,
      );
    } else {
      // No more placeholders after cursor, find the first one from the beginning
      final firstPlaceholderIndex = text.indexOf('□');
      if (firstPlaceholderIndex != -1) {
        widget.controller.selection = TextSelection(
          baseOffset: firstPlaceholderIndex,
          extentOffset: firstPlaceholderIndex + 1,
        );
      }
    }
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