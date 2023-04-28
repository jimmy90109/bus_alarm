import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_map/SearchingPlace.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class Confirming extends StatefulWidget {
  final String place_name;
  final String place_id;
  final double place_lat;
  final double place_lng;

  const Confirming(
      {super.key,
      required this.place_name,
      required this.place_id,
      required this.place_lat,
      required this.place_lng});

  @override
  State<Confirming> createState() => _ConfirmingState();
}

class _ConfirmingState extends State<Confirming> {
  var _tracking = false;

  //Gmap
  late GoogleMapController mapController;
  late LatLng _center;
  Map<MarkerId, Marker> markers = {};
  // = const LatLng(widget.place_lat!, 121.5469); 待修

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.place_lat!, widget.place_lng!);
    _addMarker(LatLng(widget.place_lat!, widget.place_lng!), "destination",
        BitmapDescriptor.defaultMarker);

  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
        Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }


  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    rootBundle.loadString('assets/no_markers.json').then((String mapStyle) {
      controller.setMapStyle(mapStyle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              compassEnabled: false,
              zoomControlsEnabled: false,
              //zoomGesturesEnabled: false,
              //scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              markers: Set<Marker>.of(markers.values),
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 16.0,
                bearing: 0,
                //tilt: 90
              ),
            ),
          ),
          Positioned(
            bottom: 5,
            left: 15,
            right: 15,
            child: SafeArea(
              child: Column(
                children: [
                  Visibility(
                    visible: !_tracking,
                    child: Row(children: <Widget>[
                      Hero(
                        tag: 'searchingHero',
                        child: Material(
                            elevation: 20,
                            //type: MaterialType.transparency,
                            //color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: InkWell(
                              customBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Ink(
                                height: 60,
                                width: MediaQuery.of(context).size.width - 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(30, 0, 30, 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          widget.place_name!,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.favorite_border_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                        size: 24.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // onTap: () {
                              //   Navigator.push(
                              //     context,
                              //     new MaterialPageRoute(
                              //       builder: (context) =>
                              //       new SearchingPlace(),
                              //     ),
                              //   );
                              // },
                            )),
                      ),
                    ]),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(children: <Widget>[
                    Visibility(
                      visible: !_tracking,
                      //maintainAnimation: true,
                      child: Expanded(
                        flex: 2,
                        child: Material(
                            elevation: 20,
                            //type: MaterialType.transparency,
                            //color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: InkWell(
                              customBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Ink(
                                height: 60,
                                width: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      // Hero(
                                      //   tag: 'sIcon',
                                      //   child:
                                      Icon(
                                        Icons.check,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        size: 24.0,
                                      ),
                                      //),
                                      SizedBox(width: 5),
                                      Text(
                                        '確認',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              onTap: () {
                                  setState(() {
                                    _addMarker(LatLng(25.0246, 121.5469), "user",
                                        BitmapDescriptor.defaultMarker);
                                    _tracking = true;
                                  });
                              },
                            )),
                      ),
                    ),
                    Visibility(
                      visible: !_tracking,
                      child: SizedBox(
                        width: 10,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Material(
                          elevation: 20,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: InkWell(
                            customBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Ink(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.cancel_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                  size: 24.0,
                                ),
                              ),
                            ),
                            onTap: () {
                              if(_tracking) {
                                setState(() {
                                  markers.remove(MarkerId("user"));
                                  _tracking = false;
                                });

                              } else {
                                Navigator.pop(context);
                              }

                            },
                          )),
                    ),
                  ]),
                  SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
