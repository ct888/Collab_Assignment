import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/moodViewModel.dart';
import '../../models/mood.dart';
import '../../models/diary_entry.dart';

class MoodInputScreen extends StatefulWidget {
  const MoodInputScreen({Key? key}) : super(key: key);

  @override
  State<MoodInputScreen> createState() => _MoodInputScreenState();
}

class _MoodInputScreenState extends State<MoodInputScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedMood = 'neutral';
  int _moodIntensity = 5;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _diaryController = TextEditingController();
  
  final List<String> _moodOptions = [
    'happy', 'sad', 'anxious', 'relaxed', 'angry', 
    'excited', 'tired', 'bored', 'stressed', 'neutral'
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling?'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select your current mood:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMoodSelector(),
                const SizedBox(height: 24),
                const Text(
                  'How intense is this feeling?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildIntensitySlider(),
                const SizedBox(height: 24),
                const Text(
                  'Additional notes about how you feel:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe your feelings in more detail...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Diary Entry (optional):',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _diaryController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Write about your day or what\'s on your mind...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveMoodData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _moodOptions.map((mood) {
        return ChoiceChip(
          label: Text(
            mood.substring(0, 1).toUpperCase() + mood.substring(1),
            style: TextStyle(
              color: _selectedMood == mood ? Colors.white : Colors.black,
            ),
          ),
          selected: _selectedMood == mood,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedMood = mood;
              });
            }
          },
          selectedColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey.shade200,
        );
      }).toList(),
    );
  }

  Widget _buildIntensitySlider() {
    return Column(
      children: [
        Slider(
          value: _moodIntensity.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: _moodIntensity.toString(),
          onChanged: (value) {
            setState(() {
              _moodIntensity = value.round();
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Mild'),
            Text('Strong'),
          ],
        ),
      ],
    );
  }

  void _saveMoodData() {
    if (_formKey.currentState!.validate()) {
      final moodViewModel = Provider.of<MoodViewModel>(context, listen: false);
      
      // Create mood data
      final mood = UserMood(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        moodType: _selectedMood,
        intensity: _moodIntensity,
        notes: _notesController.text,
        timestamp: DateTime.now(),
      );
      
      // Save mood
      moodViewModel.setMood(mood);
      
      // Create diary entry if provided
      if (_diaryController.text.isNotEmpty) {
        final diaryEntry = DiaryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _diaryController.text,
          timestamp: DateTime.now(),
          tags: [_selectedMood],
        );
        
        // Save diary entry
        moodViewModel.setDiaryEntry(diaryEntry);
      }
      
      // Return to previous screen
      Navigator.pop(context, true);
    }
  }
}