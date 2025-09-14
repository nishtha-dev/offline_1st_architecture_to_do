
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:to_dp/sd_ui/sd_ui.dart';



typedef StacAction = Map<String, dynamic>;








abstract class WidgetParser {
  String get type;
  Widget parse(Map<String, dynamic> json, BuildContext context);
}

class WidgetFactory {
  final Map<String, WidgetParser> _parsers = {};

  void register(WidgetParser parser) {
    _parsers[parser.type] = parser;
  }

  Widget fromJson(Map<String, dynamic> json, BuildContext context) {
    final type = json["type"];
    final parser = _parsers[type];
    if (parser == null) {
      return const SizedBox(); // fallback
    }
    return parser.parse(json, context);
  }
}




















// Call this function at app startup (e.g., in main())

