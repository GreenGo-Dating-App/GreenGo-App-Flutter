import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/chat_ideas_sheet.dart';

void main() {
  for (final name in ['icebreakers', 'sentences']) {
    test('every $name category has its own icon (no shared, no fallback)', () {
      final items = jsonDecode(File('assets/chat_datasets/$name.json').readAsStringSync()) as List;
      final topics = {for (final i in items) (i as Map)['p'] as String};
      final icons = [for (final t in topics) chatTopicIcon(t)];
      expect(icons.toSet().length, topics.length);
      expect(icons, isNot(contains(Icons.chat_bubble_outline)));
    });
  }
}
