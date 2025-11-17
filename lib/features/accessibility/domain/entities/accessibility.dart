/**
 * Accessibility Entity
 * Points 296-300: Accessibility features
 */

import 'package:equatable/equatable.dart';

/// Accessibility settings (Points 296-300)
class AccessibilitySettings extends Equatable {
  final bool screenReaderEnabled; // Point 296
  final bool highContrastMode; // Point 297
  final double textScaleFactor; // Point 298 (1.0 - 2.0)
  final bool keyboardNavigationEnabled; // Point 299
  final bool reduceMotion;
  final bool reduceTransparency;
  final ColorBlindnessMode? colorBlindnessMode;
  final bool boldText;
  final bool largerText;

  const AccessibilitySettings({
    this.screenReaderEnabled = false,
    this.highContrastMode = false,
    this.textScaleFactor = 1.0,
    this.keyboardNavigationEnabled = false,
    this.reduceMotion = false,
    this.reduceTransparency = false,
    this.colorBlindnessMode,
    this.boldText = false,
    this.largerText = false,
  });

  bool get hasAccessibilityEnabled =>
      screenReaderEnabled ||
      highContrastMode ||
      textScaleFactor > 1.0 ||
      keyboardNavigationEnabled ||
      reduceMotion ||
      reduceTransparency ||
      colorBlindnessMode != null ||
      boldText ||
      largerText;

  @override
  List<Object?> get props => [
        screenReaderEnabled,
        highContrastMode,
        textScaleFactor,
        keyboardNavigationEnabled,
        reduceMotion,
        reduceTransparency,
        colorBlindnessMode,
        boldText,
        largerText,
      ];
}

/// Screen reader semantics (Point 296)
class SemanticLabel extends Equatable {
  final String label;
  final String? hint;
  final String? value;
  final bool isButton;
  final bool isHeader;
  final bool isImage;
  final bool isLink;
  final bool isLiveRegion;

  const SemanticLabel({
    required this.label,
    this.hint,
    this.value,
    this.isButton = false,
    this.isHeader = false,
    this.isImage = false,
    this.isLink = false,
    this.isLiveRegion = false,
  });

  String get fullAnnouncement {
    final parts = <String>[];

    if (isHeader) parts.add('Heading');
    parts.add(label);

    if (value != null && value!.isNotEmpty) {
      parts.add(value!);
    }

    if (isButton) parts.add('Button');
    if (isLink) parts.add('Link');
    if (isImage) parts.add('Image');

    if (hint != null && hint!.isNotEmpty) {
      parts.add(hint!);
    }

    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
        label,
        hint,
        value,
        isButton,
        isHeader,
        isImage,
        isLink,
        isLiveRegion,
      ];
}

/// High contrast theme (Point 297)
class HighContrastTheme extends Equatable {
  final String backgroundColor;
  final String foregroundColor;
  final String accentColor;
  final String borderColor;
  final double borderWidth;
  final double minimumContrastRatio; // WCAG AA: 4.5:1, AAA: 7:1

  const HighContrastTheme({
    this.backgroundColor = '#000000', // Pure black
    this.foregroundColor = '#FFFFFF', // Pure white
    this.accentColor = '#FFFF00', // Bright yellow
    this.borderColor = '#FFFFFF',
    this.borderWidth = 2.0,
    this.minimumContrastRatio = 7.0, // WCAG AAA
  });

  @override
  List<Object?> get props => [
        backgroundColor,
        foregroundColor,
        accentColor,
        borderColor,
        borderWidth,
        minimumContrastRatio,
      ];
}

/// Color blindness modes (Point 297)
enum ColorBlindnessMode {
  protanopia, // Red-blind
  deuteranopia, // Green-blind
  tritanopia, // Blue-blind
  monochromacy; // Complete color blindness

  String get displayName {
    switch (this) {
      case ColorBlindnessMode.protanopia:
        return 'Protanopia (Red-Blind)';
      case ColorBlindnessMode.deuteranopia:
        return 'Deuteranopia (Green-Blind)';
      case ColorBlindnessMode.tritanopia:
        return 'Tritanopia (Blue-Blind)';
      case ColorBlindnessMode.monochromacy:
        return 'Monochromacy (Complete Color Blindness)';
    }
  }

