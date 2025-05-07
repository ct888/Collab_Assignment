import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/diary_home_viewmodel.dart';
import '../model/diary_entry.dart';
import 'dairy_write_screen.dart';
import 'diaryDetail.dart';
import '../viewmodel/diaryDetai_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seek_here/Model/appimages.dart';

class DiaryHomeScreen extends StatelessWidget {
  final String currentUserId;

  const DiaryHomeScreen({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiaryHomeViewModel(currentUserId: currentUserId),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: WillPopScope(
            onWillPop: () async {
              // Handle back button press to keep top navigation intact.
              return true; // Allow pop
            },
            child: _DiaryHomeContent(),
          ),
        ),
      ),
    );
  }
}

class _DiaryHomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DiaryHomeViewModel>(context);

    if (viewModel.isLoading) {
      return Stack(
        children: [
          const Center(child: CircularProgressIndicator()),
          _buildFAB(context),
        ],
      );
    }

    if (viewModel.errorMessage.isNotEmpty) {
      return Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${viewModel.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadEntries(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          _buildFAB(context),
        ],
      );
    }

    if (viewModel.currentUserId == null) {
      return Stack(
        children: [
          const Center(child: Text('Please log in to view your diary entries')),
          _buildFAB(context),
        ],
      );
    }

    final entriesByMonth = viewModel.getEntriesByMonth();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: -2,
              child: SvgPicture.asset(AppImages.bgCloud),
            ),

            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  _buildSearchField(context),
                  _buildVisibilityToggle(context),
                  entriesByMonth.isEmpty
                      ? _buildEmptyState()
                      : Expanded(
                        child: SingleChildScrollView(
                          child: _buildEntriesList(context, entriesByMonth),
                        ),
                      ),
                  const SizedBox(height: 80),
                ],
              ),
            ),

            _buildFAB(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          onChanged: (query) {
            Provider.of<DiaryHomeViewModel>(
              context,
              listen: false,
            ).searchEntries(query);
          },
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search diary...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: const Icon(Icons.search, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 16,
            ),
          ),
        ),
      ),
    );
  }
Widget _buildVisibilityToggle(BuildContext context) {
  final viewModel = Provider.of<DiaryHomeViewModel>(context);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Filter by visibility:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.51), // "almost" transparent
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: viewModel.filterOption,
              onChanged: (value) {
                if (value != null) {
                  viewModel.setFilterOption(value);
                }
              },
              items: const [
                DropdownMenuItem<int>(
                  value: 0,
                  child: Text(
                    'Show All',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 1,
                  child: Text(
                    'Public Entries',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 2,
                  child: Text(
                    'Private Entries',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              icon: const Icon(
                Icons.arrow_drop_down,
                size: 24,
                color: Color.fromARGB(255, 100, 130, 250),
              ),
              style: const TextStyle(fontSize: 13, color: Colors.black),
            ),
          ),
        ),
      ],
    ),
  );
}





  Widget _buildFAB(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 72, 87, 247).withOpacity(0.7),
        onPressed: () async {
          final currentUserId =
              Provider.of<DiaryHomeViewModel>(
                context,
                listen: false,
              ).currentUserId ??
              '';
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DiaryWriteScreen(currentUserId: currentUserId),
            ),
          );
          Provider.of<DiaryHomeViewModel>(context, listen: false).loadEntries();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.book, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No diary entries yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to create your first entry',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(
    BuildContext context,
    Map<String, List<DiaryEntry>> entriesByMonth,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entriesByMonth.length,
      itemBuilder: (context, index) {
        final month = entriesByMonth.keys.elementAt(index);
        final entries = entriesByMonth[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(month),
            ...entries.map((e) => _diaryCard(context, e)),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
      color: const Color.fromARGB(255, 160, 168, 250).withOpacity(0.7),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _diaryCard(BuildContext context, DiaryEntry entry) {
    final date = entry.date;
    final day =
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

    String? firstImageUrl;
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      firstImageUrl = entry.imageUrl!.split(',')[0];
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 6, // Slightly elevated for depth
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color.fromARGB(255, 240, 240, 245), // Soft background color
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final shouldReload = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryDetailScreen(entry: entry),
            ),
          );

          if (shouldReload == true) {
            await Provider.of<DiaryHomeViewModel>(
              context,
              listen: false,
            ).loadEntries();
          }
        },
       child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Date column
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(day, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${date.day}/${date.month}"),
                ],
              ),
              SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.content,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.publicVisibility)
                      Row(
                        children: [
                          Icon(Icons.public, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'Public',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Image thumbnail if available
              if (firstImageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      firstImageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
