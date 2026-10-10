import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        // Единый стиль для текстовых полей
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.indigo.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
  final _formKey = GlobalKey<FormState>();
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();
  
  // Доступные операции
  final List<String> _operations = ['+', '-', '×', '÷'];
  int _selectedOperationIndex = 0; // По умолчанию выбран плюс
  String _result = '';

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      final num1 = double.parse(_firstController.text.replaceAll(',', '.'));
      final num2 = double.parse(_secondController.text.replaceAll(',', '.'));
      double res = 0;

      switch (_selectedOperationIndex) {
        case 0:
          res = num1 + num2;
          break;
        case 1:
          res = num1 - num2;
          break;
        case 2:
          res = num1 * num2;
          break;
        case 3:
          if (num2 == 0) {
            setState(() => _result = 'Ошибка: деление на 0');
            return;
          }
          res = num1 / num2;
          break;
      }

      // Убираем лишние нули после запятой, если число целое
      setState(() {
        if (res % 1 == 0) {
          _result = res.toInt().toString();
        } else {
          _result = res.toStringAsFixed(3);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Калькулятор',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                // Первое число
                TextFormField(
                  controller: _firstController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Первое число',
                    hintText: 'Введите значение',
                    prefixIcon: Icon(Icons.looks_one_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите первое число';
                    if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Введите корректное число';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Второе число
                TextFormField(
                  controller: _secondController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Второе число',
                    hintText: 'Введите значение',
                    prefixIcon: Icon(Icons.looks_two_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите второе число';
                    if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Введите корректное число';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Красивый кастомный выбор операций
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_operations.length, (index) {
                    final isSelected = _selectedOperationIndex == index;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () => setState(() => _selectedOperationIndex = index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.primaryContainer.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _operations[index],
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                
                // Главная кнопка расчета
                FilledButton(
                  onPressed: _calculate,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Рассчитать',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                
                // Визуальный блок с результатом (появляется при расчете)
                if (_result.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Результат вычислений',
                            style: TextStyle(color: theme.colorScheme.onSecondaryContainer.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _result,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
