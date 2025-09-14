import 'package:flutter/material.dart';

abstract class NavigationStrategy {
  Future<dynamic>? execute({
    required BuildContext context,
    Widget? widget,
    String? routeName,
    Object? result,
    Object? arguments,
  });
}

class PushStrategy implements NavigationStrategy {
  @override
  Future<dynamic>? execute({
    required BuildContext context,
    Widget? widget,
    String? routeName,
    Object? result,
    Object? arguments,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => widget ?? const SizedBox()),
    );
  }
}

class PopStrategy implements NavigationStrategy {
  @override
  Future<dynamic>? execute({
    required BuildContext context,
    Widget? widget,
    String? routeName,
    Object? result,
    Object? arguments,
  }) {
    Navigator.pop(context, result);
    return null;
  }
}

class PushNamedStrategy implements NavigationStrategy {
  @override
  Future<dynamic>? execute({
    required BuildContext context,
    Widget? widget,
    String? routeName,
    Object? result,
    Object? arguments,
  }) {
    return Navigator.pushNamed(
      context,
      routeName!,
      arguments: arguments,
    );
  }
}

class NavigationStrategyFactory {
  static NavigationStrategy createStrategy(NavigationStyle style) {
    switch (style) {
      case NavigationStyle.push:
        return PushStrategy();
      case NavigationStyle.pop:
        return PopStrategy();
      case NavigationStyle.pushNamed:
        return PushNamedStrategy();
      default:
        throw UnimplementedError('Navigation style $style not implemented');
    }
  }
}

enum NavigationStyle {
  push,
  pop,
  pushNamed,
}
