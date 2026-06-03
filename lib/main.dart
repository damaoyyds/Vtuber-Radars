import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';
import './theme/app_theme.dart';
import './components/bottom_navigation.dart';
import './components/add_radar_card.dart';
import './components/radar_card.dart';
import './models/radar_config.dart';
import './models/organization.dart';
import './models/search_result.dart';
import './models/message.dart';
import './services/search_api.dart';
import './services/radar_storage.dart';
import './screens/chat_detail_page.dart';

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
  bool _isSelectMode = false;
  Set<String> _selectedRadarIds = {};
  List<Message> _messages = [];

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
    _checkAndRunAutoSearch();
  }

  Future<void> _checkAndRunAutoSearch() async {
    final now = DateTime.now();
    final lastAutoSearchTime = await RadarStorage.getLastAutoSearchTime();
    final lastDate = lastAutoSearchTime ?? DateTime(2020);

    for (var radar in _radarConfigs) {
      if (radar.isAutoSearch && radar.isAutoSearchEnabled) {
        // 计算今天的预定搜索时间
        final todayScheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          radar.autoSearchHour,
          radar.autoSearchMinute,
        );

        // 检查是否已经执行过今天的自动搜索
        final alreadyRanToday = lastDate.year == now.year &&
            lastDate.month == now.month &&
            lastDate.day == now.day;

        // 如果当前时间已过设定时间，且今天还未执行，则执行搜索
        if (!alreadyRanToday && now.isAfter(todayScheduledTime)) {
          // 执行搜索
          _searchWithRadar(radar);

          // 更新最后执行时间
          await RadarStorage.setLastAutoSearchTime(now);
        }
      }
    }
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
        );
      case 2:
        return _buildMessagePage();
      case 3:
        return _buildProfilePage();
      default:
        return _buildRadarPage();
    }
  }

  Widget _buildMessagePage() {
    Map<String, List<Message>> groupedMessages = {};
    for (var msg in _messages) {
      if (!groupedMessages.containsKey(msg.radarName)) {
        groupedMessages[msg.radarName] = [];
      }
      groupedMessages[msg.radarName]!.add(msg);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 60),
          if (groupedMessages.isEmpty)
            Container(
              decoration: cardDecoration,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              child: const Column(
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: textTertiary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '暂无消息',
                    style: TextStyle(
                      fontSize: 18,
                      color: textTertiary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...groupedMessages.entries.map((entry) {
              String radarName = entry.key;
              List<Message> radarMessages = entry.value;
              Message latestMsg = radarMessages.first;
              
              return _buildConversationItem(radarName, radarMessages, latestMsg);
            }).toList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildConversationItem(String radarName, List<Message> messages, Message latestMsg) {
    int unreadCount = messages.where((m) => m.type != MessageType.searching).length;
    
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                radarName: radarName,
                messages: List.from(messages),
              ),
            ),
          );
      },
      child: Container(
        decoration: cardDecoration,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: const Icon(Icons.radar, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    radarName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    latestMsg.text ?? (latestMsg.clipItem != null ? '搜索到新结果' : ''),
                    style: const TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${latestMsg.timestamp.hour.toString().padLeft(2, '0')}:${latestMsg.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: textTertiary,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  Widget _buildRadarPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '我的雷达',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              if (_radarConfigs.isNotEmpty)
                TextButton(
                  onPressed: _toggleSelectMode,
                  child: Text(
                    _isSelectMode ? '取消' : '编辑',
                    style: const TextStyle(color: primaryColor),
                  ),
                ),
            ],
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
              onTap: () {
                if (_isSelectMode) {
                  _toggleRadarSelection(radar.id);
                } else {
                  _onApplyRadar(radar);
                }
              },
              onDelete: () => _deleteRadar(radar.id),
              onSearch: () => _searchWithRadar(radar),
              onToggleAutoSearch: radar.isAutoSearch ? () => _toggleAutoSearch(radar) : null,
              onDoubleTap: () => _showEditRadarDialog(radar),
              isSelected: _isSelectMode && _selectedRadarIds.contains(radar.id),
              showCheckbox: _isSelectMode,
            );
          }),
          AddRadarCard(
            onTap: () => _showCreateRadarDialog(),
          ),
          if (_isSelectMode && _selectedRadarIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration,
              child: Row(
                children: [
                  Text('已选择 ${_selectedRadarIds.length} 个雷达'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _deleteSelectedRadars,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('删除'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedRadarIds.clear();
      }
    });
  }

  void _toggleRadarSelection(String radarId) {
    setState(() {
      if (_selectedRadarIds.contains(radarId)) {
        _selectedRadarIds.remove(radarId);
      } else {
        _selectedRadarIds.add(radarId);
      }
    });
  }

  Future<void> _deleteSelectedRadars() async {
    if (_selectedRadarIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除选中的 ${_selectedRadarIds.length} 个雷达吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                for (String id in _selectedRadarIds) {
                  await RadarStorage.deleteRadarConfig(id);
                }
                await _loadRadarConfigs();
                setState(() {
                  _isSelectMode = false;
                  _selectedRadarIds.clear();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('雷达删除成功')),
                );
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _searchWithRadar(RadarConfig radar) async {
    setState(() {
      _messages.insert(0, Message(
        id: const Uuid().v4(),
        radarName: radar.name,
        timestamp: DateTime.now(),
        type: MessageType.searching,
        text: '搜索中...',
      ));
    });

    try {
      String? startDateStr = radar.startDate?.toIso8601String().split('T')[0];
      String? endDateStr = radar.endDate?.toIso8601String().split('T')[0];

      SearchResult result = await SearchApi.fetchSearchResults(
        radar.keyword,
        radar.selectedOrgIds,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      setState(() {
        _messages.removeWhere((m) => m.radarName == radar.name && m.type == MessageType.searching);
        _messages.insert(0, Message(
          id: const Uuid().v4(),
          radarName: radar.name,
          timestamp: DateTime.now(),
          type: MessageType.searchComplete,
          text: '搜索完成，找到 ${result.items.length} 条结果',
        ));
        for (var item in result.items) {
          _messages.insert(0, Message(
            id: const Uuid().v4(),
            radarName: radar.name,
            timestamp: DateTime.now(),
            type: MessageType.searchComplete,
            clipItem: item,
          ));
        }
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            radarName: radar.name,
            messages: _messages.where((m) => m.radarName == radar.name).toList(),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _messages.insert(0, Message(
          id: const Uuid().v4(),
          radarName: radar.name,
          timestamp: DateTime.now(),
          type: MessageType.searchError,
          text: '搜索失败: $e',
        ));
      });
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url != null && await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
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

  void _showCreateRadarDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _CreateRadarDialog(
          onSave: (name, keyword, orgIds, startDate, endDate, isAutoSearch, autoHour, autoMinute) async {
            final config = RadarConfig(
              id: const Uuid().v4(),
              name: name,
              keyword: keyword,
              selectedOrgIds: orgIds,
              startDate: startDate,
              endDate: endDate,
              createdAt: DateTime.now(),
              isAutoSearch: isAutoSearch,
              autoSearchHour: autoHour,
              autoSearchMinute: autoMinute,
            );
            await RadarStorage.saveRadarConfig(config);
            await _loadRadarConfigs();
          },
        );
      },
    );
  }

  void _showEditRadarDialog(RadarConfig radar) {
    showDialog(
      context: context,
      builder: (context) {
        return _CreateRadarDialog(
          radar: radar,
          onSave: (name, keyword, orgIds, startDate, endDate, isAutoSearch, autoHour, autoMinute) async {
            final updatedConfig = RadarConfig(
              id: radar.id,
              name: name,
              keyword: keyword,
              selectedOrgIds: orgIds,
              startDate: startDate,
              endDate: endDate,
              createdAt: radar.createdAt,
              isAutoSearch: isAutoSearch,
              autoSearchHour: autoHour,
              autoSearchMinute: autoMinute,
              isAutoSearchEnabled: radar.isAutoSearchEnabled,
            );
            await RadarStorage.saveRadarConfig(updatedConfig);
            await _loadRadarConfigs();
          },
        );
      },
    );
  }

  void _toggleAutoSearch(RadarConfig radar) async {
    final updatedRadar = radar.copyWith(
      isAutoSearchEnabled: !radar.isAutoSearchEnabled,
    );
    await RadarStorage.saveRadarConfig(updatedRadar);
    await _loadRadarConfigs();
  }
}

class _CreateRadarDialog extends StatefulWidget {
  final Function(String, String, List<String>, DateTime, DateTime, bool, int, int) onSave;
  final RadarConfig? radar;

  const _CreateRadarDialog({
    super.key,
    required this.onSave,
    this.radar,
  });

  @override
  State<_CreateRadarDialog> createState() => _CreateRadarDialogState();
}

class _CreateRadarDialogState extends State<_CreateRadarDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  final Map<String, bool> _selectedOrgs = {};
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isAutoSearch;
  late int _autoSearchHour;
  late int _autoSearchMinute;

  @override
  void initState() {
    super.initState();
    organizations.forEach((key, value) {
      _selectedOrgs[key] = false;
    });

    if (widget.radar != null) {
      _nameController.text = widget.radar!.name;
      _keywordController.text = widget.radar!.keyword;
      _startDate = widget.radar!.startDate ?? DateTime.now().subtract(const Duration(days: 30));
      _endDate = widget.radar!.endDate ?? DateTime.now();
      _isAutoSearch = widget.radar!.isAutoSearch;
      _autoSearchHour = widget.radar!.autoSearchHour;
      _autoSearchMinute = widget.radar!.autoSearchMinute;
      for (var orgId in widget.radar!.selectedOrgIds) {
        _selectedOrgs[orgId] = true;
      }
    } else {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _isAutoSearch = false;
      _autoSearchHour = 9;
      _autoSearchMinute = 0;
    }
  }

  Future<void> _showDatePicker({required bool isStart}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
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

  void _handleSave() {
    String name = _nameController.text.trim();
    String keyword = _keywordController.text.trim();
    List<String> selectedOrgIds = _selectedOrgs.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入雷达名称')),
      );
      return;
    }

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

    widget.onSave(name, keyword, selectedOrgIds, _startDate, _endDate, _isAutoSearch, _autoSearchHour, _autoSearchMinute);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.radar != null ? '雷达修改成功' : '雷达创建成功')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.radar != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑雷达' : '新建雷达'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '雷达名称',
                hintText: '请输入雷达名称',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keywordController,
              decoration: const InputDecoration(
                labelText: '搜索关键词',
                hintText: '请输入搜索关键词',
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '选择时间范围:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showDatePicker(isStart: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '开始时间',
                            style: TextStyle(color: textSecondary),
                          ),
                          Text(
                            '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _showDatePicker(isStart: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '结束时间',
                            style: TextStyle(color: textSecondary),
                          ),
                          Text(
                            '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '选择组织:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: organizations.entries.map((entry) {
                return FilterChip(
                  label: Text(entry.value.name),
                  selected: _selectedOrgs[entry.key] ?? false,
                  onSelected: (selected) {
                    setState(() {
                      _selectedOrgs[entry.key] = selected;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '自动搜索',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _isAutoSearch,
                  onChanged: (value) {
                    setState(() {
                      _isAutoSearch = value;
                    });
                  },
                ),
              ],
            ),
            if (_isAutoSearch)
              Column(
                children: [
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '自动搜索时间:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _autoSearchHour,
                          items: List.generate(24, (index) => index).map((hour) {
                            return DropdownMenuItem(
                              value: hour,
                              child: Text('${hour.toString().padLeft(2, '0')} 时'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _autoSearchHour = value ?? 9;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: _autoSearchMinute.toString().padLeft(2, '0'),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '分 (0-59)',
                          ),
                          onChanged: (value) {
                            int? minute = int.tryParse(value);
                            if (minute != null && minute >= 0 && minute <= 59) {
                              _autoSearchMinute = minute;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _handleSave,
          child: Text(isEditing ? '保存' : '创建'),
        ),
      ],
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

  const SearchScreenWithState({
    super.key,
    required this.keywordController,
    required this.selectedOrgs,
    required this.startDate,
    required this.endDate,
    required this.onDateChanged,
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