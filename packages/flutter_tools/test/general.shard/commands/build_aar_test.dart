// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/aar.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_aar.dart';
import 'package:flutter_tools/src/reporting/usage.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  Cache.disableLocking();

  group('getUsage', () {
    Directory tempDir;
    AarBuilder mockAarBuilder;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      mockAarBuilder = MockAarBuilder();
      when(mockAarBuilder.build(
          project: anyNamed('project'),
          androidBuildInfo: anyNamed('androidBuildInfo'),
          target: anyNamed('target'),
          outputDir: anyNamed('outputDir'))).thenAnswer((_) => Future<void>.value());
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    Future<BuildAarCommand> runCommandIn(String target, { List<String> arguments }) async {
      final BuildAarCommand command = BuildAarCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'aar',
        ...?arguments,
        target,
      ]);
      return command;
    }

    testUsingContext('indicate that project is a module', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=module']);

      final BuildAarCommand command = await runCommandIn(projectPath);
      expect(await command.usageValues,
          containsPair(kCommandBuildAarProjectType, 'module'));

    }, overrides: <Type, Generator>{
      AarBuilder: () => mockAarBuilder,
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('indicate that project is a plugin', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=plugin', '--project-name=aar_test']);

      final BuildAarCommand command = await runCommandIn(projectPath);
      expect(await command.usageValues,
          containsPair(kCommandBuildAarProjectType, 'plugin'));

    }, overrides: <Type, Generator>{
      AarBuilder: () => mockAarBuilder,
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('indicate the target platform', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=module']);

      final BuildAarCommand command = await runCommandIn(projectPath,
          arguments: <String>['--target-platform=android-arm']);
      expect(await command.usageValues,
          containsPair(kCommandBuildAarTargetPlatform, 'android-arm'));

    }, overrides: <Type, Generator>{
      AarBuilder: () => mockAarBuilder,
    }, timeout: allowForCreateFlutterProject);
  });
}

class MockAarBuilder extends Mock implements AarBuilder {}
