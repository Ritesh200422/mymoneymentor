import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TrendingNews extends StatefulWidget {
  const TrendingNews({super.key});

  @override
  _TrendingNewsState createState() => _TrendingNewsState();
}

class _TrendingNewsState extends State<TrendingNews> {
  List articles = [];
  bool isLoading = true;
  Map<String, bool> isFollowing = {};
  Map<String, int> reactionCounts = {};
  Map<String, bool> isBookmarked = {};

  final String apiKey = '6kDE0e2yqJVriDxBzp66Vyr5kF9QfzEm9bS3WwNU'; // Replace with your API key

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    final url = Uri.parse(
        'https://newsapi.org/v2/top-headlines?country=in&apiKey=74345873716c4a649bdc9269ad4205ed');
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      setState(() {
        articles = data['articles'];
        // Initialize reaction counts and follow status
        for (var article in articles) {
          String key = article['url'] ?? article['title'];
          reactionCounts[key] = reactionCounts[key] ?? 0;
          isFollowing[key] = isFollowing[key] ?? false;
          isBookmarked[key] = isBookmarked[key] ?? false;
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching news: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleReaction(String articleKey) {
    setState(() {
      reactionCounts[articleKey] = (reactionCounts[articleKey] ?? 0) + 1;
    });
  }

  void _toggleFollow(String articleKey) {
    setState(() {
      isFollowing[articleKey] = !(isFollowing[articleKey] ?? false);
    });
  }

  void _toggleBookmark(String articleKey) {
    setState(() {
      isBookmarked[articleKey] = !(isBookmarked[articleKey] ?? false);
    });
  }

  void _shareArticle(Map article) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share Article',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareOption(Icons.send, 'Message', Colors.blue),
                _buildShareOption(Icons.link, 'Copy Link', Colors.green),
                _buildShareOption(Icons.chat, 'Twitter', Colors.blue),
                _buildShareOption(Icons.thumb_up, 'Facebook', Colors.blue),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Trending Tech News'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          final articleKey = article['url'] ?? article['title'];

          return _buildNewsCard(article, articleKey);
        },
      ),
    );
  }

  Widget _buildNewsCard(Map article, String articleKey) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with source info and follow button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Text(
                    article['source']['name']?.toString().substring(0, 1) ?? 'N',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['source']['name'] ?? 'Unknown Source',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${DateTime.now().difference(DateTime.parse(article['publishedAt'] ?? DateTime.now().toString())).inHours}h ago',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleFollow(articleKey),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFollowing[articleKey]! ? Colors.blue : Colors.transparent,
                      border: Border.all(color: Colors.blue, width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFollowing[articleKey]! ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: isFollowing[articleKey]! ? Colors.white : Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Article content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article['title'] ?? 'No Title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (article['description'] != null)
                  Text(
                    article['description']!,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Article image
          if (article['urlToImage'] != null)
            Container(
              margin: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(article['urlToImage']!),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Reactions and actions bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reactions
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleReaction(articleKey),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            color: reactionCounts[articleKey]! > 0 ? Colors.red : Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${reactionCounts[articleKey]}',
                            style: TextStyle(
                              color: reactionCounts[articleKey]! > 0 ? Colors.red : Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        Icon(Icons.comment, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '0',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),

                // Action buttons
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isBookmarked[articleKey]! ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked[articleKey]! ? Colors.blue : Colors.grey[400],
                      ),
                      onPressed: () => _toggleBookmark(articleKey),
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.grey[400]),
                      onPressed: () => _shareArticle(article),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}