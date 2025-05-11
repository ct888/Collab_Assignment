import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/diaryBrowse_viewmodel.dart';
import '../model/diary_entry.dart';
import '../View/browseView.dart';

class BrowseView extends StatelessWidget {
  final String currentUserId;

  const BrowseView({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Consumer<BrowseViewModel>(
      builder: (context, viewModel, child) {
        return Stack(
          children: [
            Positioned(
              top: 40,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF8E97FD).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -40,
              bottom: 70,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF8E97FD).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (viewModel.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (viewModel.errorMessage.isNotEmpty)
              Center(
                child: Text(
                  viewModel.errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (viewModel.publicEntries.isEmpty)
              const Center(child: Text('No public diary entries yet.'))
            else
              ListView.builder(
                itemCount:
                    viewModel.publicEntries.length +
                    (viewModel.hasMore ? 1 : 0),
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                itemBuilder: (context, index) {
                  if (index < viewModel.publicEntries.length) {
                    final entry = viewModel.publicEntries[index];
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
              ),
          ],
        );
      },
    );
  }

  Widget _buildDiaryCard(
    BuildContext context,
    DiaryEntry entry,
    BrowseViewModel viewModel,
  ) {
    final date = entry.date;
    final day =
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    final formattedTime =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    String? firstImageUrl;
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      firstImageUrl = entry.imageUrl!.split(',')[0];
    }

    final isLiked = entry.likedUsers.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color.fromARGB(255, 240, 240, 245),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to DiaryDetailPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryDetailPage(entry: entry),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.content,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                            size: 18,
                          ),
                          onPressed: () async {
                            await viewModel.toggleLike(entry, currentUserId);
                          },
                        ),
                        Text(
                          '${entry.likes} likes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (firstImageUrl != null)
                GestureDetector(
                  onTap: () {
                    _showFullScreenImage(context, firstImageUrl!);
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(left: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(firstImageUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Image.network(imageUrl),
        );
      },
    );
  }
}
