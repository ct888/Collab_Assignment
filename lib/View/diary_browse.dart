import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/diaryBrowse_viewmodel.dart';
import '../model/diary_entry.dart';
import 'package:intl/intl.dart';

class BrowseView extends StatelessWidget {
  final String currentUserId;

  const BrowseView({Key? key, required this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BrowseViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage.isNotEmpty) {
          return Center(child: Text(viewModel.errorMessage, style: TextStyle(color: Colors.red)));
        }

        final entries = viewModel.publicEntries;

        if (entries.isEmpty) {
          return const Center(child: Text('No public diary entries yet.'));
        }

        return ListView.builder(
          itemCount: entries.length + (viewModel.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < entries.length) {
              final entry = entries[index];
              return _buildDiaryCard(context, entry, viewModel);
            } else {
              viewModel.loadMoreEntries();
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildDiaryCard(BuildContext context, DiaryEntry entry, BrowseViewModel viewModel) {
    final date = entry.date;
    final dayOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7];
    final formattedDate = "${date.day}/${date.month}/${date.year}";
    final formattedTime = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    String? firstImageUrl;
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      firstImageUrl = entry.imageUrl!.split(',')[0];
    }

    // Check if the current user has liked this entry
    final isLiked = entry.likedUsers.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Optional: Navigate to detail page
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and weekday information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$formattedDate ($dayOfWeek) $formattedTime",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    "User: ${entry.userId ?? 'Unknown'}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Content
              Text(
                entry.content,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Image
              if (firstImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    firstImageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8),

              // Like button and like count
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    onPressed: () async {
                      await viewModel.toggleLike(entry, currentUserId);
                    },
                  ),
                  Text('${entry.likes} likes'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
