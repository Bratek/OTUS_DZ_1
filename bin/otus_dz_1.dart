import 'dart:math';

enum TokenType { number, operation, parenthesis }

enum Operation {
  plus,
  minus,
  multiply,
  divide,
  power,
  unaryMinus;

  int priority() => switch (this) {
    Operation.power => 4,
    Operation.unaryMinus => 3,
    Operation.multiply || Operation.divide => 2,
    Operation.plus || Operation.minus => 1,
  };

  static Operation? fromString(String op, {bool isUnary = false}) {
    if (isUnary && op == '-') return Operation.unaryMinus;
    return switch (op) {
      '+' => Operation.plus,
      '-' => Operation.minus,
      '*' => Operation.multiply,
      '/' => Operation.divide,
      '^' => Operation.power,
      _ => null,
    };
  }

  double apply(double arg1, [double? arg2]) {
    return switch (this) {
      Operation.plus => arg1 + (arg2 ?? 0),
      Operation.minus => arg1 - (arg2 ?? 0),
      Operation.multiply => arg1 * (arg2 ?? 1),
      Operation.divide => arg2 != 0 ? arg1 / arg2! : throw ArgumentError("Division by zero"),
      Operation.power => pow(arg1, arg2!).toDouble(),
      Operation.unaryMinus => -arg1,
    };
  }
}

/// Тип данных для хранения токенов
/// TokenType - тип токена
/// Value - значение токена (например, число или оператор)
/// isUnary - является ли унарным оператором
class Token {
  final TokenType type;
  final String value;
  final bool isUnary;

  Token(this.type, this.value, {this.isUnary = false});
}

/// Вычисляемая машина
class Abacus {
  String expression;
  Map<String, double> values;

  Abacus(this.expression, this.values);

  /// Вычисление выражения (основная функция)
  /// Возвращает результат вычисления
  double calculate() {
    // 1. Подстановка переменных
    String processedExp = expression;
    values.forEach((key, value) {
      processedExp = processedExp.replaceAll(key, value.toString());
    });

    // 2. Токенизация с учетом унарных знаков
    List<Token> tokens = _tokenize(processedExp);

    // 3. Преобразование в обратную польскую запись (RPN)
    List<Token> rpn = _convertToRPN(tokens);

    // 4. Вычисление обратной польской записи (RPN)
    return _calculateRPN(rpn);
  }

  /// Преобразование данных через токены (Токенизация)
  /// Возвращает сформированный список токенов
  /// input - входная строка выражения
  List<Token> _tokenize(String input) {
    List<Token> tokens = [];
    String numberBuffer = ""; //буфер для сборки числа из символов

    for (int i = 0; i < input.length; i++) {
      String char = input[i];

      if (RegExp(r'[0-9.]').hasMatch(char)) {
        numberBuffer += char;
      } else {
        if (numberBuffer.isNotEmpty) {
          tokens.add(Token(TokenType.number, numberBuffer));
          numberBuffer = "";
        }

        if (char == '(' || char == ')') {
          tokens.add(Token(TokenType.parenthesis, char));
        } else if (Operation.fromString(char) != null) {
          // Проверка на унарный минус: если это начало строки или перед ним скобка/оператор
          bool isUnary = false;
          if (char == '-') {
            if (tokens.isEmpty ||
                (tokens.last.type == TokenType.parenthesis && tokens.last.value == '(') ||
                tokens.last.type == TokenType.operation) {
              isUnary = true;
            }
          }
          tokens.add(Token(TokenType.operation, char, isUnary: isUnary));
        }
      }
    }
    if (numberBuffer.isNotEmpty) tokens.add(Token(TokenType.number, numberBuffer));
    return tokens;
  }

  /// Преобразование в обратную польскую запись (RPN)
  /// Возвращает список токенов в обратной польской записи
  List<Token> _convertToRPN(List<Token> tokens) {
    List<Token> output = [];
    List<Token> stack = [];

    for (var token in tokens) {
      if (token.type == TokenType.number) {
        output.add(token);
      } else if (token.type == TokenType.operation) {
        var op1 = Operation.fromString(token.value, isUnary: token.isUnary)!;
        while (stack.isNotEmpty && stack.last.type == TokenType.operation) {
          var op2 = Operation.fromString(stack.last.value, isUnary: stack.last.isUnary)!;
          // Унарный оператор имеет высокий приоритет и правоассоциативен
          if (op1.priority() <= op2.priority() && !token.isUnary) {
            output.add(stack.removeLast());
          } else {
            break;
          }
        }
        stack.add(token);
      } else if (token.value == '(') {
        stack.add(token);
      } else if (token.value == ')') {
        while (stack.isNotEmpty && stack.last.value != '(') {
          output.add(stack.removeLast());
        }
        stack.removeLast(); // Удаляем '('
      }
    }

    while (stack.isNotEmpty) {
      output.add(stack.removeLast());
    }

    return output;
  }

  /// Вычисление обратной польской записи (RPN)
  /// rpn - список токенов в обратной польской записи
  /// Возвращает результат вычисления
  double _calculateRPN(List<Token> rpn) {
    List<double> stack = [];

    for (var token in rpn) {
      if (token.type == TokenType.number) {
        stack.add(double.parse(token.value));
      } else {
        var op = Operation.fromString(token.value, isUnary: token.isUnary)!;
        if (token.isUnary) {
          double a = stack.removeLast();
          stack.add(op.apply(a));
        } else {
          double b = stack.removeLast();
          double a = stack.removeLast();
          stack.add(op.apply(a, b));
        }
      }
    }
    return stack.first;
  }
}

void main() {
  print(Abacus("-10+x^2-5*x+(12/2)", {"x": 3}).calculate());
  print(Abacus("-x + (y * -3) + 2^3", {'x': 10.0, 'y': 2.0}).calculate());
  print(Abacus("-x + (2 * -y)", {"x": 5, "y": 3}).calculate());
  print(Abacus("x + -y + 2", {"x": 4, "y": 5}).calculate());
  print(Abacus("10*5+4/2-1", {}).calculate());
  print(Abacus("(x*3-5)/5", {"x": 10}).calculate());
  print(Abacus("3*x+15/(3+2)", {"x": 10}).calculate());
}
