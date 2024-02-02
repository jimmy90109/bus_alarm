import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:google_map/database/place_database.dart';
import 'package:google_map/model/place.dart';
import 'dart:developer' as developer;

import 'package:google_map/util/toast.dart';

class Profile extends StatelessWidget {
  const Profile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      actions: [
        SignedOutAction((context) {
          Navigator.pop(context);
        }),
      ],
      children: [
        OutlinedButton(
            onPressed: () {
              backUp();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sync),
                SizedBox(width: 10),
                Text("同步資料"),
              ],
            ))
      ],
    );
  }
}

Future<void> backUp() async {
  FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;
  var uid = user?.uid;
  DatabaseReference ref = FirebaseDatabase.instance.ref(uid.toString());

  List<Place> hisPlaceList, favPlaceList;
  hisPlaceList = await PlacesDatabase.instance.readAllPlaces(hisTable);
  favPlaceList = await PlacesDatabase.instance.readAllPlaces(favTable);

  await updateList(ref, hisPlaceList, hisTable);
  await updateList(ref, favPlaceList, favTable);

  warning("已同步資料！");
}

Future updateList(DatabaseReference ref, List places, String listName) async {
  //update local data to firebase
  if (places.isNotEmpty) {
    for (var item in places) {
      listName == hisTable
          ? await ref.update(
              {"history/${item.id}": item.toJsonNoID()},
            ).catchError((error) => {
                warning("歷史地點上傳失敗"),
                developer.log(error.toString(), name: "historyBackUp"),
              })
          : await ref.update(
              {"favorite/${item.id}": item.toJsonNoID()},
            ).catchError((error) => {
                warning("收藏地點上傳失敗"),
                developer.log(error.toString(), name: "favoriteBackUp"),
              });
    }
    places.clear();
  }

  //download firebase data to local
  await ref
      .child(
        listName == hisTable ? 'history' : 'favorite',
      )
      .get()
      .then((snapshot) {
    for (var msgSnapshot in snapshot.children) {
      final data = Map<String, dynamic>.from(msgSnapshot.value as Map);
      data['id'] = msgSnapshot.key.toString();
      developer.log(data.toString(), name: "JsonData");
      var place = Place.fromJson(data);
      places.add(place);
    }
  });

  //add to SQLite
  await PlacesDatabase.instance.clear(listName == hisTable ? hisTable : favTable);
  for (var place in places) {
    await PlacesDatabase.instance.create(listName == hisTable ? hisTable : favTable, place);
  }
}
