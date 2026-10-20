import 'package:flutter/material.dart';

// ganti value sesuai kebutuhan
//====================================================================================

// Dulu disimpan di native-key.cpp (Config.RestServ / HostName / PassRef)
const String baseUrl = "https://kreenconnect.com/kreenapi/event/"; // Config.SERVER_REST (live)
const String apiHostname = "kreenconnect.com"; // Config.HOSTNAME
const String passPref = "hyPERD@T@3mergancy#PXV2022"; // Config.PASSPREF

// JipremiumNetworkModule / ApiServiceJipremium
const String baseUrlJipremium = "https://jipremium.com/api/";
const String jipremiumSecretKey =
    "eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=";

// ScanActivity.kreenConnectSecretKey
const String kreenConnectSecretKey =
    "eyJpdiI6ImZNOGFOVitXTlwvT0hEeUVBSzlDNXdRPT0iLCJ2YWx1ZSI6IldzVFhUUkJ4YWJxcEcxUWFLYk9kd1dJVTNwUTF3Q0tFQjhnVmVJWlprTHdvdVNJb3lJemRmOG9pOUVxRlwveENkcEtIWUlMeldNMlkyM0p4NWRxaGJZMWRzYzJjZm9vTEwzYTY1aHlvTzBCZz0iLCJtYWMiOiJkNTA2ZDE3YTgzYjE3ZjA5ZWNlOWZlZTY3NzhkZjBmNzI2MjExZTY2NTEyMzk4MTdkZThlZDE1ZmNlZDQ0NDA1In0=";

// ParticipantDetail2Activity / ParticipantDetail3Activity.ALLOWED_EVENT_ID
const String allowedEventId = "FWSCMNHJGCBHYDJOQ961";

// Kode referral yang dapat icon gift waktu print (ParticipantDetail2 & 3)
const Set<String> referralCodes = {
  "AZ01TA", "RA02KB", "NP03KG", "AP04WD", "MS05RE", "MI06UN", "DA07HV", "AF08ZZ", "CM09JZ",
  "AG10CY", "CH11WX", "SA12MO", "AR13YU", "MG14QC", "NH15DL", "RP16YI", "MZ17WW", "SR18UQ",
  "CO19YP", "AI20CI", "AA21FS", "NA22KP", "AC23WR", "AP24AD", "IZ25NR", "MA26KW", "TL27LX",
  "EF28JD", "MR29EN", "GS30JO", "SA31EO", "NN32KD", "PO33GL", "MR34FZ", "FW35AV", "DP36OE",
  "AF37OZ", "FC38KS", "AA39PW", "DS40NT", "AN41XN", "KN42UJ", "ZH43FW", "NZ44AM", "KN45UO",
  "BAHASA IBU BAHAGIA COMMUNITY", "BAHASA IBU COMMUNITY", "BIB", "BIBXIMKDS", "PETCAPET",
};

// Key storage (Config.kt)
const String dataPref = "dataPref";
const String tokenF = "tokenFire";
const String statusLoginSp = "loginStatus";
const String idEventSp = "idEvent";
const String titleEventSp = "titleEvent";
const String topicEventSp = "topicEvent";
const String typeEventSp = "typeEvent";
const String bannerTopListSp = "bannerTopList";
const String bannerDownListSp = "bannerDownList";
const String languageSp = "language";
const String printTypeSdkSp = "printTypeSDK";

// PrintTypeSDK.kt
const String printTypeEscpos = "escpos";
const String printTypePrintama = "printama";

// HttpStatus (Resource.kt)
const int httpOk = 200;
const int httpCreated = 201;
const int httpBadRequest = 400;
const int httpErrInternetDisconnected = 422;
const int httpUnauthorized = 401;
const int httpForbidden = 403;
const int httpNotFound = 404;
const int httpInternalServerError = 500;

// Bahasa aktif aplikasi (LanguageManager). "in" = Indonesia, selain itu = default (English).
ValueNotifier<String> langNotifier = ValueNotifier('en');

// Android 15+ (API 35) dengan targetSdk 35: window edge-to-edge (diisi di main())
bool edgeToEdge = true;

// Dipakai ActivityLifecycle untuk onResume/onPause per halaman
final RouteObserver<PageRoute> activityRouteObserver = RouteObserver<PageRoute>();

// Skala font sistem (dipakai untuk ukuran "sp"; ukuran "__Nssp" proyek ini aslinya dp)
double systemTextScale = 1.0;

// res/values/colors.xml
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color colorPrimaryNight = Color(0xFFED5B60);
const Color colorPrimary = Color(0xFFE01A21);
const Color colorPrimaryVariant = Color(0xFFE01A21);
const Color colorPrimaryLight = Color(0xFFFF1D25);
const Color colorPrimaryTransparent = Color(0x17E01A21);
const Color colorTextPrimary = Color(0xFF070707);
const Color colorTextSecondary = Color(0xFF4A4A4A);
const Color colorTextTertiary = Color(0xFF999798);
const Color colorTextFourth = Color(0xFF9E9E9E);
const Color colorTextHint = Color(0xFFC8C8C8);
const Color colorStroke = Color(0xFFE5E5E5);
const Color colorStrokeBg = Color(0xFFF4F4F4);
const Color colorBg = Color(0xFFEFF0F4);
const Color colorBg2 = Color(0xFFF4F4F4);
const Color colorRead = Color(0xFFF21A43);
const Color colorIcon = Color(0xFF949398);
const Color colorGreen = Color(0xFF00CA77);
const Color colorOrange = Color(0xFFFBB004);
const Color colorOrangeLight = Color(0xFFFFF8E8);
// dari library Printama (dipakai di layout printer)
const Color colorWhite = Color(0xFFFFFFFF);
const Color colorAccent = colorPrimary;

// selector_stock_bottom_nav_view.xml
const Color navItemChecked = colorPrimary;
const Color navItemUnchecked = Color(0xFF949398);

// form_background.xml stroke
const Color formStroke = Color(0xFFDADCE0);
