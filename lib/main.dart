import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_map/SearchingPlace.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map/PanelWidget.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

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

  //Gmap
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(25.0246, 121.5469);
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
                margin: EdgeInsets.fromLTRB(15.0, 0, 15.0, 0.0),
                backdropEnabled: true,
                backdropTapClosesPanel: true,
                //defaultPanelState: PanelState.CLOSED,

                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                panelBuilder: (controller) => Panel(
                  controller: controller,
                  panelController: _pc,
                ),

                body: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        compassEnabled: false,
                        zoomControlsEnabled: false,
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
                                    'Bus Alert',
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
                      bottom: 5,
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
                                              'Search',
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
                                      Navigator.push(
                                        context,
                                        new MaterialPageRoute(
                                          builder: (context) =>
                                              new SearchingPlace(),
                                        ),
                                      );
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
                                    _pc.open();
                                  },
                                )),
                          ]),
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