  String get description {
    switch (this) {
      case ColorBlindnessMode.protanopia:
        return 'Difficulty distinguishing red and green';
      case ColorBlindnessMode.deuteranopia:
        return 'Difficulty distinguishing red and green (most common)';
      case ColorBlindnessMode.tritanopia:
        return 'Difficulty distinguishing blue and yellow';
      case ColorBlindnessMode.monochromacy:
        return 'See only shades of gray';
    }
  }
}

/// Text scaling preferences (Point 298)
class TextScalingPreferences extends Equatable {
  final double scaleFactor; // 1.0 - 2.0 (100% - 200%)
  final bool boldText;
  final bool increasedLineHeight;
  final bool increasedLetterSpacing;

  const TextScalingPreferences({
    this.scaleFactor = 1.0,
    this.boldText = false,
    this.increasedLineHeight = false,
    this.increasedLetterSpacing = false,
  });

  double get lineHeightMultiplier =>
      increasedLineHeight ? 1.5 : 1.2;

  double get letterSpacingMultiplier =>
      increasedLetterSpacing ? 1.2 : 1.0;

  @override
  List<Object?> get props => [
        scaleFactor,
        boldText,
        increasedLineHeight,
        increasedLetterSpacing,
      ];
}

/// Keyboard navigation (Point 299)
class KeyboardNavigationSettings extends Equatable {
  final bool enabled;
  final bool showFocusIndicator;
  final String focusIndicatorColor;
  final double focusIndicatorWidth;
  final bool enableTabNavigation;
  final bool enableArrowKeyNavigation;
  final bool enableShortcuts;
  final Map<String, KeyboardShortcut> shortcuts;

  const KeyboardNavigationSettings({
    this.enabled = false,
    this.showFocusIndicator = true,
    this.focusIndicatorColor = '#FFD700', // Gold
    this.focusIndicatorWidth = 3.0,
    this.enableTabNavigation = true,
    this.enableArrowKeyNavigation = true,
    this.enableShortcuts = true,
    this.shortcuts = const {},
  });

  @override
  List<Object?> get props => [
        enabled,
        showFocusIndicator,
        focusIndicatorColor,
        focusIndicatorWidth,
        enableTabNavigation,
        enableArrowKeyNavigation,
        enableShortcuts,
        shortcuts,
      ];
}

/// Keyboard shortcut
class KeyboardShortcut extends Equatable {
  final String action;
  final String key;
  final bool ctrlKey;
  final bool altKey;
  final bool shiftKey;
  final String description;

  const KeyboardShortcut({
    required this.action,
    required this.key,
    this.ctrlKey = false,
    this.altKey = false,
    this.shiftKey = false,
    required this.description,
  });

  String get shortcutString {
    final parts = <String>[];
    if (ctrlKey) parts.add('Ctrl');
    if (altKey) parts.add('Alt');
    if (shiftKey) parts.add('Shift');
    parts.add(key.toUpperCase());
    return parts.join('+');
  }

  @override
  List<Object?> get props => [
        action,
        key,
        ctrlKey,
        altKey,
        shiftKey,
        description,
      ];
}

/// Common keyboard shortcuts (Point 299)
class CommonShortcuts {
  static const KeyboardShortcut navigateForward = KeyboardShortcut(
    action: 'navigate_forward',
    key: 'Tab',
    description: 'Navigate to next element',
  );

  static const KeyboardShortcut navigateBackward = KeyboardShortcut(
    action: 'navigate_backward',
    key: 'Tab',
    shiftKey: true,
    description: 'Navigate to previous element',
  );

  static const KeyboardShortcut activate = KeyboardShortcut(
    action: 'activate',
    key: 'Enter',
    description: 'Activate focused element',
  );

  static const KeyboardShortcut escape = KeyboardShortcut(
    action: 'escape',
    key: 'Escape',
    description: 'Close dialog or go back',
  );

