# Accessibility

## Built in
| Need | What the app does |
|---|---|
| VoiceOver | Rows read "US dollar, USD. 1.3978 Canadian dollars. Up 0.17% since the previous day" instead of a flag emoji and an arrow |
| VoiceOver actions | Swipe-to-favourite is also a VoiceOver custom action (swipe up or down on a row) |
| Dynamic Type | Every label uses text styles or `UIFontMetrics`; list rows stack name and rate at large sizes |
| Colour | Trends show ▲ / ▼ as well as green / red; the colours are darker than the system ones to pass 4.5:1 contrast |
| Dark Mode | System backgrounds and dynamic colours throughout |
| Headings | Section headers carry the header trait, so VoiceOver's rotor can jump between them |
| Updates | The converter's result has the "updates frequently" trait |
| Charts | Swift Charts gives VoiceOver an audio graph of the line automatically |

## Automated audit
`AccessibilityAuditTests` runs Xcode's `performAccessibilityAudit()` on each screen.

<!-- auto:a11y-audit -->
| Screen | Result | Details |
|---|---|---|
| Rates | 2 issue(s) | Text clipped<br>Potentially inaccessible text |
| Rate detail | 1 issue(s) | Potentially inaccessible text |
| Converter | 2 issue(s) | Text clipped<br>Label not human-readable |
| Rates (offline) | 1 issue(s) | Text clipped |
<!-- /auto:a11y-audit -->

## Manual checks (do these yourself)
- Turn on VoiceOver and convert 50 euros with your eyes closed.
- Set the text size to the largest accessibility size and check nothing is cut off.
- Switch the phone to French and read every screen.
