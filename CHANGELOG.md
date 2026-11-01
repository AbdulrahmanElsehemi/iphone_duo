## 0.6.0

Everything new is opt-in: an app on 0.5.1 builds and behaves as before.

* `DuoNavigationShell` and `DuoDestination`: an app's tabs in one widget,
  down the status bar's column on the Duo and a `NavigationBar` elsewhere,
  or the app's own bar (`bottomBar`). The pages keep their state as the Duo
  opens and folds.
* `ListDetailController`: opens and closes an item of a `ListDetail` from
  outside the list (a deep link, a notification). `ListDetail(initialItem:)`
  starts on one. On a narrow window either goes to its own page through
  `onNarrowed`.
* `ListDetail(detailNavigator: true)`: the detail pane has a navigator of
  its own, so a page the item opens stays beside the list.
  `onGenerateDetailRoute` gives it the app's named routes.
* `HingeBuilder`: how far the Duo is open, from 0 to 1, for something that
  moves with the hinge.
* `dart run iphone_duo:doctor`: checks an app for what the Duo needs (the
  landscape orientations, `DuoScope`, `KeyboardAboveFold`, the view
  controller `NoVerticalBar` needs, Xcode), and exits with 1 when something
  keeps the package from working.
* In a debug build, a widget with no `DuoScope` above it says so once.
* `testDuoWidgets` in `package:iphone_duo/testing.dart` runs a test once in
  every way the Duo is held, a phone and an iPad, and
  `DuoSimulator.applyTo(tester)` sizes a test's view as one of them. The
  package now depends on `flutter_test` from the Flutter SDK for them.
* `EdgeBleedArea`: around a page's scroll view padded by
  `EdgeBleed.padding`, it takes the side insets out of the `MediaQuery`
  under it, so a `ListTile` or a `SafeArea` in the list no longer keeps
  clear of the status bar's column a second time. `EdgeBleed` and
  `HeroBleed` under it still reach the glass.
* Fixed: VoiceOver can press the tabs of `SideTabBar` and the buttons down
  the column. They were read out but had no action.
* Fixed: `SideTabBar`'s pages no longer start over when the bar comes or
  goes, as when the Duo opens upright from closed.
* `KeyboardAboveFold` and `DialogOffFold` no longer rebuild on every change
  to the window where there is no keyboard or no fold.
* The API docs are grouped by category, and the README has recipes for
  go_router, deep links and state management.
* The example's tabs are a `DuoNavigationShell`, its shop a `ListDetail`,
  and its Profile tab opens a product as a deep link does.

## 0.5.1

* The repository is now github.com/AbdulrahmanElsehemi/iphone_duo, and
  pub.dev links to it.
* The README says the package is not affiliated with Apple.
* The plugin's podspec carries the package's version again (it said 0.4.0).

## 0.5.0

* Published on pub.dev as `iphone_duo`: the name `duo_layout` there is
  someone else's. Import `package:iphone_duo/iphone_duo.dart` and
  `package:iphone_duo/testing.dart`; the plugin's channels and its Swift
  module are `iphone_duo` too.
* `DuoAppBar(menu:, columnLimit:)` and `SideToolbarMenuButton`: past three
  actions, the rest go behind a "…" at the foot of the column, in iOS's own
  pull-down menu (`UIMenu`); Flutter's `MenuAnchor` in the bar across the
  top and off iOS. `DuoAction.systemImage` is the SF Symbol beside an action
  that goes in the menu.
* `NoVerticalBar`: while a screen shows, iOS keeps the status bar and the
  bars across the top (`preferredVerticalBarBehavior = .disabled`). Needs
  the app's root to be the plugin's `DuoFlutterViewController`.
* Swift Package Manager: the privacy manifest is bundled, with SPM and with
  CocoaPods, and CI builds the example both ways with the newest Xcode.
* Not yet tried on the iPhone Duo simulator: the native menu,
  `NoVerticalBar`, and the build with Swift Package Manager.

## 0.4.0

* `showModalBottomSheetOffFold` and `SheetOffFold`: a bottom sheet kept off
  the fold, under it when it runs across the screen and in the end half
  beside it on a two-pane window. In Arabic the end half no longer keeps
  room for a column down the other half.
* `KeyboardAboveFold`: while the keyboard is up on the Duo open upright,
  screens are told it reaches the fold, so the field being typed in stays
  above the bend.
* `HeroBleed`: a page's lead picture reaches under the status bar's column
  to the edge of the glass, and what is drawn on it stays clear of it.
* `PostureBuilder`: builds by how the Duo is held, and again only when that
  changes, not on every step of the hinge.
* `TabletopLayout`: what is watched on the upright half, what is touched on
  the half on the table, while the Duo stands as a tabletop.
* `package:duo_layout/testing.dart`: `DuoSimulator`, the simulator's window,
  insets, fold and hinge for every way the Duo is held, and a `scope` to
  test a layout in each.
* `DuoDebugOverlay`, and `DuoScope(debugShowRegions: true)`: the fold, the
  camera and the column drawn over the app, with the posture named.
* `DuoScope` keeps the app under a `GlobalKey`, so nothing under it starts
  over when what is around it changes.
* CI: analyze and test on every push; the example built for iOS on a
  release tag, or by hand.
* iOS only: the example app has no Android project any more, and the README
  no longer plans Android foldables. On Android the widgets still build as
  before, with no fold and no column, so an app that also ships there needs
  no change.

## 0.3.0

* `ListDetail`: a list beside the item picked from it on a wide window, the
  item on a page of its own on a narrow one. The list keeps its state and
  its scroll as the Duo opens and folds, and an item open beside it goes on
  to its own page when the Duo is folded shut.
* `DialogOffFold`: keeps a dialog off the fold, under it when it runs across
  the screen and in the end half when it runs down it.
* `FoldSplit` and `FoldRow`: two things compared side by side, one either
  side of a fold down the window, the two as wide as each other.

## 0.2.0

* An iOS plugin that asks iOS 27.1 about the iPhone Duo: the side of the
  status bar's column (`verticalBarEdge`), the hinge (`UIHingeInteraction`),
  and the fold and camera regions (`reservedRegions`). Read it with
  `DuoDevice.of(context)`: `hinge`, `fold`, `occlusions`, `posture`
  (closed, tabletop, book, flat).
* `context.barEdge` takes the column's side from iOS when it says, and
  still guesses from the safe area before iOS 27.1, off iOS and in tests.
* `DuoDevice.regionsOf(context)` reads the same without the hinge, so a
  layout doesn't rebuild many times a second while the Duo folds.
* `TwoPane` splits at the fold iOS reports.
* `SideToolbar` starts its column under the clock and camera iOS reports
  (`SideToolbar.topOf`); `defaultTop` is now the fallback.
* Needs Flutter 3.44 or later.
* The README is in English only, with a full guide.

## 0.1.0

* First release, taken out of a shop app running on the iPhone Duo:
  `DuoScope`, `BarEdge` / `BarEdgeScope`, `SideTabBar`, `SideToolbar` /
  `SideToolbarButton`, `DuoAppBar`, `TwoPane`, `EdgeBleed`, `WindowClass` /
  `DuoBreakpoints`, `DuoDesignSize`.
* An example app, and the README's pictures drawn from it.
