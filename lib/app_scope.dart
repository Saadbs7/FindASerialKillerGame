import 'package:flutter/widgets.dart';
import 'game_controller.dart';

class GameScope extends InheritedNotifier<GameController> {
  const GameScope({super.key, required GameController controller, required super.child}) : super(notifier: controller);
  static GameController of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GameScope>()!.notifier!;
}

