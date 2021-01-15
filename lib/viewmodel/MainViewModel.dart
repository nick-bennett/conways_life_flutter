import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../model/Terrain.dart';

class MainViewModel {
  static const _size = 500;

  final _density;
  final _iterationStreamController;
  final _populationStreamController;
  final _cellsStreamController;
  final _receivePort;
  Isolate _runner;
  SendPort _sendPort;
  bool _running;

  Stream<int> get iterationStream => _iterationStreamController.stream;

  Stream<int> get populationStream => _populationStreamController.stream;

  Stream<List<Uint8ClampedList>> get cellsStream => _cellsStreamController;

  MainViewModel()
      : _receivePort = ReceivePort(),
        _iterationStreamController = StreamController<int>(),
        _populationStreamController = StreamController<int>(),
        _cellsStreamController = StreamController<List<Uint8ClampedList>>(),
        _density = 0.2 {
    _running = false;
    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        reset();
      } else {
        final map = message as Map<String, Object>;
        _iterationStreamController.add(map['iterations'] as int);
        _populationStreamController.add(map['population'] as int);
        _cellsStreamController.add(map['cells'] as List<Uint8ClampedList>);
        if (_running) {
          iterate();
        }
      }
    });
    Isolate.spawn(_startCA, _receivePort.sendPort).then((isolate) {
      _runner = isolate;
    });
  }

  void toggleRunning() {
    _running = !_running;
    if (_running) {
      iterate();
    }
  }

  void reset() {
    _sendPort.send({'init': true, 'size': _size, 'density': _density});
  }

  void iterate() {
    _sendPort.send({'iterate': true});
  }

  void kill() {
    _runner.kill();
  }

  static void _startCA(message) {
    SendPort sendPort = message as SendPort;
    void sendUpdate(Terrain terrain) {
      sendPort.send({
        'iterations': terrain.iterationCount,
        'population': terrain.population,
        'cells': terrain.cells,
      });
    }

    ReceivePort receivePort = ReceivePort();
    Terrain terrain;
    receivePort.listen((message) {
      final map = message as Map<String, Object>;
      if (map.containsKey('init')) {
        terrain = Terrain(map['size'] as int, map['density'] as double, Random());
        sendUpdate(terrain);
      } else if (map.containsKey('iterate')) {
        terrain.iterate();
        sendUpdate(terrain);
      }
    });
    sendPort.send(receivePort.sendPort);
  }

}

