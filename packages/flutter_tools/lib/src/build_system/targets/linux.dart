// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../globals.dart';
import '../build_system.dart';

/// Copies the Linux desktop embedding files to the copy directory.
class UnpackLinux extends Target {
  const UnpackLinux();

  @override
  String get name => 'unpack_linux';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/linux.dart'),
    Source.artifact(Artifact.linuxDesktopPath),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{PROJECT_DIR}/linux/flutter/libflutter_linux.so'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_export.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_messenger.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_plugin_registrar.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_glfw.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/icudtl.dat'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/cpp_client_wrapper/*'),
  ];

  @override
  List<Target> get dependencies => <Target>[];

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async {
    final String basePath = artifacts.getArtifactPath(Artifact.linuxDesktopPath);
    for (File input in inputFiles) {
      if (fs.path.basename(input.path) == 'linux.dart') {
        continue;
      }
      final String outputPath = fs.path.join(
        environment.projectDir.path,
        'linux',
        'flutter',
        fs.path.relative(input.path, from: basePath),
      );
      final File destinationFile = fs.file(outputPath);
      if (!destinationFile.parent.existsSync()) {
        destinationFile.parent.createSync(recursive: true);
      }
      fs.file(input).copySync(destinationFile.path);
    }
  }
}
