import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  () => NavigationIndexNotifier(),
);
