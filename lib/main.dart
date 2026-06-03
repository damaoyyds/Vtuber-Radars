import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import './theme/app_theme.dart';
import './components/bottom_navigation.dart';
import './components/add_radar_card.dart';
import './components/radar_card.dart';
import './models/radar_config.dart';
import './models/organization.dart';
import './models/search_result.dart';
import './services/search_api.dart';
import './services/radar_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vtuber Radar',
      theme: appTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final TextEditingController _keywordController = TextEditingController();
  final Map<String, bool> _selectedOrgs = {};
  DateTime? _startDate;
  DateTime? _endDate;
  List<RadarConfig> _radarConfigs = [];

  @override
  void initState() {
    super.initState();
    organizations.forEach((key, value) {
      _selectedOrgs[key] = false;
    });
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _loadRadarConfigs();
  }

  Future<void> _loadRadarConfigs() async {
    final configs = await RadarStorage.getRadarConfigs();
    setState(() {
      _radarConfigs = configs;
    });
  }

  void _onApplyRadar(RadarConfig config) {
    setState(() {
      _keywordController.text = config.keyword;
      _startDate = config.startDate;
      _endDate = config.endDate;
      _selectedOrgs.updateAll((key, value) => config.selectedOrgIds.contains(key));
      _selectedIndex = 1;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _loadRadarConfigs();
    }
  }

  Future<void> _deleteRadar(String id) async {
    await RadarStorage.deleteRadarConfig(id);
    await _loadRadarConfigs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: _buildPage(),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildRadarPage();
      case 1:
        return SearchScreenWithState(
          keywordController: _keywordController,
          selectedOrgs: _selectedOrgs,
          startDate: _startDate,
          endDate: _endDate,
          onDateChanged: (start, end) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
          },
          onSaveRadar: () {
            _showSaveRadarDialog();
          },
        );
      case 2:
        return _buildProfilePage();
      default:
        return _buildRadarPage();
    }
  }

  Widget _buildRadarPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Text(
            '我的雷达',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '追踪你关注的 VTuber 动态',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ..._radarConfigs.map((radar) {
            return RadarCard(
              radar: radar,
              isLive: radar.name.contains('1'),
              viewerCount: 2300,
              onTap: () => _onApplyRadar(radar),
              onDelete: () => _deleteRadar(radar.id),
            );
          }),
          AddRadarCard(
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
              'https://neeko-copilot.bytedance.net/api/text_to_image?prompt=anime%20girl%20avatar%20cute%20purple%20hair&image_size=square',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vtuber 爱好者',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '追踪 12 位 VTuber',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    StatItem(value: '12', label: '雷达数量'),
                    StatItem(value: '58', label: '已追踪'),
                    StatItem(value: '3', label: '正在直播'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                SettingItem(icon: Icons.notifications, label: '通知设置'),
                SettingItem(icon: Icons.privacy_tip, label: '隐私设置'),
                SettingItem(icon: Icons.help, label: '帮助与反馈'),
                SettingItem(icon: Icons.info, label: '关于我们'),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showSaveRadarDialog() {
    String keyword = _keywordController.text.trim();
    List<String> selectedOrgIds = _selectedOrgs.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入搜索关键词')),
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
                  keyword: keyword,
                  selectedOrgIds: selectedOrgIds,
                  startDate: _startDate,
                  endDate: _endDate,
                  createdAt: DateTime.now(),
                );

                await RadarStorage.saveRadarConfig(config);
                await _loadRadarConfigs();

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
}

class StatItem extends StatelessWidget {
  final String value;
  final String label;

  const StatItem({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

class SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const SettingItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: textTertiary),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: textPrimary,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: textTertiary),
        ],
      ),
    );
  }
}

class SearchScreenWithState extends StatefulWidget {
  final TextEditingController keywordController;
  final Map<String, bool> selectedOrgs;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateChanged;
  final VoidCallback onSaveRadar;

  const SearchScreenWithState({
    super.key,
    required this.keywordController,
    required this.selectedOrgs,
    required this.startDate,
    required this.endDate,
    required this.onDateChanged,
    required this.onSaveRadar,
  });

  @override
  State<SearchScreenWithState> createState() => _SearchScreenWithStateState();
}

