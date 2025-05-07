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

  @override
  void initState() {
    super.initState();
    _getAnswer();
  }

  void _addToProgressMeter() async {
    ProgressMeterViewModel _progressMeterVM = ProgressMeterViewModel();
    RecordEntry.insertTimestampToCollection("quote");
    _progressMeterVM.showProgressUpdateToast(context, "quote");
  }

  Future<void> _getAnswer() async {
    final response = await OpenAIService.askAI(widget.preference);
    
    setState(() {
      _response = response;
      _isLoading = false;
      
    });

    _addToProgressMeter();
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
                            _response ?? 'Patient is key to life',
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
