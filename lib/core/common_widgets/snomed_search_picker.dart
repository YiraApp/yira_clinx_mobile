import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import '../../features/data/models/snomed/snomed_concept_model.dart';
import '../../features/domain/repositories/snomed/snomed_repository.dart';

class SnomedSearchPicker extends StatefulWidget {
  final String label;
  final String hintText;
  final String? initialValue;
  final String? initialConceptId;
  final String snomedType; // 'finding', 'disorder', 'drug', 'procedure', 'allergy'
  final Function(String term, String? conceptId) onSelected;
  final bool isRequired;

  const SnomedSearchPicker({
    super.key,
    required this.label,
    required this.hintText,
    this.initialValue,
    this.initialConceptId,
    required this.snomedType,
    required this.onSelected,
    this.isRequired = false,
  });

  @override
  State<SnomedSearchPicker> createState() => _SnomedSearchPickerState();
}

class _SnomedSearchPickerState extends State<SnomedSearchPicker> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant SnomedSearchPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullScreenSearch() async {
    final result = await Navigator.of(context).push<SnomedConceptModel>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _SnomedFullScreenSearch(
          title: widget.label,
          snomedType: widget.snomedType,
          initialQuery: _controller.text,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _controller.text = result.term;
      });
      widget.onSelected(result.term, result.conceptId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.search_rounded, color: theme.primaryColor, size: 16),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            if (widget.isRequired)
              const Text(' *',
                  style: TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _openFullScreenSearch,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? darkModeCardColor : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 18,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _controller.text.isNotEmpty
                        ? _controller.text
                        : widget.hintText,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      color: _controller.text.isNotEmpty
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 12,
                            color: Colors.green.shade600),
                        const SizedBox(width: 3),
                        Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade600,
                            fontFamily: appPoppinFont,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Full-screen SNOMED search page
// ─────────────────────────────────────────────────────────────
class _SnomedFullScreenSearch extends StatefulWidget {
  final String title;
  final String snomedType;
  final String initialQuery;

  const _SnomedFullScreenSearch({
    required this.title,
    required this.snomedType,
    required this.initialQuery,
  });

  @override
  State<_SnomedFullScreenSearch> createState() =>
      _SnomedFullScreenSearchState();
}

class _SnomedFullScreenSearchState extends State<_SnomedFullScreenSearch> {
  final TextEditingController _searchController = TextEditingController();
  final SnomedRepository _snomedRepo = sl<SnomedRepository>();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  List<SnomedConceptModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.trim().isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
    // Auto-focus the search field after page animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel('disposed');
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    _cancelToken?.cancel('new_search_started');
    _cancelToken = CancelToken();
    final currentToken = _cancelToken;

    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final concepts = await _snomedRepo.searchConcepts(
      term: query,
      type: widget.snomedType,
      limit: 25,
      cancelToken: currentToken,
    );

    if (mounted && currentToken == _cancelToken) {
      setState(() {
        _results = concepts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1117) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1D27) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search (e.g. Paracetamol, Headache)...',
                hintStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.primaryColor,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            size: 18, color: Colors.grey.shade500),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Use custom text banner ──
          if (_searchController.text.trim().isNotEmpty && !_isLoading)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: InkWell(
                onTap: () {
                  Navigator.pop(
                    context,
                    SnomedConceptModel(
                      conceptId: '',
                      term: _searchController.text.trim(),
                      fsn: _searchController.text.trim(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add_rounded,
                            color: theme.primaryColor, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add as custom entry',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '"${_searchController.text.trim()}"',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: theme.primaryColor),
                    ],
                  ),
                ),
              ),
            ),

