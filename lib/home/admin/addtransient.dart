import 'dart:collection';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlng/latlng.dart';
import 'package:telenant/home/admin/gmap/map.dart';
import 'package:telenant/models/model.dart';

import '../../FirebaseServices/services.dart';

typedef IconEntry = DropdownMenuEntry<IconLabel>;

enum IconLabel {
  single('Single Bed Room', Icons.single_bed_rounded),
  twin('Twin Bed Room', Icons.bedroom_parent_rounded),
  double('Double Bed Room', Icons.meeting_room_rounded),
  premier('Premier', Icons.hotel_rounded),
  executive('Executive', Icons.hotel),
  superior('Superior', Icons.king_bed_rounded);

  const IconLabel(this.label, this.icon);
  final String label;
  final IconData icon;

  // Add a static getter for all values
  static const List<IconLabel> allValues = [
    single,
    twin,
    double,
    premier,
    executive,
    superior,
  ];

  static final List<DropdownMenuEntry<IconLabel>> entries = allValues
      .map<DropdownMenuEntry<IconLabel>>(
        (icon) => DropdownMenuEntry<IconLabel>(
          value: icon,
          label: icon.label,
          leadingIcon: Icon(icon.icon),
        ),
      )
      .toList();
}

class AddTransient extends StatefulWidget {
  const AddTransient({super.key});

  @override
  State<AddTransient> createState() => _AddTransientState();
}

class _AddTransientState extends State<AddTransient> {
  List<String> list = <String>['Townhouse', 'Apartment'];
  final List<String> _selectedAmenities = [
    'Cleaning Products',
    'Clothing Storage (Closet)',
    'Ethernet Connection',
    'TV',
    'WiFi',
    'Hot Water',
    'Extra Towel',
    'Extra Pillow and Blanket',
  ];
  String _newAmenity = '';
  String dropdownValue = 'Townhouse';
  bool _fourGuestMax = false;
  bool _noPets = false;
  bool _quietHours = false;
  bool _noSmoking = false;
  ImagePicker picker = ImagePicker();
  bool loading = false;
  XFile? imagecover;
  LocationLatLng? locationLatLng;
  List<XFile>? imagealbum;
  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _transient = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _min = TextEditingController();
  final TextEditingController _max = TextEditingController();
  final TextEditingController _roomTypeController = TextEditingController();
  final TextEditingController _roomBedsController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();
  final TextEditingController _newAmenityController = TextEditingController();
  IconLabel? selectedIcon;
  final List<String> _selectedHouseRules = [];
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  addImage(String from) async {
    if (from == 'imagealbum') {
      try {
        var pickedfiles = await picker.pickMultiImage();
        imagealbum = pickedfiles;
        setState(() {});
      } catch (e) {
        print("error while picking file.");
      }
      setState(() {});
    } else {
      imagecover = await picker.pickImage(source: ImageSource.gallery);
      setState(() {});
    }
  }

