import 'package:flutter/material.dart';
import 'package:seek_here/Model/openai_service.dart';

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

  Future<void> _getAnswer() async {
    final response = await OpenAIService.askAI(widget.preference);
    setState(() {
      _response = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Answer")),
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _response ?? "No answer received.",
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  )
                ),
      ),
    );
  }
}
