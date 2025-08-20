import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/mains/main_landing.dart';
import 'package:groovyn/main.dart';
import 'package:intl/intl.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? selectedDateOfBirth;
  String selectedGender = "Male";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    EasyLoading.show(status: 'Loading...');
    try {
      final userDoc =
      FirebaseFirestore.instance.collection('users').doc(theID);
      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          firstNameController.text = data['name'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
          selectedDateOfBirth = data['dob'];
          selectedGender = data['gender'] ?? 'Male';
        });
      }
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.showError('Failed to load data');
    }
  }

  Future<void> updateProfile() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty) {
      EasyLoading.showError('All fields are required!');
      return;
    }

    EasyLoading.show(status: 'Updating...');
    try {
      await FirebaseFirestore.instance.collection('users').doc(theID).update({
        'name': firstNameController.text,
        'lastName': lastNameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'dob': selectedDateOfBirth,
        'gender': selectedGender,
      });
      EasyLoading.showSuccess('Profile Updated!');
    } catch (e) {
      EasyLoading.showError('Update failed!');
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDateOfBirth = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Update Profile",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField("First Name*", firstNameController),
                        _buildTextField("Last Name*", lastNameController),
                        _buildTextField("Email Address*", emailController),
                        const SizedBox(height: 10),
                        _buildDatePicker(),
                        const SizedBox(height: 10),
                        _buildGenderSelector(),
                        const SizedBox(height: 10),
                        _buildPhoneField(),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: updateProfile,
                            child: Text("UPDATE",
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: returnBottomBar(context),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    bool enabled = false;
    if(label.contains("Email") && emailController.text.isEmpty){
      enabled = true;
    }
    else if(label.contains("Phone") && phoneController.text.isEmpty){
      enabled = true;
    }
    else if(!(label.contains("Email") || label.contains("phone"))){
      enabled = true;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            filled: true,
            enabled: enabled,
            fillColor: const Color.fromARGB(255, 245, 245, 245),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Date of Birth",
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 245, 245, 245),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selectedDateOfBirth ?? 'Select Date of Birth',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: selectedDateOfBirth != null
                    ? Colors.black
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Text("Gender",
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(width: 20),
        Row(
          children: [
            Radio(
              value: "Male",
              groupValue: selectedGender,
              onChanged: (value) {
                setState(() {
                  selectedGender = value!;
                });
              },
            ),
            Text("Male", style: GoogleFonts.poppins(fontSize: 14)),
          ],
        ),
        Row(
          children: [
            Radio(
              value: "Female",
              groupValue: selectedGender,
              onChanged: (value) {
                setState(() {
                  selectedGender = value!;
                });
              },
            ),
            Text("Female", style: GoogleFonts.poppins(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField("Telephone +91*", phoneController),
        ),
        TextButton(
          onPressed: () {},
          child: Text("Change",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blueAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(2, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            'Profile',
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(width: 10),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
