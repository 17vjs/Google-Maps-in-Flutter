import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'src/locations.dart' as locations;
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:imei_plugin/imei_plugin.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => new MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(title: 'Police app', home: FirstScreen());
  }
}

class FirstScreen extends StatefulWidget {
  @override
  FirstScreenState createState() => new FirstScreenState();
}

class FirstScreenState extends State<FirstScreen> {
  final _formKey = GlobalKey<FormState>();
  String imei='unknown';
  String selectedIcon;
  final username_controller = TextEditingController();
  final password_controller = TextEditingController();


  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ImeiPlugin.getImei;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      imei = platformVersion;
    });
  }
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    username_controller.dispose();
    password_controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: new AppBar(
        title: new Text("Login Screen"),
      ),
      body: SingleChildScrollView(
          child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.all(10.0),
                child: TextFormField(
                  controller: username_controller,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Username'),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                )),
            Padding(
                padding: EdgeInsets.all(10.0),
                child: TextFormField(
                  controller: password_controller,
                  obscureText: true,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.verified_user),
                      hintText: 'Password'),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter some text';
                    }

                    return null;
                  },
                )),
            Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedIcon = "bike";
                        });
                      },
                      child: SizedBox(
                        width: 125.0,
                        height: 100.0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selectedIcon == "bike"
                                ? Colors.green
                                : Colors.white,
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Image(
                            image: AssetImage('images/bike.png'),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedIcon = "car";
                        });
                      },
                      child: SizedBox(
                        height: 100.0,
                        width: 125.0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selectedIcon == "car"
                                ? Colors.green
                                : Colors.white,
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Image(
                            image: AssetImage('images/car.png'),
                          ),
                        ),
                      ),
                    )
                  ],
                )),
            Padding(
                padding: EdgeInsets.all(10.0),
                child: ButtonTheme(
                  minWidth: 1000.0,
                  height: 50.0,
                  child: RaisedButton(
                    color: Colors.lightBlueAccent,
                    textColor: Colors.white,
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        if (username_controller.text == "admin" &&
                            password_controller.text == "12345" &&
                            selectedIcon != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SecondScreen()),
                          );
                        }
                      }
                    },
                    child: Text("LOGIN"),
                  ),
                )),
            Text(imei),
          ],
        ),
      )),
    );
  }
}

class SecondScreen extends StatefulWidget {
  @override
  SecondScreenState createState() => new SecondScreenState();
}

class SecondScreenState extends State<SecondScreen> {
  LocationData _startLocation;
  LocationData _currentLocation;
  final Map<String, Marker> _markers = {};
  final Map<String, Marker> _markers_cleared = {};
  final Set<Polygon> _polygons={
    Polygon(
        polygonId: PolygonId("1"),
       fillColor: Colors.redAccent,
       strokeColor: Colors.blue,
       strokeWidth: 2,
       points: [LatLng( 22.723505029629937,-118.96871566772461), LatLng(52.13888791853904,-0.8437156677246094 ),LatLng(-17.174373883836022,17.43753433227539 )]
    )
  };

  StreamSubscription<LocationData> _locationSubscription;

  Location _locationService = new Location();
  bool _permission = false;
  String error;

  bool currentWidget = true;

  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _initialCamera = CameraPosition(
    target: LatLng(0, 0),
    zoom: 4,
  );

  CameraPosition _currentCameraPosition;

  GoogleMap googleMap;

  @override
  void initState() {
    super.initState();

    initPlatformState();
    _getPoliceStations('https://about.google/static/data/locations.json');
   // _getPatrollingRegion();

  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    await _locationService.changeSettings(
        accuracy: LocationAccuracy.HIGH, interval: 1000);

    LocationData location;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      bool serviceStatus = await _locationService.serviceEnabled();
      print("Service status: $serviceStatus");
      if (serviceStatus) {
        _permission = await _locationService.requestPermission();
        print("Permission: $_permission");
        if (_permission) {
          location = await _locationService.getLocation();

          _locationSubscription = _locationService
              .onLocationChanged()
              .listen((LocationData result) async {
            _currentCameraPosition = CameraPosition(
                target: LatLng(result.latitude, result.longitude), zoom: 16);

            final GoogleMapController controller = await _controller.future;
            controller.animateCamera(
                CameraUpdate.newCameraPosition(_currentCameraPosition));

            if (mounted) {
              setState(() {
                _currentLocation = result;
              });
            }
          });
        }
      } else {
        bool serviceStatusResult = await _locationService.requestService();
        print("Service status activated after request: $serviceStatusResult");
        if (serviceStatusResult) {
          initPlatformState();
        }
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        error = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        error = e.message;
      }
      location = null;
    }

