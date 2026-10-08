import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const Lab4App());
}

class Lab4App extends StatelessWidget {
  const Lab4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Лабораторная 4 — Cubit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainScreenProvider(),
    );
  }
}

// ============================ СОСТОЯНИЯ ============================

/// Базовый класс состояний главного экрана.
/// Все возможные "экраны" приложения — наследники этого класса.
abstract class MainScreenState {
  const MainScreenState();
}

/// Состояние "экран ввода данных" (бывший первый экран).
class MainScreenInput extends MainScreenState {
  const MainScreenInput();
}

/// Состояние "экран результата" (бывший второй экран).
/// Результат хранится прямо в состоянии — передавать его
/// через аргументы Navigator больше не нужно.
class MainScreenResult extends MainScreenState {
  final double first;
  final double second;
  final String operation;
  final double result;

  const MainScreenResult({
    required this.first,
    required this.second,
    required this.operation,
    required this.result,
  });
}

/// Состояние ошибки валидации ввода.
class MainScreenError extends MainScreenState {
  final String message;

  const MainScreenError(this.message);
}

// ============================ КУБИТ ============================

/// Кубит главного экрана.
/// Вся бизнес-логика (расчёты) вынесена сюда, UI только читает состояние.
class MainScreenCubit extends Cubit<MainScreenState> {
  MainScreenCubit() : super(const MainScreenInput());

  /// Расчёт — единственное место, где "живёт" формула.
  void calculate({
    required String firstText,
    required String secondText,
    required String operation,
  }) {
    final first = double.tryParse(firstText.replaceAll(',', '.'));
    final second = double.tryParse(secondText.replaceAll(',', '.'));

    if (first == null || second == null) {
      emit(const MainScreenError('Введите корректные числа'));
      return;
    }

    double result;
    switch (operation) {
      case '+':
        result = first + second;
        break;
      case '-':
        result = first - second;
        break;
      case '*':
        result = first * second;
        break;
      case '/':
        if (second == 0) {
          emit(const MainScreenError('Деление на ноль невозможно'));
          return;
        }
        result = first / second;
        break;
      default:
        emit(const MainScreenError('Неизвестная операция'));
        return;
    }

    // Вместо Navigator.push — смена состояния:
    emit(
      MainScreenResult(
        first: first,
        second: second,
        operation: operation,
        result: result,
      ),
    );
  }

  /// Вместо Navigator.pop — возврат к состоянию ввода.
  void backToInput() {
    emit(const MainScreenInput());
  }
}

// ============================ ПРОВАЙДЕР ============================

/// Провайдер кубита: оборачивает экран, чтобы все виджеты
/// имели доступ к одному экземпляру MainScreenCubit.
class MainScreenProvider extends StatelessWidget {
  const MainScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MainScreenCubit(),
      child: const MainScreen(),
    );
  }
}

// ============================ ЭКРАН ============================

/// Экран приложения: один виджет, который в зависимости от состояния
/// кубита показывает "экран ввода", "экран результата" или ошибку.
/// Никакого Navigator — смена экранов происходит через emit состояний.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: BlocBuilder<MainScreenCubit, MainScreenState>(
          builder: (context, state) {
            if (state is MainScreenResult) {
              return const Text('Результат');
            }
            return const Text('Калькулятор');
          },
        ),
      ),
      body: BlocBuilder<MainScreenCubit, MainScreenState>(
        builder: (context, state) {
          if (state is MainScreenInput) {
            return const _InputView();
          }
          if (state is MainScreenResult) {
            return _ResultView(state: state);
          }
          if (state is MainScreenError) {
            return _ErrorView(message: state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------- "Экран ввода" ----------

class _InputView extends StatefulWidget {
  const _InputView();

  @override
  State<_InputView> createState() => _InputViewState();
}

class _InputViewState extends State<_InputView> {
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();
  String _operation = '+';

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MainScreenCubit>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _firstController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Первое число',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _secondController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Второе число',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '+', label: Text('+')),
              ButtonSegment(value: '-', label: Text('−')),
              ButtonSegment(value: '*', label: Text('×')),
              ButtonSegment(value: '/', label: Text('÷')),
            ],
            selected: {_operation},
            onSelectionChanged: (selected) =>
                setState(() => _operation = selected.first),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => cubit.calculate(
              firstText: _firstController.text,
              secondText: _secondController.text,
              operation: _operation,
            ),
            child: const Text('Рассчитать'),
          ),
        ],
      ),
    );
  }
}

// ---------- "Экран результата" ----------

class _ResultView extends StatelessWidget {
  final MainScreenResult state;

  const _ResultView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MainScreenCubit>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_fmt(state.first)} ${state.operation} ${_fmt(state.second)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '= ${_fmt(state.result)}',
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: cubit.backToInput,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Новый расчёт'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double value) {
    final fixed = value.toStringAsFixed(4);
    return fixed.replaceAll(RegExp(r'0+$'), '').replaceAll('.', ',');
  }
}

// ---------- Состояние ошибки ----------

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MainScreenCubit>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: cubit.backToInput,
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}
