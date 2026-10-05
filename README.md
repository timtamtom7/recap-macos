# Recap

A screen recorder with visual annotation for macOS.

## What it does

- Record
- crop
- annotate on canvas
- library
- display/window pickers

## Targets

- macOS menu bar

## Structure

Key types:

- ``ScreenRecordingService``
- ``AnnotationCanvasView`/`AnnotationEditorView`/`AnnotationEngine``
- ``CropService``
- ``RecordingStore``
- ``DisplayPickerView``
- ``WindowPickerView``

Annotation over recorded video — closer to a review tool than a recorder.

## Status

Apple-platform experiment built to explore what an AI coding agent could produce for a native app. Not actively maintained.

Xcode projects here were generated with XcodeGen (`project.yml`) unless noted; open the `.xcodeproj` directly.
