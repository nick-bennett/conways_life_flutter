import 'dart:math';
import 'dart:typed_data';

class Terrain {

  static const _neighborhood = [
    [-1, -1], [-1, 0], [-1, 1],
    [ 0, -1],          [ 0, 1],
    [ 1, -1], [ 1, 0], [ 1, 1]
  ];
  static const _minNeighborsBirth = 3;
  static const _maxNeighborsBirth = 3;
  static const _minNeighborsSurvival = 2;
  static const _maxNeighborsSurvival = 3;

  final _size;

  List<Uint8ClampedList> _cells;
  List<Uint8ClampedList> _next;
  int _population;
  int _iterationCount;

  int get size => _size;

  int get population => _population;

  int get iterationCount => _iterationCount;

  List<Uint8ClampedList> get cells => _cells;

  Terrain(int size, double density, Random rng) : _size = size {
    _cells = List.generate(size, (i) => Uint8ClampedList(size));
    _next = List.generate(size, (i) => Uint8ClampedList(size));
    _population = 0;
    _iterationCount = 0;
    for (var row in _cells) {
      for (var colIndex = 0; colIndex < row.length; colIndex++) {
        if (rng.nextDouble() < density) {
          row[colIndex] = 1;
          _population++;
        }
      }
    }
  }

  int get(int rowIndex, int colIndex) => _cells[rowIndex][colIndex];

  void set(int rowIndex, int colIndex, int age) =>
      _cells[rowIndex][colIndex] = age;

  void iterate() {
    int nextPopulation = 0;
    for (var rowIndex = 0; rowIndex < size; rowIndex++) {
      for (var colIndex = 0; colIndex < size; colIndex++) {
        final count = _countNeighbors(rowIndex, colIndex);
        var age = _cells[rowIndex][colIndex];
        age = _nextGenerationAge(age, count);
        if (age > 0) {
          nextPopulation++;
        }
        _next[rowIndex][colIndex] = age;
      }
    }
    var temp = _cells;
    _cells = _next;
    _next = temp;
    _population = nextPopulation;
    _iterationCount++;
    print(population);
  }

  void copyCells(List<Uint8ClampedList> cells) {

  }

  int _countNeighbors(int rowIndex, int colIndex) {
    var count = 0;
    for (var offsets in _neighborhood) {
      if (_cells[(rowIndex + offsets[0]) % _size]
              [(colIndex + offsets[1]) % _size] >
          0) {
        count++;
      }
    }
    return count;
  }

  int _nextGenerationAge(int age, int numNeighbors) {
    int next;
    if (age == 0) {
      next = (numNeighbors >= _minNeighborsBirth &&
              numNeighbors <= _maxNeighborsBirth)
          ? 1
          : 0;
    } else if (numNeighbors >= _minNeighborsSurvival &&
        numNeighbors <= _maxNeighborsSurvival) {
      next = age + 1;
    } else {
      next = 0;
    }
    return next;
  }


}
