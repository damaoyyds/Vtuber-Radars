import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/radar_config.dart';
import '../models/schedule_time.dart';
import '../models/organization.dart';
import '../services/radar_storage.dart';
import '../theme/app_theme.dart';
import '../components/org_chip.dart';

class CreateRadarPage extends StatefulWidget {
  final RadarConfig? radar;

  const CreateRadarPage({
    super.key,
    this.radar,
  });

  @override
  State<CreateRadarPage> createState() => _CreateRadarPageState();
}

class _TimePointState {
  int hour;
  int minute;

  _TimePointState({
    required this.hour,
    required this.minute,
  });
}

class _CreateRadarPageState extends State<CreateRadarPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _newKeywordController = TextEditingController();
  List<String> _keywords = [];
  final Map<String, bool> _selectedOrgs = {};
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isAutoSearch;
  List<_TimePointState> _timePoints = [];
  String? _avatarPath;
  late TimeRangeType _timeRangeType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    organizations.forEach((key, value) {
      _selectedOrgs[key] = false;
    });

    if (widget.radar != null) {
      _nameController.text = widget.radar!.name;
      _keywords = List.from(widget.radar!.keywords);
      _startDate = widget.radar!.startDate ?? DateTime.now().subtract(const Duration(days: 30));
      _endDate = widget.radar!.endDate ?? DateTime.now();
      _isAutoSearch = widget.radar!.isAutoSearch;
      _avatarPath = widget.radar!.avatarPath;
      _timeRangeType = widget.radar!.timeRangeType;
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
      _timeRangeType = TimeRangeType.custom;
      _timePoints = [_TimePointState(
        hour: 9,
        minute: 0,
      )];
    }
  }

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

  void _selectTimeRange(TimeRangeType type) {
    setState(() {
      _timeRangeType = type;
      final now = DateTime.now();
      switch (type) {
        case TimeRangeType.lastDay:
          _startDate = now.subtract(const Duration(days: 1));
          _endDate = now;
          break;
        case TimeRangeType.lastThreeDays:
          _startDate = now.subtract(const Duration(days: 3));
          _endDate = now;
          break;
        case TimeRangeType.lastSevenDays:
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case TimeRangeType.lastMonth:
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
          break;
        case TimeRangeType.custom:
          break;
      }
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

  Future<void> _handleSave() async {
    String name = _nameController.text.trim();
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

    setState(() {
      _isSaving = true;
    });

    List<ScheduleTime> scheduleTimes = _timePoints.map((tp) => ScheduleTime(
      hour: tp.hour,
      minute: tp.minute,
    )).toList();

    RadarConfig config;
    if (widget.radar != null) {
      config = RadarConfig(
        id: widget.radar!.id,
        name: name,
        keywords: _keywords,
        selectedOrgIds: selectedOrgIds,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: widget.radar!.createdAt,
        isAutoSearch: _isAutoSearch,
        scheduleTimes: scheduleTimes,
        isAutoSearchEnabled: widget.radar!.isAutoSearchEnabled,
        avatarPath: _avatarPath,
        timeRangeType: _timeRangeType,
      );
    } else {
      config = RadarConfig(
        id: const Uuid().v4(),
        name: name,
        keywords: _keywords,
        selectedOrgIds: selectedOrgIds,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: DateTime.now(),
        isAutoSearch: _isAutoSearch,
        scheduleTimes: scheduleTimes,
        avatarPath: _avatarPath,
        timeRangeType: _timeRangeType,
      );
    }

    await RadarStorage.saveRadarConfig(config);

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.radar != null ? '雷达修改成功' : '雷达创建成功')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.radar != null ? '编辑雷达' : '新建雷达'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              '头像',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: InkWell(
                onTap: _showAvatarPicker,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardBg,
                    border: Border.all(color: cardBorder, width: 1),
                  ),
                  child: _avatarPath != null
                      ? ClipOval(
                    child: Image.file(
                      File(_avatarPath!),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(
                    Icons.add_a_photo,
                    color: textSecondary,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '雷达名称',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '请输入雷达名称',
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(color: cardBorder, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '搜索关键词',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newKeywordController,
                    decoration: InputDecoration(
                      hintText: '输入关键词后按回车添加',
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _addKeyword(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addKeyword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                  child: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择组织',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      bool allSelected = _selectedOrgs.values.every((selected) => selected);
                      _selectedOrgs.updateAll((key, value) => !allSelected);
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
              selectedOrgs: _selectedOrgs,
              onOrgSelected: (key, selected) {
                setState(() {
                  _selectedOrgs[key] = selected;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '时间范围',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectTimeRange(TimeRangeType.lastDay),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _timeRangeType == TimeRangeType.lastDay ? primaryColor : cardBg,
                      foregroundColor: _timeRangeType == TimeRangeType.lastDay ? Colors.white : textPrimary,
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
                    onPressed: () => _selectTimeRange(TimeRangeType.lastSevenDays),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _timeRangeType == TimeRangeType.lastSevenDays ? primaryColor : cardBg,
                      foregroundColor: _timeRangeType == TimeRangeType.lastSevenDays ? Colors.white : textPrimary,
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
                    onPressed: () => _selectTimeRange(TimeRangeType.lastMonth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _timeRangeType == TimeRangeType.lastMonth ? primaryColor : cardBg,
                      foregroundColor: _timeRangeType == TimeRangeType.lastMonth ? Colors.white : textPrimary,
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
                  child: InkWell(
                    onTap: () => _showDatePicker(isStart: true),
                    child: Container(
                      decoration: cardDecoration,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '起始日期',
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${_startDate.year}.${_startDate.month}.${_startDate.day}",
                            style: const TextStyle(color: textPrimary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _showDatePicker(isStart: false),
                    child: Container(
                      decoration: cardDecoration,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '结束日期',
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${_endDate.year}.${_endDate.month}.${_endDate.day}",
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
            Row(
              children: [
                const Text(
                  '自动搜索',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isAutoSearch,
                  onChanged: (value) {
                    setState(() {
                      _isAutoSearch = value;
                    });
                  },
                  activeColor: primaryColor,
                ),
              ],
            ),
            if (_isAutoSearch) ...[
              const SizedBox(height: 12),
              const Text(
                '搜索时间',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ..._timePoints.asMap().entries.map((entry) {
                int index = entry.key;
                _TimePointState timePoint = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: cardDecoration,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Center(
                                child: DropdownButton<int>(
                                  value: timePoint.hour,
                                  items: List.generate(24, (i) => i).map((hour) {
                                    return DropdownMenuItem(
                                      value: hour,
                                      child: Text('${hour.toString().padLeft(2, '0')}时'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      timePoint.hour = value!;
                                    });
                                  },
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: cardDecoration,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Center(
                                child: DropdownButton<int>(
                                  value: timePoint.minute,
                                  items: [0, 15, 30, 45].map((minute) {
                                    return DropdownMenuItem(
                                      value: minute,
                                      child: Text('${minute.toString().padLeft(2, '0')}分'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      timePoint.minute = value!;
                                    });
                                  },
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeScheduleTime(index),
                      color: Colors.red,
                    ),
                  ],
                );
              }).toList(),
              const SizedBox(height: 8),
              if (_timePoints.length < 10)
                ElevatedButton(
                  onPressed: _addScheduleTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardBg,
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                  child: const Text('添加时间点'),
                ),
            ],
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: gradientButtonDecoration,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '保存',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}