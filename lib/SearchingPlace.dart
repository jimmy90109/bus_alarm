import 'dart:async';
import 'dart:convert';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:google_map/BusConfirm.dart';
import 'package:google_map/Confirming.dart';
import 'package:location/location.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

import 'animation/RouteAnimation.dart';

class SearchingPlace extends StatefulWidget {
  final LocationData currentLocation;
  const SearchingPlace({
    super.key,
    required this.currentLocation,
  });

  @override
  State<SearchingPlace> createState() => _SearchingPlaceState();
}

class _SearchingPlaceState extends State<SearchingPlace> {
  late FocusNode focusNode = FocusNode();
  TextEditingController txcontroller = TextEditingController();

  //for place autoComplete
  final String _gAPI = "AIzaSyBu6yKj0QDgRglC0Ns-yx_FIUgGBOueh4Q";
  var uuid = const Uuid();
  late String _sessionToken;
  List<dynamic> _placeList = [];

  //for bus search
  String busToken = "";

  //prevent update too responsive
  Timer? _debounced;

  //place or bus
  late int searchMode;

  @override
  void initState() {
    super.initState();
    // optional add a delay before the focus happens.
    Future.delayed(const Duration(milliseconds: 400), () {
      focusNode.requestFocus(); //auto focus on text field.
    });
    _sessionToken = uuid.v4();
    searchMode = 1;
  }

  void _textOnChanged(String value) {
    //1s buffer
    if (_debounced?.isActive ?? false) _debounced!.cancel();
    _debounced = Timer(const Duration(milliseconds: 1000), () => getSuggestion(value));
  }

  void getSuggestion(String input) async {
    if (searchMode == 1) {
      String baseURL = "https://maps.googleapis.com/maps/api/place/autocomplete/json";
      String request = '$baseURL'
          '?input=$input'
          '&key=$_gAPI'
          '&sessiontoken=$_sessionToken'
          '&region=tw'
          '&language=zh-TW';
      var response = await http.get(Uri.parse(request));
      developer.log(json.decode(response.body).toString(), name: 'placeAPI');
      if (response.statusCode == 200) {
        setState(() {
          _placeList = json.decode(response.body)['predictions'];
        });
      } else {
        throw Exception('Failed to load place predictions');
      }
    }

    if (searchMode == 2) {
      //TODO busAPI
      if (busToken.isNotEmpty) {
        var uri = Uri.parse(
            'https://tdx.transportdata.tw/api/basic/v2/Bus/Route/City/Taipei/$input?%24top=20&%24format=JSON');
        var response = await http.get(uri, headers: {'authorization': "Bearer $busToken"});
        if (response.statusCode == 200) {
          developer.log("got response of bus searching");
          setState(() {
            _placeList = json.decode(response.body);
          });
        } else {
          //token expired
          developer.log(json.decode(response.body).toString());
          getBusToken();
        }
      } else {
        //no token
        getBusToken();
      }
    }
  }

