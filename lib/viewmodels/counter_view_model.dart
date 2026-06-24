import 'package:flutter/foundation.dart';

import '../models/counter_model.dart';

class CounterViewModel extends ChangeNotifier {
  CounterModel _counter = const CounterModel();

  int get counter => _counter.value;

  void increment() {
    _counter = _counter.copyWith(value: _counter.value + 1);
    notifyListeners();
  }
}
