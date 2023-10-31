import 'package:flutter/material.dart';
import 'package:google_map/animation/RouteAnimation.dart';
import 'package:google_map/main.dart';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:vibration/vibration.dart';

class Arrived extends StatefulWidget {
  String placeName;
  Arrived({super.key, required this.placeName});

  @override
  State<Arrived> createState() => _ArrivedState();
}

class _ArrivedState extends State<Arrived> {
  bool vibrating = true;
  vibrate() async {
    while (vibrating) {
      developer.log("vibrated", name: "vibration");
      Vibration.vibrate(pattern: [500, 100, 100, 100, 500, 500]);
      await Future.delayed(const Duration(milliseconds: 1900));
    }
  }

  @override
  void initState() {
    vibrate();
    super.initState();
  }

  @override
  void dispose() {
    developer.log("canceled", name: "vibration");
    vibrating = false;
    // Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(0, 75, 0, 50),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // mainAxisSize: MainAxisSize.max,
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.placeName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Column(
                children: [
                  Transform.rotate(
                    angle: 30 * math.pi / 180,
                    child: Icon(
                      Icons.vibration,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 160,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    "已到站",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                child: Material(
                    elevation: 20,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    child: InkWell(
                        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        child: Ink(
                          height: 60,
                          // width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Theme.of(context).colorScheme.tertiaryContainer,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  size: 24.0,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '完成',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.popUntil(context, ModalRoute.withName('/'));
                        })),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
