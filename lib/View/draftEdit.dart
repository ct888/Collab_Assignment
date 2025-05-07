/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/diaryDraftEdit_viewmodel.dart';
import '/widgets/confirmation_dialog.dart';
import '../view/utils/wave_painter.dart';

class DiaryDraftEditScreen extends StatelessWidget {
  final String draftContent; // 接受草稿内容作为参数

  const DiaryDraftEditScreen({super.key, required this.draftContent});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiaryDraftEditViewModel(),
      child: const DiaryDraftEditView(),
    );
  }
}

class DiaryDraftEditView extends StatelessWidget {
  const DiaryDraftEditView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DiaryDraftEditViewModel>(context);

    // 在页面加载时加载草稿内容
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draftContent = ModalRoute.of(context)?.settings.arguments as String?;
      if (draftContent != null) {
        viewModel.loadDraftContent(draftContent); // 加载草稿内容
      }
    });

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
                          icon: Icon(Icons.arrow_back, color: Colors.black),
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
                              controller: TextEditingController(text: viewModel.currentContent),
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

                            // Switch (公开与否)
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
                                await showBeautifulConfirmationDialog(
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
                                await viewModel.saveDraft(); // 保存草稿
                                Navigator.of(context).pop(); // 保存成功后返回
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
*/