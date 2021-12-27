// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/source.dart';
import 'package:flutter_tools/src/cache.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  SourceVisitor visitor;
  Environment environment;

  setUp(() {
    testbed = Testbed(setup: () {
      fs.directory('cache').createSync();
      environment = Environment(
        projectDir: fs.currentDirectory,
        buildDir: fs.directory('build'),
      );
      visitor = SourceVisitor(environment);
      environment.buildDir.createSync(recursive: true);
    });
  });

  test('configures implicit vs explict correctly', () => testbed.run(() {
    expect(const Source.pattern('{PROJECT_DIR}/foo').implicit, false);
    expect(const Source.pattern('{PROJECT_DIR}/*foo').implicit, true);
    expect(Source.function((Environment environment) => <File>[]).implicit, true);
    expect(Source.behavior(TestBehavior()).implicit, true);
  }));

  test('can substitute {PROJECT_DIR}/foo', () => testbed.run(() {
    fs.file('foo').createSync();
    const Source fooSource = Source.pattern('{PROJECT_DIR}/foo');
    fooSource.accept(visitor);

    expect(visitor.sources.single.path, fs.path.absolute('foo'));
  }));

  test('can substitute {BUILD_DIR}/bar', () => testbed.run(() {
    final String path = fs.path.join(environment.buildDir.path, 'bar');
    fs.file(path).createSync();
    const Source barSource = Source.pattern('{BUILD_DIR}/bar');
    barSource.accept(visitor);

    expect(visitor.sources.single.path, fs.path.absolute(path));
  }));

  test('can substitute {FLUTTER_ROOT}/foo', () => testbed.run(() {
    final String path = fs.path.join(environment.flutterRootDir.path, 'foo');
    fs.file(path).createSync();
    const Source barSource = Source.pattern('{FLUTTER_ROOT}/foo');
    barSource.accept(visitor);

    expect(visitor.sources.single.path, fs.path.absolute(path));
  }));

  test('can substitute Artifact', () => testbed.run(() {
    final String path = fs.path.join(
      Cache.instance.getArtifactDirectory('engine').path,
      'windows-x64',
      'foo',
    );
    fs.file(path).createSync(recursive: true);
    const Source fizzSource = Source.artifact(Artifact.windowsDesktopPath, platform: TargetPlatform.windows_x64);
    fizzSource.accept(visitor);

    expect(visitor.sources.single.resolveSymbolicLinksSync(), fs.path.absolute(path));
  }));

  test('can substitute {PROJECT_DIR}/*.fizz', () => testbed.run(() {
    const Source fizzSource = Source.pattern('{PROJECT_DIR}/*.fizz');
    fizzSource.accept(visitor);

    expect(visitor.sources, isEmpty);

    fs.file('foo.fizz').createSync();
    fs.file('foofizz').createSync();


    fizzSource.accept(visitor);

    expect(visitor.sources.single.path, fs.path.absolute('foo.fizz'));
  }));

  test('can substitute {PROJECT_DIR}/fizz.*', () => testbed.run(() {
    const Source fizzSource = Source.pattern('{PROJECT_DIR}/fizz.*');
    fizzSource.accept(visitor);

    expect(visitor.sources, isEmpty);

    fs.file('fizz.foo').createSync();
    fs.file('fizz').createSync();

    fizzSource.accept(visitor);

    expect(visitor.sources.single.path, fs.path.absolute('fizz.foo'));
  }));


  test('can substitute {PROJECT_DIR}/a*bc', () => testbed.run(() {
    const Source fizzSource = Source.pattern('{PROJECT_DIR}/bc*bc');
    fizzSource.accept(visitor);

    expect(visitor.sources, isEmpty);

    fs.file('bcbc').createSync();
    fs.file('bc').createSync();

    fizzSource.accept(visitor);

    expect(visitor.sources.single.path, fs.path.absolute('bcbc'));
  }));


  test('crashes on bad substitute of two **', () => testbed.run(() {
    const Source fizzSource = Source.pattern('{PROJECT_DIR}/*.*bar');

    fs.file('abcd.bar').createSync();

    expect(() => fizzSource.accept(visitor), throwsA(isInstanceOf<InvalidPatternException>()));
  }));


  test('can\'t substitute foo', () => testbed.run(() {
    const Source invalidBase = Source.pattern('foo');

    expect(() => invalidBase.accept(visitor), throwsA(isInstanceOf<InvalidPatternException>()));
  }));
}

class TestBehavior extends SourceBehavior {
  @override
  List<File> inputs(Environment environment) {
    return null;
  }

  @override
  List<File> outputs(Environment environment) {
    return null;
  }
}