          // ── Results / States ──
          Expanded(
            child: _isLoading
                ? const _SnomedSearchShimmer()
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _hasSearched
                                    ? Icons.search_off_rounded
                                    : Icons.medication_liquid_rounded,
                                size: 56,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _hasSearched
                                    ? 'No results found'
                                    : 'Start typing to search',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _hasSearched
                                    ? 'Try a different search term or use the custom entry above'
                                    : 'Search clinical terms, medications, or conditions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return _ResultTile(
                            item: item,
                            isDark: isDark,
                            theme: theme,
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Individual result tile ──
class _ResultTile extends StatelessWidget {
  final SnomedConceptModel item;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ResultTile({
    required this.item,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D27) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.medical_information_outlined,
                    color: theme.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.term,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.semanticTag != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.semanticTag!,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 20,
                  color: theme.primaryColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Multi-Select SNOMED Search Picker Widget
// ─────────────────────────────────────────────────────────────
class SnomedMultiSearchPicker extends StatefulWidget {
  final String label;
  final String hintText;
  final String? initialValue; // Comma-separated initial values
  final String snomedType; // 'finding', 'disorder', etc.
  final Function(List<String> selectedTerms) onSelected;
  final bool isRequired;

  const SnomedMultiSearchPicker({
    super.key,
    required this.label,
    required this.hintText,
    this.initialValue,
    required this.snomedType,
    required this.onSelected,
    this.isRequired = false,
  });

  @override
  State<SnomedMultiSearchPicker> createState() => _SnomedMultiSearchPickerState();
}

class _SnomedMultiSearchPickerState extends State<SnomedMultiSearchPicker> {
  List<String> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _parseInitialValue();
  }

  @override
  void didUpdateWidget(covariant SnomedMultiSearchPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _parseInitialValue();
    }
  }

  void _parseInitialValue() {
    if (widget.initialValue != null && widget.initialValue!.trim().isNotEmpty) {
      _selectedItems = widget.initialValue!
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      _selectedItems = [];
    }
  }

  void _removeItem(String item) {
    setState(() {
      _selectedItems.remove(item);
    });
    widget.onSelected(_selectedItems);
  }

  void _openFullScreenMultiSearch() async {
    final List<String>? results = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _SnomedMultiFullScreenSearch(
          title: widget.label,
          snomedType: widget.snomedType,
          initialSelectedItems: List.from(_selectedItems),
        ),
      ),
    );

    if (results != null) {
      setState(() {
        _selectedItems = results;
      });
      widget.onSelected(_selectedItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.checklist_rounded, color: theme.primaryColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (widget.isRequired)
                  const Text(' *', style: TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ),
            if (_selectedItems.isNotEmpty)
              Text(
                '${_selectedItems.length} selected',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Display selected chips if any
        if (_selectedItems.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedItems.map((item) {
              return Chip(
                backgroundColor: theme.primaryColor.withValues(alpha: isDark ? 0.18 : 0.08),
                side: BorderSide(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                label: Text(
                  item,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                deleteIcon: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                onDeleted: () => _removeItem(item),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Trigger Button to open multi-select search modal
        InkWell(
          onTap: _openFullScreenMultiSearch,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? darkModeCardColor : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 18,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedItems.isEmpty
                        ? widget.hintText
                        : "Tap to add/edit ${widget.label.toLowerCase()}...",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      color: _selectedItems.isEmpty
                          ? Colors.grey.shade400
                          : theme.primaryColor,
                      fontWeight: _selectedItems.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Full-screen Multi-Select SNOMED Search Page
// ─────────────────────────────────────────────────────────────
class _SnomedMultiFullScreenSearch extends StatefulWidget {
  final String title;
  final String snomedType;
  final List<String> initialSelectedItems;

  const _SnomedMultiFullScreenSearch({
    required this.title,
    required this.snomedType,
    required this.initialSelectedItems,
  });

  @override
  State<_SnomedMultiFullScreenSearch> createState() =>
      _SnomedMultiFullScreenSearchState();
}

class _SnomedMultiFullScreenSearchState
    extends State<_SnomedMultiFullScreenSearch> {
  final TextEditingController _searchController = TextEditingController();
  final SnomedRepository _snomedRepo = sl<SnomedRepository>();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  late Set<String> _selectedSet;
  List<SnomedConceptModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _selectedSet = Set<String>.from(widget.initialSelectedItems);
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel('disposed');
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    _cancelToken?.cancel('new_search_started');
    _cancelToken = CancelToken();
    final currentToken = _cancelToken;

    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final concepts = await _snomedRepo.searchConcepts(
      term: query,
      type: widget.snomedType,
      limit: 30,
      cancelToken: currentToken,
    );

    if (mounted && currentToken == _cancelToken) {
      setState(() {
        _results = concepts;
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String term) {
    setState(() {
      if (_selectedSet.contains(term)) {
        _selectedSet.remove(term);
      } else {
        _selectedSet.add(term);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1117) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1D27) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context, _selectedSet.toList()),
        ),
        title: Text(
          "Select ${widget.title}",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()} (SNOMED CT)...',
                hintStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.primaryColor,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            size: 18, color: Colors.grey.shade500),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Currently Selected Items Bar
          if (_selectedSet.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark
                  ? const Color(0xFF161922)
                  : theme.primaryColor.withValues(alpha: 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected (${_selectedSet.length}):',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSet.clear();
                          });
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _selectedSet.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Chip(
                            backgroundColor: theme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 0),
                            label: Text(
                              item,
                              style: const TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            onDeleted: () => _toggleSelection(item),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          // Custom entry option if typed text isn't selected
          if (_searchController.text.trim().isNotEmpty && !_isLoading)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: InkWell(
                onTap: () {
                  final text = _searchController.text.trim();
                  _toggleSelection(text);
                  _searchController.clear();
                  _performSearch('');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          color: theme.primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add custom: "${_searchController.text.trim()}"',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Search Results / Empty State
          Expanded(
            child: _isLoading
                ? const _SnomedSearchShimmer()
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.manage_search_rounded,
                                size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Type to search ${widget.title.toLowerCase()}',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              'No matching terms found',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _results.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _results[index];
                              final isSelected = _selectedSet.contains(item.term);

                              return ListTile(
                                onTap: () => _toggleSelection(item.term),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tileColor: isSelected
                                    ? theme.primaryColor.withValues(alpha: 0.08)
                                    : null,
                                leading: Icon(
                                  isSelected
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  color: isSelected
                                      ? theme.primaryColor
                                      : (isDark
                                          ? Colors.white38
                                          : Colors.grey.shade400),
                                ),
                                title: Text(
                                  item.term,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                subtitle: item.semanticTag != null
                                    ? Text(
                                        item.semanticTag!,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
          ),

          // Bottom Action Bar: Done / Apply Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D27) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, _selectedSet.toList());
                  },
                  child: Text(
                    _selectedSet.isEmpty
                        ? 'Done'
                        : 'Apply Selection (${_selectedSet.length})',
                    style: const TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnomedSearchShimmer extends StatelessWidget {
  final int count;
  const _SnomedSearchShimmer({this.count = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1D27) : Colors.white;

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
            ),
          ),
          child: BaseShimmer(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 160, height: 12, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 10, color: Colors.white),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
