import 'dart:async';

import 'package:flutter/material.dart';
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


/// ------------------------------------------------------------
/// 1. Navigation Types
/// ------------------------------------------------------------
///
abstract class StacActionParser<T> {
  const StacActionParser();

  String get actionType;

  T getModel(StacAction json);

  FutureOr<dynamic> onCall(BuildContext context, T model);
}

void main() {
  final actionHandler = ActionHandler();
  final WidgetFactory widgetFactory = WidgetFactory();
    widgetFactory..register(TextParser(actionHandler))
    ..register(ImageParser(actionHandler))
    ..register(CardParser(actionHandler, widgetFactory))
    ..register(ExampleButtonParser(actionHandler))
    ..register(ColumnParser(widgetFactory));
  
  final widget = widgetFactory.fromJson(jsonData, context);
}

// void initializeWidgetFactory(WidgetFactory widgetFactory, ActionHandler actionHandler) {
//   widgetFactory = WidgetFactory()
//     ..register(TextParser(actionHandler))
//     ..register(ImageParser(actionHandler))
//     ..register(CardParser(actionHandler, widgetFactory))
//     ..register(ExampleButtonParser(actionHandler));
// }

enum NavigationStyle {
  push,
  pop,
  // pushReplacement,
  // pushAndRemoveAll,
  // popAll,
  pushNamed,
  // pushNamedAndRemoveAll,
  // pushReplacementNamed,
}

/// ------------------------------------------------------------
/// 2. Base Action Interface
/// ------------------------------------------------------------
abstract class Action {
  String get type;


  static Action? fromJson(Map<String, dynamic>? json, BuildContext context) {
    if (json == null) return null;
    switch (json["type"]) {
      case "navigate":
        return NavigateAction.fromJson(json, context);
      default:
        return null;
    }
  }
}

/// ------------------------------------------------------------
/// 3. Navigation Action
/// ------------------------------------------------------------
class NavigateAction implements Action {
  @override
  final String type = "navigate";

  final NavigationStyle navigationStyle;
  final String? route;
  final Map<String, dynamic>? arguments;
  final Widget? widget;

  NavigateAction({
    required this.navigationStyle,
    this.route,
    this.arguments,
    this.widget,
  });

  factory NavigateAction.fromJson(Map<String, dynamic> json, BuildContext context) {
    return NavigateAction(
      navigationStyle: NavigationStyle.values.firstWhere(
        (e) => e.toString().split('.').last == (json["style"] ?? "pushNamed"),
        orElse: () => NavigationStyle.pushNamed,
      ),
      route: json["route"] as String?,
      arguments: json["arguments"] as Map<String, dynamic>?,
      widget: json["widget"] != null
          ? widgetFactory.fromJson(json["widget"], context)
          : null
    );
  }

}


/// ------------------------------------------------------------
/// 5. Navigation Service
/// ------------------------------------------------------------
class NavigationService {
  static Future<dynamic>? navigate<T extends Object?>({
    required BuildContext context,
    required NavigationStyle navigationStyle,
    Widget? widget,
    String? routeName,
    T? result,
    T? arguments,
  }) {
    switch (navigationStyle) {
      case NavigationStyle.push:
        return Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => widget ?? const SizedBox()),
        );

      case NavigationStyle.pop:
        Navigator.pop(context, result);
        break;
      //  case NavigationStyle.pushReplacementNamed:
      //   return Navigator.pushReplacementNamed(
      //     context,
      //     routeName!,
      //     result: result,
      //     arguments: arguments,
      //   );
      case NavigationStyle.pushNamed:
        return Navigator.pushNamed(
          context,
          routeName!,
          arguments: arguments,
        );

      // case NavigationStyle.pushReplacement:
      //   return Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => widget ?? const SizedBox()),
      //     result: result,
      //   );

      // case NavigationStyle.pushAndRemoveAll:
      //   return Navigator.pushAndRemoveUntil(
      //     context,
      //     MaterialPageRoute(builder: (_) => widget ?? const SizedBox()),
      //     ModalRoute.withName('/'),
      //   );

      // case NavigationStyle.popAll:
      //   Navigator.popUntil(context, ModalRoute.withName('/'));
      //   break;

      

      // case NavigationStyle.pushNamedAndRemoveAll:
      //   return Navigator.pushNamedAndRemoveUntil(
      //     context,
      //     routeName!,
      //     ModalRoute.withName('/'),
      //     arguments: arguments,
      //   );

     
    }

    return null;
  }
}

/// ------------------------------------------------------------
/// 6. Action Handler
/// ------------------------------------------------------------
class ActionHandler {
  void handle(Action action, BuildContext context) {
    if (action is NavigateAction) {
      NavigationService.navigate(
        context: context,
        navigationStyle: action.navigationStyle,
        routeName: action.route,
        arguments: action.arguments,
      );
    }
    // 🔥 Add more actions (dialog, API call, openUrl, etc.)
  }
}