class _SearchScreenWithStateState extends State<SearchScreenWithState> {
  final TextEditingController _localKeywordController = TextEditingController();
  final Map<String, bool> _localSelectedOrgs = {};
  DateTime? _localStartDate;
  DateTime? _localEndDate;
  SearchResult? _searchResult;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _syncWithParent();
  }

  void _syncWithParent() {
    _localKeywordController.text = widget.keywordController.text;
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

  Future<void> _onSearch() async {
    String keyword = _localKeywordController.text.trim();

    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入搜索关键词')),
      );
      return;
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

      SearchResult result = await SearchApi.fetchSearchResults(
        keyword,
        selectedOrgIds,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _searchResult = result;
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
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接: $url')),
        );
      }
    }
  }

  Widget _buildHighlightedText(String text, String pinyin, String keyword) {
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

    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining));
    }

    return Text.rich(TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Text(
            '发现',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '搜索你关注的 VTuber',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: cardDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _localKeywordController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '输入关键词搜索',
                suffixIcon: Icon(Icons.search, color: textTertiary),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '选择组织:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: organizations.entries.map((entry) {
              return FilterChip(
                label: Text(entry.value.name),
                selected: _localSelectedOrgs[entry.key] ?? false,
                onSelected: (selected) {
                  setState(() {
                    _localSelectedOrgs[entry.key] = selected;
                  });
                },
                backgroundColor: cardBg,
                selectedColor: primaryColor.withOpacity(0.1),
                selectedShadowColor: Colors.transparent,
                shadowColor: Colors.transparent,
                labelStyle: TextStyle(
                  color: _localSelectedOrgs[entry.key] ?? false ? primaryColor : textSecondary,
                ),
                side: BorderSide(
                  color: _localSelectedOrgs[entry.key] ?? false ? primaryColor : cardBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: cardDecoration,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: InkWell(
                    onTap: () => _showDatePicker(isStart: true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '起始日期',
                          style: TextStyle(color: textSecondary),
                        ),
                        Text(
                          _localStartDate != null
                              ? "${_localStartDate!.year}-${_localStartDate!.month.toString().padLeft(2, '0')}-${_localStartDate!.day.toString().padLeft(2, '0')}"
                              : '选择日期',
                          style: const TextStyle(color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: cardDecoration,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: InkWell(
                    onTap: () => _showDatePicker(isStart: false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '结束日期',
                          style: TextStyle(color: textSecondary),
                        ),
                        Text(
                          _localEndDate != null
                              ? "${_localEndDate!.year}-${_localEndDate!.month.toString().padLeft(2, '0')}-${_localEndDate!.day.toString().padLeft(2, '0')}"
                              : '选择日期',
                          style: const TextStyle(color: textPrimary),
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
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: cardDecoration,
            child: ElevatedButton(
              onPressed: widget.onSaveRadar,
              style: ElevatedButton.styleFrom(
                backgroundColor: cardBg,
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text(
                '保存为雷达',
                style: TextStyle(fontSize: 16),
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
                ..._searchResult!.items.asMap().entries.map((entry) {
                  int index = entry.key;
                  ClipItem item = entry.value;
                  return Container(
                    decoration: cardDecoration,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '【${index + 1}】${item.title}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '作者: ${item.author.name}',
                              style: const TextStyle(color: textSecondary),
                            ),
                            const SizedBox(width: 16),
                            if (item.orgName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.orgName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '时间: ${item.datetime}',
                          style: const TextStyle(color: textSecondary),
                        ),
                        if (item.bilibiliUrl.isNotEmpty)
                          InkWell(
                            onTap: () => _launchUrl(item.bilibiliUrl),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                item.bilibiliUrl,
                                style: const TextStyle(
                                  color: primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        if (item.subtitles.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                '匹配的字幕:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...item.subtitles.map((subtitle) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '[${subtitle.formatTime(subtitle.start)} ~ ${subtitle.formatTime(subtitle.end)}]',
                                        style: const TextStyle(color: textTertiary),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildHighlightedText(
                                        subtitle.cleanContent,
                                        subtitle.pinyin,
                                        _localKeywordController.text.trim(),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}