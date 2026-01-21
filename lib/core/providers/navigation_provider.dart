import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationIndexNotifier extends Notifier<int> {
  final List<int> _history = [];
  final List<int> _forwardStack = [];

  @override
  int build() => 0;

  void setIndex(int index, {bool isInternal = false}) {
    if (state == index) return;
    if (!isInternal) {
      _history.add(state);
      _forwardStack.clear();
    }
    state = index;
  }

  bool get canGoBack => _history.isNotEmpty;
  bool get canGoForward => _forwardStack.isNotEmpty;

  void goBack() {
    if (_history.isNotEmpty) {
      _forwardStack.add(state);
      state = _history.removeLast();
    }
  }

  void goForward() {
    if (_forwardStack.isNotEmpty) {
      _history.add(state);
      state = _forwardStack.removeLast();
    }
  }

  @override
  set state(int value) => super.state = value;
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  () => NavigationIndexNotifier(),
);