/// ------------------------------------------------------------
/// 7. Example Usage
/// ------------------------------------------------------------
///
Widget withAction({
  required Map<String, dynamic> json,
  required Widget child,
  required BuildContext context,
  required ActionHandler handler,
}) {
  final action = Action.fromJson(json["action"], context);
  if (action == null) return child;

  return GestureDetector(
    onTap: () => handler.handle(action, context),
    behavior: HitTestBehavior.opaque, // ensures full area is tappable
    child: child,
  );
}

class ExampleButtonParser implements WidgetParser {
  final ActionHandler actionHandler;

  ExampleButtonParser(this.actionHandler);

  Widget parse(Map<String, dynamic> json, BuildContext context) {
    final label = json["label"] ?? "Button";
    return withAction(
        handler: actionHandler,
        context: context,
        json: json,
        child: Text(label));
  }

  @override
  String get type => "button";
}

class CardParser implements WidgetParser {
  final ActionHandler actionHandler;
  final WidgetFactory widgetFactory;

  CardParser(this.actionHandler, this.widgetFactory);

  @override
  String get type => "card";

  @override
  Widget parse(Map<String, dynamic> json, BuildContext context) {
    final childJson = json["child"] as Map<String, dynamic>? ?? {};
    final child = widgetFactory.fromJson(childJson, context);
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: child,
      ),
    );
    return withAction(
        json: json, handler: actionHandler, context: context, child: card);
  }
}


const TextAlignEnumMap = {
  TextAlign.left: 'left',
  TextAlign.right: 'right',
  TextAlign.center: 'center',
  TextAlign.justify: 'justify',
  TextAlign.start: 'start',
  TextAlign.end: 'end',
};

class TextParser implements WidgetParser {
  final ActionHandler actionHandler;

  TextParser(
    this.actionHandler,
  );

  @override
  String get type => "text";

  @override
  Widget parse(Map<String, dynamic> json, BuildContext context) {
    final text = Text(
      json["value"] ?? "",
      style: _mapStyle(json["style"]),
      textAlign: TextAlignEnumMap.entries
          .firstWhere(
        (entry) => entry.value == json["textAlign"],
        orElse: () => const MapEntry(TextAlign.start, 'start'),
          )
          .key,
      // textDirection: model.textDirection,
      // softWrap: model.softWrap,
      // overflow: model.overflow,
      // textScaler: model.textScaleFactor != null
      //     ? TextScaler.linear(model.textScaleFactor!.parse)
      //     : TextScaler.noScaling,
      // maxLines: model.maxLines,
      // semanticsLabel: model.semanticsLabel,
      // textWidthBasis: model.textWidthBasis,
      // selectionColor: model.selectionColor.toColor(context),
    );
    return withAction(
        json: json, handler: actionHandler, context: context, child: text);
  }

  TextStyle _mapStyle(Map<String, dynamic>? style) {
    if (style == null) return const TextStyle();

    final fontSize = style["fontSize"] as double? ?? 14;
    final fontWeight = style["fontWeight"] == "bold"
        ? FontWeight.bold
        : FontWeight.normal;

    return TextStyle(fontSize: fontSize, fontWeight: fontWeight);
  }
  }


class ColumnParser implements WidgetParser {
  final WidgetFactory widgetFactory;

  ColumnParser(this.widgetFactory);

  @override
  String get type => "column";

  @override
  Widget parse(Map<String, dynamic> json, BuildContext context) {
    final children = (json["children"] as List<dynamic>? ?? [])
        .map((c) => widgetFactory.fromJson(c, context))
        .toList();
    return Column(children: children);
  }
}

class ImageParser implements WidgetParser {
  final ActionHandler actionHandler;

  ImageParser(this.actionHandler);

  @override
  String get type => "image";

  @override
  Widget parse(Map<String, dynamic> json, BuildContext context) {
    final url = json["url"];
    final image = Image.network(url ?? "", fit: BoxFit.cover);

    return withAction(
      json: json,
      child: image,
      context: context,
      handler: actionHandler,
    );
  }
}

// {
//   "type": "card",
//   "action": {
//     "type": "navigate",
//     "style": "pushNamed",
//     "route": "/details",
//     "arguments": {
//       "itemId": 123
//     }
//   },
//   "child": {
//     "type": "column",
//     "children": [
//       {
//         "type": "image",
//         "url": "https://picsum.photos/200/300",
//         "action": {
//           "type": "navigate",
//           "style": "push",
//           "route": "/image-view"
//         }
//       },
//       {
//         "type": "text",
//         "value": "Welcome to Flutter UI",
//         "style": {
//           "fontSize": 24,
//           "fontWeight": "bold"
//         },
//         "textAlign": "center"
//       },
//       {
//         "type": "text",
//         "value": "This is a dynamic UI built from JSON",
//         "style": {
//           "fontSize": 16
//         },
//         "textAlign": "center"
//       },
//       {
//         "type": "button",
//         "label": "Click Me!",
//         "action": {
//           "type": "navigate",
//           "style": "pushNamed",
//           "route": "/action",
//           "arguments": {
//             "source": "button_click"
//           }
//         }
//       }
//     ]
//   }
// }

