import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/cart/summary_page.dart';
import 'package:groovyn/widgets/delivery_widget.dart';
import 'package:http/http.dart' as http;

import '../../../main.dart';

class ShippingAddress extends StatefulWidget {
  final String total;
  const ShippingAddress({super.key, required this.total});

  @override
  State<ShippingAddress> createState() => ShippingAddressState();
}

class ShippingAddressState extends State<ShippingAddress> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();

  String? _selectedState;
  String _selectedCountry = 'India';
  bool _saveAddress = false;
  bool _showSaveAddress = true;
  bool isLoading = false;

  final List<String> _indianStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Maharashtra",
    "Madhya Pradesh",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Tripura",
    "Telangana",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Andaman & Nicobar (UT)",
    "Chandigarh (UT)",
    "Dadra & Nagar Haveli and Daman & Diu (UT)",
    "Delhi [National Capital Territory (NCT)]",
    "Jammu & Kashmir (UT)",
    "Ladakh (UT)",
    "Lakshadweep (UT)",
    "Puducherry (UT)",
  ];

  @override
  void initState() {
    super.initState();
    _pinCodeController.addListener(_fetchCityAndState);
  }

  @override
  void dispose() {
    _pinCodeController.removeListener(_fetchCityAndState);
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCityAndState() async {
    final pinCode = _pinCodeController.text.trim();

    if (pinCode.length == 6 && int.tryParse(pinCode) != null) {
      try {
        final response = await http.get(
          Uri.parse("https://api.postalpincode.in/pincode/$pinCode"),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (kDebugMode) {
            print(data);
          }

          if (data != null &&
              data[0]['Status'] == 'Success' &&
              data[0]['PostOffice'] != null &&
              data[0]['PostOffice'].isNotEmpty) {
            setState(() {
              _cityController.text = data[0]['PostOffice'][0]['District'] ?? '';
              _selectedState = data[0]['PostOffice'][0]['State'] ?? '';
            });
          } else {
            EasyLoading.showError('Pin code not found');
          }
        } else {
          EasyLoading.showError('Failed to fetch city and state');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching data: $e');
        }
      }
    } else if (pinCode.isNotEmpty) {
      // EasyLoading.showError('Enter a valid 6-digit pin code');
    }
  }


  void _showSavedAddresses() async {
    String? selectedAddressId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Address',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(thickness: 1),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('address')
                          .where('userID', isEqualTo: theID)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.location_off,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No saved addresses found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final addresses = snapshot.data!.docs;

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: addresses.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final address = addresses[index];
                            final addressId = address.id;

                            return RadioListTile<String>(
                              value: addressId,
                              groupValue: selectedAddressId,
                              title: Text(
                                address['fullName'],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address['phone'],
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  Text(
                                    '${address['address1']}, ${address['address2']}',
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  Text(
                                    '${address['city']}, ${address['state']}, ${address['pinCode']}',
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ],
                              ),
                              onChanged: (value) {
                                setState(() {
                                  selectedAddressId = value;
                                });
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 4.0,
                              ),
                              activeColor: Colors.black,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: selectedAddressId == null
                          ? null
                          : () async {
                        final addressDoc = await FirebaseFirestore.instance
                            .collection('address')
                            .doc(selectedAddressId)
                            .get();

                        if (addressDoc.exists) {
                          setState((){
                            _saveAddress = false;
                            _showSaveAddress = false;
                          });
                          final data = addressDoc.data()!;
                          _fullNameController.text = data['fullName'];
                          _phoneController.text = data['phone'];
                          _address1Controller.text = data['address1'];
                          _address2Controller.text = data['address2'];
                          _cityController.text = data['city'];
                          _pinCodeController.text = data['pinCode'];
                          _selectedState = data['state'];
                          _selectedCountry = data['country'];
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: Text(
                        'USE THIS ADDRESS',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {

      final shippingData = {
        "userID": theID,
        "total": widget.total,
        "orderTime": DateTime.now(),
        "fullName": _fullNameController.text,
        "phone": _phoneController.text,
        "address1": _address1Controller.text,
        "address2": _address2Controller.text,
        "city": _cityController.text,
        "pinCode": _pinCodeController.text,
        "state": _selectedState,
        "country": _selectedCountry,
        "images": cartProductImages,
        "prices": cartProductPrices,
        "productIDs": cartProductIDs,
        "productNames": cartProductNames,
        "quantities": cartProductQuantity,
        "productSizes": cartProductSizes,
        "productColors": cartProductColors,
        'status': 'Pending Delivery',
        'deliveryTime': DateTime.now().add(Duration(days: 4)),
        'processedTime': DateTime(1970, 1, 1),
        'dispatchedTime': DateTime(1970, 1, 1),
        'deliveredTime': DateTime(1970, 1, 1),
        'cancelledTime': DateTime(1970, 1, 1),
        'approved': false,
      };


      final addressData = {
        "userID": theID,
        "addressTime": DateTime.now(),
        "fullName": _fullNameController.text,
        "phone": _phoneController.text,
        "address1": _address1Controller.text,
        "address2": _address2Controller.text,
        "city": _cityController.text,
        "pinCode": _pinCodeController.text,
        "state": _selectedState,
        "country": _selectedCountry,
      };

      setState(() {
        isLoading = true;
      });

      EasyLoading.show(status: 'Reading address...');

      try {

        if (_saveAddress) {
          await FirebaseFirestore.instance.collection('address').add(addressData);
        }

        String address = "${_address1Controller.text} ${_address2Controller.text}, ${_cityController.text}, ${_selectedState!}, $_selectedCountry";

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SummaryPage(address: address, shippingData: shippingData)),
        );
        EasyLoading.dismiss();
        setState(() {
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        EasyLoading.showError('Error Placing the Order. Try Again Later!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(250, 250, 250, 1),
      body: Form(
        key: _formKey,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Text(
                          'Autofill',
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onPressed: _showSavedAddresses,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shipping Address',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField('Full Name', _fullNameController),
                            const SizedBox(height: 16),
                            _buildTextField('Phone Number', _phoneController),
                            const SizedBox(height: 16),
                            _buildTextField('Address Line 1', _address1Controller),
                            const SizedBox(height: 16),
                            _buildTextField('Address Line 2', _address2Controller),
                            const SizedBox(height: 16),
                            _buildTextField('City', _cityController),
                            const SizedBox(height: 16),
                            DeliveryEstimationWidget(
                              pincodeController: _pinCodeController,
                              onPincodeChanged: (pincode) {
                                // Handle pincode change if needed
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField('State', (value) {
                              _selectedState = value;
                            }),
                            const SizedBox(height: 16),
                            if(_showSaveAddress)
                            Row(
                              children: [
                                Checkbox(
                                  value: _saveAddress,
                                  onChanged: (value) {
                                    setState(() {
                                      _saveAddress = value!;
                                    });
                                  },
                                ),
                                Text(
                                  'Save this address to address book',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                  'CONTINUE',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      enabled: label == 'City' ? false:true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
      onChanged: (string){
        if(label == 'Pin Code'){
        _fetchCityAndState();
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(String label, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      items: _indianStates
          .map((option) => DropdownMenuItem<String>(
        value: option,
        child: Text(option, style: const TextStyle(color: Colors.black)),
      ))
          .toList(),
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14),
      validator: (value) => value == null ? 'Please select $label' : null,
    );
  }
}
