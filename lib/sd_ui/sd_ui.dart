// import 'dart:async';

// import 'package:flutter/material.dart';


// // Declare widgetFactory as late to break the cycle


// /// ------------------------------------------------------------
// /// 1. Navigation Types
// /// ------------------------------------------------------------
// /// 
// /// 
// enum NavigationStyle {
//   push,
//   pop,
//   pushReplacement,
//   pushAndRemoveAll,
//   popAll,
//   pushNamed,
//   pushNamedAndRemoveAll,
//   pushReplacementNamed,
// }

// // abstract class StacActionParser<T> {
// //   const StacActionParser();


// //   String get actionType;

// //   T getModel(StacAction json);

// //   FutureOr<dynamic> onCall(BuildContext context, T model);
// // }

// /// ------------------------------------------------------------
// /// 2. Base Action Interface
// /// ------------------------------------------------------------
// abstract class StacAction {
//   String get type;
// }

// /// ------------------------------------------------------------
// /// 3. Navigation Action
// /// ------------------------------------------------------------
// class StacNavigateAction implements StacAction {
//   @override
//   final String type = "navigate";

//   final NavigationStyle navigationStyle;
//   final String? route;
//   final Map<String, dynamic>? arguments;
//   final Widget? widget;

//   StacNavigateAction({
//     required this.navigationStyle,
//     this.route,
//     this.arguments,
//     this.widget,
//   });

//   factory StacNavigateAction.fromJson(Map<String, dynamic> json, BuildContext context) {
//     return StacNavigateAction(
//       navigationStyle: NavigationStyle.values.firstWhere(
//         (e) => e.toString().split('.').last == (json["style"] ?? "pushNamed"),
//         orElse: () => NavigationStyle.pushNamed,
//       ),
//       route: json["route"] as String?,
//       arguments: json["arguments"] as Map<String, dynamic>?,
//       widget: widgetFactory.fromJson(json["widget"] , context)
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         "type": type,
//         "style": navigationStyle.toString().split('.').last,
//         if (route != null) "route": route,
//         if (arguments != null) "arguments": arguments,
//       };
// }

// /// ------------------------------------------------------------
// /// 4. Action Parser
// /// ------------------------------------------------------------
// class StacActionParser {
//   static StacAction? fromJson(Map<String, dynamic>? json) {
//     if (json == null) return null;
//     switch (json["type"]) {
//       case "navigate":
//         return StacNavigateAction.fromJson(json);
//       default:
//         return null;
//     }
//   }
// }

// /// ------------------------------------------------------------
// /// 5. Navigation Service
// /// ------------------------------------------------------------
// class NavigationService {
//   static Future<dynamic>? navigate<T extends Object?>({
//     required BuildContext context,
//     required NavigationStyle navigationStyle,
//     Widget? widget,
//     String? routeName,
//     T? result,
//     T? arguments,
//   }) {
//     switch (navigationStyle) {
//       case NavigationStyle.push:
//         return Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => widget ?? const SizedBox()),
//         );

//       case NavigationStyle.pop:
//         Navigator.pop(context, result);
//         break;

//       case NavigationStyle.pushReplacement:
//         return Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => widget ?? const SizedBox()),
//           result: result,
//         );

//       case NavigationStyle.pushAndRemoveAll:
//         return Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => widget ?? const SizedBox()),
//           ModalRoute.withName('/'),
//         );

//       case NavigationStyle.popAll:
//         Navigator.popUntil(context, ModalRoute.withName('/'));
//         break;

//       case NavigationStyle.pushNamed:
//         return Navigator.pushNamed(
//           context,
//           routeName!,
//           arguments: arguments,
//         );

//       case NavigationStyle.pushNamedAndRemoveAll:
//         return Navigator.pushNamedAndRemoveUntil(
//           context,
//           routeName!,
//           ModalRoute.withName('/'),
//           arguments: arguments,
//         );

//       case NavigationStyle.pushReplacementNamed:
//         return Navigator.pushReplacementNamed(
//           context,
//           routeName!,
//           result: result,
//           arguments: arguments,
//         );
//     }

//     return null;
//   }
// }

// Widget withAction({
//   required Map<String, dynamic> json,
//   required Widget child,
//   required BuildContext context,
//   required ActionHandler handler,
// }) {
//   final action = StacActionParser.fromJson(json["action"]);
//   if (action == null) return child;

//   return GestureDetector(
//     onTap: () => handler.handle(action, context),
//     behavior: HitTestBehavior.opaque, // ensures full area is tappable
//     child: child,
//   );
// }



// /// ------------------------------------------------------------
// /// 6. Action Handler
// /// ------------------------------------------------------------
// class ActionHandler {
//   void handle(StacAction action, BuildContext context) {
//     if (action is StacNavigateAction) {
//       NavigationService.navigate(
//         context: context,
//         navigationStyle: action.navigationStyle,
//         routeName: action.route,
//         arguments: action.arguments,
//         widget: action.widget
//       );
//     }
//     // 🔥 Add more actions (dialog, API call, openUrl, etc.)
//   }
// }

// /// ------------------------------------------------------------
// /// 7. Example Usage
// /// ------------------------------------------------------------
// class ExampleButtonParser {
//   final ActionHandler actionHandler;

//   ExampleButtonParser(this.actionHandler);

//   Widget parse(Map<String, dynamic> json, BuildContext context) {
//     final label = json["label"] ?? "Button";
//     final actionJson = json["action"] as Map<String, dynamic>?;
//     final action = StacActionParser.fromJson(actionJson);

//     return ElevatedButton(
//       onPressed: action == null
//           ? null
//           : () => actionHandler.handle(action, context),
//       child: Text(label),
//     );
//   }
// }





