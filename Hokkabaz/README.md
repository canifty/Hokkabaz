# Sound Canvas

An interactive musical drawing app that combines visual art with instrumental sounds.

## Features

- Draw with colors to create music using sound visualizations
- Each color represents a different musical note
- Play back your musical creations
- Customize the app's appearance with different themes
- Export your artwork to share with others

## Important: Sound Setup

This app is designed to use different instrument sounds through soundfonts, but there are API compaibility issues with the current AudioKit version. Here are your options:

### Basic Usage (Available Now)

Without any additional setup, the app will use a single piano sound for all colors. The app is fully functional but has limited instrument variety.

### Adding a Soundfont (For Full Instrument Variety)

To enable multiple instruments, you'll need to add a soundfont file:

1. Download a General MIDI soundfont:
   - "GeneralUser GS" from: https://schristiancollins.com/generaluser.php
   - Make sure to download the SF2 version

2. Add the soundfont to your Xcode project:
   - Drag the `.sf2` file into your Xcode project navigator
   - When prompted, check "Copy items if needed"
   - Add to your target
   - **The filename MUST be exactly "GeneralUser GS.sf2"** (rename if necessary)
   - Check that it appears in your Target's "Copy Bundle Resources" build phase

3. Build and run the app.
   - If successful, you should see the message "Loaded bundled soundfont" in the console

### Technical Issues

The current version has some API compatibility issues with instrument selection:

- The app can load the soundfont but cannot switch between instruments
- You'll need to update the AudioKit implementation to enable full instrument switching
- If you'd like guidance on implementing this, see the AudioKit documentation and samples

## Colors and Notes

Each color represents a different musical note:

- Red: C note (Piano)
- Orange: D note (Guitar sound - if soundfont is available)
- Yellow: E note (Flute sound - if soundfont is available)
- Green: F note (Violin sound - if soundfont is available)
- Blue: G note (Trumpet sound - if soundfont is available)
- Purple: A note (Harp sound - if soundfont is available)
- Pink: B note (Cello sound - if soundfont is available)

## How to Use

1. Select a color from the palette at the bottom
2. Draw on the canvas to play the corresponding sound
3. Use the control panel to clear, replay, or export your creation
4. Hide the control panel using the indicator at the top for more drawing space
5. Access settings to change themes and stroke width

## Requirements

- iOS 15.0 or later
- Xcode 13 or later
- Swift 5.5 or later
- AudioKit 5.0 or later

## Credits

- Uses AudioKit for sound generation
- Soundfont capabilities provided by AppleSampler 