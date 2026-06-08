import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';
import '../models/organization.dart';
import '../models/search_result.dart';
import '../models/radar_config.dart';
import '../services/search_api.dart';
import '../services/radar_storage.dart';
import '../components/org_chip.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _newKeywordController = TextEditingController();
  List<String> _keywords = [];
  final Map<String, bool> _selectedOrgs = {};
  DateTime? _startDate;
  DateTime? _endDate;
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
    organizations.forEach((key, value) {
      _selectedOrgs[key] = false;
    });
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
  }

  Future<void> _showDatePicker({required bool isStart}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _onSearch() async {
    if (_keywords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个搜索关键词')),
      );
      return;
    }

    List<String> selectedOrgIds = _selectedOrgs.entries
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
      String startDate = _startDate?.toIso8601String().split('T')[0] ?? '';
      String endDate = _endDate?.toIso8601String().split('T')[0] ?? '';

      List<ClipItem> allItems = [];
      
      for (String keyword in _keywords) {
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

  Future<void> _saveRadarConfig() async {
    List<String> selectedOrgIds = _selectedOrgs.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (_keywords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个搜索关键词')),
      );
      return;
    }

    if (selectedOrgIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个组织')),
      );
      return;
    }

    TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('保存雷达'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '雷达名称',
              hintText: '请输入雷达名称',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                String name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入雷达名称')),
                  );
                  return;
                }

                final config = RadarConfig(
                  id: const Uuid().v4(),
                  name: name,
                  keywords: _keywords,
                  selectedOrgIds: selectedOrgIds,
                  startDate: _startDate,
                  endDate: _endDate,
                  createdAt: DateTime.now(),
                );

                await RadarStorage.saveRadarConfig(config);
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('雷达保存成功')),
                );
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHighlightedText(String text, String pinyin, String keywordsStr) {
    List<TextSpan> spans = [];
    String remaining = text;

    if (pinyin.isNotEmpty) {
      int index = remaining.indexOf(pinyin);
      if (index != -1) {
        if (index > 0) {
          spans.add(TextSpan(text: remaining.substring(0, index)));
        }
        spans.add(TextSpan(
          text: pinyin,
          style: const TextStyle(color: Colors.red),
        ));
        remaining = remaining.substring(index + pinyin.length);
      }
    }

    List<String> keywords = keywordsStr.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
    
    for (String keyword in keywords) {
      if (keyword.isNotEmpty && remaining.contains(keyword)) {
        int index = remaining.indexOf(keyword);
        if (index != -1) {
          if (index > 0) {
            spans.add(TextSpan(text: remaining.substring(0, index)));
          }
          spans.add(TextSpan(
            text: keyword,
            style: const TextStyle(color: Colors.blue),
          ));
          remaining = remaining.substring(index + keyword.length);
        }
      }
    }

    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining));
    }

    return Text.rich(TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vtuber 搜索工具'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '搜索关键词',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _keywords.map((keyword) => Chip(
                    label: Text(keyword),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => _removeKeyword(keyword),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newKeywordController,
                        decoration: const InputDecoration(
                          hintText: '输入关键词后按回车添加',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addKeyword(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addKeyword,
                      child: const Text('添加'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '选择组织',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            OrgChipGrid(
              organizations: organizations,
              selectedOrgs: _selectedOrgs,
              onOrgSelected: (key, selected) {
                setState(() {
                  _selectedOrgs[key] = selected;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showDatePicker(isStart: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '起始日期',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_startDate != null
                              ? "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}"
                              : '选择日期'),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _showDatePicker(isStart: false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '结束日期',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_endDate != null
                              ? "${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}"
                              : '选择日期'),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onSearch,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('搜索'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveRadarConfig,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('保存雷达'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!),
              ),
            if (_searchResult != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '搜索结果: 共 ${_searchResult!.items.length} 条数据',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  ..._searchResult!.items.asMap().entries.map((entry) {
                    int index = entry.key;
                    ClipItem item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '【${index + 1}】${item.title}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (item.orgName.isNotEmpty)
                              Text('组织: ${item.orgName}'),
                            Text('作者: ${item.author.name}'),
                            Text('时间: ${item.datetime}'),
                            Text('视频ID: ${item.id}'),
                            if (item.bilibiliUrl.isNotEmpty)
                              InkWell(
                                onTap: () => _launchUrl(item.bilibiliUrl),
                                child: Text(
                                  '链接: ${item.bilibiliUrl}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            if (item.subtitles.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    '匹配的字幕 (${item.subtitles.length}条):',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  ...item.subtitles.map((subtitle) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '[${subtitle.formatTime(subtitle.start)} ~ ${subtitle.formatTime(subtitle.end)}]',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                          _buildHighlightedText(
                                            subtitle.cleanContent,
                                            subtitle.pinyin,
                                            _keywords.join(','),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_searchResult!.pagination.total > 0)
                    Column(
                      children: [
                        const Divider(),
                        Text(
                          '分页信息: 第${_searchResult!.pagination.page}页 / 共${_searchResult!.pagination.totalPages}页',
                        ),
                        Text('总数据量: ${_searchResult!.pagination.total}条'),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}