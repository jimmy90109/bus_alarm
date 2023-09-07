import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_map/database/place_database.dart';
import 'package:google_map/util/toast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import 'util/map_util.dart';
import 'model/place.dart';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';

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
  bool showMap = false;
  bool loading = true;
  late GoogleMapController mapController;
  late LatLng _center;
  Set<Circle> circles = {};
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "AIzaSyBu6yKj0QDgRglC0Ns-yx_FIUgGBOueh4Q";

  //plist
  late List<Place> _placeList;
  bool _faved = false;

  Future readPlaces() async {
    _placeList = await PlacesDatabase.instance.readAllPlaces(favTable);
    setState(() {});
    developer.log(_placeList.toString(), name: 'placeFav');
    checkFav();
  }

  Future insertPlace(Place place) async {
    await PlacesDatabase.instance.create(favTable, place);
    readPlaces();
  }

  Future deletePlace(String id) async {
    await PlacesDatabase.instance.delete(favTable, id);
    readPlaces();
  }

  checkFav() {
    try {
      _placeList.firstWhere((place) => place.name == widget.place_name);
      setState(() {
        _faved = true;
      });
    } catch (error) {
      setState(() {
        _faved = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 250), () {
      setState(() {
        showMap = true;
      });
    });

    _center = LatLng(widget.place_lat, widget.place_lng);
    _addMarker(
        LatLng(widget.place_lat, widget.place_lng), "destination", BitmapDescriptor.defaultMarker);
    addCustomIcon();
    circles = {
      Circle(
        circleId: const CircleId("destination"),
        center: LatLng(widget.place_lat, widget.place_lng),
        radius: 500,
        strokeWidth: 0,
        fillColor: Colors.grey.withOpacity(0.3),
      )
    };

    getCurrentLocation();

    readPlaces();
    // checkFav();
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Offset offset = id == "user" ? const Offset(0.5, 0.5) : const Offset(0.5, 1.0);
    Marker marker =
        Marker(markerId: markerId, icon: descriptor, position: position, anchor: offset);
    markers[markerId] = marker;
  }

  void addCustomIcon() {
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(), "assets/bus.png").then(
      (icon) {
        setState(() {
          markerIcon = icon;
        });
      },
    );
  }

  _addPolyLine() {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.grey.shade600, points: polylineCoordinates, width: 5);
    polylines[id] = polyline;
    setState(() {});
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey,
        PointLatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        PointLatLng(widget.place_lat, widget.place_lng),
        travelMode: TravelMode.driving);
    polylineCoordinates.clear();
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    _addPolyLine();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    rootBundle.loadString('assets/no_markers.json').then((String mapStyle) {
      controller.setMapStyle(mapStyle);
    });
  }

  //get current location
  Location location = Location();
  LocationData? _currentLocation;

  void getCurrentLocation() async {
    location.getLocation().then(
      (location) {
        _currentLocation = location;
      },
    );

    await location.changeSettings(interval: 1000, distanceFilter: 50);

    location.onLocationChanged.listen(
      (newLoc) {
        if (_tracking) {
          developer.log("location updated!", name: 'location');
          _currentLocation = newLoc;
          updatedGPS(newLoc);
          setState(() {});
        }
      },
    );
  }

  updatedGPS(LocationData location) {
    polylines.remove(const PolylineId("poly"));
    _getPolyline();
    markers.remove(const MarkerId("user"));

    //custoer: bus
    _addMarker(LatLng(location.latitude!, location.longitude!), "user", markerIcon);

    //calculate the compass
    double calculatedRotation = Geolocator.bearingBetween(
        location.latitude!, location.longitude!, widget.place_lat, widget.place_lng);

    //let the map move down a bit
    double calculatedLat = (widget.place_lat - location.latitude!) * 0.2 + location.latitude!;
    double calculatedLng = (widget.place_lng - location.longitude!) * 0.2 + location.longitude!;

    //new CameraPosition
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(calculatedLat, calculatedLng),
      zoom: 15.0,
      tilt: 90,
      bearing: calculatedRotation,
    )));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //TODO
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              compassEnabled: false,
              zoomControlsEnabled: false,
              // zoomGesturesEnabled: false,
              // scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              markers: Set<Marker>.of(markers.values),
              polylines: Set<Polyline>.of(polylines.values),
              circles: circles,
              // padding: const EdgeInsets.fromLTRB(0, 320, 0, 0),
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 16.0,
                bearing: 0,
                // tilt: 90
              ),
            ),
          ),
          Positioned.fill(
            child: Visibility(
              visible: loading,
              child: AnimatedOpacity(
                curve: Curves.easeInCirc,
                duration: const Duration(milliseconds: 500),
                opacity: showMap ? 0 : 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                onEnd: () {
                  loading = false;
                  setState(() {});
                },
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
                                height: 64,
                                width: MediaQuery.of(context).size.width - 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          widget.place_name,
                                          style: TextStyle(
                                            fontSize: 20,
                                            color:
                                                Theme.of(context).colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      Material(
                                        type: MaterialType.transparency,
                                        child: InkWell(
                                          customBorder: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Icon(
                                              _faved
                                                  ? Icons.favorite_outlined
                                                  : Icons.favorite_border_outlined,
                                              color: _faved
                                                  ? Colors.red[700]
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSecondaryContainer,
                                              size: 24.0,
                                            ),
                                          ),
                                          onTap: () {
                                            if (_faved) {
                                              deletePlace(widget.place_id);
                                              warning("已移除收藏！");
                                              setState(() {
                                                _faved = false;
                                              });
                                            } else {
                                              insertPlace(Place(
                                                id: widget.place_id,
                                                name: widget.place_name,
                                                lat: widget.place_lat,
                                                lng: widget.place_lng,
                                              ));
                                              warning("已收藏地點！");
                                              setState(() {
                                                _faved = true;
                                              });
                                            }
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
                    Expanded(
                      child: AnimatedCrossFade(
                        crossFadeState:
                        !_tracking ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 400),
                        firstCurve: Curves.fastOutSlowIn,
                        secondCurve: Curves.fastOutSlowIn,
                        firstChild: Row(
                          children: [
                            Expanded(
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
                                      // width: 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: Theme.of(context).colorScheme.primaryContainer,
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
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                              size: 24.0,
                                            ),
                                            //),
                                            const SizedBox(width: 5),
                                            Text(
                                              '確認',
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
                                      if (_tracking) {
                                        polylines.remove(const PolylineId("poly"));
                                        markers.remove(const MarkerId("user"));
                                        setState(() {
                                          _tracking = false;
                                        });
                                        mapController
                                            .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
                                          target: _center,
                                          zoom: 16.0,
                                          bearing: 0,
                                          tilt: 0,
                                        )));
                                        //TODO
                                      } else {
                                        //TODO
                                        updatedGPS(_currentLocation!);
                                        _getPolyline();
                                        setState(() {
                                          _tracking = true;
                                        });
                                      }
                                    },
                                  )),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Material(
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
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.cancel_outlined,
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        size: 24.0,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    if (_tracking) {
                                      polylines.remove(const PolylineId("poly"));
                                      markers.remove(const MarkerId("user"));
                                      setState(() {
                                        _tracking = false;
                                      });
                                      mapController
                                          .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
                                        target: _center,
                                        zoom: 16.0,
                                        bearing: 0,
                                        tilt: 0,
                                      )));
                                      //TODO
                                    } else {
                                    Navigator.pop(context);
                                    }
                                  },
                                )),
                          ],
                        ),
                        secondChild: Row(
                          children: [
                            Expanded(
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
                                      // width: 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: <Widget>[
                                            // Hero(
                                            //   tag: 'sIcon',
                                            //   child:
                                            Icon(
                                              Icons.cancel_outlined,
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                              size: 24.0,
                                            ),
                                            //),
                                            const SizedBox(width: 5),
                                            Text(
                                              '取消',
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
                                      if (_tracking) {
                                        polylines.remove(const PolylineId("poly"));
                                        markers.remove(const MarkerId("user"));
                                        setState(() {
                                          _tracking = false;
                                        });
                                        mapController
                                            .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
                                          target: _center,
                                          zoom: 16.0,
                                          bearing: 0,
                                          tilt: 0,
                                        )));
                                        //TODO
                                      } else {
                                        //TODO
                                        updatedGPS(_currentLocation!);
                                        _getPolyline();
                                        setState(() {
                                          _tracking = true;
                                        });
                                      }
                                    },
                                  )),
                            ),
                          ],
                        ),
                      ),
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
