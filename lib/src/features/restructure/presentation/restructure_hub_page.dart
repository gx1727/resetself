import 'package:flutter/material.dart';

import '../../../core/widgets/app_page_scaffold.dart';

class RestructureHubPage extends StatelessWidget {
  const RestructureHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: '重构模块',
      subtitle: '这里会继续扩展上午/日间/夜晚分步解锁、自动保存和软校验逻辑。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _InfoTile(
            title: '上午阶段',
            description: '反愿景、厌恶旧轨道、建立切换意愿。',
          ),
          SizedBox(height: 12),
          _InfoTile(
            title: '日间阶段',
            description: '挖掘底层恐惧、限制性信念与旧脚本。',
          ),
          SizedBox(height: 12),
          _InfoTile(
            title: '夜晚阶段',
            description: '沉淀新身份叙事，绑定最小行动并准备次日校准。',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}
