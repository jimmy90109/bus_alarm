import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_map/Arrived.dart';
import 'package:google_map/animation/RouteAnimation.dart';
import 'package:google_map/database/place_database.dart';
import 'package:google_map/util/toast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:label_marker/label_marker.dart';
import 'package:location/location.dart';
// import 'util/map_util.dart';
import 'model/place.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';

class BusConfirm extends StatefulWidget {
  final String bus_route;
  final String bus_token;
  final LocationData lastLocation;

  const BusConfirm({
    super.key,
    required this.bus_route,
    required this.bus_token,
    required this.lastLocation,
  });

  @override
  State<BusConfirm> createState() => _BusConfirmState();
}

class _BusConfirmState extends State<BusConfirm> {
  var _tracking = false;

  //Gmap
  bool showMap = false;
  bool loading = true;
  late GoogleMapController mapController;
  Set<Circle> circles = {};
  BitmapDescriptor trackingMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor confirmingMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor littleBus = BitmapDescriptor.defaultMarker;
  Set<Marker> markers = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  String googleAPiKey = "AIzaSyBu6yKj0QDgRglC0Ns-yx_FIUgGBOueh4Q";

  //fav list
  late List<Place> _favList;
  bool _faved = false;

  //bus direction
  int _direction = 0;

  //bus stop list
  List<dynamic> _stopList0 = [], _stopList1 = [];
  List<dynamic> _stopList0Time = [], _stopList1Time = [];

  //bus location
  List<dynamic> _busLocation0 = [];
  List<dynamic> _busLocation1 = [];

  late LatLng _centerLatLong;
  late String _centerName, _centerID;

  late Future<LatLng> future;

  //get current location
  Location location = Location();
  LocationData? _currentLocation;

  @override
  void initState() {
    super.initState();

    _currentLocation = widget.lastLocation;

    addCustomIcon();
    readFavPlaces();

    _readBusLocation();

    future = prepareForMap();
  }

  Future<LatLng> prepareForMap() async {
    developer.log("in future...");
    await getCurrentLocation();
    developer.log('location_finished');
    await _readRouteStop();
    developer.log('stops_finished');
    await _readEstimatedTime();
    developer.log('time_finished');

    return _findNearbyStop(_stopList0);
  }

  Future readFavPlaces() async {
    _favList = await PlacesDatabase.instance.readAllPlaces(favTable);
    setState(() {});
    developer.log(_favList.toString(), name: 'placeFav');
  }

  Future insertPlace(Place place) async {
    await PlacesDatabase.instance.create(favTable, place);
    readFavPlaces();
  }

  Future deletePlace(String id) async {
    await PlacesDatabase.instance.delete(favTable, id);
    readFavPlaces();
  }

  checkFav() {
    try {
      _favList.firstWhere((place) => place.name == _centerName);
      _faved = true;
    } catch (error) {
      _faved = false;
    }
  }

  Future _readRouteStop() async {
    var uri = Uri.parse(
        'https://tdx.transportdata.tw/api/basic/v2/Bus/StopOfRoute/City/Taipei/${widget.bus_route}?%24filter=RouteName%2FZh_tw%20eq%20%27${widget.bus_route}%27&24format=JSON');
    var response = await http.get(uri, headers: {'authorization': "Bearer ${widget.bus_token}"});
    if (response.statusCode == 200) {
      _stopList0 = json.decode(response.body)[0]["Stops"];
      if (json.decode(response.body)[1].toString().isNotEmpty) {
        _stopList1 = json.decode(response.body)[1]["Stops"];
      }
    } else {
      developer.log(json.decode(response.body).toString());
    }
  }

