import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {
  Debouncer(this.interval);
  final Duration interval;

  VoidCallback? _action;
  Timer? _timer;

  void call(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _timer = Timer(interval, _callAction);
  }

  void _callAction() {
    _action?.call();
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    _action = null;
    _timer?.cancel();
    _timer = null;
  }
}
