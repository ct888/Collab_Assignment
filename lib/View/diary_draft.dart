import 'package:flutter/material.dart';
import '../model/diary_entry.dart';
import '../viewmodel/diaryDraft.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DiaryDraftScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiaryDraftViewModel(),
      child: _DiaryDraftContent(),
    );
  }
}

class _DiaryDraftContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildDraftsList()),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              child: Text(
                'Drafts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
            return _buildDraftCard(context, viewModel.entries[index], viewModel);
          },
        );
      },
    );
  }

  Widget _buildDraftCard(BuildContext context, DiaryEntry draft, DiaryDraftViewModel viewModel) {
    bool isSelected = viewModel.selectedDrafts.contains(draft.id);

    String dayName = DateFormat('EEE').format(draft.date);
    String dayNum = draft.date.day.toString();
    String? imageUrl = draft.imageUrl?.split(',').first;

    return GestureDetector(
      onTap: () {
        if (viewModel.isSelectionMode) {
          viewModel.toggleDraftSelection(draft.id);
        } else {
        //  viewModel.clearSelection();
          viewModel.toggleDraftSelection(draft.id);
        }       
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
                    Text(dayName.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(dayNum, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

        Color editColor = singleSelection ? Color(0xFFB2A4FF) : Colors.grey.withOpacity(0.3);
        Color deleteColor = hasSelection ? Color(0xFFF87171) : Colors.grey.withOpacity(0.3);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: singleSelection
                          ? () => viewModel.editSelectedDraft(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: editColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hasSelection
                          ? () => viewModel.deleteSelectedDrafts()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deleteColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasSelection
                      ? () => viewModel.uploadSelectedDrafts()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deleteColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Upload', style: TextStyle(color: Colors.white)),
                    ],
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
