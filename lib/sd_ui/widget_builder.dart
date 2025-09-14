import 'package:flutter/material.dart';

abstract class WidgetBuilder {
  Widget build(Map<String, dynamic> json, BuildContext context);
  bool canHandle(String type);
}

class CompositeWidgetBuilder implements WidgetBuilder {
  final List<WidgetBuilder> builders;

  CompositeWidgetBuilder(this.builders);

  @override
  Widget build(Map<String, dynamic> json, BuildContext context) {
    final type = json["type"] as String?;
    if (type == null) return const SizedBox();

    for (final builder in builders) {
      if (builder.canHandle(type)) {
        return builder.build(json, context);
      }
    }
    return const SizedBox();
  }

  @override
  bool canHandle(String type) => true;
}
