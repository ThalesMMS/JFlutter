# Manual QA - Transition Label Bottom Sheet

## Scenario: Edit FSA transition label on a narrow viewport

1. Launch the app with an FSA loaded and resize the window (or use an emulator) so the shortest side is below 600 px.
2. Tap a transition once to select it and trigger the label editor.
3. Confirm a modal bottom sheet appears with:
   - A focused text field titled "Rótulo".
   - Large Cancel and Salvar buttons that are easy to tap.
4. Enter a new label and press **Salvar**.
   - The sheet should close, the provider should update the transition label, and the canvas selection should clear.
5. Repeat the interaction and dismiss the sheet via the Cancel button and by swiping it down.
   - Verify both dismissal methods clear the transition selection without mutating the label.
6. Run a simulation (or highlight a transition) before editing and ensure the highlight states persist after editing via the sheet.

## Scenario: Desktop regression check

1. Resize the window so the shortest side is wider than 600 px (or use a desktop platform).
2. Select a transition and confirm the inline overlay editor still appears with keyboard submission and Escape to cancel.
