import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const methodSourceUrl = 'https://x.com/thedankoe/status/2010751592346030461';

Future<void> showMethodNote(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('关于这套方法', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text(
            '基于 Dan Koe 的文章 How to fix your entire life in 1 day。晨间探索想改变的生活，日间用实际行为核对解释，晚间整理方向；之后在行动中观察结果并调整。\n\n原文建议留出一整天、使用纸笔并自主思考。ResetSelf 提供数字记录，也允许跨日继续。最小启动行动、周回顾和专注工具是产品适配或扩展。\n\n问题是探索的邀请，你的解释可以继续核对，身份和方向可以随实践调整。这套流程不保证对每个人产生同样效果。',
          ),
          const SizedBox(height: 16),
          const SelectableText(methodSourceUrl),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: methodSourceUrl),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('来源链接已复制')));
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('复制原文链接'),
          ),
        ],
      ),
    ),
  ),
);
