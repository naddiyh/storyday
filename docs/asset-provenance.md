# Character and sticker assets

- `assets/characters/companion.png`: original user-supplied PNG, copied without altering artwork or transparency. Source: `exec-67c7eaf5-ac3f-428a-ac72-c0aa36fa5326.png`.
- `assets/stickers/jasmine.png`: generated with the built-in Imagegen tool using the imagegen skill. Used for the calendar Flower decoration and its selector. Alpha transparency is preserved. Existing Material UI icons remain code-native for consistency and accessibility.

Final generation prompt:

> Use case: illustration-story. Asset type: one tiny decorative calendar sticker for a pastel scrapbook journaling app. Primary request: a single simple five-petal cream jasmine blossom, small warm yellow center and two muted sage leaves, soft lavender thin outline, polished hand-painted paper sticker aesthetic. Composition: centered isolated blossom, compact silhouette readable at 16 to 24 pixels, no extra motifs, no frame, no text, no watermark. Truly transparent background. Palette cream, sage, pale lavender. This is decorative artwork, not an interactive control or app screenshot.

The character is rendered through `JournalCharacter` with aspect ratio preserved and bounded decoding. The flower is rendered through `CalendarSticker`, with the surrounding day or selector providing accessible meaning. No journal photos or personal content were generated.
