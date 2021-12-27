// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../artifacts.dart';
import '../base/build.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../ios/ios_workflow.dart';
import '../macos/xcode.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

class BuildAotCommand extends BuildSubCommand with TargetPlatformBasedDevelopmentArtifacts {
  BuildAotCommand({bool verboseHelp = false}) {
    usesTargetOption();
    addBuildModeFlags();
    usesPubOption();
    argParser
      ..addOption('output-dir', defaultsTo: getAotBuildDirectory())
      ..addOption('target-platform',
        defaultsTo: 'android-arm',
        allowed: <String>['android-arm', 'android-arm64', 'ios'],
      )
      ..addFlag('quiet', defaultsTo: false)
      ..addFlag('report-timings',
        negatable: false,
        defaultsTo: false,
        help: 'Report timing information about build steps in machine readable form,',
      )
      ..addMultiOption('ios-arch',
        splitCommas: true,
        defaultsTo: defaultIOSArchs.map<String>(getNameForIOSArch),
        allowed: IOSArch.values.map<String>(getNameForIOSArch),
        help: 'iOS architectures to build.',
      )
      ..addMultiOption(FlutterOptions.kExtraFrontEndOptions,
        splitCommas: true,
        hide: true,
      )
      ..addMultiOption(FlutterOptions.kExtraGenSnapshotOptions,
        splitCommas: true,
        hide: true,
      )
      ..addFlag('bitcode',
        defaultsTo: false,
        help: 'Build the AOT bundle with bitcode. Requires a compatible bitcode engine.',
        hide: true,
      );
    // --track-widget-creation is exposed as a flag here to deal with build
    // invalidation issues, but it is ignored -- there are no plans to support
    // it for AOT mode.
    usesTrackWidgetCreation(hasEffect: false, verboseHelp: verboseHelp);
  }

  @override
  final String name = 'aot';

  @override
  final String description = "Build an ahead-of-time compiled snapshot of your app's Dart code.";

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetPlatform = argResults['target-platform'];
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    if (platform == null)
      throwToolExit('Unknown platform: $targetPlatform');

    final bool bitcode = argResults['bitcode'];
    final BuildMode buildMode = getBuildMode();

    if (bitcode) {
      if (platform != TargetPlatform.ios) {
        throwToolExit('Bitcode is only supported on iOS (TargetPlatform is $targetPlatform).');
      }
      await validateBitcode();
    }

