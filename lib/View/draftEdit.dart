import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/confirmation_dialog.dart';
import '../view/utils/wave_painter.dart';
import '../model/diary_entry.dart';
import '../service/database_service.dart';
import '../ViewModel/diaryDraftEdit_viewmodel.dart';

class DiaryDraftEditScreen extends StatelessWidget {
  final DiaryEntry draft;

  const DiaryDraftEditScreen({Key? key, required this.draft}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiaryDraftEditViewModel(),
      child: DiaryDraftEditView(draft: draft),
    );
  }
}

class DiaryDraftEditView extends StatefulWidget {
  final DiaryEntry draft;

  const DiaryDraftEditView({Key? key, required this.draft}) : super(key: key);

  @override
  State<DiaryDraftEditView> createState() => _DiaryDraftEditViewState();
}

class _DiaryDraftEditViewState extends State<DiaryDraftEditView> {
  late TextEditingController _contentController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DiaryDraftEditViewModel>(context);

    // Initialize data on first build
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.draft.id != null) {
          viewModel.loadDraftById(widget.draft.id!);
          _contentController.text = widget.draft.content ?? '';
          viewModel.setVisibility(widget.draft.publicVisibility ?? false);
          viewModel.setDataTracking(widget.draft.dataTracking ?? false);
        }
        
        setState(() {
          _isInitialized = true;
        });
      });
    }

    if (viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        viewModel.clearMessages();
      });
    }

    if (viewModel.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        viewModel.clearMessages();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      body: SafeArea(
        child: Stack(
          children: [
            // 背景波浪
            CustomPaint(size: Size.infinite, painter: WavePainter()),
            
            // 主内容
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.only(top: 34.0),
                          child: Text(
                            "Edit Draft",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Diary Card (草稿编辑卡)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 360,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85), // 半透明玻璃感
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 日期
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
                                    Text(
                                      _getDayOfWeek(),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              "Edit your diary entry:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Diary 输入框
                            TextField(
                              controller: _contentController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: "Start editing your diary here...",
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              onChanged: viewModel.updateContent, // 更新内容
                            ),
                            const SizedBox(height: 20),

                            _buildSwitchRow(
                              label: "Public Visibility",
                              value: viewModel.publicVisibility,
                              onChanged: viewModel.setVisibility,
                            ),
                            _buildSwitchRow(
                              label: "Allow Data Tracking",
                              value: viewModel.dataTracking,
                              onChanged: viewModel.setDataTracking,
                            ),
                            const SizedBox(height: 12),
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
                              (viewModel.isSaving) ? null : () async {
                                await showConfirmationDialog(
                                  context: context,
                                  title: "Cancel Edit",
                                  icon: Icons.cancel,
                                  message: "Are you sure you want to cancel editing? Unsaved changes will be lost.",
                                  onConfirm: () {
                                    Navigator.of(context).pop(); // 取消编辑
                                  },
                                );
                              },
                          icon: viewModel.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black54,
                                  ),
                                )
                              : const Icon(Icons.cancel),
                          label: const Text("Cancel"),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (viewModel.isSaving) ? null : () async {
                                // 更新草稿内容
                                viewModel.updateContent(_contentController.text);
                                // 保存草稿
                                final result = await viewModel.saveDraft();
                                if (result) {
                                  Navigator.of(context).pop(true); // 保存成功后返回，并传递true表示更新成功
                                }
                              },
                          icon: viewModel.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black54,
                                  ),
                                )
                              : const Icon(Icons.save_alt),
                          label: const Text("Save Draft"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 161, 162, 245),
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