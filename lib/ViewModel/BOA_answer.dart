import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seek_here/Model/appimages.dart';
import 'package:seek_here/Model/openai_service.dart';
import 'package:seek_here/View/utils/wh_getter.dart';
import 'package:seek_here/Model/progress_meter_model.dart';
import 'package:seek_here/ViewModel/progress_meter_viewmodel.dart';

class BOAAnswer extends StatefulWidget {
  final String preference;

  const BOAAnswer({super.key, required this.preference});

  @override
  State<BOAAnswer> createState() => _BOAAnswerState();
}

class _BOAAnswerState extends State<BOAAnswer> {
  String? _response;
  bool _isLoading = true;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _getAnswer();
  }

  Future<bool> hasUsedBOAToday() async {
    if (_currentUser == null) return false;

    final uid = _currentUser.uid;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final snapshot =
          await _firebaseFirestore
              .collection("quote")
              .where('userId', isEqualTo: uid)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _addToProgressMeter() async {
    final usedToday = await hasUsedBOAToday();

    if (!usedToday) {
      await RecordEntry.insertTimestampToCollection("quote");
      ProgressMeterViewModel().showProgressUpdateToast(context, "quote");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _getAnswer() async {
    final response = await OpenAIService.askAI(widget.preference);

    final isError =
        response.startsWith("Error occurred:") ||
        response.startsWith("API call failed:");

    if (mounted) {
      setState(() {
        _response = isError ? null : response;
        _isLoading = false;
      });

      if (!isError) {
        _addToProgressMeter();
      } else {
        _showErrorSnackBar(
          "Oops! Something went wrong. Please try again later.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double h, w;
    (h, w) = WHGetter.getHeightAndWidth(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: SizedBox(
          height: h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 60,
                left: -2,
                child: SvgPicture.asset(AppImages.bgCloud),
              ),
              Center(
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _response ?? '"Patient is key to life."',
                            style: GoogleFonts.aDLaMDisplay(fontSize: 36),
                            textAlign: TextAlign.center,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
