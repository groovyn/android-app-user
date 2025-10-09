import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';

class OTPCode extends StatefulWidget {
  const OTPCode({super.key});

  @override
  OTPCodeState createState() => OTPCodeState();
}

class OTPCodeState extends State<OTPCode> {

  final List<TextEditingController> editControllers = List.generate(6, (index) => TextEditingController());

  String time = "05:00";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(230, 243, 236, 1),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            Row(
              children: [
                const SizedBox(
                  width: 12,
                ),
                GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Image.asset(
                      "assets/svgs/back.png",
                      width: 35,
                      height: 35,
                      fit: BoxFit.fitHeight,
                    )),
                const Expanded(
                    child: SizedBox(
                  width: 20,
                )),
                const Text(
                  'Enter OTP Code',
                  style: TextStyle(
                    color: Color(0xFF242833),
                    fontSize: 22,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    height: 0.06,
                  ),
                ),
                const Expanded(
                    child: SizedBox(
                  width: 20,
                )),
              ],
            ),
            const Expanded(
                child: SizedBox(
              height: 25,
            )),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'We Already have sent you verification to +923*****633, Please check it',
                    style: const TextStyle(
                      color: Color(0xFF3A3E48),
                      fontSize: 14,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w400,
                      //height: 0.09,
                    ),
                  ),
                  const TextSpan(
                    text: '(Contact SCR Administration)',
                    style: TextStyle(
                      color: Color(0xFF01803D),
                      fontSize: 14,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      //letterSpacing: -0.50,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildOtpTextField(0),
                _buildOtpTextField(1),
                _buildOtpTextField(2),
                _buildOtpTextField(3),
                _buildOtpTextField(4),
                _buildOtpTextField(5),
              ],
            ),
            const SizedBox(
              height: 25,
            ),
            GestureDetector(
              onTap: () async {
                for (int i = 0; i < editControllers.length; i++) {
                  if (editControllers[i].text.isNotEmpty) {
                  } else {
                    EasyLoading.showError('OTP Invalid');
                  }
                }
              },
              child: Container(
                height: 60,
                decoration: ShapeDecoration(
                  color: const Color(0xFF01803D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.31),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Confirm',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      //height: 0.06,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: const SizedBox(
                    height: 30,
                    child: Text(
                      'Resend Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF01803D),
                        fontSize: 13,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        height: 0.11,
                      ),
                    ),
                  ),
                ),
                Text(
                  time,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF01803D),
                    fontSize: 17,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    height: 0.08,
                  ),
                )
              ],
            ),
            const Expanded(
              flex: 3,
              child: SizedBox(
                height: 25,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOtpTextField(int value) {
    return Container(
      width: 50,
      height: 50,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: editControllers[value].text.isEmpty
            ? const Color.fromRGBO(78, 167, 120, 0.6)
            : Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.23, color: Color(0xFF3A3E48)),
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      child: Center(
        child: TextField(
          maxLength: 1,
          cursorColor: Colors.transparent,
          cursorHeight: 0,
          controller: editControllers[value],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          onChanged: (val) {
            setState(() {});
            if (value != 5) {
              FocusScope.of(context).nextFocus();
            }
          },
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
          style: const TextStyle(
            color: Color(0xFF242833),
            fontSize: 36,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            //height: 0.04,
          ),
        ),
      ),
    );
  }
}
