import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPlaces extends StatefulWidget {

  final Function(String) onPlaceSelected;

  SearchPlaces({required this.onPlaceSelected});
  @override
  State<SearchPlaces> createState() => _SearchPlacesState();
}

class _SearchPlacesState extends State<SearchPlaces> {

  final TextEditingController searchController = TextEditingController();
  List<String> suggestions = [];
  bool isLoading = false;

  final String googleApiKey = 'AIzaSyAYee63JgEDjW0y3RrnevDsI3jJv1ZJpwo'; // Replace with your API key

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
      print(response.body);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var predictions = data['predictions'];
        setState(() {
          suggestions = predictions
              .map<String>((prediction) => prediction['description'] as String)
              .toList();
        });
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search & Set Dropoff Location'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: fetchPlaceSuggestions,
              decoration: InputDecoration(
                hintText: 'Search location here...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(suggestions[index]),
                  onTap: () {
                    widget.onPlaceSelected(suggestions[index]);
                    Navigator.pop(context, suggestions[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }}