    Status status;
    if (!argResults['quiet']) {
      final String typeName = artifacts.getEngineType(platform, buildMode);
      status = logger.startProgress(
        'Building AOT snapshot in ${getFriendlyModeName(getBuildMode())} mode ($typeName)...',
        timeout: timeoutConfiguration.slowOperation,
      );
    }
    final String outputPath = argResults['output-dir'] ?? getAotBuildDirectory();
    final bool reportTimings = argResults['report-timings'];
    try {
      String mainPath = findMainDartFile(targetFile);
      final AOTSnapshotter snapshotter = AOTSnapshotter(reportTimings: reportTimings);

      // Compile to kernel.
      mainPath = await snapshotter.compileKernel(
        platform: platform,
        buildMode: buildMode,
        mainPath: mainPath,
        packagesPath: PackageMap.globalPackagesPath,
        trackWidgetCreation: false,
        outputPath: outputPath,
        extraFrontEndOptions: argResults[FlutterOptions.kExtraFrontEndOptions],
      );
      if (mainPath == null) {
        throwToolExit('Compiler terminated unexpectedly.');
        return null;
      }

      // Build AOT snapshot.
      if (platform == TargetPlatform.ios) {
        // Determine which iOS architectures to build for.
        final Iterable<IOSArch> buildArchs = argResults['ios-arch'].map<IOSArch>(getIOSArchForName);
        final Map<IOSArch, String> iosBuilds = <IOSArch, String>{};
        for (IOSArch arch in buildArchs)
          iosBuilds[arch] = fs.path.join(outputPath, getNameForIOSArch(arch));

        // Generate AOT snapshot and compile to arch-specific App.framework.
        final Map<IOSArch, Future<int>> exitCodes = <IOSArch, Future<int>>{};
        iosBuilds.forEach((IOSArch iosArch, String outputPath) {
          exitCodes[iosArch] = snapshotter.build(
            platform: platform,
            iosArch: iosArch,
            buildMode: buildMode,
            mainPath: mainPath,
            packagesPath: PackageMap.globalPackagesPath,
            outputPath: outputPath,
            extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions],
            bitcode: bitcode,
          ).then<int>((int buildExitCode) {
            return buildExitCode;
          });
        });

        // Merge arch-specific App.frameworks into a multi-arch App.framework.
        if ((await Future.wait<int>(exitCodes.values)).every((int buildExitCode) => buildExitCode == 0)) {
          final Iterable<String> dylibs = iosBuilds.values.map<String>((String outputDir) => fs.path.join(outputDir, 'App.framework', 'App'));
          fs.directory(fs.path.join(outputPath, 'App.framework'))..createSync();
          await runCheckedAsync(<String>[
            'lipo',
            ...dylibs,
            '-create',
            '-output', fs.path.join(outputPath, 'App.framework', 'App'),
          ]);
          final Iterable<String> dSYMs = iosBuilds.values.map<String>((String outputDir) => fs.path.join(outputDir, 'App.framework.dSYM'));
          fs.directory(fs.path.join(outputPath, 'App.framework.dSYM', 'Contents', 'Resources', 'DWARF'))..createSync(recursive: true);
          await runCheckedAsync(<String>[
            'lipo',
            '-create',
            '-output', fs.path.join(outputPath, 'App.framework.dSYM', 'Contents', 'Resources', 'DWARF', 'App'),
            ...dSYMs.map((String path) => fs.path.join(path, 'Contents', 'Resources', 'DWARF', 'App'))
          ]);
        } else {
          status?.cancel();
          exitCodes.forEach((IOSArch iosArch, Future<int> exitCodeFuture) async {
            final int buildExitCode = await exitCodeFuture;
            printError('Snapshotting ($iosArch) exited with non-zero exit code: $buildExitCode');
          });
        }
      } else {
        // Android AOT snapshot.
        final int snapshotExitCode = await snapshotter.build(
          platform: platform,
          buildMode: buildMode,
          mainPath: mainPath,
          packagesPath: PackageMap.globalPackagesPath,
          outputPath: outputPath,
          extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions],
          bitcode: false,
        );
        if (snapshotExitCode != 0) {
          status?.cancel();
          throwToolExit('Snapshotting exited with non-zero exit code: $snapshotExitCode');
        }
      }
    } on String catch (error) {
      // Catch the String exceptions thrown from the `runCheckedSync` methods below.
      status?.cancel();
      printError(error);
      return null;
    }
    status?.stop();

    if (outputPath == null)
      throwToolExit(null);

    final String builtMessage = 'Built to $outputPath${fs.path.separator}.';
    if (argResults['quiet']) {
      printTrace(builtMessage);
    } else {
      printStatus(builtMessage);
    }
    return null;
  }
}

Future<void> validateBitcode() async {
  final Artifacts artifacts = Artifacts.instance;
  if (artifacts is! LocalEngineArtifacts) {
    throwToolExit('Bitcode is only supported with a local engine built with --bitcode.');
  }
  final String flutterFrameworkPath = artifacts.getArtifactPath(Artifact.flutterFramework);
  if (!fs.isDirectorySync(flutterFrameworkPath)) {
    throwToolExit('Flutter.framework not found at $flutterFrameworkPath');
  }
  final Xcode xcode = context.get<Xcode>();

  // Check for bitcode in Flutter binary.
  final RunResult otoolResult = await xcode.otool(<String>[
    '-l', fs.path.join(flutterFrameworkPath, 'Flutter'),
  ]);
  if (!otoolResult.stdout.contains('__LLVM')) {
    throwToolExit('The Flutter.framework at $flutterFrameworkPath does not contain bitcode.');
  }
  final RunResult clangResult = await xcode.clang(<String>['--version']);
  final String clangVersion = clangResult.stdout.split('\n').first;
  final String engineClangVersion = iosWorkflow.getPlistValueFromFile(
    fs.path.join(flutterFrameworkPath, 'Info.plist'),
    'ClangVersion',
  );
  if (clangVersion != engineClangVersion) {
    printStatus(
      'The Flutter.framework at $flutterFrameworkPath was built '
      'with "${engineClangVersion ?? 'unknown'}", but the current version '
      'of clang is "$clangVersion". This may result in failures when '
      'archiving your application in Xcode.',
      emphasis: true,
    );
  }
}
