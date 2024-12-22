import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../search_places.dart';

class HomePage extends StatefulWidget {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  late Position currentPositionOfUser;
  final TextEditingController currentLocationController =
      TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _debounce;

  // Replace with your API key (store it securely)
  final String googleApiKey = 'AIzaSyAYee63JgEDjW0y3RrnevDsI3jJv1ZJpwo';

  List<String> suggestions = [];
  List<dynamic> predictions = [];
  bool isLoading = false;

  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes("themes/night_style.json").then((value) {
      setGoogleMapStyle(value, controller);
    });
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    var byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asInt8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  void setGoogleMapStyle(
      String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  Future<void> getCurrentLiveLocation() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng positionLatLng =
        LatLng(currentPositionOfUser.latitude, currentPositionOfUser.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: positionLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    currentLocationController.text =
        "Lat: ${currentPositionOfUser.latitude}, Long: ${currentPositionOfUser.longitude}";

    setState(() {
      _markers.add(Marker(
        markerId: MarkerId('current_location'),
        position: positionLatLng,
        infoWindow: InfoWindow(title: 'Current Location'),
      ));
    });
  }

  Future<void> fetchPlaceSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => suggestions.clear());
      return;
    }

    setState(() => isLoading = true);

    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var predictionsData = data['predictions'];
        setState(() {
          predictions = predictionsData;
          suggestions = predictionsData
              .map((prediction) => prediction['description'] as String)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchPlaceDetails(String placeId) async {
    String url =
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var result = data['result'];
        double lat = result['geometry']['location']['lat'];
        double lng = result['geometry']['location']['lng'];
        LatLng destination = LatLng(lat, lng);

        calculateRoute(destination);
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
  }

  void calculateRoute(LatLng destination) async {
    Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    LatLng origin = LatLng(userPosition.latitude, userPosition.longitude);

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        visible: true,
        points: [origin, destination],
        width: 5,
        color: Colors.blue,
      ));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            initialCameraPosition:
                CameraPosition(target: LatLng(0, 0), zoom: 2),
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);
              googleMapCompleterController.complete(controllerGoogleMap);
              getCurrentLiveLocation();
            },
            markers: _markers,
            polylines: _polylines,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "From" Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.my_location, color: Colors.blue),
                        Expanded(
                          child: TextField(
                            controller: currentLocationController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Enter starting point',
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  // "To" Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red),
                        Expanded(
                          child: TextField(
                            controller: destinationController,
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchPlaces(
                                    onPlaceSelected: (String place) {
                                      setState(() {
                                        destinationController.text = place;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },

                            onChanged: (value) {
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();
                              _debounce =
                                  Timer(Duration(milliseconds: 300), () {
                                fetchPlaceSuggestions(value);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'To',
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
