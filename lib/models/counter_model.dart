class CounterModel {
  const CounterModel({this.value = 0});

  final int value;

  CounterModel copyWith({int? value}) {
    return CounterModel(value: value ?? this.value);
  }
}
