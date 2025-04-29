import 'package:flutter/material.dart';
import 'utils/wh_getter.dart';
import 'package:seek_here/Model/openai_service.dart';

class Boa extends StatefulWidget {
  const Boa({super.key});

  @override
  State<Boa> createState() => _Boa();
}

class _Boa extends State<Boa> {
  String response = ''; // To store AI output
  bool isLoading = false;

  void getAIResponse(String prompt) async {
    setState(() {
      isLoading = true;
    });

    try {
      String result = await OpenAIService.askAI(prompt);
      setState(() {
        response = result;
      });
    } catch (e) {
      setState(() {
        response = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    
    return Scaffold(
      appBar: AppBar(title: Text("AI Demo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TextField for input
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter your prompt',
                border: OutlineInputBorder(),
              ),
              maxLines: 1, // Only one line for the prompt input
            ),
            SizedBox(height: 20),
            // Button to submit the prompt
            ElevatedButton(
              onPressed:
                  () => getAIResponse(
                    _controller.text,
                  ), // Use the input from the TextField
              child: Text("Ask AI"),
            ),
            SizedBox(height: 20),
            // Loading indicator or response text
            isLoading
                ? CircularProgressIndicator()
                : Text(response, style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
