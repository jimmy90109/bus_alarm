import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

class LabelOverrides extends DefaultLocalizations {
  const LabelOverrides();

  //Login
  @override
  String get signInText => '登入';
  @override
  String get registerHintText => '還沒有帳號嗎？';
  @override
  String get registerText => '註冊';
  @override
  String get emailInputLabel => '電子信箱';
  @override
  String get passwordInputLabel => '密碼';
  @override
  String get forgotPasswordButtonLabel => '忘記密碼？';
  @override
  String get signInActionText => '登入';
  @override
  String get signInWithGoogleButtonText => '使用 Google 帳號登入';

  //Register
  @override
  String get signInHintText => '還沒有帳號嗎？';
  @override
  String get confirmPasswordInputLabel => '確認密碼';
  @override
  String get registerActionText => '註冊';

  //Forgot password
  @override
  String get forgotPasswordViewTitle => '忘記密碼';
  @override
  String get forgotPasswordHintText => '輸入電子信箱重設密碼';
  @override
  String get resetPasswordButtonLabel => '重設密碼';
  @override
  String get goBackButtonLabel => '返回';

  //Profile
  @override
  String get signInMethods => '登入方式';
  @override
  String get enableMoreSignInMethods => '啟用更多登入方式';
  @override
  String get signOutButtonText => '登出';
  @override
  String get deleteAccount => '刪除帳號';
}