  Future _readBusLocation() async {
    var uri = Uri.parse(
        'https://tdx.transportdata.tw/api/basic/v2/Bus/RealTimeByFrequency/City/Taipei/${widget.bus_route}?%24filter=RouteName%2FZh_tw%20eq%20%27${widget.bus_route}%27%20AND%20Direction%20eq%200&%24format=JSON');
    var response = await http.get(uri, headers: {'authorization': "Bearer ${widget.bus_token}"});
    if (response.statusCode == 200) {
      //developer.log(json.decode(response.body).toString());
      _busLocation0 = json.decode(response.body);
    } else {
      developer.log(json.decode(response.body).toString());
    }

    uri = Uri.parse(
        'https://tdx.transportdata.tw/api/basic/v2/Bus/RealTimeByFrequency/City/Taipei/${widget.bus_route}?%24filter=RouteName%2FZh_tw%20eq%20%27${widget.bus_route}%27%20AND%20Direction%20eq%201&%24format=JSON');
    response = await http.get(uri, headers: {'authorization': "Bearer ${widget.bus_token}"});
    if (response.statusCode == 200) {
      // developer.log(json.decode(response.body).toString());
      _busLocation1 = json.decode(response.body);
    } else {
      developer.log(json.decode(response.body).toString());
    }

    _addBusMarker(_busLocation0);
  }

  Future _readEstimatedTime() async {
    var uri = Uri.parse(
        'https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/Taipei/${widget.bus_route}?%24filter=Direction%20eq%200&%24orderby=StopID%20asc&%24format=JSON');
    var response = await http.get(uri, headers: {'authorization': "Bearer ${widget.bus_token}"});
    if (response.statusCode == 200) {
      // developer.log(json.decode(response.body).toString());
      _stopList0Time = json.decode(response.body);
    } else {
      developer.log(json.decode(response.body).toString());
    }

    uri = Uri.parse(
        'https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/Taipei/${widget.bus_route}?%24filter=Direction%20eq%201&%24orderby=StopID%20asc&%24format=JSON');
    response = await http.get(uri, headers: {'authorization': "Bearer ${widget.bus_token}"});
    if (response.statusCode == 200) {
      // developer.log(json.decode(response.body).toString());
      _stopList1Time = json.decode(response.body);
    } else {
      developer.log(json.decode(response.body).toString());
    }
  }

  Future<LatLng> _findNearbyStop(List stops) async {
    //add all stop markers
    //add destination circle
    //check Fav

    _centerName = stops.first['StopName']['Zh_tw'];
    _centerLatLong = LatLng(stops.first['StopPosition']['PositionLat'], stops.first['StopPosition']['PositionLon']);

    var minDistance = Geolocator.distanceBetween(
        _currentLocation!.latitude!, _currentLocation!.longitude!, _centerLatLong.latitude, _centerLatLong.longitude);
    developer.log(minDistance.toString(), name: 'min distance');

    var index = 1;
    for (var stop in stops) {
      _addStopMarker(LatLng(stop['StopPosition']['PositionLat'], stop['StopPosition']['PositionLon']),
          stop['StopName']['Zh_tw'], index);

      var distance = Geolocator.distanceBetween(_currentLocation!.latitude!, _currentLocation!.longitude!,
          stop['StopPosition']['PositionLat'], stop['StopPosition']['PositionLon']);

      if (distance < minDistance) {
        _centerLatLong = LatLng(stop['StopPosition']['PositionLat'], stop['StopPosition']['PositionLon']);
        _centerName = stop['StopName']['Zh_tw'];
        minDistance = distance;
      }

      index++;
    }

    circles = {
      Circle(
        circleId: const CircleId("destination"),
        center: _centerLatLong,
        radius: 500,
        strokeWidth: 0,
        fillColor: Colors.grey.withOpacity(0.3),
      )
    };

    // _readPlaceID(_centerLatLong);
    checkFav();

    //setState(() {});
    // developer.log(_centerName, name: 'center');
    return _centerLatLong;
  }

  _readPlaceID(LatLng point) async {
    var response = await http.get(Uri.parse('https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${point.latitude},${point.longitude}'
        '&key=$googleAPiKey'));
    if (response.statusCode == 200) {
      // developer.log(json.decode(response.body).toString(), name: 'readPlaceID');
      // setState(() {
      _centerID = json.decode(response.body)['results'][0]['place_id'];

      // });
    } else {
      developer.log(json.decode(response.body).toString());
    }
  }

