// lib/models/shell_model.dart

enum ShellState { hidden, found, wrong }

class ShellModel {
  final int number; // 1–8
  final int group;    // 1 = Group A (shells 1-4), 2 = Group B (shells 5-8)
  ShellState state;
  String? tagId;

  ShellModel({required this.number, this.state = ShellState.hidden})
    : group = number <= 4 ? 1 : 2;

  bool get isFound => state == ShellState.found;
  bool get isWrong => state == ShellState.wrong;
  bool get isHidden => state == ShellState.hidden;
}
