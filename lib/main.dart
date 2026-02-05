import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A192F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4C2),
          secondary: Color(0xFF00BFA5),
        ),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String currentInput = '0';
  String currentExpression = '';
  String result = '';

  String _preprocessImplicitMultiplication(String expr) {
    final buffer = StringBuffer();
    for (int i = 0; i < expr.length; i++) {
      final char = expr[i];
      final prev = i > 0 ? expr[i - 1] : null;

      // Insertar * antes de '(' si antes hay número, punto o ')'
      if (char == '(' && prev != null && RegExp(r'[1-9.)]').hasMatch(prev)) {
        buffer.write('*');
      }

      // Insertar * después de ')' si después hay número, punto o '('
      if (prev == ')' && RegExp(r'[1-9(]').hasMatch(char)) {
        buffer.write('*');
      }

      buffer.write(char);
    }
    return buffer.toString();
  }

  // Nueva función: verifica balance de paréntesis
  bool _areParenthesesBalanced(String expr) {
    int count = 0;
    for (var char in expr.runes) {
      if (char == '('.codeUnitAt(0)) count++;
      if (char == ')'.codeUnitAt(0)) count--;
      if (count < 0) return false; // más cierres que aperturas
    }
    return count == 0;
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) return value.toInt().toString();
    String str = value.toStringAsFixed(8);
    return str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _onButtonPressed(String value) {
    setState(() {
      // Limpiar todo
      if (value == 'AC') {
        currentInput = '0';
        currentExpression = '';
        result = '';
        return;
      }

      // Borrar último dígito del input actual
      if (value == 'DEL') {
        if (currentInput.length > 1) {
          currentInput = currentInput.substring(0, currentInput.length - 1);
        } else {
          currentInput = '0';
        }
        return;
      }

      // Evaluar
      if (value == '=') {
        String fullExpr = currentExpression + currentInput;
        fullExpr = fullExpr
            .replaceAll('x', '*')
            .replaceAll('/', '/')
            .replaceAll(' ', '');
        fullExpr = _preprocessImplicitMultiplication(fullExpr);

        print('Evaluando: $fullExpr'); // ← para depurar

        try {
          // Verificación de paréntesis
          int balance = 0;
          for (var c in fullExpr.runes) {
            if (c == '('.codeUnitAt(0)) balance++;
            if (c == ')'.codeUnitAt(0)) balance--;
            if (balance < 0) throw 'Paréntesis desbalanceados';
          }
          if (balance != 0) throw 'Paréntesis sin cerrar';

          Parser p = Parser();
          Expression exp = p.parse(fullExpr);
          double eval = exp.evaluate(EvaluationType.REAL, ContextModel());
          result = _formatNumber(eval);
          currentInput = result;
          currentExpression = '';
        } catch (e) {
          result = e.toString().contains('divide by zero')
              ? 'División por cero'
              : (e.toString().contains('Paréntesis')
                    ? e.toString()
                    : 'Error de sintaxis');
        }
        return;
      }

      // Operadores binarios
      if ('+-x/'.contains(value)) {
        // Si hay input pendiente, agregarlo
        if (currentInput.isNotEmpty && currentInput != '0') {
          currentExpression += currentInput;
          currentInput = '';
        }

        // Si el último es operador, reemplazar
        if (currentExpression.isNotEmpty &&
            '+-x/'.contains(currentExpression.trim().characters.last)) {
          currentExpression =
              currentExpression.trim().characters.skipLast(1).string.trim() +
              ' $value ';
        } else {
          currentExpression += ' $value ';
        }
        return;
      }

      // Paréntesis
      if (value == '(' || value == ')') {
        // Multiplicación implícita antes de '(' si hay número previo
        if (value == '(' && currentInput.isNotEmpty && currentInput != '0') {
          currentExpression += currentInput + ' * ';
          currentInput = '';
        }

        // Antes de agregar cualquier paréntesis, aseguramos que el input pendiente se añada
        if (currentInput.isNotEmpty && currentInput != '0') {
          currentExpression += currentInput;
          currentInput = '';
        }

        // Agregar el paréntesis
        currentExpression += value;

        // Después de cerrar ')', limpiar para que el siguiente número u operador empiece fresco
        if (value == ')') {
          currentInput = '';
        }

        return;
      }

      // Punto
      if (value == '.') {
        if (currentInput.contains('.') || currentInput.isEmpty) return;
        currentInput += value;
        return;
      }

      // Números
      if (currentInput == '0' || currentInput.isEmpty) {
        currentInput = value;
      } else {
        currentInput += value;
      }
    });
  }

  Color _buttonColor(String val) {
    if (val == '=') return const Color(0xFF00D4C2);
    if ('+-x/()'.contains(val)) return const Color(0xFF00BFA5);
    if (val == 'AC' || val == 'DEL')
      return const Color.fromARGB(255, 255, 0, 0);
    return const Color(0xFF16213E);
  }

  Widget _button(String text, {bool isLarge = false}) {
    return ElevatedButton(
      onPressed: () => _onButtonPressed(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: _buttonColor(text),
        foregroundColor: Colors.white,
        elevation: text == '=' ? 10 : 4,
        shadowColor: text == '=' ? Colors.cyan.withOpacity(0.5) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(18),
      ),
      child: text == 'DEL'
          ? const Icon(Icons.backspace_outlined, size: 26)
          : Text(
              text,
              style: TextStyle(
                fontSize: isLarge ? 40 : 28,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (currentExpression.isNotEmpty)
            Text(
              currentExpression,
              style: const TextStyle(fontSize: 26, color: Colors.white70),
            ),
          Text(
            currentInput,
            style: const TextStyle(fontSize: 68, fontWeight: FontWeight.w300),
          ),
          if (result.isNotEmpty && result != currentInput)
            Text(
              '= $result',
              style: const TextStyle(fontSize: 38, color: Color(0xFF00D4C2)),
            ),
        ],
      ),
    );
  }

  Widget _buildPortraitKeyboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ), // ← más padding lateral para no pegarse
      child: Column(
        mainAxisAlignment: MainAxisAlignment
            .spaceEvenly, // ← distribuye mejor el espacio vertical
        children: [
          Row(
            children: [
              Expanded(child: _button('AC')),
              const SizedBox(width: 12),
              Expanded(child: _button('DEL')),
              const SizedBox(width: 12),
              Expanded(child: _button('(')),
              const SizedBox(width: 12),
              Expanded(child: _button(')')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _button('7')),
              const SizedBox(width: 12),
              Expanded(child: _button('8')),
              const SizedBox(width: 12),
              Expanded(child: _button('9')),
              const SizedBox(width: 12),
              Expanded(child: _button('/')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _button('4')),
              const SizedBox(width: 12),
              Expanded(child: _button('5')),
              const SizedBox(width: 12),
              Expanded(child: _button('6')),
              const SizedBox(width: 12),
              Expanded(child: _button('x')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _button('1')),
              const SizedBox(width: 12),
              Expanded(child: _button('2')),
              const SizedBox(width: 12),
              Expanded(child: _button('3')),
              const SizedBox(width: 12),
              Expanded(child: _button('-')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _button('0')),
              const SizedBox(width: 12),
              Expanded(child: _button('.')),
              const SizedBox(width: 12),
              Expanded(child: _button('+')),
              const SizedBox(width: 12),
              Expanded(child: _button('=', isLarge: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeKeyboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 5,
        childAspectRatio: 1.4, // ← ajustado para botones más equilibrados
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _button('AC'),
          _button('DEL'),
          _button('('),
          _button(')'),
          _button('/'),

          _button('7'),
          _button('8'),
          _button('9'),
          _button('x'),
          _button('-'),

          _button('4'),
          _button('5'),
          _button('6'),
          _button('1'),
          _button('2'),

          _button('3'),
          _button('0'),
          _button('.'),
          _button('+'),
          _button('=', isLarge: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return Column(
                children: [
                  Expanded(flex: 3, child: _buildDisplay()),
                  Expanded(
                    flex: 6,
                    child: _buildPortraitKeyboard(),
                  ), // ← más espacio para teclado
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildDisplay(),
                  ), // ← display más pequeño en horizontal
                  Expanded(
                    flex: 7,
                    child: _buildLandscapeKeyboard(),
                  ), // ← teclado ocupa más espacio
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
