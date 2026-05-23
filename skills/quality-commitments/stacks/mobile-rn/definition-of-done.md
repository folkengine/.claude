# Definition of Done — Mobile Application (React Native)

A change is **done** when every applicable item below holds.

## Code

- [ ] Implementation complete and self-reviewed
- [ ] Lint and typecheck pass
- [ ] No new platform-specific code without `Platform.OS` guards or `.ios.tsx` / `.android.tsx` split

## Tests

- [ ] Unit / component tests cover new behavior including negative cases
- [ ] Detox E2E covers any new critical user journey on iOS (Android via workflow_dispatch)
- [ ] Tested on at least one supported iOS and one supported Android version

## Accessibility

- [ ] `accessibilityLabel` and `accessibilityRole` set for new touchable elements
- [ ] Tested with VoiceOver / TalkBack for new screens
- [ ] Tested with system Dynamic Type / large fonts

## Performance

- [ ] Bundle size delta reviewed; large additions justified or lazy-loaded
- [ ] No new synchronous blocking call on the JS thread
- [ ] List performance preserved (virtualization, key extraction)

## Offline & resilience

- [ ] Network failures surface a useful UI state
- [ ] State persists across app backgrounding for new flows
- [ ] No data loss on poor connectivity

## Security

- [ ] No PII or secrets logged
- [ ] Sensitive local storage uses Keychain / Keystore (not AsyncStorage)
- [ ] Deep links validated before use

## App store readiness

- [ ] New permissions justified and copy added (Info.plist / AndroidManifest)
- [ ] No private API usage that would trigger store rejection
- [ ] Privacy manifest updated if data collection changed

## Documentation

- [ ] README / docs updated for user-visible changes
- [ ] `docs/quality-commitments-matrix.md` updated if a new quality type was introduced

## Exploratory

- [ ] At least one exploratory pass on a real device (not just simulator)
