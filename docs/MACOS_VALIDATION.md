# Interactive macOS validation

Run these checks on both an Apple Silicon Mac and an Intel Mac before distributing a release. Automated tests do not establish audible latency or permission behavior.

1. Build with `bash scripts/build-app.sh`, place `dist/Keebs.app` in `/Applications`, and open it. Verify the desktop window appears and the menu bar panel can reopen it after closing the window.
2. Deny Input Monitoring initially. Preview all 13 recorded sets and several originals. Click the typing area and verify press/release sounds without doubled playback. Drag every slider continuously from end to end, including in the menu bar panel; values should follow the pointer without freezing or quitting. Search, filter, favorite, and restart; the selected sound, mix, favorites, and enabled state should persist.
3. Grant Input Monitoring and restart if requested by macOS. Type in another app. Hold a letter: hear one press and one release, not repeating sounds. Test chords, Space, Return, Delete, and the keyboard playground. Typing inside Keebs should produce one sound per event.
4. On headphones, compare leftmost/rightmost keys. Set stereo width to zero: sounds should be centered. Disable key release and natural variation separately. Sweep volume, room, and desk resonance. Type quickly to check for crackles, dropped sounds, or excessive reverb.
5. Enable a password field or Terminal's Secure Keyboard Entry. Keebs should show secure-input pause and stop reacting. Exit secure input and check that normal playback resumes without a stray release sound.
6. Close the desktop window. From the keyboard icon in the macOS menu bar, pause/resume, adjust all four mix sliders, switch profiles with the picker and previous/next buttons, listen, and favorite a switch. Reopen the studio and verify the same values appear. Change the switch rapidly while typing: the final selected profile should win and no old sample should continue playing.
7. Sleep/wake, unplug headphones, change audio outputs, and revoke Input Monitoring. Check the status and verify no stuck key highlights. Regrant permission and relaunch if macOS asks.
8. Enable launch at login, approve it in System Settings if needed, and log out/in. Disable it and verify Keebs is removed from enabled login items.
9. Check VoiceOver labels, keyboard navigation, and window resizing. The app uses an ANSI position approximation; test ISO/JIS keyboards before claiming those layouts are fully supported.

For release distribution, sign with Developer ID, enable the hardened runtime, notarize, staple, and test on a clean Mac. The local ad hoc build is a development artifact.
