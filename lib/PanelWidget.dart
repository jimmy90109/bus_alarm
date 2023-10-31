import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../model/place.dart';
import 'Confirming.dart';
import 'animation/RouteAnimation.dart';
import 'dart:developer' as developer;

class Panel extends StatefulWidget {
  final ScrollController scrollController;
  final PanelController panelController;
  final String state;
  final List<Place> placeList;

  const Panel({
    Key? key,
    required this.scrollController,
    required this.panelController,
    required this.state,
    required this.placeList,
  }) : super(key: key);

  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //final size = MediaQuery.of(context).size;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(
          height: 18.0,
        ),
        Center(
          child: GestureDetector(
              child: Container(
                width: 30,
                height: 5,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    borderRadius: const BorderRadius.all(Radius.circular(12.0))),
              ),
              onTap: () => widget.panelController.close()),
        ),
        const SizedBox(
          height: 10.0,
        ),
        Text(
          widget.state == "fav" ? "收藏地點" : "歷史地點",
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 32.0,
          ),
        ),
        widget.placeList.isNotEmpty && widget.state == "fav"
            ? Flexible(
              child: ListView.builder(
                controller: widget.scrollController,
                // physics: NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), //10 20
                  shrinkWrap: true,
                  itemCount: widget.placeList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Material(
                      type: MaterialType.transparency,
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(30),
                      // ),
                      child: InkWell(
                          // customBorder: RoundedRectangleBorder(
                          //   borderRadius: BorderRadius.circular(30),
                          // ),
                          child: ListTile(
                        leading: Icon(
                          Icons.place,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 24.0,
                        ),
                        title: Text(widget.placeList[index].name),
                        onTap: () {
                          Navigator.of(context).push(SlidePageRoute(
                            Confirming(
                                place_name: widget.placeList[index].name,
                                place_id: widget.placeList[index].id,
                                place_lat: widget.placeList[index].lat,
                                place_lng: widget.placeList[index].lng),
                          ));
                          widget.panelController.close();
                        },
                      )),
                    );
                  },
                ),
            )
            : const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text("(無)"),
                ),
              ),
      ],
    );
  }
}
