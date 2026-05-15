// lib/models/shell_model.dart

enum ShellState { hidden, found, wrong }

class ShellModel {
  final int number; // 1–8
  ShellState state;
  String? tagId;

  ShellModel({required this.number, this.state = ShellState.hidden});

  bool get isFound => state == ShellState.found;
  bool get isWrong => state == ShellState.wrong;
  bool get isHidden => state == ShellState.hidden;
}
