# Hackey-Patterns

A LUA sequencer plugin for REAPER 5.x and up. Designed to mimick the pattern sequencer in Jeskola Buzz.

![Hackey Pattern in Action](https://i.imgur.com/2g22kvU.gif)

Warning: This plugin is still in BETA. Use entirely at your own risk! Remember to save often and under different filenames!

## Installation
### With Reapack
Add it in your Reapack repository list: `https://raw.githubusercontent.com/joepvanlier/Hackey-Patterns/master/index.xml`.

### Without
- Press `?` or select `Actions > Action List`
- click the ReaScript: `Load` button

### Install SWS extensions
Hackey Patterns require the SWS extensions for REAPER, which can be found here: `http://www.sws-extension.org/`

## Notes
While not ideal, Hackey Patterns stores the pattern pool at a time point late in the project. You can add items to the pool here, or just place them in the project 
area itself.

## Usage
Hackey Patterns provides an alternative to the sequencer (arrange view) in REAPER. Modelled after Jeskola Buzz, it indexes MIDI items as patterns. 
Once copied to the pool (this happens automatically) these patterns can be placed. Placing the pattern generates pooled copies.

Navigation can be performed by mouse or keyboard. Pressing ENTER (in the default keymap) opens up Hackey Trackey on that pattern. Double-clicking a pattern 
amounts to the same action. A pattern can be made unique by clicking with the middle mouse button and renamed with outer mouse button. Patterns can be terminated 
early by placing OFF symbols. A track can be renamed using the outer mouse button. Clicking on the row numbers moves the play position to that location.

## Keyboard shortcuts

  | Key                                   | Action                                                                |
  |:--------------------------------------|:----------------------------------------------------------------------|
  | Arrow keys                            | Navigate                                                              |
  | Backspace                             | Delete item and shift rows up                                         |
  | Del                                   | Delete item                                                           |
  | Insert                                | Shift all items down by one                                           |
  | Ctrl + Backspace                      | Delete row and shift rows up                                          |
  | Ctrl + Del                            | Delete row                                                            |    
  | Ctrl + Insert                         | Shift row down by one                                                 |
  | \-                                    | Place note OFF                                                        |
  | S                                     | Split pattern                                                         |
  |                                       |                                                                       |  
  | Shift + +/\-                          | Zoom in/out                                                           |    
  | Space                                 | Toggle play status                                                    |  
  | Enter                                 | Open Hackey Trackey on pattern under cursor                           |  
  | CTRL \+ Q                             | Set loop start before current row                                     |
  | CTRL \+ W                             | Set loop end after current row                                        |
  | F11                                   | Switch theme                                                          |
  | F12                                   | Panic (MIDI reset)                                                    |
  | CTRL + N                              | Rename pattern under cursor                                           |
  |                                       |                                                                       |
  | CTRL + S                              | Save Project                                                          |
  | CTRL + Z                              | Undo                                                                  |
  | CTRL + Shift + Z                      | Redo                                                                  |
  |                                       |                                                                       |
  | CTRL + C                              | Copy block                                                            |
  | CTRL + V                              | Paste block                                                           |
  | CTRL + X                              | Cut block                                                             |
  | Shift + Del                           | Delete block                                                          |