  Future<String> uploadFile(File image) async {
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final userEmail = user?.email ?? 'anonymous';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';

      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('transients/$userEmail/$fileName');

      // Create upload task
      UploadTask uploadTask = storageReference.putFile(image);

      // Monitor upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: $progress%');
      }, onError: (e) {
        throw Exception('Upload failed: $e');
      });

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      String downloadUrl = await storageReference.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  void _updateHouseRules(String rule, bool isSelected) {
    if (isSelected) {
      if (!_selectedHouseRules.contains(rule)) {
        _selectedHouseRules.add(rule);
      }
    } else {
      _selectedHouseRules.remove(rule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text('Add Transient',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Help'),
                  content: const Text(
                      'Fill in the details to add a new transient property. All fields marked with * are required.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSection(
              'Basic Information',
              [
                _buildTextField('Transient Name*', _transient,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required field' : null),
                const SizedBox(height: 16),
                _buildLocationField(),
                const SizedBox(height: 16),
                _buildTextField('Contact*', _contact,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required field' : null),
                const SizedBox(height: 16),
                _buildTextField('Website URL', _url),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Room Details',
              [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownMenu<IconLabel>(
                        controller: _roomTypeController,
                        requestFocusOnTap: true,
                        label: const Text('Room Type*'),
                        leadingIcon: selectedIcon == null
                            ? null
                            : Icon(selectedIcon!.icon),
                        onSelected: (IconLabel? icon) {
                          setState(() {
                            selectedIcon = icon;
                          });
                        },
                        dropdownMenuEntries: IconLabel.entries,
                        width: MediaQuery.of(context).size.width * 0.6,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (IconLabel.allValues.indexOf(
                            selectedIcon ?? IconLabel.allValues.first) >
                        2)
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _roomBedsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            labelText: '# of Beds*',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roomNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '# of Rooms*',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Pricing & Type',
              [
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceRangeField(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPropertyTypeDropdown(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'House Rules',
              [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    _buildRuleChip('4 guest maximum', _fourGuestMax, (value) {
                      setState(() {
                        _fourGuestMax = value ?? false;
                        _updateHouseRules('4 guest maximum', _fourGuestMax);
                      });
                    }),
                    _buildRuleChip('No pets', _noPets, (value) {
                      setState(() {
                        _noPets = value ?? false;
                        _updateHouseRules('No pets', _noPets);
                      });
                    }),
                    _buildRuleChip('Quiet hours', _quietHours, (value) {
                      setState(() {
                        _quietHours = value ?? false;
                        _updateHouseRules(
                            'Quiet hours (10 PM - 5 AM)', _quietHours);
                      });
                    }),
                    _buildRuleChip('No smoking', _noSmoking, (value) {
                      setState(() {
                        _noSmoking = value ?? false;
                        _updateHouseRules('No smoking', _noSmoking);
                      });
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Amenities',
              [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _selectedAmenities.map((amenity) {
                    return Chip(
                      backgroundColor: colorScheme.primaryContainer,
                      label: Text(amenity),
                      deleteIcon: Icon(Icons.close, color: colorScheme.primary),
                      onDeleted: () {
                        setState(() {
                          _selectedAmenities.remove(amenity);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _newAmenityController,
                        onChanged: (value) {
                          _newAmenity = value;
                        },
                        decoration: InputDecoration(
                          hintText: 'Add new amenity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_newAmenity.isNotEmpty) {
                          setState(() {
                            _selectedAmenities.add(_newAmenity);
                            _newAmenity = '';
                            _newAmenityController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Images',
              [
                _buildImageUploadCard(
                  'Cover Image*',
                  imagecover,
                  () => addImage('imagecover'),
                  Icons.image,
                ),
                const SizedBox(height: 16),
                _buildImageUploadCard(
                  'Gallery Images',
                  null,
                  () => addImage('imagealbum'),
                  Icons.photo_library,
                  isGallery: true,
                ),
                if (imagealbum != null) ...[
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: imagealbum!.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(imagealbum![index].path),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_formKey.currentState?.validate() ?? false) {
            // Additional validation for required fields
            if (selectedIcon == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a room type'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (imagecover == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please add a cover image'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Check user authentication
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please sign in to add a transient property'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            setState(() {
              loading = true;
            });

            try {
              String? cover;
              List<String> album = [];

              // Upload cover image first
              if (imagecover != null) {
                try {
                  cover = await uploadFile(File(imagecover!.path));
                } catch (e) {
                  throw Exception('Failed to upload cover image: $e');
                }
              }

              // Upload gallery images if any
              if (imagealbum != null && imagealbum!.isNotEmpty) {
                try {
                  var imageUrls = await Future.wait(
                    imagealbum!.map((image) => uploadFile(File(image.path))),
                  );
                  album = imageUrls.cast<String>();
                } catch (e) {
                  print('Warning: Some gallery images failed to upload: $e');
                  // Continue with the process even if some gallery uploads fail
                }
              }

              // Validate price range
              final minPrice = int.tryParse(_min.text) ?? 0;
              final maxPrice = int.tryParse(_max.text) ?? 0;

              if (minPrice > maxPrice) {
                throw Exception(
                    'Minimum price cannot be greater than maximum price');
              }

              if (cover == null) {
                throw Exception('Cover image upload failed');
              }

              Details detail = Details(
                name: _transient.text.trim(),
                location: _location.text.trim(),
                contact: _contact.text.trim(),
                website: _url.text.trim(),
                type: dropdownValue,
                priceRange: PriceRange(
                  min: minPrice,
                  max: maxPrice,
                ),
                locationLatLng:
                    locationLatLng ?? LocationLatLng(latitude: 0, longitude: 0),
                roomType: selectedIcon?.name ?? '',
                numberofbeds: _roomBedsController.text.trim(),
                numberofrooms: _roomNumberController.text.trim(),
                coverPage: cover,
                gallery: album,
                managedBy: user?.email ?? 'anonymous',
                amenities: _selectedAmenities,
                houseRules: _selectedHouseRules,
              );

              await FirebaseFirestoreService.instance.addTransient(detail);

              setState(() {
                loading = false;
              });

              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('Success'),
                    content:
                        const Text('Transient property added successfully'),
                    actions: <Widget>[
                      ElevatedButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context)
                              .pop(); // Go back to previous screen
                        },
                      ),
                    ],
                  ),
                );
              }
            } catch (e) {
              setState(() {
                loading = false;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Dismiss',
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );
              }
            }
          } else {
            // Scroll to the first error
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        },
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(loading ? 'Saving...' : 'Save Transient'),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _location,
      readOnly: true,
      validator: (value) =>
          value?.isEmpty ?? true ? 'Location is required' : null,
      decoration: InputDecoration(
        labelText: 'Location*',
        hintText: 'Select location on map',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        suffixIcon: IconButton(
          icon: const Icon(Icons.map),
          onPressed: () => _selectLocation(context),
        ),
      ),
    );
  }

  Widget _buildPriceRangeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range*',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _min,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Min',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('-'),
            ),
            Expanded(
              child: TextFormField(
                controller: _max,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Max',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Type*',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: dropdownValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          items: list.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              dropdownValue = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRuleChip(
      String label, bool value, void Function(bool?) onChanged) {
    return FilterChip(
      selected: value,
      label: Text(label),
      onSelected: onChanged,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildImageUploadCard(
      String title, XFile? image, VoidCallback onTap, IconData icon,
      {bool isGallery = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: image == null || isGallery
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGallery ? 'Add Gallery Images' : 'Add $title',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(image.path),
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                ),
              ),
      ),
    );
  }

  Future<void> _selectLocation(BuildContext context) async {
    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => const InteractiveMapPage(),
        ),
      );

      if (result != null && mounted) {
        final location = result['locationLatLng'] as LatLng?;
        final locationText = result['locationText'] as String?;

        if (location != null && locationText != null) {
          setState(() {
            _location.text = locationText;
            locationLatLng = LocationLatLng(
              latitude: location.latitude.degrees,
              longitude: location.longitude.degrees,
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid location data received'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
