# Additional recorded profiles

Keebs 0.1.3 adds seven sets from [Thomas Lai's kbsim](https://github.com/tplai/kbsim/tree/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4). Select them in the desktop library or the menu bar switch picker. They work offline after installation.

| Profile | Mechanism / library category | Source folder |
| --- | --- | --- |
| Alpaca | Linear | `alpaca` |
| Gateron Black Ink | Linear | `blackink` |
| Gateron Red Ink | Linear | `redink` |
| Kailh Box Navy | Clicky | `boxnavy` |
| SKCM Blue Alps | Clicky | `bluealps` |
| Topre | Electrocapacitive rubber dome / tactile | `topre` |
| Buckling Spring | Buckling spring / clicky | `buckling` |

The names match the captions exported by kbsim's audio modules. The source does not identify a generation for Alpaca or Ink switches, a specific Topre board, or a specific buckling spring keyboard; Keebs does not invent those details. The short character descriptions in the app are subjective.

Each set supplies actual press and release clips, five generic press slots, and dedicated Space, Return, and Delete samples. Natural variation selects the source slots; Gateron Black Ink R2 and R3 are identical in the original. Spatial stereo, room, and desk resonance remain available with every set.

All 84 files are copied unchanged from the pinned revision. Hash verification and FFmpeg decoding established finite, non-silent audio with durations of approximately 52–183 ms. macOS tests decode all 150 bundled MP3s with AVAudioFile, load every recorded profile's key mappings through the app, and render every recorded set through its actual AVAudioEngine graph after changing the mix. These checks establish technical compatibility; audition on your Mac to judge the sound.

kbsim's repository MIT license permits redistribution with its copyright and permission notice retained. The notice ships inside Keebs, and [the provenance manifest](kbsim-audio-provenance.json) records exact paths and Git hashes. No payment or additional download is required for these packs.
