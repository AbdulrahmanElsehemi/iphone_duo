# iphone_duo

**iPhone Duo layouts for Flutter, drawn the way Apple's Human Interface
Guidelines draw them.**

Add one widget to your app and swap a few others. On the iPhone Duo your app
then behaves like Apple's own apps:

- The tab bar stands down the side of the screen and minimizes when you scroll.
- Back and the toolbar buttons stand in the status bar's column, under the clock.
- Two panes split exactly at the fold.
- Horizontal rows of cards scroll all the way to the edge of the glass.

On an iPhone and an iPad, the same code draws the app you have today.
Nothing changes there.

The package is for iOS. If your app also ships on Android, it builds and
runs there as on any phone or tablet without a fold: no side column, and
`TwoPane` splits down the middle of a wide window.

![An iPhone, the iPhone Duo closed, and the iPhone Duo open on its side](doc/images/overview.png)

## Contents

- [The problem](#the-problem)
- [Features](#features)
- [Install](#install)
- [Quick start](#quick-start)
- [Moving an existing app over](#moving-an-existing-app-over)
- [Checking your app](#checking-your-app): `dart run iphone_duo:doctor`
- [Widgets](#widgets): [`DuoScope`](#duoscope) ·
  [`DuoNavigationShell`](#duonavigationshell) ·
  [`SideTabBar`](#sidetabbar) · [`DuoAppBar`](#duoappbar) ·
  [`SideToolbar`](#sidetoolbar) · [`TwoPane`](#twopane) ·
  [`ListDetail`](#listdetail) · [`DialogOffFold`](#dialogofffold) ·
  [Bottom sheets](#bottom-sheets) · [`KeyboardAboveFold`](#keyboardabovefold) ·
  [`FoldSplit`](#foldsplit) · [`EdgeBleed`](#edgebleed) (and
  `EdgeBleedArea`) ·
  [`HeroBleed`](#herobleed) · [`NoVerticalBar`](#noverticalbar) ·
  [`TabletopLayout`](#tabletoplayout)
- [Reading the device](#reading-the-device): the hinge, the fold, the
  posture, `PostureBuilder`, `HingeBuilder`
- [Helpers](#helpers): `context.barEdge`, window classes, even columns
- [With `flutter_screenutil`](#with-flutter_screenutil)
- [Recipes](#recipes): go_router, deep links, bloc
- [Testing your layouts](#testing-your-layouts)
- [How it works](#how-it-works)
- [Apple's rules this follows](#apples-rules-this-follows)
- [FAQ](#faq)
- [Limits](#limits)
- [Example app](#example-app)
- [Roadmap](#roadmap)

## The problem

The iPhone Duo folds like a book. It has two screens:

| Screen | Size (points) | Where the status bar is |
|---|---|---|
| Outer (closed) | 466 × 678 | Down the right side, in an 84-point column |
| Inner, held upright | 669 × 951 | Along the top, like any phone |
| Inner, on its side | 951 × 669 | Down the right side, in an 84-point column |

So on the outer screen, and on the inner one held on its side, the status bar
is **a column down the side** instead of a strip along the top. An app built
for a phone doesn't know that:

![A phone layout next to the same app with iphone_duo](doc/images/before_after.png)

| A phone layout | With iphone_duo |
|---|---|
| An empty column takes 18% of the width | The column holds the toolbar and the tabs, as in iOS |
| A bottom tab bar eats into an already short screen | The tabs float in a capsule down the side |
| The bell and the bag squeeze in beside the clock | The buttons stand under the clock, where Apple puts them |
| A row of cards stops in a straight line mid-screen | The row scrolls to the edge of the glass |

And there are problems you can't see in that picture:

- **The open Duo stays locked upright.** iOS keeps reporting the outer
  screen's size while the Duo is open. Code that locks phones to portrait
  locks the open Duo too.
- **`Info.plist` blocks it as well.** The Duo is an iPhone. If the iPhone's
  orientations list only portrait, iOS never lets the open Duo turn, whatever
  your code asks for.
- **With `flutter_screenutil`, everything is 15% too big** on the outer
  screen. It scales by the whole 466-point width, not the 382 points beside
  the column.
- **Content lands on the fold.** A three-column grid puts its middle card
  right on the crease.
- **Headers hit the rounded corner.** With the status bar down the side, iOS
  reports no top inset at all.
- **Flutter passes on nothing iOS knows about the Duo:** no hinge, no fold,
  no column. iOS 27.1 has the APIs, but only native code can call them. This
  package's iOS plugin calls them for you.

## Features

- **One line of setup.** Wrap your app in `DuoScope`, and every widget below
  adapts by itself.
- **A doctor for your setup.** `dart run iphone_duo:doctor` checks your app
  for what the Duo needs: the landscape orientations, `DuoScope`, Xcode. In
  a debug build, a widget with no `DuoScope` above it says so once.
- **It asks iOS.** A small iOS plugin reads iOS 27.1's own APIs: which side
  the status bar's column is on, the hinge angle, and where the fold and the
  camera are. Before iOS 27.1, and off iOS, it falls back to reading the safe
  area, so nothing breaks.
- **Half-open postures.** `DuoDevice.of(context).posture` tells you when the
  Duo is held like a book or stood on a table, so you can lay out around the
  bend.
- **No `if (isDuo)` in your screens.** `DuoAppBar` is a plain `AppBar` on a
  phone and moves its buttons to the column on the Duo. `SideTabBar` is just
  its child when there's no column. You write each screen once.
- **The tab bar Apple asks for.** A capsule of icons at the foot of the
  column. It shrinks to the current tab when you scroll down, and opens again
  when you scroll up or tap it.
- **The whole tab shell in one widget.** `DuoNavigationShell` shows the tabs
  down the column on the Duo and a `NavigationBar` everywhere else, and the
  pages keep their state as the Duo opens and folds.
- **iOS's own "…" menu.** Past three buttons, the rest go behind a "…" at
  the foot of the column, in iOS's own pull-down menu.
- **A screen can keep its bars across.** `NoVerticalBar` asks iOS to keep
  the status bar along the top while a screen shows, as
  `preferredVerticalBarBehavior = .disabled` does.
- **A toolbar in the column.** Back (or Close on a full-screen dialog) on
  top, your actions under it. The buttons belong to their screen: they hide
  when it's covered or its tab isn't showing, and fade with the route.
- **Two panes at the fold.** `TwoPane` splits exactly where iOS says the
  fold is. Each pane is about a phone wide, and the crease cuts nothing. On
  an iPad it's simply half and half.
- **List and detail, like Mail.** `ListDetail` opens an item beside its list
  on the open Duo and on its own page on a phone. Fold the Duo shut and the
  item you were reading goes on to its own page; the list keeps its scroll.
  A `ListDetailController` opens an item from a deep link, and the detail
  pane can have a navigator of its own.
- **Dialogs and sheets off the fold.** `DialogOffFold` keeps a dialog to
  one half, the way Apple asks. `showModalBottomSheetOffFold` opens a sheet
  under the fold, or in the end half beside it.
- **Typing above the fold.** `KeyboardAboveFold` keeps the field being typed
  in above the bend, with the keys below it.
- **Tabletop pages.** `TabletopLayout` puts what is watched on the upright
  half and what is touched on the half lying on the table.
- **Side-by-side comparisons.** `FoldSplit` and `FoldRow` put two things one
  either side of the fold, as wide as each other.
- **Rows that reach the glass.** `EdgeBleed` lets a horizontal row scroll
  under the column to the edge of the screen. Its first card still lines up
  with the page's text.
- **Pictures that reach the glass.** `HeroBleed` lets a page's lead photo
  reach under the column too, while what is drawn on it stays clear.
- **Even columns.** `DuoBreakpoints.columns(..., even: true)` gives an even
  number of grid columns, so the fold falls between two cards.
- **Orientation that works.** Phones stay upright; tablets and the open Duo
  turn every way. The lock follows the device as it opens and closes.
- **Right to left done right.** In Arabic or Hebrew the column stays on the
  same physical side of the glass, as Apple asks. The content mirrors, and in
  `TwoPane` the panes swap.
- **Accessible.** Icon-only tabs and buttons still carry labels and tooltips
  for screen readers, and VoiceOver can press them. Tap targets are 44
  points, Apple's minimum, and tests check both. Animations
  are skipped when the system asks for reduced motion.
- **Themed by default.** Colours come from your `ColorScheme`, and every
  size, colour and timing can be overridden.
- **Works with `flutter_screenutil`**, or without it. `DuoDesignSize` gives
  the right `designSize` for every window.
- **Moves with the hinge.** `HingeBuilder` hands you how far the Duo is
  open, from 0 to 1, for something that opens with the device.
- **No dependencies** beyond the Flutter SDK.
- **Tested.** 160 tests, and an example app to try on the simulator.
- **Test helpers.** `package:iphone_duo/testing.dart` has the simulator's
  numbers for every way the Duo is held, and `testDuoWidgets` runs a test
  once in each.
- **A debug overlay.** `DuoScope(debugShowRegions: true)` draws the fold,
  the camera and the column over your app.

## Install

```bash
flutter pub add iphone_duo
```

or in `pubspec.yaml`:

```yaml
dependencies:
  iphone_duo: ^0.6.0
```

Then run `flutter pub get`, and `pod install` in `ios/` if your app uses
CocoaPods. With Swift Package Manager
(`flutter config --enable-swift-package-manager`) there is nothing more to
run: the plugin ships a `Package.swift`, and its privacy manifest comes with
it either way.

Up to 0.4.0 the package was called `duo_layout` and came from Git. The
name on pub.dev is `iphone_duo`: change the dependency, and
`package:duo_layout/duo_layout.dart` to `package:iphone_duo/iphone_duo.dart`.

It needs Flutter 3.44 or later.

The hinge, the fold and the camera regions come from the iOS 27.1 SDK, so
build with Xcode 27.1 or later to get them. An app built with an older Xcode
still builds and runs: the plugin answers that it knows nothing, and the
package reads the safe area instead.

## Checking your app

From your app's folder:

```bash
dart run iphone_duo:doctor
```

It reads your app, changes nothing, and lists what the Duo needs:

```
iphone_duo doctor
  ✓ iphone_duo is in pubspec.yaml.
  ✓ Info.plist lets the iPhone turn on its side: the open Duo can.
  ✓ DuoScope is in the app.
  ! No KeyboardAboveFold: on the Duo open upright, a field can sit on the fold while typing.
    DuoScope(child: KeyboardAboveFold(child: child!))
  ✓ Xcode 27.1 builds in the hinge, the fold and the column.
```

`✗` is something that keeps the package from working, and the command then
exits with 1, so it can run in CI. `!` is advice.

## Quick start

**1. Put `DuoScope` above the navigator,** in `MaterialApp.builder`:

```dart
import 'package:iphone_duo/iphone_duo.dart';

MaterialApp(
  builder: (context, child) => DuoScope(child: child!),
  home: const Shell(),
)
```

If your app already has a builder, make `DuoScope` the outermost widget in
it. It works the same with `MaterialApp.router`.

**2. Allow landscape in `ios/Runner/Info.plist`.** iOS combines this list with
what your app asks for. With portrait only, the open Duo can never turn.

```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

Regular iPhones still stay upright, because `DuoScope` locks them from code.
This change needs a full rebuild: hot reload and hot restart won't pick it up.

**3. Use the widgets in your screens:**

```dart
// The tab shell: tabs down the column on the Duo, a NavigationBar elsewhere.
DuoNavigationShell(
  destinations: const [
    DuoDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    DuoDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
  ],
  selectedIndex: index,
  onDestinationSelected: (i) => setState(() => index = i),
  body: IndexedStack(index: index, children: pages),
)

// Any screen with a bar.
Scaffold(
  appBar: DuoAppBar(
    title: const Text('Product'),
    actions: [
      DuoAction(icon: const Icon(Icons.ios_share), tooltip: 'Share', onPressed: share),
    ],
  ),
  body: ...,
)
```

That's it. Run `dart run iphone_duo:doctor`, then run the app on the iPhone
Duo simulator, and fold, open and turn it.

## Moving an existing app over

A checklist for an app that already runs on phones:

1. **Setup.** Add `DuoScope` and the `Info.plist` orientations (see
   [Quick start](#quick-start)).
2. **Orientation code.** If you call `SystemChrome.setPreferredOrientations`
   yourself, you can delete it and keep `DuoScope`'s default. Or pass
   `DuoScope(lockPhonesUpright: false)` and lock with
   `DuoDesignSize.orientationsFor(screen, window: window)`. Don't lock to
   portrait from `main()`, because that also locks the open Duo.
3. **The tab shell.** Replace it with `DuoNavigationShell`. To keep your own
   bottom bar, pass it as `bottomBar`, or wrap the tab pages in `SideTabBar`
   and hide the bar when `SideTabBar.show(context)` is true.
4. **App bars.** Replace `AppBar` with `DuoAppBar`, and turn `IconButton`
   actions into `DuoAction`s. Move buttons with words (Cancel, Done, Add to
   bag) out of `actions`, into the page or a bottom bar.
5. **Custom headers.** Wrap them in `SideToolbar`, and leave their buttons out
   when `SideToolbar.show(context)` is true.
6. **Horizontal rows.** Wrap each one in `EdgeBleed`. Pad the page's scroll
   view with `EdgeBleed.padding` instead of a side `SafeArea`, and wrap it in
   `EdgeBleedArea`.
7. **Grids.** Count columns with `DuoBreakpoints.columns(..., even: true)`.
8. **Wide screens.** Where a list opens a detail page, show both with
   `TwoPane` when `TwoPane.fits(context)`.
9. **Scaling.** If you use `flutter_screenutil`, switch to
   [`DuoDesignSize`](#with-flutter_screenutil).

Then run `dart run iphone_duo:doctor`. You can do steps 3 to 9 one screen
at a time. Every widget is a no-op on a
phone, so a half-moved app still looks exactly as it did there.

## Widgets

### `DuoScope`

The one widget everything else needs. It goes once, above the navigator.

```dart
MaterialApp(
  builder: (context, child) => DuoScope(child: child!),
)
```

What it does:

- **Asks iOS about the device.** The column's side, the hinge, the fold and
  the camera, through the plugin. It asks again whenever the window changes,
  and iOS tells it when the hinge moves or the column changes side.
- **Finds the column.** It takes the side iOS gives, and checks it against
  the window's safe area, which it reads before any screen's `SafeArea` hides
  it. Without iOS's answer, it guesses from the safe area alone. Every other
  widget in the package reads the result from there.
- **Keeps room at the top.** With the column down the side, iOS reports no
  top inset at all, and headers would touch the rounded corner. `DuoScope`
  keeps at least `minTopInset` points there.
- **Sets orientations.** With `lockPhonesUpright`, phones stay upright, while
  tablets and the open Duo turn every way. It checks again whenever the
  window changes, so the Duo locks upright as soon as it closes.

| Parameter | Default | What it does |
|---|---|---|
| `child` | required | Your app (the navigator) |
| `minTopInset` | `24` | The least room at the top when the status bar is down a side; as tall as iPadOS's status bar |
| `lockPhonesUpright` | `true` | Sets orientations from the screen size. Turn it off if your app sets them itself |
| `debugShowRegions` | `false` | Draws what iOS reports over the app ([below](#seeing-what-ios-reports)) |

#### Seeing what iOS reports

To check a layout on the simulator, turn on `debugShowRegions`:

```dart
DuoScope(debugShowRegions: kDebugMode, child: child!)
```

It draws the fold in red (its margins pale, the crease strong, paler still
while the Duo is open flat), the camera and status bar iOS keeps clear in
blue, and the status bar's column in green. A line at the foot names the
posture, the column's side, the window's size, and whether the answer came
from iOS or from the safe area. None of it takes a tap. `DuoDebugOverlay`
draws the same over any part of the app.

### `DuoNavigationShell`

An app's tabs in one widget: a `SideTabBar` down the status bar's column on
the Duo closed or open on its side, and a `NavigationBar` at the foot
everywhere else.

```dart
DuoNavigationShell(
  destinations: const [
    DuoDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    DuoDestination(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
    DuoDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
  ],
  selectedIndex: index,
  onDestinationSelected: (i) => setState(() => index = i),
  body: IndexedStack(index: index, children: pages),
)
```

- **The pages keep their state.** `body` stays where it is in the tree
  whichever bar shows, so opening the Duo doesn't start a tab over.
- **`sideStyle`** styles the tabs down the column (`SideTabBarStyle`),
  **`bottomStyle`** the `NavigationBar` (`NavigationBarThemeData`).
- **`bottomBar`** is your own bar at the foot instead (a `CupertinoTabBar`,
  one of your design), shown where the tabs aren't down the column.
- **`minimizeOnScroll`** shrinks the side tabs on scroll, as iOS does. On by
  default.

With go_router, see [Recipes](#recipes).

### `SideTabBar`

![Tabs down the side; minimized after a scroll; a pushed page](doc/images/closed.png)

The tab bar Apple draws on the Duo: a capsule of icons at the foot of the
status bar's column. Where the status bar runs along the top, it's just its
`child`, and your own bottom bar shows instead.

```dart
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  var index = 0;

  @override
  Widget build(BuildContext context) {
    void select(int i) => setState(() => index = i);
    return Scaffold(
      body: SideTabBar(
        tabs: const [
          SideTab(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          SideTab(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
          SideTab(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: index,
        onTap: select,
        child: IndexedStack(
          index: index,
          children: const [HomePage(), ShopPage(), ProfilePage()],
        ),
      ),
      bottomNavigationBar: SideTabBar.show(context)
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: select,
              destinations: const [/* the same tabs */],
            ),
    );
  }
}
```

How it behaves:

- **Icons only.** The column is too narrow for words, and Apple asks for
  icons. `label` isn't drawn, but screen readers read it.
- **Minimizes on scroll.** Scrolling any page under it down shrinks the
  capsule to the current tab. Scrolling up, tapping the tab or changing tab
  opens it again. A tap on the minimized capsule only opens it; it doesn't
  switch tabs.
- **Takes no height.** It's drawn over the column the pages already keep
  clear of, so your pages don't lose any room.
- **Stays on its side.** In a right-to-left language it stays on the same
  physical side as the status bar.

| `SideTabBar` parameter | Default | What it does |
|---|---|---|
| `tabs` | required | A `SideTab` for each tab |
| `currentIndex` | required | The tab showing |
| `onTap` | required | Called with the index of the tab tapped |
| `child` | required | The pages |
| `minimizeOnScroll` | `true` | Shrinks to the current tab on scroll down |
| `style` | `SideTabBarStyle()` | Colours, sizes and timing |

`SideTab(icon, selectedIcon, label)`: `selectedIcon` is optional and replaces
`icon` on the current tab.

`SideTabBarStyle` lets you match your design. Colours left `null` come from
the theme:

| Field | Default |
|---|---|
| `backgroundColor` | `ColorScheme.surface` |
| `indicatorColor` (the disc behind the current tab) | `ColorScheme.secondaryContainer` |
| `selectedColor` | `ColorScheme.onSecondaryContainer` |
| `unselectedColor` | `ColorScheme.onSurfaceVariant` |
| `borderColor` | `ColorScheme.outlineVariant` |
| `shadow` | a soft shadow |
| `itemSize` | `44` (Apple's minimum tap target) |
| `iconSize` | `24` |
| `spacing` (between tabs) | `4` |
| `padding` (inside the capsule) | `4` |
| `bottomGap` (above the home indicator) | `16` |
| `duration`, `curve` | `280 ms`, `Curves.easeInOutCubic` |

`SideTabBar.show(context)` is true when the tabs are down the side. That's
when to leave your own bottom bar out.

### `DuoAppBar`

An `AppBar` that knows about the column.

```dart
Scaffold(
  appBar: DuoAppBar(
    title: Text(product.name),
    actions: [
      DuoAction(icon: const Icon(Icons.ios_share), tooltip: 'Share', onPressed: share),
      DuoAction(icon: const Icon(Icons.favorite_border), tooltip: 'Save', onPressed: save),
    ],
  ),
  body: ...,
)
```

- **With the status bar along the top** (phones, iPad, the Duo open upright),
  it's a plain `AppBar`, with the back button and the actions as
  `IconButton`s.
- **With the status bar down the side,** Back and then the actions stand in
  the column under the clock. The bar keeps only its title, from the start
  edge.
- **Back or Close.** It shows Back when the route can be popped, and Close on
  a full-screen dialog, just as `AppBar` does.
- **The buttons belong to their screen.** They hide while another route
  covers the screen or while its tab isn't the one showing, and they fade in
  and out with the route.

| Parameter | Default | What it does |
|---|---|---|
| `title` | required | The bar's title |
| `actions` | `[]` | `DuoAction`s: icon buttons only |
| `menu` | `[]` | `DuoMenuItem`s behind a "…" after the actions |
| `columnLimit` | `3` | How many actions stand in the column; the rest go first in the "…" menu |
| `automaticallyImplyLeading` | `true` | Shows Back or Close when the route can be left |
| `backgroundColor` | theme | The bar's colour |
| `centerTitle` | theme | Ignored in the column, where the title starts from the start edge |

`DuoAction(icon, tooltip, onPressed, systemImage)`: the tooltip shows on a
long press and is what screen readers read, so always set it. It's also the
action's title when it goes in the "…" menu, with `systemImage` (an SF
Symbol) beside it.

#### The "…" menu

Apple keeps three or four buttons in the column and puts the rest in a menu
at its foot. `DuoAppBar` does the same: the first `columnLimit` actions
stand under Back, and the rest, then `menu`, go behind a "…":

```dart
DuoAppBar(
  title: Text(product.name),
  actions: [share, save, compare, addToList], // addToList goes in the menu
  menu: [
    DuoMenuItem(title: 'Report a problem', systemImage: 'exclamationmark.bubble', onSelected: report),
    DuoMenuItem(title: 'Remove', systemImage: 'trash', destructive: true, onSelected: remove),
  ],
)
```

- **In the column on iOS,** the menu is iOS's own pull-down menu
  (`UIMenu`): a native button over the "…" disc opens it, so it looks,
  animates and reads out as Apple's do. `systemImage` is the SF Symbol
  beside each title, and `destructive` draws it in red.
- **In the bar across the top, and off iOS,** it's Flutter's `MenuAnchor`
  with the same items, and `icon` beside each title.
- An item whose `onSelected` is null is greyed out.
- `SideToolbarMenuButton(items: ...)` is the "…" on its own, for a
  `SideToolbar` of your own.

Keep buttons with words out of `actions`. Apple keeps text buttons in
horizontal bars on the Duo too.

### `SideToolbar`

The same as `DuoAppBar`, for a header you built yourself.

```dart
Widget build(BuildContext context) {
  final side = SideToolbar.show(context);
  return SideToolbar(
    items: [
      SideToolbarButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
      ),
      SideToolbarButton(icon: const Icon(Icons.share), tooltip: 'Share', onPressed: share),
    ],
    child: MyHeader(
      title: 'Linen Sofa',
      // In the column, the header draws only its title.
      showButtons: !side,
    ),
  );
}
```

`items` are drawn in an overlay, in the column the page keeps clear of, so
they take none of the header's height. Where there's no column, it's just
`child`.

| `SideToolbar` parameter | Default | What it does |
|---|---|---|
| `items` | required | Top to bottom: Back or Close first, then the actions |
| `child` | required | Your header, without those buttons |
| `spacing` | `8` | The gap between the buttons |
| `top` | `SideToolbar.topOf(context)` | Where the first button starts, from the top of the window: 8 points under the region iOS keeps for the camera and the clock (182 on the outer screen, 132 on the inner one, on the simulator). Before iOS 27.1, `SideToolbar.defaultTop(window)`: 160 and 104 |

`SideToolbarButton` is a raised round button, the way iOS draws the buttons
it puts in the column. That keeps it readable over whatever scrolls under it.

| `SideToolbarButton` parameter | Default |
|---|---|
| `icon`, `tooltip`, `onPressed` | required |
| `size` | `44` |
| `iconSize` | `20` |
| `backgroundColor`, `foregroundColor` | from the `ColorScheme` |

### `TwoPane`

![Shop: the list beside the product; a product: the photo beside its details](doc/images/two_panes.png)

Two panes side by side, split down the middle of the window.

```dart
// A list that opens the item beside it on a wide window,
// and pushes a page on a phone.
Widget build(BuildContext context) {
  final list = ProductList(
    selected: selected,
    onPick: (p) => TwoPane.fits(context)
        ? setState(() => selected = p)
        : Navigator.push(context, MaterialPageRoute(builder: (_) => ProductPage(p))),
  );
  if (!TwoPane.fits(context)) return list;
  return TwoPane(start: list, end: ProductDetails(selected));
}
```

```dart
// One page in two halves: the photo on one side of the fold, the details on the other.
Scaffold(
  appBar: DuoAppBar(title: Text(product.name)),
  body: TwoPane.fits(context)
      ? TwoPane(start: ProductPhoto(product), end: ProductDetails(product))
      : Column(children: [ProductPhoto(product), Expanded(child: ProductDetails(product))]),
)
```

- **Where it splits.** At the fold iOS reports, on the open Duo held on its
  side. Elsewhere, and before iOS 27.1, down the middle, which is where the
  Duo folds anyway. On an iPad it's half and half.
- **When it fits.** `TwoPane.fits(context)` is true from 840 points wide
  (`WindowClass.expanded`): the open Duo on its side, or an iPad in
  landscape.
- **Each pane can be a full `Scaffold`**, with its own `DuoAppBar`.
- **Insets.** Each pane keeps clear of its own edge of the glass only, not
  the other pane's.
- **Who gets the column.** Only the pane beside the column gives its buttons
  to it. The other pane keeps them in a bar above its content, next to what
  they act on, as Apple does in split views.
- **Right to left.** `start` is on the left in English and on the right in
  Arabic. The column stays where it is.
- **Give it the whole width.** iOS gives the fold in the window's
  coordinates, so `TwoPane` splits at it only while it's as wide as the
  window. Put it straight in a `Scaffold` body, not inside padding.

### `ListDetail`

A list beside the item picked from it, on a window wide enough for two panes
(`TwoPane.fits`), as Mail does. On a narrower window it's the list alone,
and an item opens its own page.

```dart
ListDetail<Product>(
  list: ProductList(
    // Beside the list when there's room; its own page when there isn't.
    onPick: (p) {
      if (!ListDetail.open(context, p)) openProductPage(context, p);
    },
  ),
  detail: (context, p) => ProductPage(p),
  placeholder: const Center(child: Text('Pick a product')),
  // The Duo was folded shut with an item open beside the list.
  onNarrowed: openProductPage,
  divider: BorderSide(color: Theme.of(context).dividerColor),
)
```

- **`ListDetail.open(context, item)`** shows the item in the other pane and
  returns `true`. It returns `false` on a narrow window, or outside a
  `ListDetail`, so the caller opens the item its own way.
- **`ListDetail.selectedOf<T>(context)`** is the item showing, so the list
  can mark it.
- **The detail is laid out as on a phone.** Its pane is its window, so a
  page that splits on a wide window doesn't split again inside it.
- **The list keeps its state.** It's the same widget on a narrow window and
  in a pane, so its scroll and its state survive the Duo opening and
  folding. Keep the `ListDetail` itself alive too: a shell that builds a
  side tab bar on one window and a bottom one on another should keep its
  pages under one `GlobalKey`, or every tab starts over.
- **Folded shut**, the item open beside the list is handed to `onNarrowed`
  to push, unless the list's route is covered or its tab isn't showing.
- **`divider`**, `duration` and `curve` style the line between the panes and
  the change from one item to the next. Reduced motion skips it.

#### Opening an item from outside the list

A deep link, a notification or a search result opens an item through a
`ListDetailController`:

```dart
final products = ListDetailController<Product>();

ListDetail<Product>(controller: products, /* ... */);

// From anywhere:
products.open(product); // beside the list, or on its own page (onNarrowed)
products.close();       // back to the placeholder
products.selected;      // what is open
```

`open` returns `true` when the item shows beside the list, and `false` when
it went to its own page through `onNarrowed` on a narrow window. Called
before the list is built, it waits, and the item opens as the list first
shows. The controller is a `ChangeNotifier`: dispose it in the state that
made it.

`initialItem` does the same for an item to start on:
`ListDetail(initialItem: linked, ...)`.

#### Pages inside the detail pane

With `detailNavigator: true`, the detail pane has a navigator of its own: a
page the item opens (its reviews, a photo) opens in the pane, beside the
list, as Mail opens an attachment. Without it, that page covers both panes.

```dart
ListDetail<Product>(
  detailNavigator: true,
  // For Navigator.pushNamed in the pane; pass your app's own.
  onGenerateDetailRoute: AppRoutes.generate,
  /* ... */
)
```

Under the item, `Navigator.of(context)` is the pane's navigator and
`Navigator.of(context, rootNavigator: true)` the app's. When the Duo folds
shut, the item goes to its own page, but the pages opened over it in the
pane don't follow.

### `DialogOffFold`

Keeps a dialog off the fold, as Apple asks: under a fold that runs across
the screen (the Duo open upright, or stood as a tabletop), and in the end
half beside one that runs down it (open on its side).

```dart
showDialog(
  context: context,
  builder: (context) => DialogOffFold(
    child: AlertDialog(title: const Text('Delete this address?'), actions: ...),
  ),
);
```

- The half it's given is its window: the `MediaQuery` size is the half's,
  and the insets the fold cuts away are dropped. A dialog that lays itself
  out by the window's shape, like the date picker, fits it.
- Wrap a date picker's `builder` the same way.
- Without a fold it's the child as it is: centred on a phone or an iPad.

### Bottom sheets

`showModalBottomSheetOffFold` takes the same arguments as
`showModalBottomSheet`, and keeps the sheet off the fold:

```dart
showModalBottomSheetOffFold(
  context: context,
  isScrollControlled: true,
  builder: (context) => const SortOptions(),
);
```

- **On a window wide enough for two panes** (the Duo open on its side, an
  iPad), the sheet opens in the end half and leaves the other in view. On
  the Duo that half starts at the fold. A tap on the other half closes it.
  The sheet keeps clear of the status bar's column only when the column is
  down its own edge.
- **Where the fold runs across the screen** (open upright, or stood as a
  tabletop), the sheet grows no taller than the half under the fold, and
  taller only by the keyboard it rises above.
- **Anywhere else**, it's the sheet `showModalBottomSheet` opens.

If you open sheets some other way, wrap their content in `SheetOffFold` for
the fold across the screen.

### `KeyboardAboveFold`

Open upright, the Duo's keyboard rises to about the fold, so a field
scrolled just above the keys can sit on the bend. Put `KeyboardAboveFold`
under `DuoScope`, and while the keyboard is up every screen is told that it
reaches the fold. Pages and sheets then keep the field above it, the way a
laptop has the screen above and the keys below:

```dart
MaterialApp(
  builder: (context, child) =>
      DuoScope(child: KeyboardAboveFold(child: child!)),
)
```

Without a fold across the screen, or with no keyboard, nothing changes.

### `FoldSplit`

Two things compared side by side (two products, two plans), one either side
of a fold down the window, as wide as each other. Lay every row of the
comparison out with the same split, and the values line up under their
headings.

```dart
final split = FoldSplit.of(
  context,
  // Where the rows' content starts, from each edge of the window.
  margin: EdgeBleed.sides(context) + const EdgeInsets.symmetric(horizontal: 16),
);
...
split == null
    ? Row(children: [Expanded(child: a), Expanded(child: b)])
    : FoldRow(split: split, start: a, end: b)
```

- `FoldSplit.of` is `null` without a fold down the window: on a phone, an
  iPad, or the Duo open upright.
- **`start`** is the width of the first one; **`gap`** is the space after
  it, the fold and its margins in it. The end one takes the rest.
- **Even widths.** The status bar's column takes room from one half, so both
  take the narrower half's width, and the first is set back from the fold
  rather than reaching it.
- **Right to left.** The start one is on the right, and the split follows.

### `EdgeBleed`

A horizontal row (cards, chips, logos) that scrolls under the column to the
edge of the glass, the way it scrolls off the edge of a phone. Without it,
the row stops in a straight line beside the column.

```dart
EdgeBleedArea(
  child: ListView(
    // The page keeps its side insets inside the scroll view...
    padding: EdgeBleed.padding(context, const EdgeInsets.all(16)),
    children: [
      const Text('Picks for you'),
      // ...so the row can reach through them.
      EdgeBleed(
        child: SizedBox(
          height: 176,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeBleed.padding(context, const EdgeInsets.symmetric(horizontal: 16)),
            children: cards,
          ),
        ),
      ),
      const ListTile(title: Text('Orders')),
    ],
  ),
)
```

- `EdgeBleed` widens its child by the side insets, past both edges.
- `EdgeBleed.padding(context, base)` is `base` plus the side insets. Use it
  for the page's scroll view, and again for the row's own list. Then the
  first card lines up with the page's text, and the last can scroll clear of
  the column.
- `EdgeBleed.sides(context)` is the side insets alone.
- **`EdgeBleedArea` around the page's scroll view** takes the side insets
  out of the `MediaQuery` under it, once the padding has them. Without it, a
  `ListTile` (which has a `SafeArea` of its own) or any `SafeArea` in the
  list keeps clear of the column a second time, and stops short of the
  page's text. `EdgeBleed` and `HeroBleed` under it still reach the glass.
- **Don't wrap the page's scroll view in a side `SafeArea`.** It clips the
  row at the inset. If you need one for the top and bottom, use
  `SafeArea(left: false, right: false)`.
- On an upright phone there are no side insets, so it changes nothing.

### `HeroBleed`

A page's lead picture (a product's photo, a banner, a map) that reaches
under the column to the edge of the glass, as Apple asks of pictures and
backgrounds. Without it, the photo stops beside the column and leaves a
bare strip the height of the photo.

```dart
ListView(
  padding: EdgeBleed.sides(context), // as for EdgeBleed
  children: [
    HeroBleed(
      overlay: const Align(
        alignment: AlignmentDirectional.bottomStart,
        child: ProductTitle(),
      ),
      child: AspectRatio(aspectRatio: 4 / 3, child: Image.network(url, fit: BoxFit.cover)),
    ),
    const ProductDetails(),
  ],
)
```

- `child` is the picture. It is widened by the side insets, and is as tall
  as it lays out at that width.
- `overlay` is drawn on it (a title, the photo's dots, a button) and stays
  inside the page's own width, clear of the column, as Apple keeps controls
  out of it.
- It needs the same page as `EdgeBleed`: `SafeArea(left: false, right:
  false)`, with the content padded by `EdgeBleed.sides(context)`.
- On a phone, an iPad, or a `TwoPane` pane away from the column, it's the
  picture with the overlay on it, as it is.

### `NoVerticalBar`

Some screens the column doesn't suit: a full-screen video or camera, a
game, a form whose buttons have words. Wrap such a screen in
`NoVerticalBar`, and while it shows iOS keeps the status bar and the bars
across the top, as on a phone. `context.barEdge` is then null, and the
package's widgets lay the screen out as on a phone too:

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const NoVerticalBar(child: VideoPlayerPage()),
));
```

- It counts while its screen can be seen: not while another page covers
  it, nor on a tab that isn't showing. With none showing, iOS puts the
  column back.
- Going from one such screen to another, the column doesn't come back in
  between.

It's Apple's `preferredVerticalBarBehavior = .disabled`, which iOS asks the
app's root view controller for. Flutter's can't be told, so make the root
the plugin's `DuoFlutterViewController`, a `FlutterViewController` in every
other way. In `ios/Runner/Base.lproj/Main.storyboard`, set the root's class:

```xml
<viewController id="BYZ-38-t0r" customClass="DuoFlutterViewController" sceneMemberID="viewController">
```

Or in Xcode: select the Flutter View Controller, and in the Identity
inspector set Class to `DuoFlutterViewController`, with no module. If the
app creates its view controller in code, create a `DuoFlutterViewController`
there instead (`import iphone_duo`).

Without it, or before iOS 27.1, the screen keeps the column, and a debug
build says why once.

## Reading the device

`DuoDevice.of(context)` is what iOS says about the device. It rebuilds your
widget when anything in it changes.

```dart
final device = DuoDevice.of(context);

device.hinge;      // Hinge(angle: 112.0, status: HingeStatus.partiallyOpen), or null
device.fold;       // the fold, a ReservedRegion, or null
device.occlusions; // the camera and the status bar
device.posture;    // DuoPosture.closed, tabletop, book or flat, or null
device.fromIOS;    // false before iOS 27.1, off iOS and in tests
```

| Field | What it is |
|---|---|
| `hinge.angle` | Degrees: 0 folded shut, 180 flat |
| `hinge.status` | `closed`, `partiallyOpen`, `fullyOpen` or `unknown` |
| `fold.frame` | The fold with the room iOS asks tappable content to keep from it |
| `fold.rect` | The crease itself, without that room |
| `fold.isActive` | True while the Duo is partly folded. Flat, the fold is still there, as a line to keep cards off |
| `fold.axis` | `Axis.vertical` when the fold runs from top to bottom: the Duo held on its side |
| `occlusions` | Regions iOS keeps for the camera and the status bar. `isActive` is false for one that isn't on this screen |
| `posture` | From the hinge and the way the fold runs: `tabletop` is partly open with the fold across the screen, `book` with the fold from top to bottom |

All of these are in the window's coordinates, the same logical pixels as
Flutter's.

`DuoDevice.of(context)` rebuilds your widget every time the hinge moves,
which is many times a second while the Duo folds. A layout that only needs
the fold, the camera or the column should read
`DuoDevice.regionsOf(context)` instead: it has everything but the hinge,
and rebuilds only when those change. `TwoPane` and `SideToolbar` read it
that way.

### `PostureBuilder`

`DuoDevice.of` rebuilds on every step of the hinge, many times a second
while the Duo folds. A page laid out by how the Duo is held needs none of
those. `PostureBuilder` reads the hinge itself and builds again only when
the posture changes:

```dart
PostureBuilder(
  builder: (context, posture) => posture == DuoPosture.book
      ? const TwoPageSpread()
      : const SinglePage(),
)
```

Use the hinge for effects and interactions, and the fold for layout. iOS
sends the angle as often as it likes, so if you only need to know whether
the Duo is half open, read `posture`.

### `HingeBuilder`

How far the Duo is open, from 0 folded shut to 1 flat, on every step of the
hinge: for something that moves with the device, like a lid lifting or a
welcome that unfolds as the Duo opens.

```dart
HingeBuilder(
  child: const Logo(), // built once
  builder: (context, open, child) => Transform.rotate(
    angle: (1 - open) * 0.6,
    child: child,
  ),
)
```

Off the Duo it's `fallback` (1 by default). It rebuilds many times a second
while the Duo folds, so keep what doesn't move in `child`. For layout, use
`PostureBuilder`.

### `TabletopLayout`

Stood half open on a table, the Duo is a small laptop: the upper half is
watched, the lower half is touched. `TabletopLayout` lays a page out that
way while the Duo is held so, and is the usual page otherwise:

```dart
Scaffold(
  body: TabletopLayout(
    top: const ProductPhotos(),     // the upright half
    bottom: const ProductDetails(), // the half on the table
    child: const ProductPage(),     // any other way it is held
  ),
)
```

- The fold and its margins between the halves stay empty.
- Each half is a window of its own: `MediaQuery` gives it its size, and the
  insets of the edge the fold cuts off are gone.
- It goes by the fold's place in the window, so give it the whole height
  (a Scaffold's body), as with `TwoPane`.
- Going in or out of the tabletop builds the halves anew. Keep what has to
  last (a scroll position, a pick) above it.
- For a page that splits itself, `TabletopLayout.foldOf(context, posture)`
  gives the fold while the Duo is a tabletop, and null otherwise.

## Helpers

### `context.barEdge`

```dart
switch (context.barEdge) {
  case BarEdge.left:
  case BarEdge.right:
    // The status bar runs down that side of the glass.
  case null:
    // It runs along the top: a phone, an iPad, the Duo open upright.
}
```

Use it for your own decisions, for example to hide a floating button that
would sit under the tab capsule. The `DuoContext` extension also gives you:

| Getter | What it is |
|---|---|
| `context.barEdge` | `BarEdge.left`, `BarEdge.right`, or `null` |
| `context.windowClass` | `compact`, `medium` or `expanded`, from the width |
| `context.windowInsets` | The window's own insets, even under a `SafeArea` |
| `context.windowSize` | The window's size |

`BarEdge.of(EdgeInsets)` does the same from any insets, for code without a
`BuildContext`.

### Window classes

Material's window size classes, with the Duo's screens in them:

| `WindowClass` | Width | Examples |
|---|---|---|
| `compact` | under 600 | A phone, the Duo closed |
| `medium` | 600 to 839 | An iPad in portrait, the Duo open upright |
| `expanded` | 840 and up | An iPad in landscape, the Duo open on its side |

`DuoBreakpoints.medium` (600) and `DuoBreakpoints.expanded` (840) are the
same widths as constants.

### Even columns

![The Duo open upright, and on its side](doc/images/open.png)

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final columns = DuoBreakpoints.columns(
      constraints.maxWidth,
      tile: 150, // the narrowest a card may be
      gap: 12,
      even: true,
    );
    return GridView.count(crossAxisCount: columns, children: cards);
  },
)
```

`columns` returns how many tiles at least `tile` points wide fit across the
width, and never fewer than `min` (2 by default). With `even: true`, an odd
count drops by one. On the open Duo the fold then falls between two columns
instead of through a card.

## With `flutter_screenutil`

Say your designs are drawn on a phone frame (390 × 844, for example) and
scaled with `flutter_screenutil`. A fixed `designSize` goes wrong on the Duo:

- **On the outer screen** it scales by the full 466 points, though only 382
  are beside the column. Everything comes out 15% too big.
- **On the open Duo or an iPad** it blows the phone design up instead of
  showing more.

`DuoDesignSize.forWindow` picks the design size for the window you're in:

- **On a phone or the outer screen**, it scales by the width beside the
  column, up to `maxPhoneScale` (1.15).
- **On a tablet or the open Duo**, it draws the design's points 1:1, so the
  layout shows more per row instead of growing. It never counts the height
  as less than `minHeight` (700), so a short, wide window doesn't shrink the
  text.

```dart
final size = DuoDesignSize.forWindow(
  windowSize,
  phoneFrame: const Size(390, 844), // your Figma frame
  insets: windowInsets,
);
```

`ScreenUtilInit` reads its `designSize` once, so it has to be rebuilt when
the Duo opens or closes. Copy this widget into your app, and use it in place
of `ScreenUtilInit` above your `MaterialApp`:

```dart
import 'package:iphone_duo/iphone_duo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WindowScreenUtil extends StatefulWidget {
  const WindowScreenUtil({super.key, required this.child});
  final Widget child;
  @override
  State<WindowScreenUtil> createState() => _WindowScreenUtilState();
}

class _WindowScreenUtilState extends State<WindowScreenUtil>
    with WidgetsBindingObserver {
  Size? _design;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Size _designOf(BuildContext context) {
    final view = View.of(context);
    return DuoDesignSize.forWindow(
      view.physicalSize / view.devicePixelRatio,
      phoneFrame: const Size(390, 844), // your Figma frame
      insets: EdgeInsets.fromViewPadding(view.padding, view.devicePixelRatio),
    );
  }

  @override
  void didChangeMetrics() {
    if (_designOf(context) == _design) return; // the keyboard, not a resize
    setState(() {});
    // ScreenUtilInit rebuilds only public widgets; rebuild them all.
    void rebuild(Element e) => e..markNeedsBuild()..visitChildren(rebuild);
    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) => ScreenUtilInit(
        designSize: _design = _designOf(context),
        minTextAdapt: false,
        splitScreenMode: true,
        child: widget.child,
      );
}
```

When the Duo opens or closes, the app redraws at the new size without
restarting. A half-filled form or a scrolled list stays as it was.

If you set orientations yourself, `DuoDesignSize.orientationsFor(screen,
window: window)` returns the ones `DuoScope` would use.

## Recipes

### go_router

Make `DuoNavigationShell` the shell of a `StatefulShellRoute`: each branch
keeps its own stack, and the shell its tabs.

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => DuoNavigationShell(
    destinations: destinations,
    selectedIndex: shell.currentIndex,
    onDestinationSelected: (i) =>
        shell.goBranch(i, initialLocation: i == shell.currentIndex),
    body: shell,
  ),
  branches: [/* ... */],
)
```

Put `DuoScope` in `MaterialApp.router(builder: ...)`, as with `MaterialApp`.

### A deep link into a list and its detail

Keep the `ListDetailController` beside the list, and open the item when the
link comes in. On the open Duo or an iPad it shows beside the list; on a
phone it goes to its own page through `onNarrowed`.

```dart
class _ShopState extends State<Shop> {
  final products = ListDetailController<Product>();

  @override
  void initState() {
    super.initState();
    links.listen((product) => products.open(product));
  }

  @override
  void dispose() {
    products.dispose();
    super.dispose();
  }

  // build: ListDetail<Product>(controller: products, ...)
}
```

For a link the app was opened with, `initialItem` is enough.

### bloc, or any state management

The widgets read only the window and iOS, never your state. Keep the
selected tab or item in your cubit, and hand it down:

```dart
BlocBuilder<ShellCubit, int>(
  builder: (context, index) => DuoNavigationShell(
    selectedIndex: index,
    onDestinationSelected: context.read<ShellCubit>().select,
    destinations: destinations,
    body: IndexedStack(index: index, children: pages),
  ),
)
```

### `flutter_screenutil`

See [With `flutter_screenutil`](#with-flutter_screenutil).

## Testing your layouts

You don't need the simulator to test the Duo.

### The simulator's numbers

`package:iphone_duo/testing.dart` has the window, the insets and iOS's
answer (the column, the hinge, the fold) for every way the Duo is held, as
the iPhone Duo simulator reports them:

| `DuoSimulator` | Window | Insets | Posture | Fold |
|---|---|---|---|---|
| `closed` | 466 × 678 | right 84, bottom 34 | closed | none |
| `upright` | 669 × 951 | top 82, bottom 34 | flat | across, inactive |
| `onItsSide` | 951 × 669 | right 84, bottom 34 | flat | down, inactive |
| `tabletop` | 669 × 951 | top 82, bottom 34 | tabletop | across |
| `book` | 951 × 669 | right 84, bottom 34 | book | down |
| `phone` | 390 × 844 | top 47, bottom 34 | none | none |
| `iPad` | 1194 × 834 | top 24, bottom 20 | none | none |

The fold is 40 points with margins of 20: across at
`Rect.fromLTWH(0, 455.5, 669, 40)`, down at
`Rect.fromLTWH(455.5, 0, 40, 669)`.

`testDuoWidgets` runs a test once in each, named after it, with the test's
view sized as that window and its insets. `scope` puts a widget in that
window, with iOS's answer, as `DuoScope` would hand it down:

```dart
import 'package:iphone_duo/testing.dart';

testDuoWidgets('the photos never sit on the fold', (tester, duo) async {
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => duo.scope(child: child!),
    home: const ProductPage(),
  ));
  // ... expect ...
});

// Only some of them:
testDuoWidgets('tabs down the column', (tester, duo) async { /* ... */ },
    simulators: const [DuoSimulator.closed, DuoSimulator.onItsSide]);
```

`duo.applyTo(tester)` sizes the view alone, for a test of your own. Or by
hand:

```dart
import 'package:iphone_duo/testing.dart';

for (final duo in DuoSimulator.all) {
  testWidgets('the photos never sit on the fold: $duo', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = duo.window;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => duo.scope(child: child!),
      home: const ProductPage(),
    ));
    // ... expect ...
  });
}
```

### With `DuoScope`

To test `DuoScope` itself, give the test view the Duo's size and insets:

```dart
testWidgets('the share button moves to the column on the iPhone Duo', (tester) async {
  // The outer screen: 466 × 678, with the status bar down the right.
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(466, 678)
    ..padding = const FakeViewPadding(right: 84, bottom: 34)
    ..viewPadding = const FakeViewPadding(right: 84, bottom: 34);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => DuoScope(lockPhonesUpright: false, child: child!),
    home: const ProductPage(),
  ));

  final share = tester.getCenter(find.bySemanticsLabel('Share'));
  expect(share.dx, greaterThan(466 - 84)); // in the column
});
```

The screens to test on:

| Screen | `physicalSize` | `FakeViewPadding` |
|---|---|---|
| iPhone | `Size(390, 844)` | `top: 47, bottom: 34` |
| Duo closed | `Size(466, 678)` | `right: 84, bottom: 34` |
| Duo open upright | `Size(669, 951)` | `top: 82, bottom: 34` |
| Duo open on its side | `Size(951, 669)` | `right: 84, bottom: 34` |

Pass `lockPhonesUpright: false` in tests, so `DuoScope` doesn't call the
orientation platform channel.

In tests the plugin isn't there, so `DuoDevice.of(context)` is
`DuoDevice.unknown` and the column comes from the safe area. To test with
iOS's answer, for example a half-open hinge, run as iOS and answer the
plugin's channels yourself:

```dart
debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
final device = {
  'available': true,
  'barEdge': 'right',
  'hinge': {'angle': 110.0, 'status': 'partiallyOpen'},
  'folds': [
    {'frame': [455.5, 0.0, 40.0, 669.0], 'margins': [0.0, 20.0, 0.0, 20.0], 'active': true},
  ],
  'occlusions': [],
};
final messenger = tester.binding.defaultBinaryMessenger;
messenger.setMockMethodCallHandler(const MethodChannel('iphone_duo'), (_) async => device);
messenger.setMockStreamHandler(
  const EventChannel('iphone_duo/changes'),
  MockStreamHandler.inline(onListen: (_, events) => events.success(device)),
);
// ... pump, expect ...
debugDefaultTargetPlatformOverride = null;
```

## How it works

Flutter passes on nothing iOS knows about the Duo. iOS 27.1 has APIs for
it, and the package's iOS plugin calls them on the Flutter view:

| iOS API | What the package does with it |
|---|---|
| `traitCollection.verticalBarEdge` | `context.barEdge`: which side the column is on |
| `UIHingeInteraction` | `DuoDevice.hinge` and `posture` |
| `reservedRegions(kind: .division)` | `DuoDevice.fold`, and where `TwoPane` splits |
| `reservedRegions(kind: .occlusion)` | `DuoDevice.occlusions`, and where `SideToolbar` starts |

The plugin sends a snapshot when `DuoScope` asks, which it does whenever the
window changes, and sends it again when the hinge moves or the column
changes side. iOS lays the status bar out again a moment after the window
changes, and the region it keeps for it grows (on the outer screen from 84
points tall to 174), with nothing to tell the app. So `DuoScope` asks once
more after 600 ms.

iOS gives the column as leading or trailing, in the app's own reading
direction. The plugin turns that into a side of the glass, left or right,
because that's how the package uses it.

### The fallback

Before iOS 27.1, in an app built with an older Xcode, off iOS and in
widget tests, there is no answer from iOS. `BarEdge.of` then guesses from
the safe area:

> When one side is inset deeper than the top, and the other side isn't inset
> at all, the status bar runs down that side.

| Device | Insets | `barEdge` |
|---|---|---|
| iPhone, upright | top 47, bottom 34 | `null` |
| iPhone, on its side | left 47, right 47 | `null`: both sides are inset, for the notch and corners |
| iPad | top 24, bottom 20 | `null` |
| Duo, open upright | top 82, bottom 34 | `null`: the bars stay across, as Apple says |
| Duo, closed | right 84, bottom 34 | `right` |
| Duo, open on its side | right 84, bottom 34 | `right` |

Even with iOS's answer, the package keeps a column only where the safe area
leaves room for it.

A screen can't read the safe area itself, because the `SafeArea` around its
header has already taken the insets away from everything under it. That's
why `DuoScope` reads them once, above the navigator, and hands them down in
an `InheritedWidget` (`BarEdgeScope`), together with the device.

## Apple's rules this follows

From
[Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo):

- **Bars in the column.** The tab bar, the toolbar and Back stand in the
  status bar's column: always on the outer screen, and on the inner one when
  it's held on its side. Held upright, the inner screen keeps its bars
  across.
- **Order.** Back or Close at the top, then the actions, and the tabs at the
  foot in a capsule of icons.
- **Right to left.** The column stays on the same physical side of the glass.
- **Scrolling.** The tab bar minimizes as the content scrolls.
- **Text buttons** stay in horizontal bars.
- **Split views.** Only the pane beside the column gives its buttons to it.
- **The fold.** Use an even number of columns, and don't rearrange the whole
  layout when the device folds or opens.

## FAQ

**Does it change anything on a normal iPhone or an iPad?**
No. Without a side column, every widget gives back exactly what you'd have
drawn without it: `DuoAppBar` is an `AppBar`, `SideTabBar` is its child, and
`EdgeBleed` is its child. `TwoPane` only appears where you check
`TwoPane.fits`. The one visible change is `lockPhonesUpright`, which keeps
phones in portrait. Turn it off if you lock orientations yourself.

**And on Android?**
The plugin is iOS only, so on Android there's no column and no fold:
`barEdge` is always `null` and `DuoDevice` is unknown. The widgets behave as
on an iPhone or an iPad without the plugin: `TwoPane`, `ListDetail` and
`WindowClass` still follow the window's width, and `TwoPane` splits down the
middle. Android foldables aren't supported, and aren't planned.

**Does it work with go_router, auto_route or `MaterialApp.router`?**
Yes. `DuoScope` goes in the `builder`, which every router setup has.

**Does it work with Bloc, Riverpod or Provider?**
Yes. It holds none of your state: you pass in the current tab and get `onTap`
back.

**The open Duo won't turn to landscape.**
Check that `Info.plist` lists the landscape orientations, and do a full
rebuild. Then check that nothing else in your app locks portrait, such as a
call in `main()` or another package.

**The buttons in the column sit too high or too low.**
From iOS 27.1 they start under the region iOS reports for the clock and
camera. Before that, `SideToolbar.defaultTop` was measured on the simulator.
Either way, you can pass `top:` to `SideToolbar`.

**Can I keep my own bottom bar design?**
Yes. `SideTabBar` only replaces it on the Duo. Everywhere else your own bar
shows, as before.

**How do I update?**
`flutter pub upgrade iphone_duo`. The CHANGELOG says what changed.

## Limits

- **The hinge, the fold and the camera need iOS 27.1,** and an app built
  with Xcode 27.1 or later. Before that, `DuoDevice` is unknown, `TwoPane`
  splits down the middle, and `SideToolbar` uses its measured positions.
- **Not yet tried on the iPhone Duo simulator:** iOS's "…" menu,
  `NoVerticalBar`, and the build with Swift Package Manager. Their Dart
  side is tested; the Swift builds in CI.
- **iOS only.** The plugin has no Android side, and Android foldables
  aren't supported. On Android the package reads no fold and no column.

## Example app

`example/` is a small shop with four tabs, built with every widget in the
package: the tabs are a `DuoNavigationShell`, and the Profile tab opens a
product from a "deep link" through a `ListDetailController`. Run it on an iPhone, an iPad and the iPhone Duo simulator. Then fold,
open and turn the Duo to see the same screens change:

```bash
cd example
flutter run -d "iPhone Duo"
```

Run the package's own tests with `flutter test` from the repository root.

A golden test draws the pictures in this README from the example app. To
redraw them, run this on a Mac, since it loads San Francisco from macOS:

```bash
cd example
flutter test test/screenshots_test.dart --update-goldens
```

## Roadmap

- [ ] Try iOS's "…" menu, `NoVerticalBar` and Swift Package Manager on the
  iPhone Duo simulator

## License

MIT. See [LICENSE](LICENSE).

iphone_duo is an independent open-source project. It is not affiliated with,
endorsed by or sponsored by Apple Inc. iPhone is a trademark of Apple Inc.,
registered in the U.S. and other countries.
