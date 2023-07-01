import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_map/SearchingPlace.dart';
import 'package:google_map/database/place_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map/PanelWidget.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'animation/FadeAnimation.dart';
import 'model/place.dart';

void main() {
  //transparent the notification & navigation bar
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
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
  final LatLng _center = const LatLng(25.0246, 121.5469);
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    rootBundle.loadString('assets/no_markers.json').then((String mapStyle) {
      controller.setMapStyle(mapStyle);
    });
  }

  //saved places
  late List<Place> _placeList;
  Future readPlaces(String table) async {
    _placeList = await PlacesDatabase.instance.readAllPlaces(table);
    setState(() {});
  }
  // late List<Place> _hisList;
  // Future readHisPlaces() async {
  //   _favList = await PlacesDatabase.instance.readAllPlaces(hisTable);
  //   setState(() {});
  // }
  // late List<Place> _searchList;
  // Future readSearchPlaces() async {
  //   _favList = await PlacesDatabase.instance.readAllPlaces(searchTable);
  //   setState(() {});
  // }

  @override
  void initState() {
    panelState = "hist";
    readPlaces(favTable);
    // readFavPlaces();
    // readHisPlaces();
    // readSearchPlaces();
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

          home: Builder(builder: (context) {//for dynamic theme
            return Scaffold(
              body: SlidingUpPanel(
                controller: _pc,
                minHeight: 0,
                maxHeight: MediaQuery.of(context).size.height * 0.5,
                margin: const EdgeInsets.fromLTRB(15.0, 0, 15.0, 0.0),
                backdropEnabled: true,
                backdropTapClosesPanel: true,
                //defaultPanelState: PanelState.CLOSED,
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer,
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
                        //zoomGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        initialCameraPosition: CameraPosition(
                            target: _center,
                            zoom: 20.0,
                            bearing: -85,
                            tilt: 90),
                      ),
                    ),
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
                          child: Row(children: <Widget>[
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
                                      panelState="hist";
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
                                      Navigator.of(context).push(CustomPageRoute(SearchingPlace()));

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
                                      panelState="fav";
                                    });
                                    _pc.open();
                                  },
                                )),
                          ]),
                        ),
                      ),
                    ),
                    Positioned(
                        bottom: 60,
                        child: Container(
                            height: 350,
                            width: MediaQuery.of(context).size.width,
                            child: Center(
                                child: Image.asset('assets/bus.png')
                            )
                        )
                    )
                  ],
                ),
              ),
            );
          }));
    });
  }
}
