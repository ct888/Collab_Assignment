import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/diarywrite_view_model.dart';
import '/widgets/confirmation_dialog.dart';
import 'package:image_picker/image_picker.dart';

class DiaryWriteScreen extends StatelessWidget {
  final String currentUserId;
  
  const DiaryWriteScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiaryViewModel(currentUserId: currentUserId),
      child: const DiaryWriteView(),
    );
  }
}

class DiaryWriteView extends StatelessWidget {
  const DiaryWriteView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DiaryViewModel>(context);

    // Show confirmation dialog for success or error messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.errorMessage != null) {
        showBeautifulConfirmationDialog(
          context: context,
          title: "Error",
          icon: Icons.error_outline,
          message: viewModel.errorMessage!,
          onConfirm: () => viewModel.clearMessages(),
        );
      }

      if (viewModel.successMessage != null) {
        showBeautifulConfirmationDialog(
          context: context,
          title: "Success",
          icon: Icons.check_circle_outline,
          message: viewModel.successMessage!,
          onConfirm: () => viewModel.clearMessages(),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorations
            Positioned(
              top: -80,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(200),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(200),
                ),
              ),
            ),

            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, size: 24),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.only(top: 34.0),
                          child: Text(
                            "Diary",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Diary Card
                Expanded(
                  child: Center(
                    child: Container(
                      width: 360,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Date & Day
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "${_getFormattedDate()}  ",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(_getDayOfWeek()),
                                  ],
                                ),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                            const SizedBox(height: 10),

                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Write your diary entry:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Diary input field
                            TextField(
                              controller: viewModel.contentController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: "Start writing here...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              onChanged: viewModel.setContent,
                            ),
                            const SizedBox(height: 16),

                            // Visibility & Data tracking switches
                            _buildSwitchRow(
                              label: "Public Visibility",
                              value: viewModel.publicVisibility,
                              onChanged: viewModel.setVisibility,
                            ),
                            _buildSwitchRow(
                              label: "Data Tracking",
                              value: viewModel.dataTracking,
                              onChanged: viewModel.setDataTracking,
                            ),
                            const SizedBox(height: 8),

                            // Image upload button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (viewModel.isImageUploading)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 12.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.upload_file),
                                  onPressed:
                                      viewModel.isImageUploading
                                          ? null
                                          : () async {
                                            await showDialog(
                                              context: context,
                                              builder: (_) {
                                                return AlertDialog(
                                                  title: const Text(
                                                    'Select Image Source',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () async {
                                                        await viewModel
                                                            .pickImage(
                                                              source:
                                                                  ImageSource
                                                                      .camera,
                                                            );
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                      },
                                                      child: const Text(
                                                        'Take a Photo',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        await viewModel
                                                            .pickImage(
                                                              source:
                                                                  ImageSource
                                                                      .gallery,
                                                            );
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                      },
                                                      child: const Text(
                                                        'Pick from Gallery',
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                  tooltip: "Upload images",
                                ),
                              ],
                            ),

                            // Display uploaded images
                            if (viewModel.imageFiles.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Uploaded Images:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 150,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: viewModel.imageFiles.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              viewModel.imageFiles[index],
                                              height: 150,
                                              width: 150,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 5,
                                            right: 5,
                                            child: GestureDetector(
                                              onTap: () {
                                                // Remove specific image
                                                viewModel.removeImage(index);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (viewModel.isUploading ||
                                      viewModel.isImageUploading)
                                  ? null
                                  : () async {
                                    await showBeautifulConfirmationDialog(
                                      context: context,
                                      title: "Save Draft",
                                      icon: Icons.cloud_upload,
                                      message:
                                          "Are you sure you want to save this as a draft? You can only have up to 3 drafts at a time.\n\nCurrent draft count: ${viewModel.currentDraftCount}/3?",
                                      onConfirm: () => viewModel.saveAsDraft(),
                                    );
                                  },
                          icon:
                              viewModel.isUploading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black54,
                                    ),
                                  )
                                  : const Icon(Icons.save_alt),
                          label: const Text("Save as Draft"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade100,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (viewModel.isUploading ||
                                      viewModel.isImageUploading)
                                  ? null
                                  : () async {
                                    await showBeautifulConfirmationDialog(
                                      context: context,
                                      title: "Upload Entry",
                                      icon: Icons.cloud_upload,
                                      message:
                                          "Are you sure you want to Share Your Diary?",
                                      onConfirm: () => viewModel.uploadDiary(),
                                    );
                                  },
                          icon:
                              viewModel.isUploading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black54,
                                    ),
                                  )
                                  : const Icon(Icons.share_rounded),
                          label: const Text("Share"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.shade100,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Utility function to build Switch rows
  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Text(label),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged),
        const Tooltip(
          message: "Toggle visibility or data tracking",
          child: Icon(Icons.info_outline, size: 16),
        ),
      ],
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}";
  }

  String _getDayOfWeek() {
    final now = DateTime.now();
    final days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return days[now.weekday - 1];
  }
}