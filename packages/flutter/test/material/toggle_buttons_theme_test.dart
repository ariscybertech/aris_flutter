// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

Widget boilerplate({Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );
}

void main() {
  test('ToggleButtonsThemeData copyWith, ==, hashCode basics', () {
    expect(const ToggleButtonsThemeData(), const ToggleButtonsThemeData().copyWith());
    expect(const ToggleButtonsThemeData().hashCode, const ToggleButtonsThemeData().copyWith().hashCode);
  });

   test('ToggleButtonsThemeData defaults', () {
    const ToggleButtonsThemeData themeData = ToggleButtonsThemeData();
    expect(themeData.color, null);
    expect(themeData.selectedColor, null);
    expect(themeData.disabledColor, null);
    expect(themeData.fillColor, null);
    expect(themeData.focusColor, null);
    expect(themeData.highlightColor, null);
    expect(themeData.hoverColor, null);
    expect(themeData.splashColor, null);
    expect(themeData.borderColor, null);
    expect(themeData.selectedBorderColor, null);
    expect(themeData.disabledBorderColor, null);
    expect(themeData.borderRadius, null);
    expect(themeData.borderWidth, null);

    final ToggleButtonsTheme theme = ToggleButtonsTheme();
    expect(theme.data.color, null);
    expect(theme.data.selectedColor, null);
    expect(theme.data.disabledColor, null);
    expect(theme.data.fillColor, null);
    expect(theme.data.focusColor, null);
    expect(theme.data.highlightColor, null);
    expect(theme.data.hoverColor, null);
    expect(theme.data.splashColor, null);
    expect(theme.data.borderColor, null);
    expect(theme.data.selectedBorderColor, null);
    expect(theme.data.disabledBorderColor, null);
    expect(theme.data.borderRadius, null);
    expect(theme.data.borderWidth, null);
  });

   testWidgets('Default ToggleButtonsThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ToggleButtonsThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('ToggleButtonsThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ToggleButtonsThemeData(
      color: Color(0xfffffff0),
      selectedColor: Color(0xfffffff1),
      disabledColor: Color(0xfffffff2),
      fillColor: Color(0xfffffff3),
      focusColor: Color(0xfffffff4),
      highlightColor: Color(0xfffffff5),
      hoverColor: Color(0xfffffff6),
      splashColor: Color(0xfffffff7),
      borderColor: Color(0xfffffff8),
      selectedBorderColor: Color(0xfffffff9),
      disabledBorderColor: Color(0xfffffffa),
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderWidth: 2.0,
    ).debugFillProperties(builder);

     final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

     expect(description, <String>[
      'color: Color(0xfffffff0)',
      'selectedColor: Color(0xfffffff1)',
      'disabledColor: Color(0xfffffff2)',
      'fillColor: Color(0xfffffff3)',
      'focusColor: Color(0xfffffff4)',
      'highlightColor: Color(0xfffffff5)',
      'hoverColor: Color(0xfffffff6)',
      'splashColor: Color(0xfffffff7)',
      'borderColor: Color(0xfffffff8)',
      'selectedBorderColor: Color(0xfffffff9)',
      'disabledBorderColor: Color(0xfffffffa)',
      'borderRadius: BorderRadius.circular(4.0)',
      'borderWidth: 2.0',
    ]);
  });

  testWidgets(
    'Theme text/icon colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      final ThemeData theme = ThemeData();
      const Color enabledColor = Colors.lime;
      const Color selectedColor = Colors.green;
      const Color disabledColor = Colors.yellow;

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              child: ToggleButtons(
                color: enabledColor,
                isSelected: const <bool>[false],
                onPressed: (int index) {},
                children: <Widget>[
                  // This Row is used like this to test for both TextStyle
                  // and IconTheme for Text and Icon widgets respectively.
                  Row(children: const <Widget>[
                    Text('First child'),
                    Icon(Icons.check),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );

      DefaultTextStyle textStyle;
      IconTheme iconTheme;

      // custom theme enabled color
      expect(theme.colorScheme.onSurface, isNot(enabledColor));
      textStyle = tester.firstWidget<DefaultTextStyle>(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, enabledColor);
      iconTheme = tester.firstWidget<IconTheme>(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, enabledColor);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              selectedColor: selectedColor,
              child: ToggleButtons(
                color: enabledColor,
                isSelected: const <bool>[true],
                onPressed: (int index) {},
                children: <Widget>[
                  Row(children: const <Widget>[
                    Text('First child'),
                    Icon(Icons.check),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // custom theme selected color
      expect(theme.colorScheme.primary, isNot(selectedColor));
      textStyle = tester.firstWidget<DefaultTextStyle>(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, selectedColor);
      iconTheme = tester.firstWidget<IconTheme>(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, selectedColor);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              disabledColor: disabledColor,
              child: ToggleButtons(
                color: enabledColor,
                isSelected: const <bool>[false],
                children: <Widget>[
                  Row(children: const <Widget>[
                    Text('First child'),
                    Icon(Icons.check),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // custom theme disabled color
      expect(theme.disabledColor, isNot(disabledColor));
      textStyle = tester.firstWidget<DefaultTextStyle>(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, disabledColor);
      iconTheme = tester.firstWidget<IconTheme>(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, disabledColor);
    },
  );

  testWidgets('Theme button fillColor', (WidgetTester tester) async {
    const Color customFillColor = Colors.green;
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtonsTheme(
            fillColor: customFillColor,
            child: ToggleButtons(
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                ]),
              ],
            ),
          ),
        ),
      ),
    );

    final Material material = tester.firstWidget<Material>(
      find.descendant(
        of: find.byType(RawMaterialButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, customFillColor);
    expect(material.type, MaterialType.button);
  });

  testWidgets('Theme InkWell colors', (WidgetTester tester) async {
    const Color splashColor = Color(0xff4caf50);
    const Color highlightColor = Color(0xffcddc39);
    const Color hoverColor = Color(0xffffeb3b);
    const Color focusColor = Color(0xffffff00);
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtonsTheme(
            splashColor: splashColor,
            highlightColor: highlightColor,
            hoverColor: hoverColor,
            focusColor: focusColor,
            child: ToggleButtons(
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              focusNodes: <FocusNode>[focusNode],
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.text('First child'));

    // splashColor
    // highlightColor
    final TestGesture touchGesture = await tester.createGesture();
    await touchGesture.down(center);
    await tester.pumpAndSettle();

    RenderObject inkFeatures;
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(
      inkFeatures,
      paints
        ..circle(color: splashColor)
        ..rect(color: highlightColor),
    );

    await touchGesture.up();
    await tester.pumpAndSettle();

    // hoverColor
    final TestGesture hoverGesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await hoverGesture.addPointer();
    await hoverGesture.moveTo(center);
    await tester.pumpAndSettle();

    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: hoverColor));
    await hoverGesture.removePointer();

    // focusColor
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: focusColor));
  });


  testWidgets(
    'Theme border width and border colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      const Color borderColor = Color(0xff4caf50);
      const Color selectedBorderColor = Color(0xffcddc39);
      const Color disabledBorderColor = Color(0xffffeb3b);
      const double customWidth = 2.0;

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              borderColor: borderColor,
              borderWidth: customWidth,
              child: ToggleButtons(
                isSelected: const <bool>[false],
                onPressed: (int index) {},
                children: const <Widget>[
                  Text('First child'),
                ],
              ),
            ),
          ),
        ),
      );

      RenderObject toggleButtonRenderObject;
      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: borderColor,
            strokeWidth: customWidth,
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: borderColor,
            strokeWidth: customWidth,
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              selectedBorderColor: selectedBorderColor,
              borderWidth: customWidth,
              child: ToggleButtons(
                isSelected: const <bool>[true],
                onPressed: (int index) {},
                children: const <Widget>[
                  Text('First child'),
                ],
              ),
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: selectedBorderColor,
            strokeWidth: customWidth,
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: selectedBorderColor,
            strokeWidth: customWidth,
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtonsTheme(
              disabledBorderColor: disabledBorderColor,
              borderWidth: customWidth,
              child: ToggleButtons(
                isSelected: const <bool>[false],
                children: const <Widget>[
                  Text('First child'),
                ],
              ),
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: disabledBorderColor,
            strokeWidth: customWidth,
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: disabledBorderColor,
            strokeWidth: customWidth,
          ),
      );
    },
  );
}