  // Future<String>
  void getBusToken() async {
    final response = await http.post(
      Uri.parse("https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token"),
      headers: {'content-type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': 's110916034-d403baf7-99ce-40d0',
        'client_secret': 'b5cc7437-c27f-4476-9401-ac87fc4cdf07'
      },
    );
    developer.log("got busToken");
    // developer.log(json.decode(response.body).toString(), name: 'busToken');

    setState(() {
      busToken = json.decode(response.body)['access_token'];
    });
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Material(
      //type: MaterialType.transparency,
      //color: Colors.transparent,
      //elevation: 20,
      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30),),
      child: InkWell(
        //customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30),),
        child: Ink(
          // height: MediaQuery.of(context).size.height * 1,
          // width: MediaQuery.of(context).size.width * 1,
          decoration: BoxDecoration(
            //borderRadius: BorderRadius.circular(30),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 0.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomSlidingSegmentedControl<int>(
                      initialValue: 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                      children: const {
                        1: Text(' 地點 '),
                        2: Text(' 公車 '),
                      },
                      innerPadding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      thumbDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      onValueChanged: (v) {
                        txcontroller.clear();
                        if (v == 2) {
                          if (busToken.isEmpty) {
                            getBusToken();
                          }
                        }
                        setState(() {
                          _placeList = [];
                          searchMode = v;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                      ),
                      padding: const EdgeInsets.fromLTRB(10.0, 5.0, 5.0, 10.0),
                      child: searchMode == 1
                          ? _placeList.isNotEmpty
                              ? ListView.separated(
                                  //physics: NeverScrollableScrollPhysics(),
                                  reverse: true,
                                  shrinkWrap: true,
                                  itemCount: _placeList.length,
                                  itemBuilder: (context, index) {
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
                                          title: Text(_placeList[index]["structured_formatting"]["main_text"]),
                                          onTap: () async {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            final placeId = _placeList[index]["place_id"];
                                            // print(placeId);
                                            var response = await http
                                                .get(Uri.parse('https://maps.googleapis.com/maps/api/place/details/json'
                                                    '?place_id=$placeId'
                                                    '&language=zh-TW'
                                                    '&fields=place_id,name,geometry'
                                                    '&key=$_gAPI'));
                                            if (response.statusCode == 200) {
                                              var place = json.decode(response.body)['result'];
                                              Navigator.of(context).push(FadePageRoute(Confirming(
                                                  place_name: place['name'],
                                                  place_id: place['place_id'],
                                                  place_lat: place['geometry']['location']['lat'],
                                                  place_lng: place['geometry']['location']['lng'])));
                                            } else {
                                              throw Exception('Failed to load predictions');
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  separatorBuilder: (context, index) {
                                    return const Divider();
                                  },
                                )
                              : const Center(
                                  child: Text("(搜尋地點)"),
                                )
                          : searchMode == 2
                              ? _placeList.isNotEmpty
                                  ? ListView.separated(
                                      //physics: NeverScrollableScrollPhysics(),
                                      reverse: true,
                                      shrinkWrap: true,
                                      itemCount: _placeList.length,
                                      itemBuilder: (context, index) {
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
                                              title: Text(_placeList[index]["RouteName"]["Zh_tw"]),
                                              onTap: () async {
                                                //TODO
                                                FocusManager.instance.primaryFocus?.unfocus();

                                                // final placeId = _placeList[index]["place_id"];
                                                // print(placeId);
                                                // var response = await http.get(Uri.parse(
                                                //     'https://maps.googleapis.com/maps/api/place/details/json'
                                                //     '?place_id=$placeId'
                                                //     '&language=zh-TW'
                                                //     '&fields=place_id,name,geometry'
                                                //     '&key=$_gAPI'));
                                                // if (response.statusCode == 200) {
                                                //   var place = json.decode(response.body)['result'];
                                                Navigator.of(context).push(FadePageRoute(BusConfirm(
                                                  bus_route: _placeList[index]["RouteName"]["Zh_tw"],
                                                  bus_token: busToken,
                                                  lastLocation: widget.currentLocation,
                                                )));
                                                // } else {
                                                //   throw Exception('Failed to load predictions');
                                                // }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      separatorBuilder: (context, index) {
                                        return const Divider();
                                      },
                                    )
                                  : const Center(
                                      child: Text("(搜尋公車)"),
                                    )
                              : Container(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30.0, 0.0, 30.0, 10.0),
                    child: SizedBox(
                      height: 80,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.search,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 24.0,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: txcontroller,
                              cursorHeight: 20,
                              focusNode: focusNode,
                              // controller: tc,
                              // autofocus: true,
                              decoration: InputDecoration(
                                hintText: '搜尋...',
                                suffixIcon: IconButton(
                                    icon: const Icon(Icons.cancel_outlined),
                                    onPressed: () {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      Navigator.pop(context);
                                    }),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  _textOnChanged(value);
                                }
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
