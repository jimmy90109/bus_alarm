import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_map/Login.dart';
import 'package:google_map/Profile.dart';
import 'package:google_map/Arrived.dart';
import 'package:vibration/vibration.dart';
import 'animation/RouteAnimation.dart';
import 'model/place.dart';
import 'dart:developer' as developer;

//packages
import 'package:google_map/SearchingPlace.dart';
import 'package:google_map/database/place_database.dart';
import 'package:google_map/PanelWidget.dart';
import 'package:google_map/label_overrides.dart';

//Gmap
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

//firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

//costmize loginUI text
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

void main() async {
  //transparent the notification & navigation bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    // systemNavigationBarIconBrightness: Brightness.dark,
  ));

  //firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    GoogleProvider(clientId: "497223059110-fkqmu8s74i8kjaljneu10crq1dekel37.apps.googleusercontent.com"),
  ]);

  runApp(const Home());
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //dynamic theme
  static final _defaultLightColorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFFD2E2FC));

  //siding up panel controller
  final PanelController _pc = PanelController();
  late String panelState;

  //Gmap
  late GoogleMapController mapController;
  final LatLng _taipei = const LatLng(25.047058, 121.519752);
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
        setState(() {
          _currentLocation = location;
        });
      },
    );

    //change location settings: interval: 3s, distanceFilter: 50m
    await location.changeSettings(interval: 3000, distanceFilter: 50);

    location.onLocationChanged.listen(
      (newLoc) {
        developer.log("location updated!", name: 'homeLocation');
        // if (_currentLocation == null) {
        //   _currentLocation = newLoc;
        // } else {
        //calculate bearing
        _lastLocation = _currentLocation;
        _currentLocation = newLoc;
        bearing = Geolocator.bearingBetween(_lastLocation!.latitude!, _lastLocation!.longitude!, newLoc.latitude!, newLoc.longitude!);
        // }
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
  }

  @override
  void initState() {
    panelState = "hist";
    _placeList = [];
    readPlaces(hisTable);
    getCurrentLocation();
    super.initState();
  }

  @override
  void dispose() {
    developer.log("disposed", name: "main");
    super.dispose();
  }

  recentPlacesOnTap() async {
    await readPlaces(hisTable);
    // developer.log(_placeList.toString());
    setState(() {
      panelState = "hist";
    });
    _pc.open();
  }

  favoritePlacesOnTap() async {
    await readPlaces(favTable);
    // developer.log(_placeList.toString());
    setState(() {
      panelState = "fav";
    });
    _pc.open();
  }

  @override
  Widget build(BuildContext context) {
    //draw under navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
          localizationsDelegates: [
            // Creates an instance of FirebaseUILocalizationDelegate with overridden labels
            FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides()),

            // Delegates below take care of built-in flutter widgets
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,

            // This delegate is required to provide the labels that are not overridden by LabelOverrides
            FirebaseUILocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.light,

          //get themeData from wallpaper
          theme: ThemeData(
            colorScheme: lightColorScheme ?? _defaultLightColorScheme,
            useMaterial3: true,
          ),
          // darkTheme: ThemeData(
          //   colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          //   useMaterial3: true,
          // ),

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
                defaultPanelState: PanelState.CLOSED,
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                panelBuilder: (controller) => Panel(
                  scrollController: controller,
                  panelController: _pc,
                  state: panelState,
                  placeList: _placeList,
                ),
                // collapsed: Container(),

                body: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        myLocationEnabled: false,

                        compassEnabled: false,
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        buildingsEnabled: false,
                        //padding: const EdgeInsets.fromLTRB(0, 320, 0, 0),
                        initialCameraPosition: CameraPosition(
                          target: _taipei,
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
                      top: 0,
                      left: 15,
                      right: 15,
                      child: SafeArea(
                        minimum: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                        child: Material(
                          elevation: 20,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          child: Ink(
                              width: MediaQuery.of(context).size.width - 30,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                color: Theme.of(context).colorScheme.primaryContainer,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  InkWell(
                                    customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Icon(
                                        Icons.account_circle_outlined,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        size: 24.0,
                                      ),
                                    ),
                                    onTap: () {
                                      FirebaseAuth.instance.currentUser == null
                                          ? Navigator.of(context).push(FadePageRoute(
                                              const Login(),
                                            ))
                                          : Navigator.of(context).push(FadePageRoute(
                                              const Profile(),
                                            ));
                                    },
                                  ),
                                  Text(
                                    '公車鬧鐘',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  InkWell(
                                    customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18.0),
                                      child: Image.asset('assets/NTUE.png'),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(FadePageRoute(Arrived(placeName: "（地點名稱）")));
                                    },
                                  ),
                                  // Padding(
                                  //   padding: const EdgeInsets.all(18.0),
                                  //   child: Image.asset('assets/NTUE.png'),
                                  // ),
                                  //Navigator.of(context).pushReplacement(FadePageRoute(Arrived(placeName: widget.place_name)));
                                ],
                              )),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 15,
                      right: 15,
                      child: SafeArea(
                        minimum: const EdgeInsets.only(bottom: 30),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                          Material(
                              elevation: 20,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              child: InkWell(
                                customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                child: Ink(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.access_time_outlined,
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                      size: 24.0,
                                    ),
                                  ),
                                ),
                                onTap: () => recentPlacesOnTap(),
                              )),
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
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            Icons.search,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            size: 24.0,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '搜尋',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  onTap: () => Navigator.of(context).push(SlidePageRoute(SearchingPlace(currentLocation: _currentLocation!))),
                                )),
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
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.favorite_border_outlined,
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        size: 24.0,
                                      ),
                                    ),
                                  ),
                                  onTap: () => favoritePlacesOnTap())),
                        ]),
                      ),
                    ),
                    Positioned.fill(
                        child: Center(
                            child: AnimatedOpacity(
                      curve: Curves.easeInCirc,
                      duration: const Duration(milliseconds: 1000),
                      opacity: _currentLocation == null ? 0 : 1,
                      child: SizedBox(height: 350, width: MediaQuery.of(context).size.width, child: Center(child: Image.asset('assets/bus.png'))),
                    )))
                  ],
                ),
              ),
            );
          }));
    });
  }
}
