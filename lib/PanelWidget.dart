import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../model/place.dart';
import 'Confirming.dart';
import 'animation/FadeAnimation.dart';

class Panel extends StatefulWidget {
  final ScrollController controller;
  final PanelController panelController;
  final String state;
  final List<Place> placeList;

  const Panel({
    Key? key,
    required this.controller,
    required this.panelController,
    required this.state,
    required this.placeList,
  }) : super(key: key);

  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  // List<Place> _placeList = [];
  // List<Place> temp = [];

  // void getPlaceList() async {
  //   temp = await places();
  //   print(temp);  //有東西
  //   setState(() {
  //     _placeList = temp;
  //   });
  //   print(_placeList);  //有東西
  // }

  @override
  void initState() {

    // getPlaceList();
    // _placeList = temp;
    //print(_placeList);
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    //final size = MediaQuery.of(context).size;

    // if(widget.panelController.isPanelAnimating==true){
    //   getPlaceList();
    //   print(_placeList);  //有東西
    // }

    //
    // setState(() {
    //   getPlaceList();
    //   _placeList = temp;
    //   print(_placeList);
    // });
    //print(_placeList);  //none

    return ListView(
      padding: EdgeInsets.zero,
      controller: widget.controller,
      children: <Widget>[
        SizedBox(
          height: 18.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              child: Container(
                width: 30,
                height: 5,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
              ),
              onTap: () {
                widget.panelController.close();
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32.0, 16.0, 32.0, 0),
          child:
              //state == "fav" ? favListView() : histListView(),
              Column(children: <Widget>[
                Text((() {
                  if(widget.state == "fav") {
                    return "收藏地點";
                  }return "歷史地點";
                })(),
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 32.0,
                  ),
                ),
                 widget.placeList.length > 0 && widget.state == "fav"
                     ? ListView.builder(
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    size: 24.0,
                                  ),
                                  title: Text(widget.placeList[index].name),
                                  onTap: () {
                                    widget.panelController.close();

                                    Navigator.of(context).push(CustomPageRoute(Confirming(
                                                place_name: widget.placeList[index].name,
                                                place_id: widget.placeList[index].id,
                                                place_lat: widget.placeList[index].lat,
                                                place_lng: widget.placeList[index].lng),
                                          ));

                                    // Navigator.push(
                                    //   context,
                                    //   new MaterialPageRoute(
                                    //     builder: (context) => new Confirming(
                                    //         place_name: _placeList[index].name,
                                    //         place_id: _placeList[index].id,
                                    //         place_lat: _placeList[index].lat,
                                    //         place_lng: _placeList[index].lng),
                                    //   ),
                                    // );
                                  },
                                )),
                      );
                    },
                  )
                 : Padding(
                   padding: const EdgeInsets.all(32.0),
                   child: Center(
                       child: Text("none"),
                     ),
                 ),
          ]),
        ),
        SizedBox(
          height: 36.0,
        ),
      ],
    );
  }
}
