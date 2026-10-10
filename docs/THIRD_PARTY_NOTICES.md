# Third-party sound recordings

Keebs bundles 66 unmodified MP3 files from Mechvibes at commit `326252a13e7bef4f1c35d08ef0189b5af6f8ba02`.

Source: https://github.com/hainguyents13/mechvibes/tree/326252a13e7bef4f1c35d08ef0189b5af6f8ba02/src/audio

| Set | Files | License and attribution |
| --- | --- | --- |
| Cream Full Travel | 12 | Mechvibes repository MIT license, Hai Nguyen and contributors |
| MX Black Full Travel | 12 | Mechvibes repository MIT license, Hai Nguyen and contributors |
| MX Blue Full Travel | 6 | Mechvibes repository MIT license, Hai Nguyen and contributors |
| MX Brown Full Travel | 12 | Mechvibes repository MIT license, Hai Nguyen and contributors |
| Turquoise Full Travel | 12 | Mechvibes repository MIT license, Hai Nguyen and contributors |
| Holy Pandas | 12 | Pack-specific MIT license, Thomas Lai; https://github.com/tplai/kbsim |

Mechvibes ships the first five sets under its root MIT license and contains no separate license in those pack directories at the pinned revision. Holy Pandas includes its own license and source README. Original configs define five generic press variations and a generic release; all except MX Blue map dedicated Space, Enter, and Backspace press/release samples. Keebs preserves these mappings and falls back to generic audio for MX Blue special keys.

Exact notices are bundled in the app and retained in `Sources/KeebsApp/Resources/Recordings/Mechvibes-LICENSE` and `Sources/KeebsApp/Resources/Recordings/holy-pandas/LICENSE`. `audio-provenance.json` records each file's size and original Git blob SHA-1. Files were fetched from the pinned source and verified against those hashes.

Runtime processing: float PCM decoding, mono downmix, 48 kHz resampling, short boundary fades, volume, stereo pan, EQ, reverb, and peak limiting. The source MP3s are unchanged. Switch names are source descriptions; no endorsement or affiliation is implied.
