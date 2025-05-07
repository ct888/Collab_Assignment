import 'package:flutter/material.dart';
import '../model/diary_entry.dart';
import '../viewmodel/diaryDraft.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../view/diary_draft.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seek_here/Model/appimages.dart';

class DiaryDraftScreen extends StatelessWidget {
  final String currentUserId;

  const DiaryDraftScreen({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiaryDraftViewModel(currentUserId: currentUserId),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: WillPopScope(
            onWillPop: () async => true,
            child: _DiaryDraftContent(),
          ),
        ),
      ),
    );
  }
}

class _DiaryDraftContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 60,
            left: -2,
            child: SvgPicture.asset(AppImages.bgCloud), // 添加背景图
          ),
          Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildDraftsList()),
              _buildActionButtons(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ), // Normal padding for the whole Row
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                // Only adjust the "Drafts" text padding here
                padding: const EdgeInsets.only(
                  top: 50,
                ), // This moves the "Drafts" text down
                child: Text(
                  'Drafts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ),
          ),
          Consumer<DiaryDraftViewModel>(
            builder: (context, viewModel, _) {
              return TextButton(
                onPressed: viewModel.toggleSelectionMode,
                child: Text(
                  viewModel.isSelectionMode ? 'Cancel' : 'Select',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsList() {
    return Consumer<DiaryDraftViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (viewModel.entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No drafts available',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: viewModel.entries.length,
          itemBuilder: (context, index) {
            return _buildDraftCard(
              context,
              viewModel.entries[index],
              viewModel,
            );
          },
        );
      },
    );
  }

  Widget _buildDraftCard(
    BuildContext context,
    DiaryEntry draft,
    DiaryDraftViewModel viewModel,
  ) {
    bool isSelected = viewModel.selectedDrafts.contains(draft.id);

    String dayName = DateFormat('EEE').format(draft.date);
    String dayNum = draft.date.day.toString();
    String? imageUrl = draft.imageUrl?.split(',').first;

    return GestureDetector(
      onTap: () {
        viewModel.toggleDraftSelection(draft.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFE0E7FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayName.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      dayNum,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  draft.content,
                  style: TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade300,
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<DiaryDraftViewModel>(
      builder: (context, viewModel, child) {
        bool hasSelection = viewModel.selectedDrafts.isNotEmpty;
        bool singleSelection = viewModel.selectedDrafts.length == 1;

        Color editColor =
            singleSelection
                ? const Color(0xFFB2A4FF)
                : Colors.grey.withOpacity(0.3);
        Color deleteColor =
            hasSelection
                ? const Color(0xFFF87171)
                : Colors.grey.withOpacity(0.3);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          singleSelection
                              ? () => viewModel.editSelectedDraft(context)
                              : null,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Draft'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: editColor,
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
                          hasSelection
                              ? () async {
                                bool confirmed = await showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text("Delete Drafts"),
                                        content: const Text(
                                          "Are you sure you want to delete the selected drafts?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirmed) {
                                  try {
                                    // 显示加载中对话框
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    );

                                    // 执行删除（无返回值）
                                    await viewModel.deleteSelectedDrafts();

                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Draft(s) deleted successfully.",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    // 关闭加载框
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Failed to delete draft(s): ${e.toString()}",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                              : null,

                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Drafts'),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      hasSelection
                          ? () async {
                            bool confirmed = await showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text("Upload Drafts"),
                                    content: const Text(
                                      "Are you sure you want to upload the selected drafts?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: const Text(
                                          "Upload",
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirmed) {
                              viewModel.uploadSelectedDrafts();
                            }
                          }
                          : null,
                  icon: const Icon(Icons.share),
                  label: const Text("Share"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.shade100,
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
        );
      },
    );
  }
}
