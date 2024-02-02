import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:google_map/Profile.dart';
import 'package:google_map/animation/RouteAnimation.dart';

class Login extends StatelessWidget {
  const Login({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      oauthButtonVariant: OAuthButtonVariant.icon_and_text,
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) {
          Navigator.of(context).pushReplacement(FadePageRoute(
            const Profile(),
          ));
        }),
      ],
    );
  }
}
