import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TrendingNews extends StatefulWidget {
  const TrendingNews({super.key});

  @override
  _TrendingNewsState createState() => _TrendingNewsState();
}

class _TrendingNewsState extends State<TrendingNews> {
  List<dynamic> articles = [];
  bool isLoading = true;
  String errorMessage = '';
  Map<String, bool> isFollowing = {};
  Map<String, int> reactionCounts = {};
  Map<String, bool> isBookmarked = {};
  Map<String, bool> imageLoadError = {}; // Track image load errors

  final String apiKey = '6kDE0e2yqJVriDxBzp66Vyr5kF9QfzEm9bS3WwNU'; // Replace with your API key

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    try {
      final url = Uri.parse(
        'https://api.marketaux.com/v1/news/all?api_token=$apiKey&language=en&countries=in',
      );

      final response = await http.get(url);
      print('API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Safely extract news list from 'data' key
        final List<dynamic> fetchedArticles =
        (data['data'] != null && data['data'] is List)
            ? data['data']
            : [];

        setState(() {
          articles = fetchedArticles;
          errorMessage = '';

          // Initialize reaction counts and follow status
          for (var article in articles) {
            String key = article['url'] ?? article['title'] ?? UniqueKey().toString();
            reactionCounts[key] = reactionCounts[key] ?? 0;
            isFollowing[key] = isFollowing[key] ?? false;
            isBookmarked[key] = isBookmarked[key] ?? false;
            imageLoadError[key] = false; // Initialize image error state
          }

          isLoading = false;
        });
      } else {
        final errorMsg = 'HTTP error: ${response.statusCode} - ${response.reasonPhrase}';
        print('❌ $errorMsg');
        setState(() {
          isLoading = false;
          errorMessage = errorMsg;
        });
      }
    } catch (e) {
      final errorMsg = 'Error fetching news: $e';
      print(errorMsg);
      setState(() {
        isLoading = false;
        errorMessage = errorMsg;
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

  void _handleImageError(String articleKey) {
    setState(() {
      imageLoadError[articleKey] = true;
    });
  }

  void _shareArticle(Map<String, dynamic> article) {
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

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'Failed to load news',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchNews,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          Text(
            'No articles found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
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
            icon: const Icon(Icons.refresh),
            onPressed: fetchNews,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : errorMessage.isNotEmpty
          ? _buildErrorWidget()
          : articles.isEmpty
          ? _buildEmptyWidget()
          : ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          final articleKey = article['url'] ?? article['title'] ?? UniqueKey().toString();
          return _buildNewsCard(article, articleKey);
        },
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article, String articleKey) {
    final sourceName = _getSourceName(article);
    final publishedAt = _getPublishedTime(article);
    final title = article['title'] ?? 'No Title Available';
    final description = article['description'];
    final imageUrl = article['image_url'] ?? article['urlToImage'];
    final hasImageError = imageLoadError[articleKey] ?? false;

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
                    sourceName.isNotEmpty ? sourceName[0].toUpperCase() : 'N',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sourceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        publishedAt,
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
                      color: (isFollowing[articleKey] ?? false) ? Colors.blue : Colors.transparent,
                      border: Border.all(color: Colors.blue, width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (isFollowing[articleKey] ?? false) ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: (isFollowing[articleKey] ?? false) ? Colors.white : Colors.blue,
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
                  title,
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
                if (description != null && description.isNotEmpty)
                  Text(
                    description,
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

          // Article image with error handling
          if (imageUrl != null && imageUrl.isNotEmpty && !hasImageError)
            _buildArticleImage(imageUrl, articleKey),

          if (hasImageError)
            _buildImageErrorPlaceholder(),

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
                            color: (reactionCounts[articleKey] ?? 0) > 0 ? Colors.red : Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${reactionCounts[articleKey] ?? 0}',
                            style: TextStyle(
                              color: (reactionCounts[articleKey] ?? 0) > 0 ? Colors.red : Colors.grey[400],
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
                        (isBookmarked[articleKey] ?? false) ? Icons.bookmark : Icons.bookmark_border,
                        color: (isBookmarked[articleKey] ?? false) ? Colors.blue : Colors.grey[400],
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

  Widget _buildArticleImage(String imageUrl, String articleKey) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleImageError(articleKey);
            });
            return _buildImageErrorPlaceholder();
          },
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey[500], size: 50),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _getSourceName(Map<String, dynamic> article) {
    if (article['source'] is String) {
      return article['source'] ?? 'Unknown Source';
    } else if (article['source'] is Map) {
      return article['source']['name'] ?? 'Unknown Source';
    }
    return 'Unknown Source';
  }

  String _getPublishedTime(Map<String, dynamic> article) {
    try {
      final publishedAt = article['publishedAt'] ?? article['published_at'];
      if (publishedAt != null) {
        final publishedTime = DateTime.parse(publishedAt);
        final now = DateTime.now();
        final difference = now.difference(publishedTime);

        if (difference.inMinutes < 1) {
          return 'Just now';
        } else if (difference.inHours < 1) {
          return '${difference.inMinutes}m ago';
        } else if (difference.inHours < 24) {
          return '${difference.inHours}h ago';
        } else {
          return '${difference.inDays}d ago';
        }
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return 'Unknown time';
  }
}