    setState(() {
      _startLocation = location;
    });
  }

  slowRefresh() async {
    _locationSubscription.cancel();
    await _locationService.changeSettings(
        accuracy: LocationAccuracy.BALANCED, interval: 10000);
    _locationSubscription =
        _locationService.onLocationChanged().listen((LocationData result) {
      if (mounted) {
        setState(() {
          _currentLocation = result;
        });
      }
    });
  }

  bool markerStatus = false;

  Future<void> _getPoliceStations(String url) async {
    final googleOffices = await locations.getGoogleOffices(url);
    setState(() {
      _markers.clear();
      for (final office in googleOffices.offices) {

        final marker = Marker(
          icon: BitmapDescriptor.defaultMarkerWithHue(120.0),
          markerId: MarkerId(office.name),
//         draggable: true,
          position: LatLng(office.lat, office.lng),
          infoWindow: InfoWindow(
            title: office.name,
            snippet: office.address,
          ),
        );
        _markers[office.name] = marker;
      }
    });
  }
  Future<void> _getPatrollingRegion(String url) async {
    final googleOffices = await locations.getGoogleOffices(url);
    setState(() {
      _polygons.clear();
      for (final office in googleOffices.offices) {

        final marker = Marker(
          icon: BitmapDescriptor.defaultMarkerWithHue(240.0),
          markerId: MarkerId(office.name),
//          draggable: true,
          position: LatLng(office.lat, office.lng),
          infoWindow: InfoWindow(
            title: office.name,
            snippet: office.address,
          ),
        );
        _markers[office.name] = marker;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    googleMap = GoogleMap(
      mapType: MapType.normal,
      myLocationEnabled: true,
      initialCameraPosition: _initialCamera,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
      polygons:_polygons ,
      markers: markerStatus
          ? _markers.values.toSet()
          : _markers_cleared.values.toSet(),
    );

//    widgets = [
//      Center(
//        child: SizedBox(
//
//            child: googleMap
//        ),
//      ),
//    ];
//
//
//    widgets.add(new Center(
//        child: new Text(_startLocation != null
//            ? 'Start location: ${_startLocation.latitude} & ${_startLocation.longitude}\n'
//            : 'Error: $error\n')));
//
//    widgets.add(new Center(
//        child: new Text(_currentLocation != null
//            ? 'Continuous location: \nlat: ${_currentLocation.latitude} & long: ${_currentLocation.longitude} \nalt: ${_currentLocation.altitude}m\n'
//            : 'Error: $error\n', textAlign: TextAlign.center)));
//
//    widgets.add(new Center(
//        child: new Text(_permission
//            ? 'Has permission : Yes'
//            : "Has permission : No")));
//
//    widgets.add(new Center(
//        child: new RaisedButton(
//            child: new Text("Slow refresh rate and accuracy"),
//            onPressed: () => slowRefresh()
//        )
//    ));

    return Scaffold(
        appBar: new AppBar(
          title: new Text('Map screen'),
        ),
        body: googleMap,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new FloatingActionButton(
              heroTag: null,
//           onPressed: () => _locationSubscription.cancel(),
              onPressed: () {
                setState(() {
                  markerStatus = !markerStatus;
                });
              },
              tooltip: 'Show Police Stations',
              child: Icon(Icons.home),
            ),
            new FloatingActionButton(
//           onPressed: () => _locationSubscription.cancel(),
              heroTag: null,
              backgroundColor: Colors.red,
              onPressed: () {
                setState(() {
                  markerStatus = !markerStatus;
                });
              },
              tooltip: 'Show Police Vans',
              child: Icon(Icons.directions_bus),
            ),
            new FloatingActionButton(
//           onPressed: () => _locationSubscription.cancel(),
              heroTag: null,
              backgroundColor: Colors.green,
              onPressed: () {},
              tooltip: 'Show Police Vans',
              child: Icon(Icons.toc),
            ),
          ],
        ));
  }
}
