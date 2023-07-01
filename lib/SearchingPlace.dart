import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_map/Confirming.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class SearchingPlace extends StatefulWidget {
  const SearchingPlace({super.key});

  @override
  State<SearchingPlace> createState() => _SearchingPlaceState();
}

class _SearchingPlaceState extends State<SearchingPlace> {
  //late FocusNode focusNode = FocusNode();
  TextEditingController tc = TextEditingController();

  //for autoComplete
  String kPLACES_API_KEY = "AIzaSyBu6yKj0QDgRglC0Ns-yx_FIUgGBOueh4Q";
  var uuid = new Uuid();
  String _sessionToken = "122344";
  List<dynamic> _placeList = [];

  //prevent update too responsive
  Timer? _debounced;

  @override
  void initState() {
    super.initState();
    tc.addListener(() {
      _TextOnChanged();
    });
  }

  void _TextOnChanged() {
    if (tc.text != "") {
      if (_sessionToken == null) {
        setState(() {
          _sessionToken = uuid.v4();
        });
      }
      if (_debounced?.isActive ?? false) _debounced!.cancel();
      _debounced = Timer(const Duration(milliseconds: 1000), () {
        getSuggestion(tc.text);
      });
    }
  }

  void getSuggestion(String input) async {
    String baseURL =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json";
    String request = '$baseURL'
        '?input=$input'
        '&key=$kPLACES_API_KEY'
        '&sessiontoken=$_sessionToken'
        '&region=tw'
        '&language=zh-TW';
    var response = await http.get(Uri.parse(request));

    print(response.body.toString());
    if (response.statusCode == 200) {
      setState(() {
        _placeList = json.decode(response.body)['predictions'];
      });
    } else {
      throw Exception('Failed to load predictions');
    }
  }

  // @override
  // void initState() {
  //   // optional add a delay before the focus happens.
  //   Future.delayed(Duration(milliseconds: 310), () {
  //     focusNode.requestFocus(); //auto focus on text field.
  //   });
  //   super.initState();
  // }
  //
  // @override
  // void dispose() {
  //   // Clean up the focus node when the Form is disposed.
  //   focusNode.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Hero(
          tag: 'searchingHero',
          child: Material(
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
                        Expanded(
                          flex: 5,
                          child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer,
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                  10.0, 5.0, 5.0, 10.0),
                              child: _placeList.length > 0
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
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                                size: 24.0,
                                              ),
                                              title: Text(_placeList[index]
                                                  ["description"]),
                                              onTap: () async {
                                                final placeId =
                                                    _placeList[index]
                                                        ["place_id"];
                                                print(placeId);
                                                var response = await http.get(Uri.parse(
                                                    'https://maps.googleapis.com/maps/api/place/details/json'
                                                    '?place_id=$placeId'
                                                    '&language=zh-TW'
                                                    '&fields=place_id,name,geometry'
                                                    '&key=$kPLACES_API_KEY'));
                                                if (response.statusCode ==
                                                    200) {
                                                  //json.decode(response.body)['result']
                                                  print(
                                                      response.body.toString());
                                                  var place = json.decode(
                                                      response.body)['result'];
                                                  print(place['name']);
                                                  print(place['place_id']);
                                                  print(place['geometry']
                                                      ['location']['lat']);
                                                  print(place['geometry']
                                                      ['location']['lng']);

                                                  Navigator.push(
                                                    context,
                                                    new MaterialPageRoute(
                                                      builder: (context) =>
                                                          new Confirming(
                                                              place_name:
                                                                  place['name'],
                                                              place_id: place[
                                                                  'place_id'],
                                                              place_lat: place[
                                                                          'geometry']
                                                                      [
                                                                      'location']
                                                                  ['lat'],
                                                              place_lng: place[
                                                                          'geometry']
                                                                      [
                                                                      'location']
                                                                  ['lng']),
                                                    ),
                                                  );
                                                } else {
                                                  throw Exception(
                                                      'Failed to load predictions');
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      separatorBuilder: (context, index) {
                                        return Divider();
                                      },
                                    )
                                  : Center(
                                      child: Text("(搜尋結果)"),
                                    )),
                        ),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(30.0, 0.0, 30.0, 10.0),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.search,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  size: 24.0,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    //focusNode: focusNode,
                                    controller: tc,
                                    //autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: '搜尋...',
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: Icon(Icons.cancel_outlined),
                                      ),
                                    ),

                                    //onChanged: (value) {
                                    // if (value.isNotEmpty) {
                                    //   _TextOnChanged();
                                    // } else {}
                                    //},
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
          )),
    );
  }
}