  _addStopMarker(LatLng position, String id, int index) {
    String estmateTime;
    try {
      int time;
      _direction == 0
          ? time = _stopList0Time.firstWhere((element) => element['StopName']['Zh_tw'] == id)['EstimateTime'] ~/ 60
          : time = _stopList1Time.firstWhere((element) => element['StopName']['Zh_tw'] == id)['EstimateTime'] ~/ 60;
      time == 0 ? estmateTime = "進站中" : estmateTime = "$time分鐘";
    } catch (e) {
      developer.log(e.toString());
      estmateTime = "未發車";
    }

    markers
        .addLabelMarker(LabelMarker(
      label: "$index.$id:$estmateTime",
      markerId: MarkerId(id),
      position: position,
      zIndex: 0,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      textStyle: const TextStyle(fontSize: 27.0, color: Colors.white, letterSpacing: 1.0, fontFamily: 'Roboto Bold'),
      onTap: () {
        circles.clear();
        circles = {
          Circle(
            circleId: const CircleId("destination"),
            center: position,
            radius: 500,
            strokeWidth: 0,
            fillColor: Colors.grey.withOpacity(0.3),
          )
        };
        _centerLatLong = position;
        _centerName = id;
        checkFav();
        setState(() {});
      },
    ))
        .then(
      (value) {
        setState(() {});
      },
    );
  }

  _addBusMarker(List busLocation) {
    int index = 1;
    for (var bus in busLocation) {
      markers.add(Marker(
          markerId: MarkerId("bus$index"),
          icon: littleBus,
          position: LatLng(bus['BusPosition']['PositionLat'], bus['BusPosition']['PositionLon']),
          anchor: const Offset(0.5, 0.5),
          zIndex: 1));
      index++;
    }
  }

