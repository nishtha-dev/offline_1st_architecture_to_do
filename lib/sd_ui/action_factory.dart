import 'package:flutter/material.dart' hide Action;
import 'nav_parser.dart';

abstract class ActionFactory {
  Action? createFromJson(Map<String, dynamic>? json, BuildContext context);
}

class DefaultActionFactory implements ActionFactory {
  final Map<String, ActionCreator> _actionCreators = {};

  void registerActionCreator(String type, ActionCreator creator) {
    _actionCreators[type] = creator;
  }

  @override
  Action? createFromJson(Map<String, dynamic>? json, BuildContext context) {
    if (json == null) return null;
    final creator = _actionCreators[json["type"]];
    return creator?.call(json, context);
  }
}

typedef ActionCreator = Action Function(
    Map<String, dynamic> json, BuildContext context);
