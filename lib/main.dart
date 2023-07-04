import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map/SearchingPlace.dart';
import 'package:google_map/database/place_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map/PanelWidget.dart';
import 'package:location/location.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'animation/FadeAnimation.dart';
import 'model/place.dart';
import 'dart:developer' as developer;

void main() {
  //transparent the notification & navigation bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //dynamic theme
  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.blue);
  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

  //siding up panel controller
  final PanelController _pc = PanelController();
  late String panelState;

  //Gmap
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(25.047058, 121.519752);
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    rootBundle.loadString('assets/no_markers.json').then((String mapStyle) {
      controller.setMapStyle(mapStyle);
    });
  }

  //get current location
  Location location = Location();
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  LocationData? _currentLocation;
  LocationData? _lastLocation;
  double bearing = 0;

  void getCurrentLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.getLocation().then(
      (location) {
        _currentLocation = location;
      },
    );

    await location.changeSettings(interval: 1000, distanceFilter: 50);

    location.onLocationChanged.listen(
      (newLoc) {
        developer.log("location updated!", name: 'location');
        if (_currentLocation == null) {
          _currentLocation = newLoc;
          setState(() {});
        } else {
          _lastLocation = _currentLocation;
          _currentLocation = newLoc;
          bearing = Geolocator.bearingBetween(_lastLocation!.latitude!,
              _lastLocation!.longitude!, newLoc.latitude!, newLoc.longitude!);
          setState(() {});
        }
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                newLoc.latitude!,
                newLoc.longitude!,
              ),
              zoom: 18.0,
              tilt: 90,
              bearing: bearing,
            ),
          ),
        );
      },
    );
  }

  //saved places
  late List<Place> _placeList;
  Future readPlaces(String table) async {
    _placeList = await PlacesDatabase.instance.readAllPlaces(table);
    setState(() {});
  }

  @override
  void initState() {
    panelState = "hist";
    _placeList = [];
    readPlaces(favTable);
    getCurrentLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //draw under navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
          debugShowCheckedModeBanner: false,

          //get themeData from wallpaper
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFFFFF),
            colorScheme: lightColorScheme ?? _defaultLightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.light,
          home: Builder(builder: (context) {
            //for dynamic theme
            return Scaffold(
              body: SlidingUpPanel(
                controller: _pc,
                minHeight: 0,
                maxHeight: MediaQuery.of(context).size.height * 0.5,
                margin: const EdgeInsets.fromLTRB(15.0, 0, 15.0, 0.0),
                backdropEnabled: true,
                backdropTapClosesPanel: true,
                //defaultPanelState: PanelState.CLOSED,
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                panelBuilder: (controller) => Panel(
                  controller: controller,
                  panelController: _pc,
                  state: panelState,
                  placeList: _placeList,
                ),

                body: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        compassEnabled: false,
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        buildingsEnabled: false,
                        //padding: const EdgeInsets.fromLTRB(0, 320, 0, 0),
                        initialCameraPosition: CameraPosition(
                          target: _center,
                          zoom: 12.0,
                          //bearing: -85,
                          //tilt: 90
                        ),
                      ),
                    ),
                    Visibility(
                        visible: _currentLocation == null,
                        child: Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.6),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    size: 100,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    "（正在讀取GPS...）",
                                    style: TextStyle(color: Colors.white),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )),
                    Positioned(
                      top: 10,
                      left: 15,
                      right: 15,
                      child: SafeArea(
                        child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: Offset(
                                      0, 5), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Icon(
                                    Icons.menu,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    size: 24.0,
                                  ),
                                  Text(
                                    '公車鬧鐘',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                  Icon(
                                    Icons.account_circle_outlined,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    size: 24.0,
                                  ),
                                ],
                              ),
                            )),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      left: 15,
                      right: 15,
                      child: SafeArea(
                        child: Container(
                          child: Column(
                              children: <Widget>[
                                Visibility(
                                  visible: _currentLocation != null,
                                  child: Container(
                                      height: 350,
                                      width: MediaQuery.of(context).size.width,
                                      child: Center(
                                          child: Image.asset('assets/bus.png'))),
                                ),
                                Row(children: <Widget>[
                                  Material(
                                      elevation: 20,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30)),
                                      child: InkWell(
                                        customBorder: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30)),
                                        child: Ink(
                                          height: 60,
                                          width: 60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(30),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.access_time_outlined,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              size: 24.0,
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          readPlaces(hisTable);
                                          setState(() {
                                            panelState = "hist";
                                          });
                                          // deletePlace("test");
                                          _pc.open();
                                        },
                                      )),
                                  Spacer(),
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
                                            width: 180,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(30),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                            ),
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: <Widget>[
                                                  // Hero(
                                                  //   tag: 'sIcon',
                                                  //   child:
                                                  Icon(
                                                    Icons.search,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                    size: 24.0,
                                                  ),
                                                  //),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    '搜尋',
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
                                            Navigator.of(context).push(
                                                CustomPageRoute(
                                                    const SearchingPlace()));

                                            // Navigator.push(
                                            //   context,
                                            //   new MaterialPageRoute(
                                            //     builder: (context) =>
                                            //         new SearchingPlace(),
                                            //   ),
                                            // );
                                          },
                                        )),
                                  ),
                                  Spacer(),
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.favorite_border_outlined,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              size: 24.0,
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          // Place temp = Place(
                                          //   id: "test",
                                          //   name: 'test..!',
                                          //   lat: 35.2,
                                          //   lng: 11.22,
                                          // );
                                          // insertPlace(temp);
                                          readPlaces(favTable);
                                          setState(() {
                                            panelState = "fav";
                                          });
                                          _pc.open();
                                        },
                                      )),
                                ])
                              ]

                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            );
          }));
    });
  }
}
