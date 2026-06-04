import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';
import './theme/app_theme.dart';
import './components/bottom_navigation.dart';
import './components/add_radar_card.dart';
import './components/radar_card.dart';
import './models/radar_config.dart';
import './models/schedule_time.dart';
import './models/organization.dart';
import './models/search_result.dart';
import './models/message.dart';
import './services/search_api.dart';
import './services/radar_storage.dart';
import './services/data_store_service.dart';
import './services/message_storage.dart';
import './screens/chat_detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
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
  String _cacheSize = '0 KB';

  @override
  void initState() {
    super.initState();
    organizations.forEach((key, value) {
      _selectedOrgs[key] = false;
    });
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _initApp();
  }

  Future<void> _initApp() async {
    await _loadMessages();
    await _loadRadarConfigs();
    await _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await DataStoreService.getCacheSize();
    setState(() {
      _cacheSize = size;
    });
  }

  Future<void> _loadMessages() async {
    final messages = await MessageStorage.loadMessages();
    setState(() {
      _messages = messages;
    });
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
        // 检查每个预定时间点
        for (var scheduleTime in radar.scheduleTimes) {
          // 计算今天的预定搜索时间
          final todayScheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            scheduleTime.hour,
            scheduleTime.minute,
          );

          // 检查是否已经执行过今天这个时间点的自动搜索
          final alreadyRanToday = lastDate.year == now.year &&
              lastDate.month == now.month &&
              lastDate.day == now.day;

          // 检查当前时间是否已过设定时间，且今天还未执行过，且距离上次执行已经超过1小时（避免重复执行）
          bool shouldRun = !alreadyRanToday && 
              now.isAfter(todayScheduledTime) &&
              now.difference(todayScheduledTime).inMinutes >= 1;

          if (shouldRun) {
            // 执行搜索
            _searchWithRadar(radar);

            // 更新最后执行时间
            await RadarStorage.setLastAutoSearchTime(now);
            break;
          }
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.message,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '暂无消息',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '快去创建雷达或进行搜索吧',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 0;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('创建雷达'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(color: primaryColor),
                        ),
                        child: const Text('立即搜索'),
                      ),
                    ],
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
    
    RadarConfig? radar = _radarConfigs.firstWhere(
      (r) => r.name == radarName,
      orElse: () => RadarConfig(
        id: '',
        name: radarName,
        keyword: '',
        selectedOrgIds: [],
        createdAt: DateTime.now(),
      ),
    );
    
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                radarName: radarName,
                messages: List.from(messages),
                onDeleteMessage: (messageId) => _deleteMessage(messageId),
                onClearAll: () => _deleteMessagesByRadarName(radarName),
              ),
            ),
          );
      },
      onLongPress: () => _showDeleteConversationDialog(radarName),
      child: Container(
        decoration: cardDecoration,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: radar.avatarPath != null && radar.id.isNotEmpty
                  ? FileImage(File(radar.avatarPath!))
                  : null,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: radar.avatarPath == null || radar.id.isEmpty
                  ? const Icon(Icons.radar, color: primaryColor, size: 24)
                  : null,
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
                      fontSize: 13,
                      color: textSecondary,
                    ),
                    maxLines: 2,
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

  void _showDeleteConversationDialog(String radarName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除会话'),
          content: Text('确定要删除 \"$radarName\" 的所有消息吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteMessagesByRadarName(radarName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('消息删除成功')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    setState(() {
      _messages.removeWhere((msg) => msg.id == messageId);
    });
    await MessageStorage.removeMessage(messageId);
  }

  Future<void> _deleteMessagesByRadarName(String radarName) async {
    setState(() {
      _messages.removeWhere((msg) => msg.radarName == radarName);
    });
    await MessageStorage.removeMessagesByRadarName(radarName);
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          title: Text('搜索中'),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在搜索，请稍候...'),
            ],
          ),
        );
      },
    );

    try {
      String? startDateStr = radar.startDate?.toIso8601String().split('T')[0];
      String? endDateStr = radar.endDate?.toIso8601String().split('T')[0];

      SearchResult result = await SearchApi.fetchSearchResults(
        radar.keyword,
        radar.selectedOrgIds,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      List<ClipItem> newItems = await DataStoreService.findNewItems(radar.id, result.items);
      await DataStoreService.addItemsToStore(radar.id, newItems);

      Navigator.pop(context);

      List<Message> newMessages = [];
      if (newItems.isEmpty) {
        newMessages.add(Message(
          id: const Uuid().v4(),
          radarName: radar.name,
          timestamp: DateTime.now(),
          type: MessageType.searchComplete,
          text: '搜索完成，没有新数据',
        ));
      } else {
        Set<String> authorNames = newItems.map((item) => item.author.name).toSet();
        String authorsText = authorNames.join('、');
        
        newMessages.add(Message(
          id: const Uuid().v4(),
          radarName: radar.name,
          timestamp: DateTime.now(),
          type: MessageType.searchComplete,
          text: '$authorsText 提到了 ${radar.keyword}',
        ));
        for (var item in newItems) {
          newMessages.add(Message(
            id: const Uuid().v4(),
            radarName: radar.name,
            timestamp: DateTime.now(),
            type: MessageType.searchComplete,
            clipItem: item,
            keyword: radar.keyword,
          ));
        }
      }

      setState(() {
        _messages.insertAll(0, newMessages);
      });
      await MessageStorage.saveMessages(_messages);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('搜索完成'),
            content: Text('搜索完成，搜索到 ${newItems.length} 条数据，请前往消息页面查看'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
                child: const Text('前往消息页面'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      Navigator.pop(context);

      final errorMsg = Message(
        id: const Uuid().v4(),
        radarName: radar.name,
        timestamp: DateTime.now(),
        type: MessageType.searchError,
        text: '搜索失败: $e',
      );

      setState(() {
        _messages.insert(0, errorMsg);
      });
      await MessageStorage.saveMessages(_messages);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('搜索失败'),
            content: Text('搜索失败: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
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
                  children: [
                    StatItem(value: _radarConfigs.length.toString(), label: '雷达数量'),
                    StatItem(value: organizations.length.toString(), label: '已追踪'),
                    StatItem(value: '0', label: '正在直播'),
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
              children: [
                const Text(
                  '设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SettingItem(icon: Icons.notifications, label: '通知设置'),
                SettingItem(icon: Icons.privacy_tip, label: '隐私设置'),
                SettingItem(
                  icon: Icons.delete_sweep,
                  label: '清空缓存',
                  trailing: _cacheSize,
                  onTap: _showClearCacheDialog,
                ),
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

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认清空缓存'),
          content: const Text('清空缓存后，所有已存储的视频数据将被删除，下次搜索时会重新获取数据。确定要继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await DataStoreService.clearAllDataStores();
                Navigator.pop(context);
                await _loadCacheSize();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('缓存已清空')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateRadarDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _CreateRadarDialog(
          onSave: (name, keyword, orgIds, startDate, endDate, isAutoSearch, scheduleTimes, avatarPath) async {
            final config = RadarConfig(
              id: const Uuid().v4(),
              name: name,
              keyword: keyword,
              selectedOrgIds: orgIds,
              startDate: startDate,
              endDate: endDate,
              createdAt: DateTime.now(),
              isAutoSearch: isAutoSearch,
              scheduleTimes: scheduleTimes,
              avatarPath: avatarPath,
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
          onSave: (name, keyword, orgIds, startDate, endDate, isAutoSearch, scheduleTimes, avatarPath) async {
            final updatedConfig = RadarConfig(
              id: radar.id,
              name: name,
              keyword: keyword,
              selectedOrgIds: orgIds,
              startDate: startDate,
              endDate: endDate,
              createdAt: radar.createdAt,
              isAutoSearch: isAutoSearch,
              scheduleTimes: scheduleTimes,
              isAutoSearchEnabled: radar.isAutoSearchEnabled,
              avatarPath: avatarPath,
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
  final Function(String, String, List<String>, DateTime, DateTime, bool, List<ScheduleTime>, String?) onSave;
  final RadarConfig? radar;

  const _CreateRadarDialog({
    super.key,
    required this.onSave,
    this.radar,
  });

  @override
  State<_CreateRadarDialog> createState() => _CreateRadarDialogState();
}

// 辅助类，用于跟踪每个时间点的状态
class _TimePointState {
  int hour;
  int minute;

  _TimePointState({
    required this.hour,
    required this.minute,
  });
}

class _CreateRadarDialogState extends State<_CreateRadarDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  final Map<String, bool> _selectedOrgs = {};
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isAutoSearch;
  List<_TimePointState> _timePoints = [];
  String? _avatarPath;

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
      _avatarPath = widget.radar!.avatarPath;
      _timePoints = widget.radar!.scheduleTimes.map((time) => _TimePointState(
        hour: time.hour,
        minute: time.minute,
      )).toList();
      for (var orgId in widget.radar!.selectedOrgIds) {
        _selectedOrgs[orgId] = true;
      }
    } else {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _isAutoSearch = false;
      _timePoints = [_TimePointState(
        hour: 9,
        minute: 0,
      )];
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = '${widget.radar?.id ?? const Uuid().v4()}_avatar.jpg';
        final String targetPath = '${appDir.path}/$fileName';
        
        final File newFile = await File(pickedFile.path).copy(targetPath);
        
        setState(() {
          _avatarPath = newFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  void _removeAvatar() {
    if (_avatarPath != null) {
      File(_avatarPath!).delete();
    }
    setState(() {
      _avatarPath = null;
    });
  }

  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择头像'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAvatar(ImageSource.gallery);
                },
              ),
              if (_avatarPath != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('删除头像'),
                  textColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _removeAvatar();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _addScheduleTime() {
    setState(() {
      if (_timePoints.length < 10) {
        _timePoints.add(_TimePointState(
          hour: 9,
          minute: 0,
        ));
      }
    });
  }

  void _removeScheduleTime(int index) {
    setState(() {
      if (_timePoints.length > 1) {
        _timePoints.removeAt(index);
      }
    });
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

    // 将 _timePoints 转换为 ScheduleTime 列表
    List<ScheduleTime> scheduleTimes = _timePoints.map((tp) => ScheduleTime(
      hour: tp.hour,
      minute: tp.minute,
    )).toList();

    widget.onSave(name, keyword, selectedOrgIds, _startDate, _endDate, _isAutoSearch, scheduleTimes, _avatarPath);
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
            Center(
              child: GestureDetector(
                onTap: _showAvatarPicker,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _avatarPath != null
                          ? FileImage(File(_avatarPath!))
                          : const NetworkImage(
                              'https://neeko-copilot.bytedance.net/api/text_to_image?prompt=anime%20girl%20avatar%20cute%20blue%20hair&image_size=square',
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击头像上传或修改',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
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
                  ..._timePoints.asMap().entries.map((entry) {
                    int index = entry.key;
                    _TimePointState timePoint = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: timePoint.hour.toString().padLeft(2, '0'),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '时',
                              ),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              onChanged: (value) {
                                int? hour = int.tryParse(value);
                                if (hour != null && hour >= 0 && hour <= 23) {
                                  setState(() {
                                    timePoint.hour = hour;
                                  });
                                }
                              },
                            ),
                          ),
                          const Text(':', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Expanded(
                            child: TextFormField(
                              initialValue: timePoint.minute.toString().padLeft(2, '0'),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '分',
                              ),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              onChanged: (value) {
                                int? minute = int.tryParse(value);
                                if (minute != null && minute >= 0 && minute <= 59) {
                                  setState(() {
                                    timePoint.minute = minute;
                                  });
                                }
                              },
                            ),
                          ),
                          if (_timePoints.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                              onPressed: () => _removeScheduleTime(index),
                              iconSize: 20,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  if (_timePoints.length < 10)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addScheduleTime,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('添加时间点'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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
  final String? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const SettingItem({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: textTertiary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: textPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ),
            if (showArrow)
              const Icon(Icons.arrow_forward_ios, color: textTertiary),
          ],
        ),
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
          TextField(
            controller: _localKeywordController,
            decoration: InputDecoration(
              hintText: '输入关键词搜索',
              suffixIcon: const Icon(Icons.search, color: textTertiary),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
            onSubmitted: (_) => _onSearch(),
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