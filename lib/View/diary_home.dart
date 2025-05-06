import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/diary_home_viewmodel.dart';
import '../model/diary_entry.dart';
import 'dairy_write_screen.dart';
import 'diaryDetail.dart';
import '../viewmodel/diaryDetai_viewmodel.dart';

class DiaryHomeScreen extends StatelessWidget {
  final String currentUserId;

  const DiaryHomeScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiaryHomeViewModel(currentUserId: currentUserId),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _DiaryHomeContent(),
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
                Text('Error: ${viewModel.errorMessage}', style: const TextStyle(color: Colors.red)),
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

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSearchField(context),
                    _buildVisibilityToggle(context),
                    entriesByMonth.isEmpty
                        ? _buildEmptyState()
                        : _buildEntriesList(context, entriesByMonth),
                    // Added padding at bottom to prevent FAB overlap
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildFAB(context),
      ],
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
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                // Open drawer or navigation menu
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'My Diary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: IconButton(
              icon: Icon(Icons.edit_note_outlined, color: Colors.black),
              onPressed: () {
                // Navigate to drafts screen
                // You'll need to implement the navigation based on your app's structure
                // Navigator.of(context).push(MaterialPageRoute(builder: (context) => DiaryDraftScreen(currentUserId: Provider.of<DiaryHomeViewModel>(context, listen: false).currentUserId ?? '')));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (query) {
          Provider.of<DiaryHomeViewModel>(context, listen: false).searchEntries(query);
        },
        decoration: InputDecoration(
          hintText: 'Search diary entries...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          const Text('Filter by visibility:'),
          DropdownButton<int>(
            value: viewModel.filterOption,
            onChanged: (value) {
              if (value != null) {
                viewModel.setFilterOption(value);
              }
            },
            items: const [
              DropdownMenuItem<int>(
                value: 0,
                child: Text('Show All'),
              ),
              DropdownMenuItem<int>(
                value: 1,
                child: Text('Public Entries'),
              ),
              DropdownMenuItem<int>(
                value: 2,
                child: Text('Private Entries'),
              ),
            ],
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
      backgroundColor: Color(0xFFB2A4FF),
      onPressed: () async {
        final currentUserId = Provider.of<DiaryHomeViewModel>(context, listen: false).currentUserId ?? '';
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryWriteScreen(currentUserId: currentUserId),
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

  Widget _buildEntriesList(BuildContext context, Map<String, List<DiaryEntry>> entriesByMonth) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      color: Colors.deepPurpleAccent.shade100,
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
    // Fix weekday calculation - weekday is 1-7 in Dart where 1 is Monday
    final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

    String? firstImageUrl;
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      firstImageUrl = entry.imageUrl!.split(',')[0];
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => DiaryDetailViewModel(),
                child: DiaryDetailScreen(entry: entry),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            // Fixed flex overflow by constraining the row
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("${date.day}/${date.month}"),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.content,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.publicVisibility) 
                      const Row(
                        children: [
                          Icon(Icons.public, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Public', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                  ],
                ),
              ),
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
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.broken_image, size: 60),
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