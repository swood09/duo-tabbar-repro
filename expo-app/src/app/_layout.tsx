import { NativeTabs } from 'expo-router/unstable-native-tabs';

// Stock NativeTabs, five tabs. Launch on an iPhone Duo's inner display held in
// landscape: the tab bar is missing until the device is rotated.
//
// EXPO_PUBLIC_SIDEBAR_ADAPTABLE=1 sets the one prop that changes the tab bar
// controller's mode (`tabSidebar` instead of `automatic`).
const SIDEBAR_ADAPTABLE = process.env.EXPO_PUBLIC_SIDEBAR_ADAPTABLE === '1';

export default function Layout() {
  return (
    <NativeTabs sidebarAdaptable={SIDEBAR_ADAPTABLE || undefined}>
      <NativeTabs.Trigger name="index">
        <NativeTabs.Trigger.Icon sf="house" />
        <NativeTabs.Trigger.Label>One</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="two">
        <NativeTabs.Trigger.Icon sf="dot.radiowaves.left.and.right" />
        <NativeTabs.Trigger.Label>Two</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="three">
        <NativeTabs.Trigger.Icon sf="map" />
        <NativeTabs.Trigger.Label>Three</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="four">
        <NativeTabs.Trigger.Icon sf="bubble.left.and.bubble.right" />
        <NativeTabs.Trigger.Label>Four</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="five">
        <NativeTabs.Trigger.Icon sf="person" />
        <NativeTabs.Trigger.Label>Five</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
    </NativeTabs>
  );
}
