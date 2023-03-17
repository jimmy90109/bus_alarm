import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart'as http;

class SearchingPlace extends StatefulWidget {
  const SearchingPlace({super.key});

  @override
  State<SearchingPlace> createState() => _SearchingPlaceState();
}

class _SearchingPlaceState extends State<SearchingPlace> {
  late FocusNode focusNode = FocusNode();
  TextEditingController tc = TextEditingController();

  var uuid= new Uuid();
  String _sessionToken = "122344";
  List<dynamic>_placeList = [];

  @override
  void initState() {
    super.initState();
    tc.addListener(() {
      _onChanged();
    });
  }

  void _onChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSuggestion(tc.text);
  }

  void getSuggestion(String input) async {
    String kPLACES_API_KEY = "AIzaSyDhGtsYBZrsbBpzo3N2fl3xTvv87ETTI3w";
    //String type = ‘TW’;
    String baseURL = "https://maps.googleapis.com/maps/api/place/autocomplete/json";
    String request = '$baseURL?input=$input&key=$kPLACES_API_KEY&sessiontoken=$_sessionToken&region=tw&language=zh-TW';
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
                            padding:
                                const EdgeInsets.fromLTRB(10.0, 5.0, 5.0, 10.0),
                            child: ListView.separated(
                              //physics: NeverScrollableScrollPhysics(),
                              reverse: true,
                              shrinkWrap: true,
                              itemCount: _placeList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: Icon(
                                    Icons.place,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    size: 24.0,
                                  ),
                                  title: Text(_placeList[index]["description"]),
                                  onTap: () {
                                    // do something
                                  },
                                );
                              },
                              separatorBuilder: (context, index) {
                                return Divider();
                              },
                            ),
                            // ListView(
                            //   reverse: true,
                            //   //padding: EdgeInsets.zero,
                            //   //controller: controller,
                            //   children: <Widget>[
                            //     Container(
                            //       child: Column(
                            //         crossAxisAlignment:
                            //             CrossAxisAlignment.start,
                            //         mainAxisAlignment: MainAxisAlignment.end,
                            //         children: <Widget>[
                            //           Text("About",
                            //               style: TextStyle(
                            //                 fontWeight: FontWeight.w600,
                            //               )),
                            //           SizedBox(
                            //             height: 12.0,
                            //           ),
                            //           Text(
                            //             """Pittsburgh is a city in the state of Pennsylvania in the United States, and is the county seat of Allegheny County. A population of about 302,407 (2018) residents live within the city limits, making it the 66th-largest city in the U.S. The metropolitan population of 2,324,743 is the largest in both the Ohio Valley and Appalachia, the second-largest in Pennsylvania (behind Philadelphia), and the 27th-largest in the U.S.\n\nPittsburgh is located in the southwest of the state, at the confluence of the Allegheny, Monongahela, and Ohio rivers. Pittsburgh is known both as "the Steel City" for its more than 300 steel-related businesses and as the "City of Bridges" for its 446 bridges. The city features 30 skyscrapers, two inclined railways, a pre-revolutionary fortification and the Point State Park at the confluence of the rivers. The city developed as a vital link of the Atlantic coast and Midwest, as the mineral-rich Allegheny Mountains made the area coveted by the French and British empires, Virginians, Whiskey Rebels, and Civil War raiders.\n\nAside from steel, Pittsburgh has led in manufacturing of aluminum, glass, shipbuilding, petroleum, foods, sports, transportation, computing, autos, and electronics. For part of the 20th century, Pittsburgh was behind only New York City and Chicago in corporate headquarters employment; it had the most U.S. stockholders per capita. Deindustrialization in the 1970s and 80s laid off area blue-collar workers as steel and other heavy industries declined, and thousands of downtown white-collar workers also lost jobs when several Pittsburgh-based companies moved out. The population dropped from a peak of 675,000 in 1950 to 370,000 in 1990. However, this rich industrial history left the area with renowned museums, medical centers, parks, research centers, and a diverse cultural district.\n\nAfter the deindustrialization of the mid-20th century, Pittsburgh has transformed into a hub for the health care, education, and technology industries. Pittsburgh is a leader in the health care sector as the home to large medical providers such as University of Pittsburgh Medical Center (UPMC). The area is home to 68 colleges and universities, including research and development leaders Carnegie Mellon University and the University of Pittsburgh. Google, Apple Inc., Bosch, Facebook, Uber, Nokia, Autodesk, Amazon, Microsoft and IBM are among 1,600 technology firms generating \$20.7 billion in annual Pittsburgh payrolls. The area has served as the long-time federal agency headquarters for cyber defense, software engineering, robotics, energy research and the nuclear navy. The nation's eighth-largest bank, eight Fortune 500 companies, and six of the top 300 U.S. law firms make their global headquarters in the area, while RAND Corporation (RAND), BNY Mellon, Nova, FedEx, Bayer, and the National Institute for Occupational Safety and Health (NIOSH) have regional bases that helped Pittsburgh become the sixth-best area for U.S. job growth.""",
                            //             softWrap: true,
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ),
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
                                      hintText: 'Search...',
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: Icon(Icons.cancel_outlined),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        _onChanged();
                                      } else {}
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
          )),
    );
  }
}

