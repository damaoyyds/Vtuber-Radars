import 'package:flutter/material.dart';
import '../models/radar_config.dart';
import '../models/organization.dart';
import '../services/radar_storage.dart';

class RadarScreen extends StatefulWidget {
  final Function(RadarConfig) onApplyRadar;

  const RadarScreen({super.key, required this.onApplyRadar});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  List<RadarConfig> _radarConfigs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRadarConfigs();
  }

  Future<void> _loadRadarConfigs() async {
    final configs = await RadarStorage.getRadarConfigs();
    setState(() {
      _radarConfigs = configs;
      _isLoading = false;
    });
  }

  Future<void> _deleteRadarConfig(String id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这个雷达吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await RadarStorage.deleteRadarConfig(id);
                await _loadRadarConfigs();
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

  String _getOrgNames(List<String> orgIds) {
    return orgIds.map((id) => organizations[id]?.name ?? id).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的雷达'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _radarConfigs.isEmpty
              ? const Center(
                  child: Text(
                    '暂无雷达配置',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _radarConfigs.length,
                  itemBuilder: (context, index) {
                    final config = _radarConfigs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    config.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteRadarConfig(config.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('关键词: ${config.keywords.join(', ')}'),
                            Text('组织: ${_getOrgNames(config.selectedOrgIds)}'),
                            if (config.startDate != null)
                              Text('起始日期: ${config.startDate!.year}-${config.startDate!.month.toString().padLeft(2, '0')}-${config.startDate!.day.toString().padLeft(2, '0')}'),
                            if (config.endDate != null)
                              Text('结束日期: ${config.endDate!.year}-${config.endDate!.month.toString().padLeft(2, '0')}-${config.endDate!.day.toString().padLeft(2, '0')}'),
                            Text('创建时间: ${config.createdAt.year}-${config.createdAt.month.toString().padLeft(2, '0')}-${config.createdAt.day.toString().padLeft(2, '0')}'),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onApplyRadar(config);
                                  Navigator.pop(context);
                                },
                                child: const Text('应用此雷达'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}