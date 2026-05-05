import 'package:flutter/material.dart';
import 'package:smooth_transition/smooth_transition.dart';

class AppNavigator {
  static Future<T?> push<T>(BuildContext context, Widget page) {
    final route = PageTransition(
      child: page,
      type: PageTransitionType.fadeThrough,
      duration: const Duration(milliseconds: 400),
    );
    return Navigator.push<T>(context, route as Route<T>);
  }

  static Future<T?> pushReplacement<T, TO>(BuildContext context, Widget page) {
    final route = PageTransition(
      child: page,
      type: PageTransitionType.fadeThrough,
      duration: const Duration(milliseconds: 400),
    );
    return Navigator.pushReplacement<T, TO>(context, route as Route<T>);
  }

  static Future<T?> pushAndRemoveUntil<T>(BuildContext context, Widget page) {
    final route = PageTransition(
      child: page,
      type: PageTransitionType.fadeThrough,
      duration: const Duration(milliseconds: 400),
    );
    return Navigator.pushAndRemoveUntil<T>(
      context,
      route as Route<T>,
      (route) => false,
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }
}