  static const KeyboardShortcut search = KeyboardShortcut(
    action: 'search',
    key: 'F',
    ctrlKey: true,
    description: 'Open search',
  );

  static const KeyboardShortcut settings = KeyboardShortcut(
    action: 'settings',
    key: ',',
    ctrlKey: true,
    description: 'Open settings',
  );

  static const KeyboardShortcut help = KeyboardShortcut(
    action: 'help',
    key: '?',
    shiftKey: true,
    description: 'Show help',
  );
}

/// WCAG compliance level (Point 300)
enum WCAGLevel {
  a, // Level A (minimum)
  aa, // Level AA (recommended)
  aaa; // Level AAA (enhanced)

  String get displayName {
    switch (this) {
      case WCAGLevel.a:
        return 'WCAG 2.1 Level A';
      case WCAGLevel.aa:
        return 'WCAG 2.1 Level AA';
      case WCAGLevel.aaa:
        return 'WCAG 2.1 Level AAA';
    }
  }

  double get minimumContrastRatio {
    switch (this) {
      case WCAGLevel.a:
        return 3.0;
      case WCAGLevel.aa:
        return 4.5; // Normal text
      case WCAGLevel.aaa:
        return 7.0; // Normal text
    }
  }

  double get largeTextContrastRatio {
    switch (this) {
      case WCAGLevel.a:
        return 3.0;
      case WCAGLevel.aa:
        return 3.0;
      case WCAGLevel.aaa:
        return 4.5;
    }
  }
}

/// Accessibility audit result (Point 300)
class AccessibilityAudit extends Equatable {
  final DateTime auditDate;
  final WCAGLevel targetLevel;
  final bool passed;
  final List<AccessibilityIssue> issues;
  final double overallScore; // 0-100
  final Map<String, bool> criteriaChecks;

  const AccessibilityAudit({
    required this.auditDate,
    required this.targetLevel,
    required this.passed,
    required this.issues,
    required this.overallScore,
    required this.criteriaChecks,
  });

  int get criticalIssueCount =>
      issues.where((i) => i.severity == IssueSeverity.critical).length;

  int get moderateIssueCount =>
      issues.where((i) => i.severity == IssueSeverity.moderate).length;

  int get minorIssueCount =>
      issues.where((i) => i.severity == IssueSeverity.minor).length;

  @override
  List<Object?> get props => [
        auditDate,
        targetLevel,
        passed,
        issues,
        overallScore,
        criteriaChecks,
      ];
}

/// Accessibility issue
class AccessibilityIssue extends Equatable {
  final String issueId;
  final IssueSeverity severity;
  final String principle; // Perceivable, Operable, Understandable, Robust
  final String guideline;
  final String successCriterion;
  final String description;
  final String location;
  final String recommendation;

  const AccessibilityIssue({
    required this.issueId,
    required this.severity,
    required this.principle,
    required this.guideline,
    required this.successCriterion,
    required this.description,
    required this.location,
    required this.recommendation,
  });

  @override
  List<Object?> get props => [
        issueId,
        severity,
        principle,
        guideline,
        successCriterion,
        description,
        location,
        recommendation,
      ];
}

/// Issue severity
enum IssueSeverity {
  critical,
  moderate,
  minor;

  String get displayName {
    switch (this) {
      case IssueSeverity.critical:
        return 'Critical';
      case IssueSeverity.moderate:
        return 'Moderate';
      case IssueSeverity.minor:
        return 'Minor';
    }
  }
}

/// WCAG Principles (Point 300)
enum WCAGPrinciple {
  perceivable,
  operable,
  understandable,
  robust;

  String get description {
    switch (this) {
      case WCAGPrinciple.perceivable:
        return 'Information and user interface components must be presentable to users in ways they can perceive';
      case WCAGPrinciple.operable:
        return 'User interface components and navigation must be operable';
      case WCAGPrinciple.understandable:
        return 'Information and the operation of user interface must be understandable';
      case WCAGPrinciple.robust:
        return 'Content must be robust enough to be interpreted by a wide variety of user agents';
    }
  }
}
