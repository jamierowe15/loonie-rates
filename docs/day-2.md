# Day 2: The UIKit app

## Goal
A real UIKit app with no storyboards: every view and constraint is written in code, the way
many bank teams work, because code merges cleanly in Git and storyboards don't.

## How it fits together
```
SceneDelegate ─▶ AppEnvironment (real or fake parts) ─▶ AppCoordinator
                                                          ├─ Rates tab:  RatesListViewController ◀▶ RatesListViewModel
                                                          │                └─ tap ─▶ RateDetailViewController ◀▶ RateDetailViewModel
                                                          │                                └─ RateChartView (SwiftUI, in a UIHostingController)
                                                          └─ Converter tab: ConverterViewController ◀▶ ConverterViewModel
All view models read from one RatesStore, which asks RatesRepository (Day 1).
```

## UIKit skills shown
| Skill | Where |
|---|---|
| Programmatic Auto Layout, UIStackView, UIScrollView, `keyboardLayoutGuide` | Detail and Converter screens |
| Compositional list layout + diffable data source + `reconfigureItems` | `RatesListViewController` |
| `UISearchController`, `UIRefreshControl`, swipe actions | Rates list |
| `UIContentUnavailableConfiguration` (loading, error with retry, no results) | Rates list |
| UIMenu pull-down button, UISegmentedControl, number pad with a Done bar | Converter |
| Child view controller containment with `UIHostingController` | Detail chart |
| Objective-C class called from Swift through a bridging header | `App/ObjC/LRFlagHelper` |
| Coordinator pattern for navigation | `AppCoordinator` |

## Proof
Unit tests in `AppTests/`: the list view model (loading, favourites, search, offline banner),
the converter (directions, yen, French decimals, bad input) and the Objective-C helper.
