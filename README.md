# iPhone Duo: native tabs are missing after a cold launch in landscape

On an iPhone Duo's inner display held in landscape, an app using expo-router's
`NativeTabs` (react-native-screens' tabs) launches with **no tab bar at all**.
Rotating the device once brings the tabs back. Apple's own tabbed apps launch
with their tabs in the same pose.

Reproduces on a physical iPhone Duo (iOS 27.2, 24B91016) and in the iPhone Duo
simulator (iOS 27.2, 24B91016s, Xcode 27.2 27B48).

## Versions

| | |
|---|---|
| expo | 58.0.19 |
| expo-router | 58.0.26 |
| react-native-screens | 4.30.0 |
| react-native | 0.88.0 |
| Xcode | 27.2 (27B48) |

## Reproduce (`expo-app/`)

A fresh `create-expo-app --template default@sdk-58` cut down to one layout with
five stock `NativeTabs.Trigger`s and five one-line screens. No patches, no
custom native code, no `sidebarAdaptable` unless you set
`EXPO_PUBLIC_SIDEBAR_ADAPTABLE=1`.

```sh
cd expo-app
npm install
npx expo prebuild -p ios
cd ios && pod install
xcodebuild -workspace DuoTabsRepro.xcworkspace -scheme DuoTabsRepro \
  -configuration Release -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone Duo' -derivedDataPath build build
xcrun simctl install booted build/Build/Products/Release-iphonesimulator/DuoTabsRepro.app
```

1. In the iPhone Duo simulator, open the inner display and rotate to landscape.
2. Launch DuoTabsRepro.
3. **Expected:** the vertical floating tab bar on the trailing edge, five tabs.
   **Actual:** no tab bar. The first tab's content shows; nothing can switch tabs.
4. Rotate to portrait and back to landscape: the tab bar appears and stays.

## What the view hierarchy shows

The tab bar controller has its five `tabs` and five tab bar items, its traits are
the same before and after the rotation (horizontal and vertical size class
Regular, idiom Phone), and `isTabBarHidden` is `NO`. What differs is whether
UIKit populated the floating bar:

| | After cold launch in landscape | After one rotation |
|---|---|---|
| `_UIFloatingBarContainerView` | present, **no** `_UITabButton`s | present, the tab buttons |
| `_UIBottomTabBarGroupView` → `UITabBar` | an empty `UITabBar` | (unchanged) |

Read with lldb (`uikit/probe.py`, below): `tabButtons=0` after launch,
`tabButtons=10` after rotating.

Things that do **not** bring the tabs back, applied live from the debugger:
`setNeedsLayout` + `layoutIfNeeded` on the controller's view, re-setting
`tabs` to the same array, switching `mode` between `tabSidebar`, `tabBar` and
`automatic`, and hiding the tab sidebar.

What **does** bring them back: `setTabBarHidden:YES` followed by
`setTabBarHidden:NO` on the tab bar controller.

## Plain UIKit does not reproduce (`uikit/`)

A one-file UIKit app (`uikit/main.swift`, built with `uikit/build-sim.sh`, no
Xcode project) with a `UITabBarController` and five `UITab`s. Each variable is
an environment switch read at launch, to copy what react-native-screens does:

| Switch | Meaning |
|---|---|
| `TABS_DELAY` | seconds after the window is shown before `tabs` is set (`-1`: before) |
| `EMBED=1` | the tab bar controller is a child of a `UINavigationController` |
| `MODE` | `tabSidebar` (default), `tabBar`, `automatic` |
| `MINIMIZE=never` | `tabBarMinimizeBehavior = .never` |
| `SIDEBAR_HIDDEN=1` | `sidebar.isHidden = true` before first display |
| `SELECT=1` | re-select the first tab after setting `tabs` |
| `APPEARANCE=1` | custom standard and scroll-edge appearances, tint |
| `EMPTY_FIRST=1` | an empty `tabs` before first display |

Every combination tried, including all of them at once, launched in landscape
with the floating bar populated (`tabButtons=10`). So the trigger is something
react-native-screens does when it builds the controller that a plain UIKit app
does not.

## Probe

`uikit/probe.py` launches an app in the booted simulator, waits, attaches lldb
and prints the window size, whether the floating bar container exists, and how
many tab buttons it holds.

```sh
xcrun python3 uikit/probe.py <sim udid> TABS_DELAY=0.5 EMBED=1          # the UIKit repro
BUNDLE=com.example.duotabsrepro WAIT=10 xcrun python3 uikit/probe.py <sim udid>   # the Expo repro
NOLAUNCH=1 BUNDLE=com.example.duotabsrepro xcrun python3 uikit/probe.py <sim udid> # read without relaunching
```
