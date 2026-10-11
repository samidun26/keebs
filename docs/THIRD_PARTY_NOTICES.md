# Third-party sound recordings

Keebs bundles 150 unmodified MP3 files: 66 from Mechvibes at commit `326252a13e7bef4f1c35d08ef0189b5af6f8ba02`, and 84 from kbsim at commit `ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4`.

Source: https://github.com/hainguyents13/mechvibes/tree/326252a13e7bef4f1c35d08ef0189b5af6f8ba02/src/audio

| Set | Files | License and attribution |
| --- | --- | --- |
| Cream Full Travel | 12 | Mechvibes repository MIT license, Hai Nguyen and contributors |
| MX Black Full Travel | 12 | Mechvibes repository MIT license, Hai Nguyen and contributors |
| MX Blue Full Travel | 6 | Mechvibes repository MIT license, Hai Nguyen and contributors |
| MX Brown Full Travel | 12 | Mechvibes repository MIT license, Hai Nguyen and contributors |
| Turquoise Full Travel | 12 | Mechvibes repository MIT license, Hai Nguyen and contributors |
| Holy Pandas | 12 | Pack-specific MIT license, Thomas Lai; https://github.com/tplai/kbsim |
| Alpaca | 12 | kbsim repository MIT license, Thomas Lai |
| Gateron Black Ink | 12 | kbsim repository MIT license, Thomas Lai |
| Gateron Red Ink | 12 | kbsim repository MIT license, Thomas Lai |
| Kailh Box Navy | 12 | kbsim repository MIT license, Thomas Lai |
| SKCM Blue Alps | 12 | kbsim repository MIT license, Thomas Lai |
| Topre | 12 | kbsim repository MIT license, Thomas Lai |
| Buckling Spring | 12 | kbsim repository MIT license, Thomas Lai |

Mechvibes ships the first five sets under its root MIT license and contains no separate license in those pack directories at the pinned revision. Holy Pandas includes its own license and source README. Original configs define five generic press variations and a generic release; all except MX Blue map dedicated Space, Enter, and Backspace press/release samples. Keebs preserves these mappings and falls back to generic audio for MX Blue special keys.

Exact notices are bundled in the app and retained in `Sources/KeebsApp/Resources/Recordings/Mechvibes-LICENSE` and `Sources/KeebsApp/Resources/Recordings/holy-pandas/LICENSE`. `audio-provenance.json` records each file's size and original Git blob SHA-1. Files were fetched from the pinned source and verified against those hashes.

Runtime processing: float PCM decoding, mono downmix, 48 kHz resampling, short boundary fades, volume, stereo pan, EQ, reverb, and peak limiting. The source MP3s are unchanged. Switch names are source descriptions; no endorsement or affiliation is implied.

Additional source: https://github.com/tplai/kbsim/tree/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio

kbsim publishes these seven sets under its root MIT license, with no separate asset license at the pinned revision. That notice is bundled as `Sources/KeebsApp/Resources/Recordings/kbsim-LICENSE`. `kbsim-audio-provenance.json` records every copied source path, size, and original Git blob SHA-1. Names and press/release mappings follow the source's `src/features/audioModules/*.js` exports. Only the 12 mapped clips per set are copied; Blue Alps' unused `GENERIC_long.mp3` is omitted.

Each new set has five generic press slots, one generic release, and dedicated Space, Enter, and Backspace press/release recordings. Gateron Black Ink's R2 and R3 slots contain the same original bytes; Keebs preserves that duplication. These are source-labeled recordings, not manufacturer reference measurements; keyboard case, keycaps, and recording conditions are not documented by the source.
