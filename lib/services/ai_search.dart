import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdftron_flutter/pdftron_flutter.dart';


class AiSearchService {
  final BuildContext context;

  AiSearchService({required this.context});

  /// Open AI-powered search dialog
  Future<void> openAiSearch({
    required String filePath,
    String? initialQuery,
  }) async {
    showDialog(
      context: context,
      builder: (context) => AiSearchDialog(
        filePath: filePath,
        initialQuery: initialQuery,
      ),
    );
  }

  /// Perform smart search in the document
  /// This searches with PDFTron and can be enhanced with AI
  Future<List<SearchResult>> searchInDocument({
    required String query,
    bool matchCase = false,
    bool matchWholeWord = false,
  }) async {
    try {
      // Use PDFTron's native search
      await PdftronFlutter.openSearch();

      // In a real implementation, you would:
      // 1. Extract text from PDF
      // 2. Send to AI service (OpenAI, Claude, etc.)
      // 3. Get intelligent results back
      // 4. Display enhanced results

      return [];
    } catch (e) {
      print('Error in AI search: $e');
      return [];
    }
  }

  /// Get search suggestions based on document content
  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    // This would connect to an AI service to get intelligent suggestions
    // For now, return common suggestions
    return [
      'Find sections about $partialQuery',
      'Search for $partialQuery definitions',
      'Show all mentions of $partialQuery',
      'Summarize content about $partialQuery',
    ];
  }

  /// Extract and summarize search results using AI
  Future<String> summarizeResults(List<SearchResult> results) async {
    // This would use AI to create a summary of all search results
    return 'Found ${results.length} results for your query.';
  }
}

/// Search result model
class SearchResult {
  final int pageNumber;
  final String snippet;
  final String context;
  final double relevanceScore;

  SearchResult({
    required this.pageNumber,
    required this.snippet,
    required this.context,
    required this.relevanceScore,
  });
}

/// AI Search Dialog Widget
class AiSearchDialog extends StatefulWidget {
  final String filePath;
  final String? initialQuery;

  const AiSearchDialog({
    Key? key,
    required this.filePath,
    this.initialQuery,
  }) : super(key: key);

  @override
  _AiSearchDialogState createState() => _AiSearchDialogState();
}

class _AiSearchDialogState extends State<AiSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];
  bool _isSearching = false;
  SearchMode _searchMode = SearchMode.smart;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    if (_searchController.text.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      // Close dialog and open PDFTron search
      Navigator.pop(context);
      await PdftronFlutter.openSearch();

      // Future enhancement: Send query to AI service
      // and display intelligent results
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    // Generate smart suggestions
    setState(() {
      _suggestions = [
        'Find all mentions of "$query"',
        'Summarize sections about "$query"',
        'Show context for "$query"',
        'Related topics to "$query"',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Smart Search',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Intelligent document search',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 24.sp),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Search Mode Selector
            Text(
              'Search Mode',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _buildModeChip(
                    SearchMode.smart,
                    'Smart',
                    Icons.auto_awesome,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildModeChip(
                    SearchMode.exact,
                    'Exact',
                    Icons.search,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildModeChip(
                    SearchMode.semantic,
                    'Semantic',
                    Icons.lightbulb_outline,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Search Input
            TextField(
              controller: _searchController,
              onChanged: _updateSuggestions,
              onSubmitted: (_) => _performSearch(),
              autofocus: true,
              style: TextStyle(
                fontSize: 16.sp,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: _getHintText(),
                prefixIcon: Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, size: 20.sp),
                  onPressed: () {
                    _searchController.clear();
                    _updateSuggestions('');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.blue.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Suggestions
            if (_suggestions.isNotEmpty) ...[
              Text(
                'Smart Suggestions',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                constraints: BoxConstraints(maxHeight: 150.h),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        _searchController.text = _suggestions[index];
                        _performSearch();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 10.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 18.sp,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                _suggestions[index],
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14.sp,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.cancel_outlined, size: 20.sp),
                    label: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _performSearch,
                    icon: _isSearching
                        ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Icon(Icons.search, size: 20.sp),
                    label: Text(_isSearching ? 'Searching...' : 'Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
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

  Widget _buildModeChip(SearchMode mode, String label, IconData icon) {
    final bool isSelected = _searchMode == mode;
    return InkWell(
      onTap: () => setState(() => _searchMode = mode),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHintText() {
    switch (_searchMode) {
      case SearchMode.smart:
        return 'Ask anything about the document...';
      case SearchMode.exact:
        return 'Search for exact words...';
      case SearchMode.semantic:
        return 'Describe what you\'re looking for...';
    }
  }
}

/// Search modes for AI search
enum SearchMode {
  /// Smart search with AI assistance
  smart,

  /// Exact text matching
  exact,

  /// Semantic search (meaning-based)
  semantic,
}