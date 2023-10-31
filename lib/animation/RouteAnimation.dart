import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRoute<T> {
  final Widget child;
  FadePageRoute(this.child);
  @override
  Color get barrierColor => Colors.black;
  @override
  Null get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

class SlidePageRoute<T> extends PageRoute<T> {
  final Widget child;
  SlidePageRoute(this.child);
  @override
  Color get barrierColor => Colors.black.withOpacity(0.6);
  @override
  Null get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);
  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.ease;
    return SlideTransition(
        position: animation.drive(Tween(begin: begin, end: end).chain(CurveTween(curve: curve))),
        child: child);
  }
}
