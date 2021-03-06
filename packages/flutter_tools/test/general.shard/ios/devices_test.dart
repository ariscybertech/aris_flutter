// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

class MockIOSApp extends Mock implements IOSApp {}
class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
class MockDirectory extends Mock implements Directory {}
class MockFileSystem extends Mock implements FileSystem {}
class MockIMobileDevice extends Mock implements IMobileDevice {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcode extends Mock implements Xcode {}
class MockFile extends Mock implements File {}
class MockProcess extends Mock implements Process {}

void main() {
  final FakePlatform macPlatform = FakePlatform.fromPlatform(const LocalPlatform());
  macPlatform.operatingSystem = 'macos';
  final FakePlatform linuxPlatform = FakePlatform.fromPlatform(const LocalPlatform());
  linuxPlatform.operatingSystem = 'linux';
  final FakePlatform windowsPlatform = FakePlatform.fromPlatform(const LocalPlatform());
  windowsPlatform.operatingSystem = 'windows';

  group('IOSDevice', () {
    final List<Platform> unsupportedPlatforms = <Platform>[linuxPlatform, windowsPlatform];

    testUsingContext('successfully instantiates on Mac OS', () {
      IOSDevice('device-123');
    }, overrides: <Type, Generator>{
      Platform: () => macPlatform,
    });

    for (Platform platform in unsupportedPlatforms) {
      testUsingContext('throws UnsupportedError exception if instantiated on ${platform.operatingSystem}', () {
        expect(
            () { IOSDevice('device-123'); },
            throwsA(isInstanceOf<AssertionError>())
        );
      }, overrides: <Type, Generator>{
        Platform: () => platform,
      });
    }

    group('Process calls', () {
      MockIOSApp mockApp;
      MockArtifacts mockArtifacts;
      MockCache mockCache;
      MockFileSystem mockFileSystem;
      MockProcessManager mockProcessManager;
      const String installerPath = '/path/to/ideviceinstaller';
      const String appId = '789';
      const MapEntry<String, String> libraryEntry = MapEntry<String, String>(
          'DYLD_LIBRARY_PATH',
          '/path/to/libraries'
      );
      final Map<String, String> env = Map<String, String>.fromEntries(
          <MapEntry<String, String>>[libraryEntry]
      );

      setUp(() {
        mockApp = MockIOSApp();
        mockArtifacts = MockArtifacts();
        mockCache = MockCache();
        when(mockCache.dyLdLibEntry).thenReturn(libraryEntry);
        mockFileSystem = MockFileSystem();
        mockProcessManager = MockProcessManager();
        when(
            mockArtifacts.getArtifactPath(
                Artifact.ideviceinstaller,
                platform: anyNamed('platform'),
            )
        ).thenReturn(installerPath);
      });

      testUsingContext('installApp() invokes process with correct environment', () async {
        final IOSDevice device = IOSDevice('123');
        const String bundlePath = '/path/to/bundle';
        final List<String> args = <String>[installerPath, '-i', bundlePath];
        when(mockApp.deviceBundlePath).thenReturn(bundlePath);
        final MockDirectory directory = MockDirectory();
        when(mockFileSystem.directory(bundlePath)).thenReturn(directory);
        when(directory.existsSync()).thenReturn(true);
        when(mockProcessManager.run(args, environment: env))
            .thenAnswer(
                (_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', ''))
            );
        await device.installApp(mockApp);
        verify(mockProcessManager.run(args, environment: env));
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        FileSystem: () => mockFileSystem,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
      });

      testUsingContext('isAppInstalled() invokes process with correct environment', () async {
        final IOSDevice device = IOSDevice('123');
        final List<String> args = <String>[installerPath, '--list-apps'];
        when(mockProcessManager.run(args, environment: env))
            .thenAnswer(
                (_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', ''))
            );
        when(mockApp.id).thenReturn(appId);
        await device.isAppInstalled(mockApp);
        verify(mockProcessManager.run(args, environment: env));
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
      });

      testUsingContext('uninstallApp() invokes process with correct environment', () async {
        final IOSDevice device = IOSDevice('123');
        final List<String> args = <String>[installerPath, '-U', appId];
        when(mockApp.id).thenReturn(appId);
        when(mockProcessManager.run(args, environment: env))
            .thenAnswer(
                (_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', ''))
            );
        await device.uninstallApp(mockApp);
        verify(mockProcessManager.run(args, environment: env));
      }, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        Platform: () => macPlatform,
        ProcessManager: () => mockProcessManager,
      });
    });
  });

  group('getAttachedDevices', () {
    MockIMobileDevice mockIMobileDevice;

    setUp(() {
      mockIMobileDevice = MockIMobileDevice();
    });

    testUsingContext('return no devices if Xcode is not installed', () async {
      when(mockIMobileDevice.isInstalled).thenReturn(false);
      expect(await IOSDevice.getAttachedDevices(), isEmpty);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
      Platform: () => macPlatform,
    });

    testUsingContext('returns no devices if none are attached', () async {
      when(iMobileDevice.isInstalled).thenReturn(true);
      when(iMobileDevice.getAvailableDeviceIDs())
          .thenAnswer((Invocation invocation) => Future<String>.value(''));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, isEmpty);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
      Platform: () => macPlatform,
    });

    final List<Platform> unsupportedPlatforms = <Platform>[linuxPlatform, windowsPlatform];
    for (Platform platform in unsupportedPlatforms) {
      testUsingContext('throws Unsupported Operation exception on ${platform.operatingSystem}', () async {
        when(iMobileDevice.isInstalled).thenReturn(false);
        when(iMobileDevice.getAvailableDeviceIDs())
            .thenAnswer((Invocation invocation) => Future<String>.value(''));
        expect(
            () async { await IOSDevice.getAttachedDevices(); },
            throwsA(isInstanceOf<UnsupportedError>()),
        );
      }, overrides: <Type, Generator>{
        IMobileDevice: () => mockIMobileDevice,
        Platform: () => platform,
      });
    }

    testUsingContext('returns attached devices', () async {
      when(iMobileDevice.isInstalled).thenReturn(true);
      when(iMobileDevice.getAvailableDeviceIDs())
          .thenAnswer((Invocation invocation) => Future<String>.value('''
98206e7a4afd4aedaff06e687594e089dede3c44
f577a7903cc54959be2e34bc4f7f80b7009efcf4
'''));
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'DeviceName'))
          .thenAnswer((_) => Future<String>.value('La tele me regarde'));
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'ProductVersion'))
          .thenAnswer((_) => Future<String>.value('10.3.2'));
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'DeviceName'))
          .thenAnswer((_) => Future<String>.value('Puits sans fond'));
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'ProductVersion'))
          .thenAnswer((_) => Future<String>.value('11.0'));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, hasLength(2));
      expect(devices[0].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
      expect(devices[0].name, 'La tele me regarde');
      expect(devices[1].id, 'f577a7903cc54959be2e34bc4f7f80b7009efcf4');
      expect(devices[1].name, 'Puits sans fond');
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
      Platform: () => macPlatform,
    });

    testUsingContext('returns attached devices and ignores devices that cannot be found by ideviceinfo', () async {
      when(iMobileDevice.isInstalled).thenReturn(true);
      when(iMobileDevice.getAvailableDeviceIDs())
          .thenAnswer((Invocation invocation) => Future<String>.value('''
98206e7a4afd4aedaff06e687594e089dede3c44
f577a7903cc54959be2e34bc4f7f80b7009efcf4
'''));
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'DeviceName'))
          .thenAnswer((_) => Future<String>.value('La tele me regarde'));
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'DeviceName'))
          .thenThrow(IOSDeviceNotFoundError('Device not found'));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, hasLength(1));
      expect(devices[0].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
      expect(devices[0].name, 'La tele me regarde');
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
      Platform: () => macPlatform,
    });
  });

  group('decodeSyslog', () {
    test('decodes a syslog-encoded line', () {
      final String decoded = decodeSyslog(r'I \M-b\M^]\M-$\M-o\M-8\M^O syslog \M-B\M-/\134_(\M-c\M^C\M^D)_/\M-B\M-/ \M-l\M^F\240!');
      expect(decoded, r'I ?????? syslog ??\_(???)_/?? ???!');
    });

    test('passes through un-decodeable lines as-is', () {
      final String decoded = decodeSyslog(r'I \M-b\M^O syslog!');
      expect(decoded, r'I \M-b\M^O syslog!');
    });
  });
  group('logging', () {
    MockIMobileDevice mockIMobileDevice;
    MockIosProject mockIosProject;

    setUp(() {
      mockIMobileDevice = MockIMobileDevice();
      mockIosProject = MockIosProject();
    });

    testUsingContext('suppresses non-Flutter lines from output', () async {
      when(mockIMobileDevice.startLogger('123456')).thenAnswer((Invocation invocation) {
        final Process mockProcess = MockProcess();
        when(mockProcess.stdout).thenAnswer((Invocation invocation) =>
            Stream<List<int>>.fromIterable(<List<int>>['''
  Runner(Flutter)[297] <Notice>: A is for ari
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestaltSupport.m:153: pid 123 (Runner) does not have sandbox access for frZQaeyWLUvLjeuEK43hmg and IS NOT appropriately entitled
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestalt.c:550: no access to InverseDeviceID (see <rdar://problem/11744455>)
  Runner(Flutter)[297] <Notice>: I is for ichigo
  Runner(UIKit)[297] <Notice>: E is for enpitsu"
  '''.codeUnits]));
        when(mockProcess.stderr)
            .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
        // Delay return of exitCode until after stdout stream data, since it terminates the logger.
        when(mockProcess.exitCode)
            .thenAnswer((Invocation invocation) => Future<int>.delayed(Duration.zero, () => 0));
        return Future<Process>.value(mockProcess);
      });

      final IOSDevice device = IOSDevice('123456');
      final DeviceLogReader logReader = device.getLogReader(
        app: BuildableIOSApp(mockIosProject),
      );

      final List<String> lines = await logReader.logLines.toList();
      expect(lines, <String>['A is for ari', 'I is for ichigo']);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
      Platform: () => macPlatform,
    });
    testUsingContext('includes multi-line Flutter logs in the output', () async {
      when(mockIMobileDevice.startLogger('123456')).thenAnswer((Invocation invocation) {
        final Process mockProcess = MockProcess();
        when(mockProcess.stdout).thenAnswer((Invocation invocation) =>
            Stream<List<int>>.fromIterable(<List<int>>['''
  Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with another Flutter message following it.
  Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with a non-Flutter log message following it.
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt
  '''.codeUnits]));
        when(mockProcess.stderr)
            .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
        // Delay return of exitCode until after stdout stream data, since it terminates the logger.
        when(mockProcess.exitCode)
            .thenAnswer((Invocation invocation) => Future<int>.delayed(Duration.zero, () => 0));
        return Future<Process>.value(mockProcess);
      });

      final IOSDevice device = IOSDevice('123456');
      final DeviceLogReader logReader = device.getLogReader(
        app: BuildableIOSApp(mockIosProject),
      );

      final List<String> lines = await logReader.logLines.toList();
      expect(lines, <String>[
        'This is a multi-line message,',
        '  with another Flutter message following it.',
        'This is a multi-line message,',
        '  with a non-Flutter log message following it.',
      ]);
      expect(device.category, Category.mobile);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
      Platform: () => macPlatform,
    });
  });
  testUsingContext('IOSDevice.isSupportedForProject is true on module project', () async {
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example

flutter:
  module: {}
''');
    fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSDevice('test').isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    Platform: () => macPlatform,
  });
  testUsingContext('IOSDevice.isSupportedForProject is true with editable host app', () async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.directory('ios').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSDevice('test').isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    Platform: () => macPlatform,
  });

  testUsingContext('IOSDevice.isSupportedForProject is false with no host app and no module', () async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSDevice('test').isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    Platform: () => macPlatform,
  });
}
