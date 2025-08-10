We’ll handle two types of keys:

Static symbols → just insert the symbol at the cursor.

Functional symbols → insert a template with placeholders and place the cursor in the first placeholder.

For CAPS Grade 12, that means:

Static: π, ∞, ≥, ≤, ÷, etc.

Functional: x², xⁿ, √, nth root, logₐ, ∫, d/dx, lim, Σ, trig functions.

Flutter Implementation
dart
Copy
Edit
import 'package:flutter/material.dart';

class MathKeyboard extends StatefulWidget {
  @override
  State<MathKeyboard> createState() => _MathKeyboardState();
}

class _MathKeyboardState extends State<MathKeyboard> {
  final TextEditingController _controller = TextEditingController();

  // Define your symbols with types
  final List<Map<String, dynamic>> mathKeys = [
    // Functional templates
    {"label": "x²", "type": "template", "template": "x²"},
    {"label": "xⁿ", "type": "template", "template": "x^□"},
    {"label": "√", "type": "template", "template": "√(□)"},
    {"label": "ⁿ√□", "type": "template", "template": "□√(□)"},
    {"label": "logₐ", "type": "template", "template": "log_{□}(□)"},
    {"label": "∫", "type": "template", "template": "∫_{□}^{□} (□ dx)"},
    {"label": "d/dx", "type": "template", "template": "d/dx (□)"},
    {"label": "lim", "type": "template", "template": "lim_{x→□} (□)"},
    {"label": "Σ", "type": "template", "template": "Σ_{n=□}^{□} (□)"},
    {"label": "sin", "type": "template", "template": "sin(□)"},
    {"label": "cos", "type": "template", "template": "cos(□)"},
    {"label": "tan", "type": "template", "template": "tan(□)"},

    // Static symbols
    {"label": "π", "type": "static"},
    {"label": "θ", "type": "static"},
    {"label": "∞", "type": "static"},
    {"label": "≥", "type": "static"},
    {"label": "≤", "type": "static"},
    {"label": "÷", "type": "static"},
    {"label": "·", "type": "static"},
    {"label": "≠", "type": "static"},
  ];

  void insertText(String text) {
    final selection = _controller.selection;
    final newText = _controller.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    final newPosition = selection.start + text.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Math Keyboard")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter math expression",
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1.5,
              ),
              itemCount: mathKeys.length,
              itemBuilder: (context, index) {
                final keyData = mathKeys[index];
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (keyData["type"] == "static") {
                        insertText(keyData["label"]);
                      } else if (keyData["type"] == "template") {
                        insertText(keyData["template"]);
                      }
                    },
                    child: Text(
                      keyData["label"],
                      style: TextStyle(fontSize: 18),
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
}
How It Works
Static buttons → just insert symbol text.

Functional buttons → insert a template with placeholders (□).

You can later replace placeholders with a better editable math widget using flutter_math_fork so it displays as real math formatting.

