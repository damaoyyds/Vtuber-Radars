import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../components/org_chip.dart';
import '../components/clip_item_card.dart';
import '../models/search_result.dart';
import '../models/organization.dart';
import '../services/search_api.dart';
import '../theme/app_theme.dart';

class SearchScreenWithState extends StatefulWidget {
  final Map<String, bool> selectedOrgs;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateChanged;

  const SearchScreenWithState({
    super.key,
    required this.selectedOrgs,
    required this.startDate,
    required this.endDate,
    required this.onDateChanged,
  });

  @override
  State<SearchScreenWithState> createState() => _SearchScreenWithStateState();
}

class _SearchScreenWithStateState extends State<SearchScreenWithState> {
  final TextEditingController _newKeywordController = TextEditingController();
  List<String> _keywords = [];
  final Map<String, bool> _localSelectedOrgs = {};
  DateTime? _localStartDate;
  DateTime? _localEndDate;
  SearchResult? _searchResult;
  bool _isLoading = false;
  String? _errorMessage;

  void _addKeyword() {
    String keyword = _newKeywordController.text.trim();
    if (keyword.isNotEmpty && !_keywords.contains(keyword)) {
      setState(() {
        _keywords.add(keyword);
        _newKeywordController.clear();
      });
    }
  }

  void _removeKeyword(String keyword) {
    setState(() {
      _keywords.remove(keyword);
    });
  }

  @override
  void initState() {
    super.initState();
    _syncWithParent();
  }

  void _syncWithParent() {
    _localSelectedOrgs.clear();
    widget.selectedOrgs.forEach((key, value) {
      _localSelectedOrgs[key] = value;
    });
    _localStartDate = widget.startDate;
    _localEndDate = widget.endDate;
  }

  Future<void> _showDatePicker({required bool isStart}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_localStartDate ?? DateTime.now()) : (_localEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _localStartDate = picked;
        } else {
          _localEndDate = picked;
        }
      });
      widget.onDateChanged(_localStartDate, _localEndDate);
    }
  }

  void _setTimeRange(int days) {
    setState(() {
      _localEndDate = DateTime.now();
      _localStartDate = DateTime.now().subtract(Duration(days: days));
    });
    widget.onDateChanged(_localStartDate, _localEndDate);
  }

  Future<void> _onSearch() async {
    List<String> searchKeywords = List.from(_keywords);
    
    if (searchKeywords.isEmpty) {
      String inputText = _newKeywordController.text.trim();
      if (inputText.isNotEmpty) {
        searchKeywords.add(inputText);
        _keywords.add(inputText);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请至少添加一个搜索关键词')),
        );
        return;
      }
    }

    List<String> selectedOrgIds = _localSelectedOrgs.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedOrgIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个组织')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResult = null;
    });

    try {
      String startDate = _localStartDate?.toIso8601String().split('T')[0] ?? '';
      String endDate = _localEndDate?.toIso8601String().split('T')[0] ?? '';

      List<ClipItem> allItems = [];
      
      for (String keyword in searchKeywords) {
        SearchResult result = await SearchApi.fetchSearchResults(
          keyword,
          selectedOrgIds,
          startDate: startDate,
          endDate: endDate,
        );
        allItems.addAll(result.items);
      }

      allItems.sort((a, b) => b.datetime.compareTo(a.datetime));

      setState(() {
        _searchResult = SearchResult(
          items: allItems,
          pagination: Pagination(page: 1, totalPages: 1, total: allItems.length),
        );
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '搜索',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '搜索你关注的 VTuber',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: _keywords.map((keyword) => Chip(
                  label: Text(keyword),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeKeyword(keyword),
                )).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newKeywordController,
                      decoration: InputDecoration(
                        hintText: '输入关键词后按回车添加',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onSubmitted: (_) => _addKeyword(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(borderRadius),
                        onTap: _addKeyword,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Text(
                            '添加',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择组织:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    bool allSelected = _localSelectedOrgs.values.every((selected) => selected);
                    _localSelectedOrgs.updateAll((key, value) => !allSelected);
                  });
                },
                child: const Text(
                  '全选',
                  style: TextStyle(color: primaryColor, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OrgChipGrid(
            organizations: organizations,
            selectedOrgs: _localSelectedOrgs,
            onOrgSelected: (key, selected) {
              setState(() {
                _localSelectedOrgs[key] = selected;
              });
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _setTimeRange(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardBg,
                    foregroundColor: textPrimary,
                    side: BorderSide(color: cardBorder, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                  child: const Text('前一天'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _setTimeRange(7),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardBg,
                    foregroundColor: textPrimary,
                    side: BorderSide(color: cardBorder, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                  child: const Text('前七天'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _setTimeRange(30),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardBg,
                    foregroundColor: textPrimary,
                    side: BorderSide(color: cardBorder, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                  child: const Text('前三十天'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: cardDecoration,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: InkWell(
                    onTap: () => _showDatePicker(isStart: true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '起始日期',
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _localStartDate != null
                              ? "${_localStartDate!.year}.${_localStartDate!.month}.${_localStartDate!.day}"
                              : '选择日期',
                          style: const TextStyle(color: textPrimary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: cardDecoration,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: InkWell(
                    onTap: () => _showDatePicker(isStart: false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '结束日期',
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _localEndDate != null
                              ? "${_localEndDate!.year}.${_localEndDate!.month}.${_localEndDate!.day}"
                              : '选择日期',
                          style: const TextStyle(color: textPrimary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: gradientButtonDecoration,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '搜索',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_searchResult != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '搜索结果: ${_searchResult!.items.length} 条',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._searchResult!.items.map((item) {
                  return ClipItemCard(item: item);
                }),
              ],
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
