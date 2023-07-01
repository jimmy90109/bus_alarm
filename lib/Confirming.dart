import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_map/database/place_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'map_util.dart';
import 'model/place.dart';

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
  Set<Circle> circles = {};
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "AIzaSyBu6yKj0QDgRglC0Ns-yx_FIUgGBOueh4Q";

  //plist
  late List<Place> _placeList;

  Future readPlaces() async {
    _placeList = await PlacesDatabase.instance.readAllPlaces(favTable);
    setState(() {});
  }

  Future insertPlace(Place place) async {
    await PlacesDatabase.instance.create(favTable, place);
    readPlaces();
  }

  Future deletePlace(String id) async {
    await PlacesDatabase.instance.delete(favTable, id);
    readPlaces();
  }

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.place_lat, widget.place_lng);
    _addMarker(LatLng(widget.place_lat, widget.place_lng), "destination",
        BitmapDescriptor.defaultMarker);
    circles = {Circle(
      circleId: const CircleId("destination"),
      center: LatLng(widget.place_lat, widget.place_lng),
      radius: 500,
      strokeWidth: 0,
      fillColor: Colors.grey.withOpacity(0.3),
    )};

    readPlaces();
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
        Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  _addPolyLine() {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.grey.shade600,
        points: polylineCoordinates,
        width: 5
    );
    polylines[id] = polyline;
    //print(polylines[PolylineId("poly")]?.polylineId);
    setState(() {});
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey,
        const PointLatLng(25.0246, 121.5469),
        PointLatLng(widget.place_lat, widget.place_lng),
        travelMode: TravelMode.driving);
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    _addPolyLine();
  }

  // _getPlist() async {
  //   _placeList = await places();
  // }

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
              polylines: Set<Polyline>.of(polylines.values),
              circles: circles,
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
                                          widget.place_name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      // Material(
                                      //   type: MaterialType.transparency,
                                      //   child: InkWell(
                                      //     customBorder: RoundedRectangleBorder(
                                      //         borderRadius: BorderRadius.circular(30)),
                                      //     child: Ink(
                                      //       height: 40,
                                      //       width: 40,
                                      //       child: Icon(
                                      //         Icons.delete_forever,
                                      //         color: Theme.of(context)
                                      //             .colorScheme
                                      //             .onSecondaryContainer,
                                      //         size: 24.0,
                                      //       ),
                                      //     ),
                                      //     onTap: () {
                                      //       //if(_placeList[widget.place_name!]==null){
                                      //       // insertPlace(
                                      //       //     Place(
                                      //       //       id: widget.place_id,
                                      //       //       name: widget.place_name,
                                      //       //       lat: widget.place_lat,
                                      //       //       lng: widget.place_lng,
                                      //       //     )
                                      //       // );
                                      //       //}else{
                                      //       print("unfaved!");
                                      //       deletePlace(widget.place_id);
                                      //       //}
                                      //     },
                                      //   ),
                                      // ),
                                      Material(
                                        type: MaterialType.transparency,
                                        child: InkWell(
                                          customBorder: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30)),
                                          child: Ink(
                                            height: 40,
                                            width: 40,
                                            child: Icon(
                                              Icons.favorite_border_outlined,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              size: 24.0,
                                            ),
                                          ),
                                          onTap: () {
                                            try{
                                              _placeList.firstWhere((place) => place.name == widget.place_name);
                                              print("unfaved!");
                                              deletePlace(widget.place_id);
                                            }catch(error){
                                              print("faved!");
                                              insertPlace(
                                                  Place(
                                                    id: widget.place_id,
                                                    name: widget.place_name,
                                                    lat: widget.place_lat,
                                                    lng: widget.place_lng,
                                                  )
                                              );
                                            }
                                            // if(){
                                            //   print("faved!");
                                            //   insertPlace(
                                            //       Place(
                                            //         name: widget.place_name,
                                            //         lat: widget.place_lat,
                                            //         lng: widget.place_lng,
                                            //       )
                                            //   );
                                            // }else{
                                            //  print("unfaved!");
                                            //  deletePlace(widget.place_id);
                                            // }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ),
                    ]),
                  ),
                  const SizedBox(
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
                                      const SizedBox(width: 5),
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
                                _addMarker(const LatLng(25.0246, 121.5469), "user",
                                    BitmapDescriptor.defaultMarkerWithHue(200));
                                mapController.animateCamera(
                                    CameraUpdate.newLatLngBounds(
                                        MapUtils.boundsFromLatLngList(markers
                                            .values
                                            .map((e) => e.position)
                                            .toList()),
                                        1));
                                if(polylines[const PolylineId("poly")]==null) {
                                  _getPolyline();
                                } else{
                                  polylines[const PolylineId("poly")]=Polyline(
                                      polylineId: const PolylineId("poly"),
                                      color: Colors.grey.shade600,
                                      width: 5,
                                      points: polylineCoordinates);
                                }
                                setState(() {
                                  _tracking = true;
                                });
                              },
                            )),
                      ),
                    ),
                    Visibility(
                      visible: !_tracking,
                      child: const SizedBox(
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
                              if (_tracking) {
                                polylines[const PolylineId("poly")]=Polyline(
                                    polylineId: const PolylineId("poly"),
                                    color: Colors.transparent,
                                    width: 5,
                                    points: polylineCoordinates);
                                markers.remove(const MarkerId("user"));
                                setState(() {
                                  _tracking = false;
                                });
                                mapController.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                  target: _center,
                                  zoom: 16.0,
                                )));
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          )),
                    ),
                  ]),
                  const SizedBox(
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