  addCustomIcon() {
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(), "assets/bus.png").then(
      (icon) {
        setState(() {
          trackingMarker = icon;
        });
      },
    );
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(), "assets/blueDot.png").then(
      (icon) {
        setState(() {
          confirmingMarker = icon;
        });
      },
    );
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(), "assets/littleBus.png").then(
      (icon) {
        setState(() {
          littleBus = icon;
        });
      },
    );
  }

  _addPolyLine() {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(polylineId: id, color: Colors.grey.shade600, points: polylineCoordinates, width: 5);
    polylines[id] = polyline;
    setState(() {});
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey,
        PointLatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        PointLatLng(_centerLatLong.latitude, _centerLatLong.longitude),
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
    // mapController.showMarkerInfoWindow(MarkerId(_centerName));
  }

  //get current location

  getCurrentLocation() async {
    location.getLocation().then(
      (location) {
        _currentLocation = location;
        developer.log("got location!", name: 'location');

        markers.remove(const MarkerId("user"));
        markers.add(Marker(
            markerId: const MarkerId("user"),
            icon: confirmingMarker,
            position: LatLng(location.latitude!, location.longitude!),
            anchor: const Offset(0.5, 0.5),
            zIndex: 99));
      },
    );

    await location.changeSettings(interval: 60000, distanceFilter: 50);
    location.onLocationChanged.listen(
      (newLoc) {
        if (_tracking) {
          developer.log("location updated!", name: 'location');
          _currentLocation = newLoc;
          if (Geolocator.distanceBetween(_currentLocation!.latitude!, _currentLocation!.longitude!,
                  _centerLatLong.latitude, _centerLatLong.longitude) <
              500) {
            Navigator.of(context).push(FadePageRoute(Arrived(
              placeName: _centerName,
            )));
          }
          updatedGPS(newLoc);
        }
      },
    );
  }

  updatedGPS(LocationData location) {
    polylines.remove(const PolylineId("poly"));
    _getPolyline();

    //custoer: bus
    markers.removeWhere((stop) => stop.markerId == const MarkerId("user"));
    markers.add(Marker(
        markerId: const MarkerId("user"),
        icon: trackingMarker,
        position: LatLng(location.latitude!, location.longitude!),
        anchor: const Offset(0.5, 0.5),
        zIndex: 99));
    // _addUserMarker(LatLng(location.latitude!, location.longitude!), "user", trackingMarker);

    //calculate the compass
    double calculatedRotation = Geolocator.bearingBetween(
        location.latitude!, location.longitude!, _centerLatLong.latitude, _centerLatLong.longitude);

    //let the map move down a bit
    double calculatedLat = (_centerLatLong.latitude - location.latitude!) * 0.2 + location.latitude!;
    double calculatedLng = (_centerLatLong.longitude - location.longitude!) * 0.2 + location.longitude!;

    //new CameraPosition
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(calculatedLat, calculatedLng),
      zoom: 15.0,
      tilt: 90,
      bearing: calculatedRotation,
    )));

    // setState(() {});
  }

  favOnTap() async {
    await _readPlaceID(_centerLatLong);
    if (_faved) {
      deletePlace(_centerID);
      warning("已移除收藏！");
      setState(() {
        _faved = false;
      });
    } else {
      insertPlace(Place(
        id: _centerID,
        name: _centerName,
        lat: _centerLatLong.latitude,
        lng: _centerLatLong.longitude,
      ));
      warning("已收藏地點！");
      setState(() {
        _faved = true;
      });
    }
  }

  reverseOnTap() {
    markers.removeWhere((stop) => stop.markerId != const MarkerId("user"));
    // developer.log(markers.toString());
    // setState(() {});

    if (_direction == 0) {
      _direction = 1;
      _addBusMarker(_busLocation1);
      _findNearbyStop(_stopList1);
    } else {
      _direction = 0;
      _addBusMarker(_busLocation0);
      _findNearbyStop(_stopList0);
    }
    // setState(() {});

    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: _centerLatLong,
      zoom: 16.0,
      bearing: 0,
      tilt: 0,
    )));
  }

  refreshOmTap() async {
    await _readEstimatedTime();
    await _readBusLocation();

    markers.removeWhere((stop) => stop.markerId != const MarkerId("user"));
    if (_direction == 1) {
      _addBusMarker(_busLocation1);
      _findNearbyStop(_stopList1);
    } else {
      _addBusMarker(_busLocation0);
      _findNearbyStop(_stopList0);
    }
  }

  startTracking() {
    markers.removeWhere((marker) => marker.markerId != const MarkerId("user"));
    markers
        .addLabelMarker(LabelMarker(
      label: _centerName,
      markerId: MarkerId(_centerName),
      position: _centerLatLong,
      zIndex: 0,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      textStyle: const TextStyle(fontSize: 27.0, color: Colors.white, letterSpacing: 1.0, fontFamily: 'Roboto Bold'),
    ))
        .then(
      (value) {
        setState(() {});
      },
    );
    // Navigator.of(context).push(FadePageRoute(const Arrived()));
    updatedGPS(_currentLocation!);
    _getPolyline();
    setState(() {
      _tracking = true;
    });
  }

  cancelTracking() {
    polylines.remove(const PolylineId("poly"));
    markers.clear();
    markers.add(Marker(
        markerId: const MarkerId("user"),
        icon: confirmingMarker,
        position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        anchor: const Offset(0.5, 0.5),
        zIndex: 99));

    if (_direction == 1) {
      _addBusMarker(_busLocation1);
      var index = 1;
      for (var stop in _stopList1) {
        _addStopMarker(LatLng(stop['StopPosition']['PositionLat'], stop['StopPosition']['PositionLon']),
            stop['StopName']['Zh_tw'], index);
        index++;
      }
    } else {
      _addBusMarker(_busLocation0);
      var index = 1;
      for (var stop in _stopList0) {
        _addStopMarker(LatLng(stop['StopPosition']['PositionLat'], stop['StopPosition']['PositionLon']),
            stop['StopName']['Zh_tw'], index);
        index++;
      }
    }

    setState(() {
      _tracking = false;
    });
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: _centerLatLong,
      zoom: 16.0,
      bearing: 0,
      tilt: 0,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //Google Map
          Positioned.fill(
            child: FutureBuilder<LatLng>(
                future: future,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    developer.log(snapshot.toString(), name: 'snapshot');

                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return GoogleMap(
                        onMapCreated: _onMapCreated,
                        compassEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        // zoomGesturesEnabled: false,
                        // scrollGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        markers: markers,
                        polylines: Set<Polyline>.of(polylines.values),
                        circles: circles,
                        // padding: const EdgeInsets.fromLTRB(0, 320, 0, 0),
                        initialCameraPosition: CameraPosition(
                          target: snapshot.data,
                          zoom: 16.0,
                          bearing: 0,
                          // tilt: 90
                        ),
                      );
                      // return Text("Contents: ${snapshot.data}");
                    }
                  } else {
                    // loading
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                }),
          ),

          //Bottom Widgets
          Positioned(
            bottom: 0,
            left: 15,
            right: 15,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(0, 0, 0, 30),
              child: Column(
                children: <Widget>[
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
                              borderRadius: BorderRadius.circular(32),
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
                                          widget.bus_route,
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      Material(
                                        type: MaterialType.transparency,
                                        child: InkWell(
                                          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                                            child: Icon(
                                              Icons.swap_horiz,
                                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                                              size: 24.0,
                                            ),
                                          ),
                                          onTap: () => reverseOnTap(),
                                        ),
                                      ),
                                      Material(
                                        type: MaterialType.transparency,
                                        child: InkWell(
                                          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                                            child: Icon(
                                              Icons.autorenew,
                                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                                              size: 24.0,
                                            ),
                                          ),
                                          onTap: () => refreshOmTap(),
                                        ),
                                      ),
                                      Material(
                                        type: MaterialType.transparency,
                                        child: InkWell(
                                          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 20, 10.0, 20),
                                            child: Icon(
                                              _faved ? Icons.favorite_outlined : Icons.favorite_border_outlined,
                                              color: _faved
                                                  ? Colors.red[700]
                                                  : Theme.of(context).colorScheme.onSecondaryContainer,
                                              size: 24.0,
                                            ),
                                          ),
                                          onTap: () => favOnTap(),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
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
                  AnimatedCrossFade(
                    crossFadeState: !_tracking ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 400),
                    firstCurve: Curves.fastOutSlowIn,
                    secondCurve: Curves.fastOutSlowIn,
                    firstChild: Row(
                      children: [
                        Expanded(
                          child: Material(
                              // elevation: 20,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: InkWell(
                                customBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Ink(
                                  height: 60,
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
                                onTap: () => startTracking(),
                                // {
                                //   if (_tracking) {
                                //     polylines.remove(const PolylineId("poly"));
                                //     markers.remove(const MarkerId("user"));
                                //     setState(() {
                                //       _tracking = false;
                                //     });
                                //     mapController.animateCamera(
                                //         CameraUpdate.newCameraPosition(
                                //             CameraPosition(
                                //       target: _center,
                                //       zoom: 16.0,
                                //       bearing: 0,
                                //       tilt: 0,
                                //     )));
                                //     //TODO
                                //   } else {
                                //     //TODO
                                //     updatedGPS(_currentLocation!);
                                //     _getPolyline();
                                //     setState(() {
                                //       _tracking = true;
                                //     });
                                //   }
                                // },
                              )),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Material(
                            // elevation: 20,
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
                              onTap: () => Navigator.pop(context),
                              // {
                              //   if (_tracking) {
                              //     polylines.remove(const PolylineId("poly"));
                              //     markers.remove(const MarkerId("user"));
                              //     setState(() {
                              //       _tracking = false;
                              //     });
                              //     mapController.animateCamera(
                              //         CameraUpdate.newCameraPosition(
                              //             CameraPosition(
                              //       target: _center,
                              //       zoom: 16.0,
                              //       bearing: 0,
                              //       tilt: 0,
                              //     )));
                              //     //TODO
                              //   } else {
                              //     Navigator.pop(context);
                              //   }
                              // },
                            )),
                      ],
                    ),
                    secondChild: Material(
                        // elevation: 20,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: InkWell(
                          customBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Ink(
                            height: 60,
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
                          onTap: () => cancelTracking(),
                          // {
                          //   if (_tracking) {
                          //     polylines.remove(const PolylineId("poly"));
                          //     markers.remove(const MarkerId("user"));
                          //     setState(() {
                          //       _tracking = false;
                          //     });
                          //     mapController.animateCamera(
                          //         CameraUpdate.newCameraPosition(CameraPosition(
                          //       target: _center,
                          //       zoom: 16.0,
                          //       bearing: 0,
                          //       tilt: 0,
                          //     )));
                          //     //TODO
                          //   } else {
                          //     //TODO
                          //     updatedGPS(_currentLocation!);
                          //     _getPolyline();
                          //     setState(() {
                          //       _tracking = true;
                          //     });
                          //   }
                          // },
                        )),
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
