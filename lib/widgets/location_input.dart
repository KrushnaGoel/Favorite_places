import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

class LocationInput extends StatefulWidget {
  const LocationInput({super.key, required this.onSelectLocation});
  final void Function(LocationData location) onSelectLocation;

  @override
  State<LocationInput> createState() {
    return _LocationInputState();
  }
}

class _LocationInputState extends State<LocationInput> {
  LocationData? _pickedLocation;
  var _isGettingLocation = false;

  final _mapController = MapController();

  void _updatePickedLocation(LocationData location) {
    setState(() {
      _pickedLocation = location;
      widget.onSelectLocation(_pickedLocation!); // Call the callback with the new location
    });
  }
  void _selectOnMap() async {
  final result = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => Scaffold(
        appBar: AppBar(
          title: const Text('Select Your Location'),
        ),
        body: FlutterLocationPicker(
          // ... other properties ...
          onPicked: (pickedData) {
            Navigator.of(ctx).pop(pickedData.latLong); // Return the picked location
          },
          initPosition: LatLong(30.9686901,76.4655716),
          // ... other properties ...
        ),
      ),
    ),
  );

  if (result != null) {
    setState(() {
      _pickedLocation = LocationData.fromMap({
        'latitude': result.latitude,
        'longitude': result.longitude,
      });
    });
  }
  _updatePickedLocation(_pickedLocation!);
}



  void _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    setState(() {
      _isGettingLocation = true;
    });

    locationData = await location.getLocation();
    if (!mounted) return; // Check if the widget is still mounted

    setState(() {
      if (locationData!=null) {
        _pickedLocation = locationData;
        _mapController.move(
          LatLng(locationData.latitude!, locationData.longitude!),
          13.0,
        );
        _isGettingLocation = false;
      }
    });
    _updatePickedLocation(_pickedLocation!);
  }

  @override
  Widget build(BuildContext context) {
    Widget previewContent = _pickedLocation == null
        ? Text(
            'No location Entered',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
          )
        : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                  _pickedLocation!.latitude!, _pickedLocation!.longitude!),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(_pickedLocation!.latitude!,
                        _pickedLocation!.longitude!),
                    child: const Icon(Icons.location_on),
                  ),
                ],
              ),
            ],
          );

    return Column(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: previewContent,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              label: const Text('Get Current \n Location'),
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.location_on),
            ),
            TextButton.icon(
              label: const Text('Select on map'),
              onPressed: _selectOnMap,
              icon: const Icon(Icons.map),
            ),
          ],
        )
      ],
    );
  }
}
