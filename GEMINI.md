# JFlutter Project Analysis

## Project Overview

JFlutter is a mobile-first educational application built with Flutter for learning formal language theory and automata. It is a modern port of the classic JFLAP tool, designed with a touch-optimized interface for creating, editing, and simulating formal language constructs like finite automata and context-free grammars.

**Key Technologies:**

*   **Framework:** Flutter
*   **Language:** Dart
*   **State Management:** Riverpod, Provider, GetIt
*   **Architecture:** Clean Architecture (Presentation, Core, Data layers)
*   **UI:** Material 3
*   **Testing:** flutter_test

## Building and Running

### Prerequisites

*   Flutter SDK 3.16+
*   Dart SDK 3.0+

### Commands

*   **Install dependencies:**
    ```bash
    flutter pub get
    ```
*   **Run the app:**
    ```bash
    flutter run
    ```
*   **Run tests:**
    ```bash
    flutter test
    ```
*   **Run static analysis:**
    ```bash
    flutter analyze
    ```

## Development Conventions

*   **State Management:** Primarily uses Riverpod for state management.
*   **Design:** Follows Material 3 design principles.
*   **Optimization:** Code should be optimized for mobile devices.
*   **Testing:** Comprehensive tests (unit, integration, contract) are expected for new features.
*   **Documentation:** Public APIs should be well-documented.
