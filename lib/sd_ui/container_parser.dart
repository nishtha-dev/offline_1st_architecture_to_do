// opacity = ((opacityPercentage) * 255 / 100).round();
// int? intColor = int.tryParse(buffer.toString(), radix: 16);

// color parsing

//  if (colorString.contains(_transparencySeparator)) {
//       final parts = colorString.split(_transparencySeparator);
//       colorString = parts[0];
//       // Parse transparency percentage (0-100) and convert to alpha value (0-255)
//       final opacityPercentage = int.tryParse(parts[1]);
//       if (opacityPercentage != null &&
//           opacityPercentage >= 0 &&
//           opacityPercentage <= 100) {
//         opacity = ((opacityPercentage) * 255 / 100).round();
//       }
//     }

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:to_dp/sd_ui/sd.dart';

const String _transparencySeparator = "@";
const String _hashtag = "#";
const String _empty = "";

extension ColorExt on String? {
  Color? toColor() {
    // check if opacity present

    String colorString = this!;
    int opacity = 255; // Default: fully opaque
    if (colorString.contains(_transparencySeparator)) {
      final parts = colorString.split(_transparencySeparator);
      colorString = parts[0];
      // Parse transparency percentage (0-100) and convert to alpha value (0-255)
      final opacityPercentage = int.tryParse(parts[1]);
      if (opacityPercentage != null &&
          opacityPercentage >= 0 &&
          opacityPercentage <= 100) {
        opacity = ((opacityPercentage) * 255 / 100).round();
      }
    }

    // Ex: #000000 or #FF000000
    Color? parsedColor;
    if (colorString.startsWith(_hashtag)) {
      // parsedColor = _parseHexColor(colorString, opacity);
      // int? intColor = int.tryParse(buffer.toString(), radix: 16);
    } else {
      // Try theme color first, then named color
      // parsedColor = _parseThemeColor(colorString, context);
      // parsedColor ??= _parseNameColor(colorString);
    }
  }

  Color _parseHexColor(String color, [int alpha = 255]) {
    // Ex: #000000 or #FF000000
    final buffer = StringBuffer();
    if (color.length == 6 || color.length == 7) {
      // Add alpha channel
      buffer.write(alpha.toRadixString(16).padLeft(2, '0'));
    }
    buffer.write(color.replaceFirst(_hashtag, _empty));
    int? intColor = int.tryParse(buffer.toString(), radix: 16);
    intColor = intColor ?? 0x00000000;
    return Color(intColor);
  }
}

class ContainerModel {
  final Alignment? alignment;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;
  final String? color;
  final double? width;
  final double? height;

  final Map<String, dynamic>? child;

  const ContainerModel({
    this.alignment,
    this.padding,
    this.decoration,
    this.color,
    this.width,
    this.height,
    this.margin,
    this.child,
  });

  factory ContainerModel.fromJson(Map<String, dynamic> json) {
    return ContainerModel(
      alignment: json["alignment"],
      padding: json["padding"],
      margin: json["margin"],
      decoration: json["decoration"],
      color: json["color"] as String?,
      width: json["width"]?.toDouble(),
      height: json["height"]?.toDouble(),
      child: json["child"],
    );
  }
}

extension StacDoubleParser on double {
  double get parse {
    return this.toDouble();
  }
}

extension StacEdgeInsetsParser on EdgeInsets? {
  EdgeInsets get parse {
    return EdgeInsets.only(
      left: this?.left?.parse ?? 0,
      right: this?.right?.parse ?? 0,
      top: this?.top?.parse ?? 0,
      bottom: this?.bottom?.parse ?? 0,
    );
  }
}

// Widget parse(ContainerModel model, BuildContext context) {
//    return Container(
//       width: model.width,
//       height: model.height,
//       color: model.color != null ? model.color!.toString().toColor() : null,
//       padding: model.padding?.parse,
//       margin: model.margin?.parse,
//       child: model.child != null
//           ? widgetFactory.fromJson(model.child!, context)
//           : null,
//     );
//   }

class ContainerParser implements WidgetParser {
  final WidgetFactory widgetFactory;
  ContainerParser(this.widgetFactory);
  @override
  Widget parse(Map<String, dynamic> json, BuildContext context) {
    return Container(
      width: json["width"]?.toDouble(),
      height: json["height"]?.toDouble(),
      color: json["color"] != null ? json["color"].toString().toColor() : null,
      padding: json["padding"] != null
          ? EdgeInsets.only(
              left: json["padding"].toDouble(),
              top: json["padding"].toDouble(),
              right: json["padding"].toDouble(),
              bottom: json["padding"].toDouble(),
            )
          : null,
      margin: json["margin"] != null
          ? EdgeInsets.all(json["margin"].toDouble())
          : null,
      child: json["child"] != null
          ? widgetFactory.fromJson(json["child"], context)
          : null,
    );
  }

  @override
  String get type => "container";
}
