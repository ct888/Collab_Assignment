import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/diary_entry.dart';
import '../viewmodel/diaryDetai_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seek_here/Model/appimages.dart';

class DiaryDetailScreen extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create the ViewModel provider at the top level of the widget
    return ChangeNotifierProvider(
      create: (_) => DiaryDetailViewModel(),
      child: _DiaryDetailContent(entry: entry),
    );
  }
}

class _DiaryDetailContent extends StatelessWidget {
  final DiaryEntry entry;

  const _DiaryDetailContent({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = entry.date;
    final dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final dayName = dayNames[date.weekday % 7];
    final formattedDate = "${date.day}/${date.month}/${date.year}";

    List<String> images = [];
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      images = entry.imageUrl!.split(',');
    }

    // Get access to the ViewModel
    final viewModel = Provider.of<DiaryDetailViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 80,
              left: -2,
              child: SvgPicture.asset(AppImages.bgCloud),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            "My Diary",
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
                Expanded(
                  child: Center(
                    child: Container(
                      width: 360,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "$formattedDate  ",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(dayName),
                                      ],
                                    ),
                                    const Icon(Icons.calendar_today, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  entry.content,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (images.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  images.length == 1
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          images.first,
                                          width: 200,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : SizedBox(
                                        height: 200,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: images.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              width: 200,
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  images[index],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                ],
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Icon(
                                      entry.publicVisibility
                                          ? Icons.public
                                          : Icons.lock,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      entry.publicVisibility
                                          ? "Public"
                                          : "Private",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (entry.dataTracking) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.analytics_outlined,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Data tracking enabled",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Text(
                                  "Likes: ${entry.likedUsers.length}",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                if (entry.likedUsers.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        entry.likedUsers.map((uid) {
                                          return Text(
                                            uid,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: -10,
                            right: -15, // 右边再偏一点
                            child: IconButton(
                              iconSize: 32, // 放大图标
                              icon: const Icon(
                                Icons.delete,
                                color: Color.fromARGB(255, 254, 99, 87),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text("Delete Entry"),
                                        content: Text(
                                          "Are you sure you want to delete this diary entry?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              try {
                                                // // Check if entry.id is null or empty
                                                // if (entry.id.isEmpty) {
                                                //   Navigator.pop(context); // Close dialog
                                                //   ScaffoldMessenger.of(context).showSnackBar(
                                                //     SnackBar(
                                                //       content: Text('Cannot delete entry: Invalid entry ID'),
                                                //       backgroundColor: Colors.red,
                                                //     ),
                                                //   );
                                                //   return;
                                                // }

                                                print(
                                                  "Attempting to delete diary entry with ID: ${entry.id}",
                                                );

                                                // Show loading indicator
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (
                                                    BuildContext context,
                                                  ) {
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  },
                                                );

                                                // Delete the entry
                                                await viewModel.deleteEntry(
                                                  entry,
                                                );

                                                // Close loading indicator
                                                Navigator.pop(context);

                                                // Close delete confirmation dialog
                                                Navigator.pop(context);

                                                // Return to the previous screen
                                                Navigator.pop(context, true);

                                                // Show success message
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Entry deleted successfully',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              } catch (e) {
                                                print(
                                                  "Error deleting entry: ${e.toString()}",
                                                );

                                                // Close loading indicator if it's showing
                                                Navigator.pop(context);

                                                // Close delete confirmation dialog
                                                Navigator.pop(context);

                                                // Show error message
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to delete entry: ${e.toString()}',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text("Delete"),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
