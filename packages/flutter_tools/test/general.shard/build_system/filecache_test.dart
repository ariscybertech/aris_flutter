// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/file_hash_store.dart';
import 'package:flutter_tools/src/build_system/filecache.pb.dart' as pb;

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  Environment environment;

  setUp(() {
    testbed = Testbed(setup: () {
      fs.directory('build').createSync();
      environment = Environment(
        projectDir: fs.currentDirectory,
      );
    });
  });

  test('Initializes file cache', () => testbed.run(() {
    final FileHashStore fileCache = FileHashStore(environment);
    fileCache.initialize();
    fileCache.persist();

    expect(fs.file(fs.path.join('build', '.filecache')).existsSync(), true);

    final List<int> buffer = fs.file(fs.path.join('build', '.filecache')).readAsBytesSync();
    final pb.FileStorage fileStorage = pb.FileStorage.fromBuffer(buffer);

    expect(fileStorage.files, isEmpty);
    expect(fileStorage.version, 1);
  }));

  test('saves and restores to file cache', () => testbed.run(() {
    final File file = fs.file('foo.dart')
      ..createSync()
      ..writeAsStringSync('hello');
    final FileHashStore fileCache = FileHashStore(environment);
    fileCache.initialize();
    fileCache.hashFiles(<File>[file]);
    fileCache.persist();
    final String currentHash =  fileCache.currentHashes[file.resolveSymbolicLinksSync()];
    final List<int> buffer = fs.file(fs.path.join('build', '.filecache')).readAsBytesSync();
    pb.FileStorage fileStorage = pb.FileStorage.fromBuffer(buffer);

    expect(fileStorage.files.single.hash, currentHash);
    expect(fileStorage.files.single.path, file.resolveSymbolicLinksSync());


    final FileHashStore newFileCache = FileHashStore(environment);
    newFileCache.initialize();
    expect(newFileCache.currentHashes, isEmpty);
    expect(newFileCache.previousHashes[fs.path.absolute('foo.dart')],  currentHash);
    newFileCache.persist();

    // Still persisted correctly.
    fileStorage = pb.FileStorage.fromBuffer(buffer);

    expect(fileStorage.files.single.hash, currentHash);
    expect(fileStorage.files.single.path, file.resolveSymbolicLinksSync());
  }));
}
