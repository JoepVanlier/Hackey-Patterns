--[[
@description Hackey-Patterns: An interface plugin for REAPER 5.x and up designed to mimick the sequencer in Jeskola Buzz.
@author: Joep Vanlier
@links
  https://github.com/JoepVanlier/Hackey-Patterns
@license MIT
@version 0.15
@about 
  ### Hackey-Patterns
  #### What is it?
  A lightweight sequencer plugin for REAPER 5.x and up.
  
  Usage
  Hackey Patterns provides an alternative way for visualizing and manipulating timeline in REAPER.
  
  WARNING: THIS PLUGIN IS INCOMPLETE AND NOT READY FOR USE
  
  If you use this plugin and enjoy it let me/others know. If you run into any bugs
  and figure out a way to reproduce them, please open an issue on the plugin's
  github page [here](https://github.com/JoepVanlier/Hackey-Trackey/issues). I would
  greatly appreciate it!
  
  Happy sequencin' :)
--]]

--[[
 * Changelog:
 * v0.15 (2018-10-06)
   + Zero is zero ;)
   + Added play from / play toggle.
   + Display current play position.
   + Added looping commands (CTRL + Q/W in default layout).
 * v0.14 (2018-10-06)
   + Middle mouse uniqueifies a pattern (un-ghost/un-pool).
 * v0.13 (2018-10-06)
   + Added MUTE/SOLO options.
   + Improved rendering (no lines in continuous items.
   + Show non-MIDI media items in a different color.
   + Added track renaming (outer mouse click).
   + Added pattern renaming (outer mouse click).
   + Added drag clipboard (no actual clipboard functionality available yet).
 * v0.12 (2018-10-04)
   + Worked on pattern renaming.
   + Started work on mouse actions.
 * v0.11 (2018-10-03)
   + Worked on automation.
 * v0.10 (2018-10-03)
   + Fix y scrolling issue.
 * v0.09 (2018-10-03)
   + Worked more on automation integration.
 * v0.08 (2018-10-03)
   + Added mending to insert operator.
 * v0.07 (2018-10-03)
   + Added mending to backspace operator.
 * v0.06 (2018-10-03)
   + Stretch last media item (mending).
   + Started work on processing automation properly.
 * v0.05 (2018-10-03)
   + Started work on add pattern functionality. Still have to make sure that when patterns are deleted, the media item adjacent is also stretched to fill up the space.
 * v0.04 (2018-10-02)
   + Added insert and delete functionality.
 * v0.03 (2018-10-01)
   + Made patterns per track rather than per project.
 * v0.02 (2018-10-01)
   + Started adding navigation / clipboard stuff. No editing possible yet.
 * v0.01 (2018-08-03)
   + First upload.
--]]

-- Depends on SWS for:
--   reaper.BR_GetMidiTakePoolGUID

-- 41072 => Paste pooled

scriptName = "Hackey Patterns v0.15"
postMusic = 500

seq             = {}
seq.fov         = {}
seq.fov.scrollx = 0
seq.fov.scrolly = 0
seq.fov.width   = 6
seq.fov.height  = 6
seq.xpos        = 0
seq.ypos        = 0
seq.res         = 16
seq.patterns    = {}
seq.renaming    = 0

seq.posList = {}

seq.cfg = {}
seq.cfg.nChars        = 9
seq.cfg.nameSize      = 180
seq.cfg.page          = 4
seq.cfg.automation    = 1

seq.advance       = 1

seq.cfg.zoom      = 1

seq.cp = {}
seq.cp.lastShiftCoord = nil
seq.cp.xstart = -1
seq.cp.ystart = -1
seq.cp.xstop = -1
seq.cp.ystop = -1
seq.cp.all = 0

seq.chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

function initCharMap()
  seq.charCodes = {}
  local j = 0
  for i=47,56 do
    seq.charCodes[i] = j
    j = j + 1
  end
  for i=97,122 do
    seq.charCodes[i] = j
    j = j + 1
  end
  for i=65,90 do
    seq.charCodes[i] = j
    j = j + 1
  end  
end
initCharMap()

-- This block is straight up copied from the tracker for now. Will clean this up when the time comes.

-- Default when no config file is present
keysets = { "default", "buzz", "renoise" }
keys = {}

-- You can find the keycodes by setting printKeys to 1 and hitting any key.
function seq:loadKeys( keySet )
  local keyset = keySet or seq.cfg.keyset
  
  if keyset == "default" then
    --                    CTRL    ALT SHIFT Keycode
    keys.left           = { 0,    0,  0,    1818584692 }    -- <-
    keys.right          = { 0,    0,  0,    1919379572 }    -- ->
    keys.up             = { 0,    0,  0,    30064 }         -- /\
    keys.down           = { 0,    0,  0,    1685026670 }    -- \/
    keys.off            = { 0,    0,  0,    45 }            -- -
    keys.delete         = { 0,    0,  0,    6579564 }       -- Del
    keys.delete2        = { 0,    0,  0,    46 }            -- .
    keys.home           = { 0,    0,  0,    1752132965 }    -- Home
    keys.End            = { 0,    0,  0,    6647396 }       -- End
    keys.toggle         = { 0,    0,  0,    32 }            -- Space
    keys.playfrom       = { 0,    0,  0,    13 }            -- Enter
    keys.enter          = { 0,    0,  0,    13 }            -- Enter        
    keys.insert         = { 0,    0,  0,    6909555 }       -- Insert
    keys.remove         = { 0,    0,  0,    8 }             -- Backspace
    keys.pgup           = { 0,    0,  0,    1885828464 }    -- Page up
    keys.pgdown         = { 0,    0,  0,    1885824110 }    -- Page down
    keys.undo           = { 1,    0,  0,    26 }            -- CTRL + Z
    keys.redo           = { 1,    0,  1,    26 }            -- CTRL + SHIFT + Z
    keys.beginBlock     = { 1,    0,  0,    2 }             -- CTRL + B
    keys.endBlock       = { 1,    0,  0,    5 }             -- CTRL + E
    keys.cutBlock       = { 1,    0,  0,    24 }            -- CTRL + X
    keys.pasteBlock     = { 1,    0,  0,    22 }            -- CTRL + V
    keys.copyBlock      = { 1,    0,  0,    3 }             -- CTRL + C
    keys.shiftItemUp    = { 0,    0,  1,    43 }            -- SHIFT + Num pad +
    keys.shiftItemDown  = { 0,    0,  1,    45 }            -- SHIFT + Num pad -
    keys.scaleUp        = { 1,    1,  1,    267 }           -- CTRL + SHIFT + ALT + Num pad +
    keys.scaleDown      = { 1,    1,  1,    269 }           -- CTRL + SHIFT + ALT + Num pad -   
    keys.octaveup       = { 1,    0,  0,    30064 }         -- CTRL + /\
    keys.octavedown     = { 1,    0,  0,    1685026670 }    -- CTRL + \/
    keys.envshapeup     = { 1,    0,  1,    30064 }         -- CTRL + SHIFT + /\
    keys.envshapedown   = { 1,    0,  1,    1685026670 }    -- CTRL + SHIFT + /\
    keys.help           = { 0,    0,  0,    26161 }         -- F1
    keys.outchandown    = { 0,    0,  0,    26162 }         -- F2
    keys.outchanup      = { 0,    0,  0,    26163 }         -- F3
    keys.advancedown    = { 0,    0,  0,    26164 }         -- F4
    keys.advanceup      = { 0,    0,  0,    26165 }         -- F5
    keys.stop2          = { 0,    0,  0,    26168 }         -- F8
    keys.harmony        = { 0,    0,  0,    26169 }         -- F9
    keys.options        = { 0,    0,  0,    6697265 }       -- F11    
    keys.panic          = { 0,    0,  0,    6697266 }       -- F12
    keys.setloop        = { 1,    0,  0,    12 }            -- CTRL + L
    keys.setloopstart   = { 1,    0,  0,    17 }            -- CTRL + Q
    keys.setloopend     = { 1,    0,  0,    23 }            -- CTRL + W
    keys.interpolate    = { 1,    0,  0,    9 }             -- CTRL + I
    keys.shiftleft      = { 0,    0,  1,    1818584692 }    -- Shift + <-
    keys.shiftright     = { 0,    0,  1,    1919379572 }    -- Shift + ->
    keys.shiftup        = { 0,    0,  1,    30064 }         -- Shift + /\
    keys.shiftdown      = { 0,    0,  1,    1685026670 }    -- Shift + \/
    keys.deleteBlock    = { 0,    0,  1,    6579564 }       -- Shift + Del
    keys.resolutionUp   = { 0,    1,  1,    30064 }         -- SHIFT + Alt + Up
    keys.resolutionDown = { 0,    1,  1,    1685026670 }    -- SHIFT + Alt + Down
    keys.commit         = { 0,    1,  1,    13 }            -- SHIFT + Alt + Enter
    keys.nextMIDI       = { 1,    0,  0,    1919379572.0 }  -- CTRL + ->
    keys.prevMIDI       = { 1,    0,  0,    1818584692.0 }  -- CTRL + <-
    keys.duplicate      = { 1,    0,  0,    4 }             -- CTRL + D
    keys.rename         = { 1,    0,  0,    14 }            -- CTRL + N
    keys.escape         = { 0,    0,  0,    27 }            -- Escape
    keys.toggleRec      = { 1,    0,  0,    18 }            -- CTRL + R
    keys.showMore       = { 1,    0,  0,    11 }            -- CTRL + +
    keys.showLess       = { 1,    0,  0,    13 }            -- CTRL + -
    keys.addCol         = { 1,    0,  1,    11 }            -- CTRL + Shift + +
    keys.remCol         = { 1,    0,  1,    13 }            -- CTRL + Shift + -
    keys.addColAll      = { 1,    0,  1,    1 }             -- CTRL + Shift + A
    keys.addPatchSelect = { 1,    0,  1,    16 }            -- CTRL + Shift + P
    keys.tab            = { 0,    0,  0,    9 }             -- Tab
    keys.shifttab       = { 0,    0,  1,    9 }             -- SHIFT + Tab
    keys.follow         = { 1,    0,  0,    6 }             -- CTRL + F
    keys.deleteRow      = { 1,    0,  0,    6579564 }       -- Ctrl + Del
    keys.closeTracker   = { 1,    0,  0,    6697266 }       -- Ctrl + F12
    keys.nextTrack      = { 1,    0,  1,    1919379572.0 }  -- CTRL + Shift + ->
    keys.prevTrack      = { 1,    0,  1,    1818584692.0 }  -- CTRL + Shift + <-
    
    keys.insertRow      = { 1,    0,  0,    6909555 }       -- Insert row CTRL+Ins
    keys.removeRow      = { 1,    0,  0,    8 }             -- Remove Row CTRL+Backspace
    keys.wrapDown       = { 1,    0,  1,    6909555 }       -- CTRL + SHIFT + Ins
    keys.wrapUp         = { 1,    0,  1,    8 }             -- CTRL + SHIFT + Backspace    
    
    keys.m0             = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.m25            = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.m50            = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.m75            = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.off2           = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned    
    keys.renoiseplay    = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shpatdown      = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shpatup        = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shcoldown      = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shcolup        = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shblockdown    = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shblockup      = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned    
    
    keys.cutPattern     = { 1,    0,  0,    500000000000000000000000 }
    keys.cutColumn      = { 1,    0,  1,    500000000000000000000000 }
    keys.cutBlock2      = { 1,    1,  0,    500000000000000000000000 }
    keys.copyPattern    = { 1,    0,  0,    500000000000000000000000 }
    keys.copyColumn     = { 1,    0,  1,    500000000000000000000000 }
    keys.copyBlock2     = { 1,    1,  0,    500000000000000000000000 }
    keys.pastePattern   = { 1,    0,  0,    500000000000000000000000 }
    keys.pasteColumn    = { 1,    0,  1,    500000000000000000000000 }
    keys.pasteBlock2    = { 1,    1,  0,    500000000000000000000000 }
    keys.patternOctDown = { 1,    0,  0,    500000000000000000000000.0 }
    keys.patternOctUp   = { 1,    0,  0,    500000000000000000000000.0 }
    keys.colOctDown     = { 1,    0,  1,    500000000000000000000000.0 }
    keys.colOctUp       = { 1,    0,  1,    500000000000000000000000.0 }
    keys.blockOctDown   = { 1,    1,  0,    500000000000000000000000.0 }
    keys.blockOctUp     = { 1,    1,  0,    500000000000000000000000.0 }
    
    keys.shiftpgdn      = { 0,    0,  1,    1885824110 }    -- Shift + PgDn
    keys.shiftpgup      = { 0,    0,  1,    1885828464 }    -- Shift + PgUp
    keys.shifthome      = { 0,    0,  1,    1752132965 }    -- Shift + Home
    keys.shiftend       = { 0,    0,  1,    6647396 }       -- Shift + End
    
    help = {
      { 'Shift + Note', 'Advance column after entry' },
      { 'Insert/Backspace/-', 'Insert/Remove/Note OFF' },   
      { 'CTRL + Insert/Backspace', 'Insert Row/Remove Row' },
      { 'CTRL + Shift + Ins/Bksp', 'Wrap Forward/Backward' },
      { 'Del/.', 'Delete' }, 
      { 'Space/Return', 'Play/Play From' },
      { 'CTRL + L', 'Loop pattern' },
      { 'CTRL + Q/W', 'Loop start/end' },
      { 'Shift + +/-', 'Transpose selection' },
      { 'CTRL + B/E', 'Selection begin/End' },
      { 'SHIFT + Arrow Keys', 'Block selection' },
      { 'CTRL + C/X/V', 'Copy / Cut / Paste' },
      { 'CTRL + I', 'Interpolate' },
      { 'Shift + Del', 'Delete block' },
      { 'CTRL + (SHIFT) + Z', 'Undo / Redo' }, 
      { 'SHIFT + Alt + Up/Down', '[Res]olution Up/Down' },
      { 'SHIFT + Alt + Enter', '[Res]olution Commit' },  
      { 'CTRL + Up/Down', '[Oct]ave up/down' },
      { 'CTRL + Shift + Up/Down', '[Env]elope change' },
      { 'F4/F5', '[Adv]ance De/Increase' },
      { 'F2/F3', 'MIDI [out] down/up' },
      { 'F8/F11/F12', 'Stop / Options / Panic' },
      { 'CTRL + Left/Right', 'Switch MIDI item/track' },   
      { 'CTRL + Shift + Left/Right', 'Switch Track' },         
      { 'CTRL + D', 'Duplicate pattern' },
      { 'CTRL + N', 'Rename pattern' },
      { 'CTRL + R', 'Play notes' },
      { 'CTRL + +/-', 'Advanced col options' },
      { 'CTRL + Shift + +/-', 'Add CC (adv mode)' },
      { 'CTRL + Shift + A/P', 'Per channel CC/PC' },
      { '', '' },
      { 'Harmony helper', '' },      
      { 'F9', 'Toggle harmonizer' },
      { 'CTRL + Click', 'Insert chord' },
      { 'Alt', 'Invert first note' },
      { 'Shift', 'Invert second note' },
      { 'CTRL + Shift + Alt + +/-', 'Shift root note' },
    }
    
  elseif keyset == "buzz" then
    --                    CTRL    ALT SHIFT Keycode
    keys.left           = { 0,    0,  0,    1818584692 }    -- <-
    keys.right          = { 0,    0,  0,    1919379572 }    -- ->
    keys.up             = { 0,    0,  0,    30064 }         -- /\
    keys.down           = { 0,    0,  0,    1685026670 }    -- \/
    keys.off            = { 0,    0,  0,    96 }            -- ` (should be 1 but whatever)
    keys.delete         = { 0,    0,  0,    6579564 }       -- Del
    keys.delete2        = { 0,    0,  0,    46 }            -- .
    keys.home           = { 0,    0,  0,    1752132965 }    -- Home
    keys.End            = { 0,    0,  0,    6647396 }       -- End
    keys.enter          = { 0,    0,  0,    13 }            -- Enter        
    keys.toggle         = { 0,    0,  0,    26165 }         -- f5 = play/pause
    keys.playfrom       = { 0,    0,  0,    26166 }         -- f6 = play here 
    keys.stop2          = { 0,    0,  0,    26168 }         -- f8 = Stop
    keys.harmony        = { 0,    0,  0,    26169 }         -- f9 = Harmony helper
    keys.options        = { 0,    0,  0,    6697265 }       -- f11 = Options
    keys.panic          = { 0,    0,  0,    6697266 }       -- f12 = MIDI Panic!
    keys.insert         = { 0,    0,  0,    6909555 }       -- Insert
    keys.remove         = { 0,    0,  0,    8 }             -- Backspace
    keys.pgup           = { 0,    0,  0,    1885828464 }    -- Page up
    keys.pgdown         = { 0,    0,  0,    1885824110 }    -- Page down
    keys.undo           = { 1,    0,  0,    26 }            -- CTRL + Z
    keys.redo           = { 1,    0,  1,    26 }            -- CTRL + SHIFT + Z
    keys.beginBlock     = { 1,    0,  0,    2 }             -- CTRL + B
    keys.endBlock       = { 1,    0,  0,    5 }             -- CTRL + E
    keys.cutBlock       = { 1,    0,  0,    24 }            -- CTRL + X
    keys.pasteBlock     = { 1,    0,  0,    22 }            -- CTRL + V
    keys.copyBlock      = { 1,    0,  0,    3 }             -- CTRL + C
    keys.shiftItemUp    = { 0,    0,  1,    43 }            -- SHIFT + Num pad+
    keys.shiftItemDown  = { 0,    0,  1,    45 }            -- SHIFT + Num pad-
    keys.octaveup       = { 0,    0,  0,    42 }            -- *
    keys.octavedown     = { 0,    0,  0,    47 }            -- /
    keys.scaleUp        = { 1,    1,  1,    267 }           -- CTRL + SHIFT + ALT + Num pad +
    keys.scaleDown      = { 1,    1,  1,    269 }           -- CTRL + SHIFT + ALT + Num pad -    
    keys.envshapeup     = { 1,    0,  1,    30064 }         -- CTRL + SHIFT + /\
    keys.envshapedown   = { 1,    0,  1,    1685026670 }    -- CTRL + SHIFT + /\
    keys.help           = { 0,    0,  0,    26161 }         -- F1
    keys.outchanup      = { 1,    0,  0,    30064 }         -- CTRL + UP   (Buzz = next instrument)
    keys.outchandown    = { 1,    0,  0,    1685026670 }    -- CTRL + DOWN (Buzz = prev instrument)
    keys.advancedown    = { 1,    0,  0,    26161 }         -- CTRL + F1 (in Buzz CTRL + -1 = sets step to 1, but that didn't work here)
    keys.advanceup      = { 1,    0,  0,    26162 }         -- CTRL + F2 (in Buzz CTRL + 2 = sets step to 2, but that didn't work here)
    keys.setloop        = { 1,    0,  0,    12 }            -- CTRL + L (no equiv, would be done in F4 seq view)
    keys.setloopstart   = { 1,    0,  0,    17 }            -- CTRL + Q (ditto)
    keys.setloopend     = { 1,    0,  0,    23 }            -- CTRL + W (ditto)
    keys.interpolate    = { 1,    0,  0,    9 }             -- CTRL + I
    keys.shiftleft      = { 0,    0,  1,    1818584692 }    -- Shift + <-
    keys.shiftright     = { 0,    0,  1,    1919379572 }    -- Shift + ->
    keys.shiftup        = { 0,    0,  1,    30064 }         -- Shift + /\
    keys.shiftdown      = { 0,    0,  1,    1685026670 }    -- Shift + \/
    keys.deleteBlock    = { 0,    0,  1,    6579564 }       -- Shift + Del
    keys.resolutionUp   = { 0,    1,  1,    30064 }         -- SHIFT + Alt + Up    (no equiv, would be set in pattern properties)
    keys.resolutionDown = { 0,    1,  1,    1685026670 }    -- SHIFT + Alt + Down  (ditto)
    keys.commit         = { 0,    1,  1,    13 }            -- SHIFT + Alt + Enter (ditto)
    keys.nextMIDI       = { 0,    0,  0,    43 }            -- +
    keys.prevMIDI       = { 0,    0,  0,    45 }            -- -
    keys.duplicate      = { 1,    0,  1,    13 }            -- CTRL + Shift + Return = create copy
    keys.rename         = { 1,    0,  0,    8 }             -- CTRL + Backspace = pattern properties (where name is set)
    keys.escape         = { 0,    0,  0,    27 }            -- Escape
    keys.toggleRec      = { 0,    0,  0,    26167 }         -- f7 = record ...I wanted ALT + N = Play _N_otes, but it didn't work ¯\_(ツ)_/¯
    keys.showMore       = { 1,    0,  0,    11 }            -- CTRL + +
    keys.showLess       = { 1,    0,  0,    13 }            -- CTRL + -
    keys.addCol         = { 1,    0,  1,    11 }            -- CTRL + Shift + +
    keys.remCol         = { 1,    0,  1,    13 }            -- CTRL + Shift + -
    keys.tab            = { 0,    0,  0,    9 }             -- Tab
    keys.shifttab       = { 0,    0,  1,    9 }             -- SHIFT + Tab
    keys.follow         = { 1,    0,  0,    6 }             -- CTRL + F    
    keys.deleteRow      = { 1,    0,  0,    6579564 }       -- Ctrl + Del
    keys.addColAll      = { 1,    0,  1,    1 }             -- CTRL + Shift + A
    keys.addPatchSelect = { 1,    0,  1,    16 }            -- CTRL + Shift + P    
    keys.nextTrack      = { 1,    0,  1,    1919379572.0 }  -- CTRL + Shift + ->
    keys.prevTrack      = { 1,    0,  1,    1818584692.0 }  -- CTRL + Shift + <-
    
    keys.insertRow      = { 1,    1,  0,    6909555 }       -- Insert row CTRL+Alt+Ins
    keys.removeRow      = { 1,    1,  0,    8 }             -- Remove Row CTRL+Alt+Backspace
    keys.wrapDown       = { 1,    0,  1,    6909555 }       -- CTRL + SHIFT + Ins
    keys.wrapUp         = { 1,    0,  1,    8 }             -- CTRL + SHIFT + Backspace     
    
    keys.m0             = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.m25            = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.m50            = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.m75            = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.off2           = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.renoiseplay    = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shpatdown      = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shpatup        = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shcoldown      = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shcolup        = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shblockdown    = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.shblockup      = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned    
    
    keys.cutPattern     = { 1,    0,  0,    500000000000000000000000 }
    keys.cutColumn      = { 1,    0,  1,    500000000000000000000000 }
    keys.cutBlock2      = { 1,    1,  0,    500000000000000000000000 }
    keys.copyPattern    = { 1,    0,  0,    500000000000000000000000 }
    keys.copyColumn     = { 1,    0,  1,    500000000000000000000000 }
    keys.copyBlock2     = { 1,    1,  0,    500000000000000000000000 }
    keys.pastePattern   = { 1,    0,  0,    500000000000000000000000 }
    keys.pasteColumn    = { 1,    0,  1,    500000000000000000000000 }
    keys.pasteBlock2    = { 1,    1,  0,    500000000000000000000000 }
    keys.patternOctDown = { 1,    0,  0,    500000000000000000000000.0 }
    keys.patternOctUp   = { 1,    0,  0,    500000000000000000000000.0 }
    keys.colOctDown     = { 1,    0,  1,    500000000000000000000000.0 }
    keys.colOctUp       = { 1,    0,  1,    500000000000000000000000.0 }
    keys.blockOctDown   = { 1,    1,  0,    500000000000000000000000.0 }
    keys.blockOctUp     = { 1,    1,  0,    500000000000000000000000.0 }
    keys.closeTracker   = { 0,    0,  0,    500000000000000000000000 }      -- Unassigned
    keys.addColAll      = { 1,    0,  1,    1 }             -- CTRL + Shift + A
    keys.shiftpgdn      = { 0,    0,  1,    1885824110 }    -- Shift + PgDn
    keys.shiftpgup      = { 0,    0,  1,    1885828464 }    -- Shift + PgUp
    keys.shifthome      = { 0,    0,  1,    1752132965 }    -- Shift + Home
    keys.shiftend       = { 0,    0,  1,    6647396 }       -- Shift + End
    
    help = {
      { 'Shift + Note', 'Advance column after entry' },
      { '`', 'Note OFF' },
      { 'Insert/Backspace', 'Insert/Remove line' },   
      { 'CTRL + Alt + Insert/Backspace', 'Insert Row/Remove Row' },
      { 'CTRL + Shift + Insert/Backspace', 'Wrap Forward/Backward' },      
      { 'Del/.', 'Delete' }, 
      { 'F5/F6', 'Play/Play from here' },
      { 'F8/F11/F12', 'Stop / Options / Panic' },
      { 'CTRL + L', 'Loop pattern' },
      { 'CTRL + Q/W', 'Loop start/end' },
      { 'Shift + +/-', 'Transpose selection' },
      { 'CTRL + B/E', 'Selection Begin/End' },
      { 'SHIFT + Arrow Keys', 'Block selection' },
      { 'CTRL + C/X/V', 'Copy / Cut / Paste' },
      { 'CTRL + I', 'Interpolate' },
      { 'Shift + Del', 'Delete block' },
      { 'CTRL + (SHIFT) + Z', 'Undo / Redo' }, 
      { 'SHIFT + Alt + Up/Down', '[Res]olution Up/Down' },
      { 'SHIFT + Alt + Return', '[Res]olution Commit' },  
      { '*//', '[Oct]ave Up/Down' },     
      { 'CTRL + Shift + Up/Down', '[Env]elope change' },
      { 'CTRL + F1/F2', '[Adv]ance De/Increase' },
      { 'CTRL + Up/Down', 'MIDI [out] Up/Down' },  
      { '-/+', 'Switch MIDI item' },
      { 'CTRL + Shift + Left/Right', 'Switch track' },
      { 'CTRL + Shift + Return', 'Duplicate pattern' },
      { 'CTRL + Backspace', 'Rename pattern' },
      { 'F7', 'Toggle note play' },
      { 'CTRL + +/-', 'Advanced col options' },
      { 'CTRL + Shift + +/-', 'Add CC (adv mode)' },
      { 'CTRL + Shift + A/P', 'Per channel CC/PC' },
      { '', '' },
      { 'Harmony helper', '' },      
      { 'F9', 'Toggle harmonizer' },
      { 'CTRL + Click', 'Insert chord' },
      { 'Alt', 'Invert first note' },
      { 'Shift', 'Invert second note' },   
      { 'CTRL + Shift + Alt + +/-', 'Shift root note' },
    }
  elseif keyset == "renoise" then
    --                    CTRL    ALT SHIFT Keycode
    keys.left           = { 0,    0,  0,    1818584692 }    -- <-
    keys.right          = { 0,    0,  0,    1919379572 }    -- ->
    keys.up             = { 0,    0,  0,    30064 }         -- /\
    keys.down           = { 0,    0,  0,    1685026670 }    -- \/
    keys.off            = { 0,    0,  0,    92 }            -- Backslash (\) (temporary)
    keys.delete         = { 0,    0,  0,    500000000000000000000000 }        -- Not assigned
    keys.delete2        = { 0,    0,  0,    6579564 }       -- Del
    keys.home           = { 0,    0,  0,    1752132965 }    -- Home
    keys.End            = { 0,    0,  0,    6647396 }       -- End
    keys.enter          = { 0,    0,  0,    13 }            -- Enter        
    keys.renoiseplay    = { 0,    0,  0,    32 }            -- Play/pause (space)
    keys.playfrom       = { 0,    0,  1,    32 }            -- Shift + space
    keys.stop2          = { 0,    0,  0,    500000000000000000000000 }  -- Not assigned
    keys.harmony        = { 1,    0,  0,    8  }             -- ctrl+h harmony helper
    keys.options        = { 1,    0,  0,    15 }            -- ctrl+o options
    keys.panic          = { 0,    0,  0,    27 }            -- Escape = MIDI Panic!
    keys.insert         = { 0,    0,  0,    6909555 }       -- Insert
    keys.remove         = { 0,    0,  0,    8 }             -- Backspace
    keys.pgup           = { 0,    0,  0,    1885828464 }    -- Page up
    keys.pgdown         = { 0,    0,  0,    1885824110 }    -- Page down
    keys.m0             = { 0,    0,  0,    26169.0 }       -- F9
    keys.m25            = { 0,    0,  0,    6697264.0 }     -- F10
    keys.m50            = { 0,    0,  0,    6697265.0 }     -- F11
    keys.m75            = { 0,    0,  0,    6697266.0 }     -- F12
    keys.undo           = { 1,    0,  0,    26 }            -- CTRL + Z
    keys.redo           = { 1,    0,  1,    26 }            -- CTRL + SHIFT + Z
    keys.beginBlock     = { 1,    0,  0,    2 }             -- CTRL + B
    keys.endBlock       = { 1,    0,  0,    5 }             -- CTRL + E
    keys.cutBlock       = { 1,    0,  0,    24 }            -- CTRL + X
    keys.pasteBlock     = { 1,    0,  0,    22 }            -- CTRL + V
    keys.copyBlock      = { 1,    0,  0,    3 }             -- CTRL + C
    keys.shiftItemUp    = { 0,    0,  1,    43 }            -- SHIFT + Num pad+
    keys.shiftItemDown  = { 0,    0,  1,    45 }            -- SHIFT + Num pad-
    keys.octaveup       = { 0,    0,  0,    42 }            -- *
    keys.octavedown     = { 0,    0,  0,    47 }            -- /
    keys.scaleUp        = { 1,    1,  1,    267 }           -- CTRL + SHIFT + ALT + Num pad +
    keys.scaleDown      = { 1,    1,  1,    269 }           -- CTRL + SHIFT + ALT + Num pad -    
    keys.envshapeup     = { 1,    0,  1,    30064 }         -- CTRL + SHIFT + /\
    keys.envshapedown   = { 1,    0,  1,    1685026670 }    -- CTRL + SHIFT + /\
    keys.help           = { 0,    0,  0,    26161 }         -- F1
    keys.outchanup      = { 0,    0,  0,    43 }            -- +
    keys.outchandown    = { 0,    0,  0,    45 }            -- -
    keys.advancedown    = { 1,    0,  0,    13 }            -- CTRL + -
    keys.advanceup      = { 1,    0,  0,    11 }            -- CTRL + +
    keys.setloop        = { 0,    0,  0,    13 }            -- Enter
    keys.setloopstart   = { 1,    0,  0,    17 }            -- CTRL + Q (ditto)
    keys.setloopend     = { 1,    0,  0,    23 }            -- CTRL + W (ditto)
    keys.interpolate    = { 1,    0,  0,    9 }             -- CTRL + I
    keys.shiftleft      = { 0,    0,  1,    1818584692 }    -- Shift + <-
    keys.shiftright     = { 0,    0,  1,    1919379572 }    -- Shift + ->
    keys.shiftup        = { 0,    0,  1,    30064 }         -- Shift + /\
    keys.shiftdown      = { 0,    0,  1,    1685026670 }    -- Shift + \/
    keys.deleteBlock    = { 0,    0,  1,    6579564 }       -- Shift + Del
    keys.resolutionUp   = { 0,    1,  1,    30064 }         -- SHIFT + Alt + Up    (no equiv, would be set in pattern properties)
    keys.resolutionDown = { 0,    1,  1,    1685026670 }    -- SHIFT + Alt + Down  (ditto)
    keys.commit         = { 0,    1,  1,    13 }            -- SHIFT + Alt + Enter (ditto)
    keys.nextMIDI       = { 1,    0,  0,    1685026670.0 }  -- CTRL + /\
    keys.prevMIDI       = { 1,    0,  0,    30064.0 }       -- CTRL + \/
    keys.duplicate      = { 1,    0,  1,    13 }            -- CTRL + Shift + Return = create copy
    keys.rename         = { 1,    0,  1,    14 }            -- CTRL + SHIFT + N
    keys.escape         = { 0,    0,  0,    27 }            -- Escape
    keys.toggleRec      = { 1,    0,  0,    18 }            -- CTRL + N
    keys.showMore       = { 1,    1,  0,    267 }           -- CTRL + Alt + +
    keys.showLess       = { 1,    1,  0,    269 }           -- CTRL + Alt + -
    keys.addCol         = { 1,    0,  1,    11 }            -- CTRL + Shift + +
    keys.remCol         = { 1,    0,  1,    13 }            -- CTRL + Shift + -
    keys.addColAll      = { 1,    0,  1,    1 }             -- CTRL + Shift + A
    keys.addPatchSelect = { 1,    0,  1,    16 }            -- CTRL + Shift + P
    keys.tab            = { 0,    0,  0,    9 }             -- Tab
    keys.shifttab       = { 0,    0,  1,    9 }             -- SHIFT + Tab
    keys.follow         = { 1,    0,  0,    6 }             -- CTRL + F
    
    keys.off2           = { 0,    0,  0,    97 }            -- A
    
    keys.shpatdown      = { 1,    0,  0,    26161 }         -- CTRL + F1
    keys.shpatup        = { 1,    0,  0,    26162 }         -- CTRL + F2
    keys.shcoldown      = { 1,    0,  1,    26161 }         -- CTRL + SHIFT + F1
    keys.shcolup        = { 1,    0,  1,    26162 }         -- CTRL + SHIFT + F2
    keys.shblockdown    = { 1,    1,  0,    26161 }         -- CTRL + ALT  + F1      same as shiftItemDown
    keys.shblockup      = { 1,    1,  0,    26162 }         -- CTRL + ALT  + F2      same as shiftItemUp
    
    keys.cutPattern     = { 1,    0,  0,    26163 }         -- CTRL + F3
    keys.cutColumn      = { 1,    0,  1,    26163 }         -- CTRL + SHIFT + F3
    keys.cutBlock2      = { 1,    1,  0,    26163 }         -- CTRL + ALT + F3
    
    keys.copyPattern    = { 1,    0,  0,    26164 }         -- CTRL + F4
    keys.copyColumn     = { 1,    0,  1,    26164 }         -- CTRL + SHIFT + F4
    keys.copyBlock2     = { 1,    1,  0,    26164 }         -- CTRL + ALT + F4

    keys.pastePattern   = { 1,    0,  0,    26165 }         -- CTRL + F5
    keys.pasteColumn    = { 1,    0,  1,    26165 }         -- CTRL + SHIFT + F5
    keys.pasteBlock2    = { 1,    1,  0,    26165 }         -- CTRL + ALT + F5
    
    keys.patternOctDown = { 1,    0,  0,    6697265.0 }     -- CTRL + F11
    keys.patternOctUp   = { 1,    0,  0,    6697266.0 }     -- CTRL + F12
    
    keys.colOctDown     = { 1,    0,  1,    6697265.0 }     -- CTRL + SHIFT + F11
    keys.colOctUp       = { 1,    0,  1,    6697266.0 }     -- CTRL + SHIFT + F12
    
    keys.blockOctDown   = { 1,    1,  0,    6697265.0 }     -- CTRL + ALT + F11
    keys.blockOctUp     = { 1,    1,  0,    6697266.0 }     -- CTRL + ALT + F12
    
    keys.deleteRow      = { 1,    0,  0,    6579564 }       -- Ctrl + Del
    
    keys.toggle         = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned    
    
    keys.shiftpgdn      = { 0,    0,  1,    1885824110 }    -- Shift + PgDn
    keys.shiftpgup      = { 0,    0,  1,    1885828464 }    -- Shift + PgUp
    keys.shifthome      = { 0,    0,  1,    1752132965 }    -- Shift + Home
    keys.shiftend       = { 0,    0,  1,    6647396 }       -- Shift + End
    
    keys.closeTracker   = { 0,    0,  0,    26168 }         -- F8
    
    keys.insertRow      = { 1,    0,  0,    6909555 }       -- Insert row CTRL+Ins
    keys.removeRow      = { 1,    0,  0,    8 }             -- Remove Row CTRL+Backspace
    keys.wrapDown       = { 1,    0,  1,    6909555 }       -- CTRL + SHIFT + Ins
    keys.wrapUp         = { 1,    0,  1,    8 }             -- CTRL + SHIFT + Backspace   
    
    keys.nextTrack      = { 1,    0,  1,    1919379572.0 }  -- CTRL + Shift + ->
    keys.prevTrack      = { 1,    0,  1,    1818584692.0 }  -- CTRL + Shift + <-
    
    help = {
      { 'Shift + Note', 'Advance column after entry' },
      { '\\ or A', 'Note OFF' },
      { 'Insert/Backspace', 'Insert/Remove line' },
      { 'CTRL + Insert/Backspace', 'Insert Row/Remove Row' },     
      { 'Del/Ctrl+Del', 'Delete/Delete Row' }, 
      { 'CTRL + Shift + Insert/Backspace', 'Wrap Forward/Backward' },      
      { 'Space/Shift+Space', 'Play / Play From' },
      { 'Ctrl + O / Escape', 'Options / Stop all notes' },
      { 'Enter', 'Loop pattern' },
      { 'CTRL + Q/W', 'Loop start/end' },
      { 'Shift + +/-', 'Transpose selection' },
      { 'CTRL + B/E', 'Selection Begin/End' },
      { 'SHIFT + Arrow Keys', 'Block selection' },
      { 'CTRL + C/X/V', 'Copy / Cut / Paste' },
      { 'CTRL + I', 'Interpolate' },
      { 'Shift + Del', 'Delete block' },
      { 'CTRL + (SHIFT) + Z', 'Undo / Redo' }, 
      { 'SHIFT + Alt + Up/Down', '[Res]olution Up/Down' },
      { 'SHIFT + Alt + Return', '[Res]olution Commit' },  
      { '*//', '[Oct]ave Up/Down' },     
      { 'CTRL + Shift + Up/Down', '[Env]elope change' },
      { 'CTRL + -/+ | SHIFT + -/=', '[Adv]ance De/Increase' },
      { '+/-', 'MIDI [out] Up/Down' },  
      { 'CTRL + Up/Down', 'Switch MIDI item' },
      { 'CTRL + Shift + Return', 'Duplicate pattern' },
      { 'CTRL + SHIFT + N', 'Rename pattern' },
      { 'CTRL + R', 'Toggle note play' },
      { 'CTRL + Alt + +/-', 'Advanced col options' },
      { 'CTRL + Shift + +/-', 'Add CC (adv mode)' },
      { 'F9/F10/F11/F12', 'Goto 0, 25, 50 and 75%%' },
      { 'F8', 'Close tracker' },
      { '---', '' },
      { 'CTRL + F1/F2', 'Shift pattern down/up' },
      { 'CTRL + Shift + F1/F2', 'Shift column down/up' },
      { 'CTRL + Alt + F1/F2', 'Shift block down/up' },
      { 'CTRL + F3/F4/F5', 'Cut/Copy/Paste pattern' },
      { 'CTRL + Shift + F3/F4/F5', 'Cut/Copy/Paste column' },
      { 'CTRL + Alt + F3/F4/F5', 'Cut/Copy/Paste block' },
      { 'CTRL + F11/F12', 'Pattern octave up' },
      { 'CTRL + Shift + F11/F12', 'Column octave up' },      
      { 'CTRL + Alt + F11/F12', 'Block octave up' },    
      { '---', '' },      
      { 'CTRL + H', 'Toggle harmonizer' },
      { 'CTRL + Click', 'Insert chord' },
      { 'Alt', 'Invert first note' },
      { 'Shift', 'Invert second note' },   
      { 'CTRL + Shift + Alt + +/-', 'Shift root note' },
    }    
  end
end

seq.colorschemes = {"default", "buzz", "it", "hacker", "renoise", "renoiseB"}
function seq:loadColors(colorScheme)
  -- If you come up with a cool alternative color scheme, let me know
  self.colors = {}
  self.colors.bar = {}
  self.colors.normal = {}
  self.colors.patternFont = nil
  self.colors.patternFontSize = nil
  local colorScheme = colorScheme or seq.cfg.colorscheme
  if colorScheme == "default" then
  -- default
    self.colors.helpcolor    = {.8, .8, .9, 1}
    self.colors.helpcolor2   = {.7, .7, .9, 1}
    self.colors.selectcolor  = {.6, 0, .6, 1}
    self.colors.textcolor    = {.7, .8, .8, 1}
    self.colors.headercolor  = {.5, .5, .8, 1}
    self.colors.inactive     = {.2, .2, .3, 1}    
    self.colors.linecolor    = {.1, .0, .4, .4}
    self.colors.linecolor2   = {.3, .0, .6, .4}
    self.colors.linecolor3   = {.4, .1, 1, 1}
    self.colors.linecolor4   = {.2, .0, 1, .5}
    self.colors.linecolor5   = {.3, .0, .6, .4}
    self.colors.loopcolor    = {.2, .3, .8, .5}
    self.colors.copypaste    = {5.0, .7, 0.1, .2}
    self.colors.scrollbar1   = {.2, .1, .6, 1.0}
    self.colors.scrollbar2   = {.1, .0, .3, 1.0}
    self.colors.changed      = {1.0, 0.1, 0.1, 1.0} 
    self.colors.changed2     = {0.0, 0.1, 1.0, .5} -- Only listening    
    self.colors.windowbackground = {0, 0, 0, 1}
    self.crtStrength         = 2
  elseif colorScheme == "hacker" then
    self.colors.helpcolor    = {0, .4, .2, 1}
    self.colors.helpcolor2   = {0, .7, .3, 1}
    self.colors.selectcolor  = {0, .3, 0, 1}
    self.colors.textcolor    = {0, .8, .4, 1}
    self.colors.textcolorbar = {0.05, 1.0, .7, 1}    
    self.colors.headercolor  = {0, .9, .5, 1}
    self.colors.inactive     = {0, .3, .1, 1}    
    self.colors.linecolor    = {0, .1, 0, .4}
    self.colors.linecolor2   = {0, .3, .2, .4}
    self.colors.linecolor3   = {0, .2, 0, 1}
    self.colors.linecolor4   = {0, .1, .1, .5}
    self.colors.linecolor5   = {0, .6, .5, .4}
    self.colors.loopcolor    = {0, .3, 0, .5}
    self.colors.copypaste    = {0, .7, .5, .2}
    self.colors.scrollbar1   = {0, .1, 0, 1.0}
    self.colors.scrollbar2   = {0, .0, 0, 1.0}
    self.colors.changed      = {.4,  1, .4, 1.0} 
    self.colors.changed2     = {.4,  .5, .4, .5} -- Only listening    
    self.colors.windowbackground = {0, 0, 0, 1}
    self.crtStrength         = 4
    self.colors.ellipsis     = 1
  elseif colorScheme == "buzz" then
    -- Buzz
    self.colors.helpcolor        = {1/256*159, 1/256*147, 1/256*115, 1} -- the functions
    self.colors.helpcolor2       = {1/256*48, 1/256*48, 1/256*33, 1} -- the keys
    self.colors.selectcolor      = {37/256, 41/256, 54/256, 1} -- the cursor
    self.colors.selecttext       = {207/256, 207/256, 222/256, 1} -- the cursor
    self.colors.textcolor        = {1/256*48, 1/256*48, 1/256*33, 1} -- main pattern data
    self.colors.headercolor      = {1/256*48, 1/256*48, 1/256*33, 1} -- column headers, statusbar etc
    self.colors.inactive         = {1/256*178, 1/256*174, 1/256*161, 1} -- column headers, statusbar etc    
    self.colors.linecolor        = {1/256*218, 1/256*214, 1/256*201, 0} -- normal row
    self.colors.linecolor2       = {1/256*181, 1/256*189, 1/256*158, 0.4} -- beats (must not have 100% alpha as it's drawn over the cursor(!))
    self.colors.linecolor3       = {1/256*159, 1/256*147, 1/256*115, 1} -- scroll indicating trangle thingy
    self.colors.linecolor4       = {1, 1, 0, 1} -- Reaper edit cursor
    self.colors.linecolor5       = {1/256*159*.4+218/256*.6, 1/256*147*.4+214/256*.6, 1/256*115*.4+201/256*.6, 1.0} -- Bar start
    self.colors.loopcolor        = {1/256*48, 1/256*48, 1/256*33, 1} -- lines surrounding loop
    self.colors.copypaste        = {1/256*247, 1/256*247, 1/256*244, 0.66}  -- the selection (should be lighter(not alpha blanded) but is drawn over the data)
    self.colors.scrollbar1       = {1/256*48, 1/256*48, 1/256*33, 1} -- scrollbar handle & outline
    self.colors.scrollbar2       = {1/256*218, 1/256*214, 1/256*201, 1} -- scrollbar background
    self.colors.changed          = {1, 1, 0, 1} -- Uncommited resolution changes
    self.colors.changed2         = {0, .5, 1, .5} -- Only listening
    self.colors.windowbackground = {1/256*218, 1/256*214, 1/256*201, 1}
    self.crtStrength             = .3
  elseif colorScheme == "it" then
    -- Reapulse Tracker (Impulse Tracker)
    self.colors.helpcolor        = {0, 0, 0, 1} -- the functions
    self.colors.helpcolor2       = {1/256*124, 1/256*88, 1/256*68, 1} -- the keys
    self.colors.selectcolor      = {1, 1, 1, 1} -- the cursor
    self.colors.textcolor        = {1, 1, 1, 1} --{1/256*60, 1/256*105, 1/256*59, 1} -- main pattern data (rows should all be darker & this should be green)
    self.colors.headercolor      = {0, 0, 0, 1} -- column headers, statusbar etc
    self.colors.inactive         = {.2, .2, .2, 1} -- column headers, statusbar etc    
    self.colors.linecolor        = {0,0,0, 0.6} -- normal row
    self.colors.linecolor2       = {1/256*52, 1/256*48, 1/256*44, 0.6} -- beats (must not have 100% alpha as it's drawn over the cursor(!))
    self.colors.linecolor3       = {1/256*180, 1/256*148, 1/256*120, 1} -- scroll indicating trangle thingy
    self.colors.linecolor4       = {1/256*204, 1/256*204, 1/256*68, 1} -- Reaper edit cursor
    self.colors.linecolor5       = {1/256*88, 1/256*64, 1/256*60, 0.6} -- Bar start
    self.colors.loopcolor        = {1/256*204, 1/256*204, 1/256*68, 1} -- lines surrounding loop
    self.colors.copypaste        = {1/256*24, 1/256*116, 1/256*44, 0.66}  -- the selection (should be lighter(not alpha blanded) but is drawn over the data)
    self.colors.scrollbar1       = {1/256*124, 1/256*88, 1/256*68, 1} -- scrollbar handle & outline
    self.colors.scrollbar2       = {1/256*180, 1/256*148, 1/256*120, 1} -- scrollbar background
    self.colors.changed          = {1, 1, 0, 1}
    self.colors.changed2         = {0, .5, 1, .5} -- Only listening
    self.colors.windowbackground = {1/256*180, 1/256*148, 1/256*120, 1}
    self.crtStrength             = .5
  elseif colorScheme == "renoise" then
    self.colors.ellipsis         = 1
    self.colors.harmonycolor     = {177/255, 171/255, 116/255, 1.0}
    self.colors.harmonyselect    = {183/255, 255/255, 191/255, 1.0}
    self.colors.helpcolor        = {243/255, 171/255, 116/255, 1.0} -- the functions
    self.colors.helpcolor2       = {178/256, 178/256, 178/256, 1} -- the keys
    self.colors.selectcolor      = {1, 234/256, 20/256, 1} -- the cursor
    self.colors.selecttext       = {0, 0, 0, 1} -- the cursor
    self.colors.textcolor        = {148/256, 148/256, 148/256, 1} --{1/256*60, 1/256*105, 1/256*59, 1} -- main pattern data (rows should all be darker & this should be green)
    self.colors.textcolorbar     = {1, 1, 1, 1}
    self.colors.headercolor      = {215/256, 215/256, 215/256, 1} -- column headers, statusbar etc
    self.colors.inactive         = {115/256, 115/256, 115/256, 1} -- column headers, statusbar etc    
    self.colors.linecolor        = {18/256,18/256,18/256, 0.6} -- normal row
    self.colors.linecolor2       = {1/256*55, 1/256*55, 1/256*55, 0.6} -- beats (must not have 100% alpha as it's drawn over the cursor(!))
    self.colors.linecolor3       = {1/256*180, 1/256*148, 1/256*120, 1} -- scroll indicating trangle thingy
    self.colors.linecolor4       = {1/256*204, 1/256*204, 1/256*68, 1} -- Reaper edit cursor
    self.colors.linecolor5       = {41/256, 41/256, 41/256, 1.0} -- Bar start
    self.colors.loopcolor        = {1/256*204, 1/256*204, 1/256*68, 1} -- lines surrounding loop
    self.colors.copypaste        = {1/256*57, 1/256*57, 1/256*20, 0.66}  -- the selection (should be lighter(not alpha blanded) but is drawn over the data)
    self.colors.scrollbar1       = {98/256, 98/256, 98/256, 1} -- scrollbar handle & outline
    self.colors.scrollbar2       = {19/256, 19/256, 19/256, 1} -- scrollbar background
    self.colors.changed          = {1, 1, 0, 1}
    self.colors.changed2         = {0, .5, 1, .5} -- Only listening
    self.colors.windowbackground = {18/256, 18/256, 18/256, 1}
    self.crtStrength             = 0   
    
    self.colors.normal.mod1      = {243/255, 171/255, 116/255, 1.0}
    self.colors.normal.mod2      = self.colors.normal.mod1
    self.colors.normal.mod3      = self.colors.normal.mod1
    self.colors.normal.mod4      = self.colors.normal.mod1
    self.colors.normal.modtxt1   = {243/255, 171/255, 116/255, 1.0}
    self.colors.normal.modtxt2   = self.colors.normal.modtxt1
    self.colors.normal.modtxt3   = self.colors.normal.modtxt1
    self.colors.normal.modtxt4   = self.colors.normal.modtxt1
    self.colors.normal.vel1      = {186/255, 185/255, 108/255, 1.0}
    self.colors.normal.vel2      = self.colors.normal.vel1
    self.colors.normal.delay1    = {123/255, 149/255, 197/255, 1.0}
    self.colors.normal.delay2    = self.colors.normal.delay1
    self.colors.normal.fx1       = {183/255, 255/255, 191/255, 1.0}
    self.colors.normal.fx2       = self.colors.normal.fx1
    self.colors.normal.end1      = {136/255, 80/255, 178/255, 1.0}
    self.colors.normal.end2      = self.colors.normal.end1
    
    self.colors.bar.mod1         = {255/255, 159/255, 88/255, 1.0}
    self.colors.bar.mod2         = self.colors.bar.mod1
    self.colors.bar.mod3         = self.colors.bar.mod1
    self.colors.bar.mod4         = self.colors.bar.mod1
    self.colors.bar.modtxt1      = {255/255, 159/255, 88/255, 1.0}
    self.colors.bar.modtxt2      = self.colors.bar.modtxt1
    self.colors.bar.modtxt3      = self.colors.bar.modtxt1
    self.colors.bar.modtxt4      = self.colors.bar.modtxt1
    self.colors.bar.vel1         = {171/255, 169/255, 77/255, 1.0}
    self.colors.bar.vel2         = self.colors.bar.vel1
    self.colors.bar.delay1       = {116/255, 162/255, 255/255, 1.0}
    self.colors.bar.delay2       = self.colors.bar.delay1    
    self.colors.bar.fx1          = {146/255, 255/255, 157/255, 1.0}
    self.colors.bar.fx2          = self.colors.normal.fx1   
    self.colors.bar.end1         = {136/255, 80/255, 178/255, 1.0}
    self.colors.bar.end2         = self.colors.bar.end1
  elseif colorScheme == "renoiseB" then
    self.colors.ellipsis         = 1
    self.colors.harmonycolor     = {177/255, 171/255, 116/255, 1.0}
    self.colors.harmonyselect    = {183/255, 255/255, 191/255, 1.0}
    self.colors.helpcolor        = {243/255, 171/255, 116/255, 1.0} -- the functions
    self.colors.helpcolor2       = {178/256, 178/256, 178/256, 1} -- the keys
    self.colors.selectcolor      = {1, 234/256, 20/256, 1} -- the cursor
    self.colors.selecttext       = {0, 0, 0, 1} -- the cursor
    self.colors.textcolor        = {148/256, 148/256, 148/256, 1} --{1/256*60, 1/256*105, 1/256*59, 1} -- main pattern data (rows should all be darker & this should be green)
    self.colors.textcolorbar     = {1, 1, 1, 1}
    self.colors.headercolor      = {215/256, 215/256, 215/256, 1} -- column headers, statusbar etc
    self.colors.inactive         = {115/256, 115/256, 115/256, 1} -- column headers, statusbar etc    
    self.colors.linecolor        = {18/256,18/256,18/256, 0.6} -- normal row
    self.colors.linecolor2       = {1/256*55, 1/256*55, 1/256*55, 0.6} -- beats (must not have 100% alpha as it's drawn over the cursor(!))
    self.colors.linecolor3       = {1/256*180, 1/256*148, 1/256*120, 1} -- scroll indicating trangle thingy
    self.colors.linecolor4       = {1/256*204, 1/256*204, 1/256*68, 1} -- Reaper edit cursor
    self.colors.linecolor5       = {41/256, 41/256, 41/256, 1.0} -- Bar start
    self.colors.loopcolor        = {1/256*204, 1/256*204, 1/256*68, 1} -- lines surrounding loop
    self.colors.copypaste        = {1/256*57, 1/256*57, 1/256*20, 0.66}  -- the selection (should be lighter(not alpha blanded) but is drawn over the data)
    self.colors.scrollbar1       = {98/256, 98/256, 98/256, 1} -- scrollbar handle & outline
    self.colors.scrollbar2       = {19/256, 19/256, 19/256, 1} -- scrollbar background
    self.colors.changed          = {1, 1, 0, 1}
    self.colors.changed2         = {0, .5, 1, .5} -- Only listening
    self.colors.windowbackground = {18/256, 18/256, 18/256, 1}
    self.crtStrength             = 0   
    
    self.colors.normal.mod1      = {243/255, 171/255, 116/255, 1.0}
    self.colors.normal.mod2      = self.colors.normal.mod1
    self.colors.normal.mod3      = self.colors.normal.mod1
    self.colors.normal.mod4      = self.colors.normal.mod1
    self.colors.normal.modtxt1   = {243/255, 171/255, 116/255, 1.0}
    self.colors.normal.modtxt2   = self.colors.normal.modtxt1
    self.colors.normal.modtxt3   = self.colors.normal.modtxt1
    self.colors.normal.modtxt4   = self.colors.normal.modtxt1
    self.colors.normal.vel1      = {186/255, 185/255, 108/255, 1.0}
    self.colors.normal.vel2      = self.colors.normal.vel1
    self.colors.normal.delay1    = {123/255, 149/255, 197/255, 1.0}
    self.colors.normal.delay2    = self.colors.normal.delay1
    self.colors.normal.fx1       = {183/255, 255/255, 191/255, 1.0}
    self.colors.normal.fx2       = self.colors.normal.fx1
    self.colors.normal.end1      = {136/255, 80/255, 178/255, 1.0}
    self.colors.normal.end2      = self.colors.normal.end1
    
    self.colors.bar.mod1         = {255/255, 159/255, 88/255, 1.0}
    self.colors.bar.mod2         = self.colors.bar.mod1
    self.colors.bar.mod3         = self.colors.bar.mod1
    self.colors.bar.mod4         = self.colors.bar.mod1
    self.colors.bar.modtxt1      = {255/255, 159/255, 88/255, 1.0}
    self.colors.bar.modtxt2      = self.colors.bar.modtxt1
    self.colors.bar.modtxt3      = self.colors.bar.modtxt1
    self.colors.bar.modtxt4      = self.colors.bar.modtxt1
    self.colors.bar.vel1         = {171/255, 169/255, 77/255, 1.0}
    self.colors.bar.vel2         = self.colors.bar.vel1
    self.colors.bar.delay1       = {116/255, 162/255, 255/255, 1.0}
    self.colors.bar.delay2       = self.colors.bar.delay1    
    self.colors.bar.fx1          = {146/255, 255/255, 157/255, 1.0}
    self.colors.bar.fx2          = self.colors.normal.fx1   
    self.colors.bar.end1         = {136/255, 80/255, 178/255, 1.0}
    self.colors.bar.end2         = self.colors.bar.end1
    
    
    self.colors.customFontDisplace  = { 8, -3 }
  end
  -- clear colour is in a different format
  gfx.clear = seq.colors.windowbackground[1]*256+(seq.colors.windowbackground[2]*256*256)+(seq.colors.windowbackground[3]*256*256*256)
  self.colors.red                 = {1, 0.4, 0.2, 0.4}
  self.colors.green               = {.7, 1.0, 0.4, 0.4}
  local mix                       = 0.5
  self.colors.linecolor6          = {self.colors.linecolor5[1]*mix+(1-mix)*(self.colors.windowbackground[1]), self.colors.linecolor5[2]*mix+(1-mix)*(self.colors.windowbackground[1]), self.colors.linecolor5[3]*mix+(1-mix)*(self.colors.windowbackground[2]), self.colors.linecolor5[4]}
       
  self.colors.patternFont         = "DejaVu Sans"
  self.colors.patternFontSize     = 12
  
  gfx.setfont(1, self.colors.patternFont, self.colors.patternFontSize)
  local w, h  = gfx.measurestr("X")
  self.cellw  = w * self.cfg.nChars
  self.cellh  = h
end

local function clamp( min, max, val )
  if ( val > max ) then
    return max
  elseif ( val < min ) then
    return min
  else
    return val
  end
end

local function print(...)
  if ( not ... ) then
    reaper.ShowConsoleMsg("nil value\n")
    return
  end
  reaper.ShowConsoleMsg(...)
  reaper.ShowConsoleMsg("\n")
end

local function fitStr( str, width )
  local w = 0
  local a = 0
  width = width - 10
  local nstr = #str
  
  while( a <= nstr ) do
    a = a + 1
    w = gfx.measurestr(str:sub(1,a))
    if ( w > width ) then
      break;
    end
  end
  
  return str:sub(1,a)
end

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent, maxindent, verbose)
  if ( not tbl ) then
    print( "nil" )
    return
  end
  if ( type(tbl) == "table" ) then 
    if not maxindent then maxindent = 2 end
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
      local formatting = string.rep(" ", indent) .. k .. ": "
      if type(v) == "table" then
        if ( indent < maxindent ) then
          print(formatting)
          tprint(v, indent+1, maxindent)
        end
      else
        -- Hide the functions in shared.lua for clarity
        if ( not verbose ) then
          if type(v) == 'boolean' then
            print(formatting .. tostring(v))
          elseif type(v) == 'number' then
            print(formatting .. tostring(v))
          else
            print(formatting .. tostring(v))
          end
        end
      end
    end
  else
    if ( type(tbl) == "function" ) then 
      print('Function supplied to tprint instead of table')
    end
  end
end 


-- Prep process
function seq:selectMediaItem(item)
  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(item, true)
end

function seq:uniqueMIDI(track, row)
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom

  --41613  Item: Remove active take from MIDI source data pool (AKA un-pool, un-ghost, make unique)
  reaper.SelectAllMediaItems(0, false)

  local cTrack = reaper.GetTrack(0, track)
  for i,v in pairs(trackItems) do
    if ( v[2] == cTrack ) then
      local pos = reaper.GetMediaItemInfo_Value( v[1], "D_POSITION" )
      if ( math.floor( pos / rps + 0.0001 ) == row ) then
        reaper.SetMediaItemInfo_Value( v[1], "B_UISEL", 1 )
      end
    end
  end
  
  reaper.Main_OnCommand(41613, 0) -- Unpool MIDI item
end

function seq:uniqueAutomation(track, row)
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local cTrack = reaper.GetTrack(0, track)

  -- Select only the automation items of interest.
  local selected
  if ( self.cfg.automation == 1 ) then
    for envIdx = 0,reaper.CountTrackEnvelopes(cTrack)-1 do
      local trackEnv = reaper.GetTrackEnvelope(cTrack, envIdx)
      for i=0,reaper.CountAutomationItems(trackEnv)-1 do
        local d_pos = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POSITION", 0, false)
        if ( math.floor( d_pos / rps + 0.0001 ) == row ) then
          reaper.Main_OnCommand(40769, 0) -- Deselect all items
          reaper.GetSetAutomationItemInfo(trackEnv, i, "D_UISEL", 1, true)
          reaper.SetEditCurPos2(0, d_pos, false, false)
          reaper.SetCursorContext(2, trackEnv)
--          reaper.Main_OnCommand(40699, 0) -- Cut items
          reaper.Main_OnCommand(40059, 0) -- Cut items
          reaper.Main_OnCommand(40058, 0) -- Paste items 
        end
      end
    end
  end
end

function seq:pushPosition()
  seq.posList[#seq.posList+1] = reaper.GetCursorPosition()
end

function seq:popPosition()
  reaper.SetEditCurPos2(0, seq.posList[#seq.posList], true, false)
  seq.posList[#seq.posList] = nil
end

function seq:uniqueifyElement(track, row)
  self:pushPosition()
  self:uniqueMIDI(track, row)
  self:uniqueAutomation(track, row)
  self:popPosition()
end

function seq:testWillBeUnique()
  
end

-- Find all MIDI items
function seq:fetchPatterns()
  poolGUIDs = {}
  trackItems = {}
  
  local c = 0
  local maxloc = {}
  for i=0,reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, i)
    maxloc[track] = postMusic
  end
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(mediaItem)
    local take = reaper.GetActiveTake(mediaItem)
    
    -- Is it a midi take?
    if ( reaper.TakeIsMIDI(take) ) then
      local retval, GUID = reaper.BR_GetMidiTakePoolGUID(take)
      
      local loc = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      if ( loc >= postMusic ) then
        poolGUIDs[GUID] = { mediaItem, track, take }
        if ( loc > maxloc[track] ) then
          maxloc[track] = loc
        end
      else
        trackItems[c] = { mediaItem, track, take, GUID }
        c = c + 1
      end
    end
  end
  
  self.poolGUIDs = poolGUIDs
  self.trackItems = trackItems
  self.maxloc = maxloc
end
  
function seq:copyUnknownToPool()
  local trackItems = self.trackItems
  local poolGUIDs = self.poolGUIDs
  
  self:pushPosition()

  -- Check if there are any that aren't in the pool yet.
  local maxloc = self.maxloc
  for i,v in pairs( trackItems ) do
    local GUID = v[4]
    if ( not poolGUIDs[GUID] ) then
      -- Duplicate these
      self:selectMediaItem(v[1])
      local cTrack = v[2]
      reaper.SetOnlyTrackSelected(cTrack)
      reaper.Main_OnCommand(40698, 0) -- Copy selected items
      reaper.SetEditCurPos2(0, maxloc[cTrack], false, false)
      reaper.Main_OnCommand(41072, 0) -- Paste pooled
      poolGUIDs[v[4]] = {v[1], cTrack, v[3]}
      if ( maxloc[cTrack] ) then
        local nloc = maxloc[cTrack] + reaper.GetMediaItemInfo_Value(v[1], "D_LENGTH")
        maxloc[cTrack] = nloc        
      end
      
      -- 40058 is paste, 41072 is paste pooled
    end
  end
  
  self.poolGUIDs = poolGUIDs
  self.maxloc = maxloc
  
  self:popPosition()
end

-- Index the GUID
function seq:buildPatternList()
  -- These tables should eventually be stored and loaded from the track
  local guidToPatternIdx  = {}
  local idxToGUID         = {}
  local patternNames      = {}
  local trackToIndex      = self.trackToIndex
  local nChars            = self.cfg.nChars
  local cellw             = self.cellw
  local nTracks           = reaper.CountTracks(0)
  
  local idx = {}
  for jTrack=0,nTracks-1 do
    idx[jTrack] = 1
    if ( not guidToPatternIdx[jTrack] ) then
      guidToPatternIdx[jTrack] = {}
      idxToGUID[jTrack] = {}
      patternNames[jTrack] = {}
    end
  end
  
  for i,v in pairs( self.poolGUIDs ) do
    trackidx = trackToIndex[v[2]]
    index = idx[trackidx]
  
    -- If it hasn't been seen, add it
    if ( not guidToPatternIdx[trackidx][i] ) then
      guidToPatternIdx[trackidx][i] = index
      idxToGUID[trackidx][index]    = i
      
      local str = reaper.GetTakeName(v[3])
      if ( str == "untitled MIDI item" ) then
        patternNames[trackidx][index] = string.format("%02d", index)
      else
        patternNames[trackidx][index] = fitStr( str, cellw ) --str:sub(1,nChars)
      end
       
      idx[trackidx] = idx[trackidx] + 1
    end
  end
  
  self.guidToPatternIdx = guidToPatternIdx
  self.idxToGUID        = idxToGUID
  self.patternNames     = patternNames
end

local function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  return script_path
end

function seq:loadConfig(fn, cfg)
    local file = io.open(get_script_path()..fn, "r")
    
    if ( file ) then
      io.input(file)
      local str = io.read()
      while ( str ) do
        for k, v in string.gmatch(str, "(%w+)=(%w+)") do
          local no = tonumber(v)
        
          if ( no ) then
            cfg[k] = no
          else
            cfg[k] = v
          end
        end
        str = io.read()
      end
      io.close(file)
    end    
    
    return cfg
end

function seq:saveConfig(fn, cfg) 
  tracker:saveConfigFile( fn, cfg )
end

function seq:saveConfigFile(fn, cfg)
  local dir = get_script_path()
  local filename = dir..fn
  local file = io.open(filename, "w+")
  
  if ( file ) then
    io.output(file)
    for i,v in pairs(cfg) do
      io.write( string.format('%s=%s\n', i, v) )
    end
    io.close(file)
  end
end

function seq:terminate()
  local d, x, y, w, h = gfx.dock(nil,1,1,1,1)
  seq:saveConfigFile("_wpos.cfg", {d=d, x=x, y=y, w=w, h=h})
  gfx.quit()
end

-- Fetch the track names and construct a table which has the tracks.
function seq:fetchTracks()
  local trackToIndex  = {}
  local trackTitles   = {}
  local cellw         = self.cellw
  local colors        = self.colors
  local nTracks       = self.max_xpos
  
  gfx.setfont(1, colors.patternFont, colors.patternFontSize)
  for i=0,nTracks-1 do
    local trk = reaper.GetTrack(0, i)
    local retval, str = reaper.GetSetMediaTrackInfo_String(trk, "P_NAME", "", false)
    if str == "" then
      trackTitles[i] = string.format("Track %02d", i)
    else
      trackTitles[i] = fitStr( str, cellw )  
    end
    trackToIndex[trk] = i
  end
  
  self.trackToIndex = trackToIndex
  self.trackTitles  = trackTitles  
end

function seq:populateSequencer()
  local patterns      = {}
  local trackToIndex  = self.trackToIndex
  
  -- Go over all the media items we found that weren't in the pool
  --   trackItems[i] = { mediaItem, track, take, GUID }
  --   guidToPatternIdx[i] = c
  for i=0,self.max_xpos-1 do
    patterns[i] = {}
  end
  local dy = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local guidToPatternIdx = self.guidToPatternIdx
  
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0,i)
    local trackIdx = trackToIndex[reaper.GetMediaItemTrack(mediaItem)]
    local pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")    
    local ystart = math.floor(pos/dy)
    local yend = math.ceil((pos+len)/dy)
    for q = ystart+1,yend-1 do
      patterns[trackIdx][q] = -2
    end
  end
  
  for i,v in pairs(self.trackItems) do
    local trackGUID = v[4]
    local pos = reaper.GetMediaItemInfo_Value(v[1], "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(v[1], "D_LENGTH")

    local ystart = math.floor(pos/dy)
    local yend = math.ceil((pos+len)/dy)
    local q = ystart
    local trackIdx = trackToIndex[v[2]]
    patterns[trackIdx][q] = guidToPatternIdx[trackIdx][trackGUID]
    for q = ystart+1,yend-1 do
      patterns[trackIdx][q] = -1
    end
  end
  
  self.patterns     = patterns
end

function seq:updateData()
  seq:computeSize()
  seq:fetchTracks()
  seq:fetchPatterns()
  seq:copyUnknownToPool()
  seq:buildPatternList()
  seq:populateSequencer()
end

local function triangle( xc, yc, size, ori )
    local gfx = gfx
    ori = ori or 1
    gfx.line(xc-size,yc-ori*size,xc,yc+ori*size)
    gfx.line(xc,yc+ori*size,xc+size,yc-ori*size)
    gfx.line(xc+size,yc-ori*size,xc-size,yc-ori*size)
end

function seq:updateGUI()
  local nTracks       = reaper.CountTracks(0)
  local patternNames  = self.patternNames
  local patterns      = self.patterns
  local trackTitles   = self.trackTitles
  local fov           = self.fov
  
  local xrel          = self.xpos - fov.scrollx
  local yrel          = self.ypos - fov.scrolly
  local width         = self.fov.width
  local height        = self.fov.height
  local colors        = self.colors
  local customFont    = colors.customFontDisplace
  
  local scrollx       = fov.scrollx
  local scrolly       = fov.scrolly
  
  local fw            = self.cellw
  local fh            = self.cellh
  local ymax          = fov.height

  local xOrigin       = 0
  local yOrigin       = 0
  gfx.setfont(1, colors.patternFont, colors.patternFontSize)
  
  local xStart = 0
  local xEnd = fov.width
  if ( xEnd > nTracks-1 ) then
    xEnd = nTracks-1
  end
  
  -- Draw headers
  local mm = .5*gfx.measurestr("M")
  local ms = .5*gfx.measurestr("S")  
  for ix=xStart,xEnd do
    local xl = xOrigin + fw*(ix+1)
    local cTrack = reaper.GetTrack( 0, ix+scrollx )
    gfx.x = xl + 4
    gfx.y = yOrigin
    if ( self.renaming == 2 and ix+scrollx == self.renameTrackIdx ) then
      gfx.set( table.unpack( colors.changed ) )
    else
      gfx.set( table.unpack( colors.textcolor ) )          
    end
    gfx.printf( "%s", trackTitles[ix+scrollx] )
    gfx.set( table.unpack( colors.textcolor ) )
        
    local muted = reaper.GetMediaTrackInfo_Value( cTrack, "B_MUTE" )
    local solo = reaper.GetMediaTrackInfo_Value( cTrack, "I_SOLO" );
    if ( muted == 1 ) then
      gfx.set( table.unpack( colors.red ) )
    else
      gfx.set( table.unpack( colors.inactive ) )
    end
    gfx.rect( xl, yOrigin + fh, .5*fw, fh )
    gfx.set( table.unpack( colors.textcolor ) )

    if ( solo == 1 ) then
      gfx.set( table.unpack( colors.green ) )
    else
      gfx.set( table.unpack( colors.inactive ) )
    end
    gfx.rect( xl + .5*fw, yOrigin + fh, .5*fw, fh )
    gfx.set( table.unpack( colors.textcolor ) )
    
    gfx.x = xl + 0.25 * fw - mm
    gfx.y = yOrigin+fh
    gfx.printf( "M" )
    gfx.x = xl + 0.75 * fw - ms
    gfx.printf( "S" )
    gfx.rect( xl+.5*fw, yOrigin + 1*fh-1, 1, fh )
  end 
   
  -- Dark alternating colors
  gfx.set( table.unpack( colors.linecolor2 ) )
  for iy = 6,ymax,8 do
    gfx.rect( xOrigin, yOrigin + fh * iy, fw, fh )
  end
  gfx.set( table.unpack( colors.linecolor5 ) )
  for iy = 2,ymax,8 do
    gfx.rect( xOrigin, yOrigin + fh * iy, fw, fh )
  end
  
  -- Horizontal lines
  for iy=1,ymax do
    gfx.set( table.unpack( colors.inactive ) )
    gfx.rect( xOrigin + 3,  yOrigin + (iy+1)*fh-1, fw * (xEnd-xStart+2)-3, 1 )
  end 
  
  -- Pattern names
  gfx.set( table.unpack( colors.textcolor ) )
  for ix=xStart,xEnd do
    for iy=0,ymax do
      gfx.x = xOrigin + (ix+1)*fw + 3
      gfx.y = yOrigin + (iy+2)*fh
      local curElement = patterns[ix+scrollx][iy+scrolly]
      if ( curElement ) then
        local nextElement = 0
        if ( patterns[ix+scrollx][iy+scrolly+1] ) then
          nextElement = 1
        end
        if ( curElement < -1 ) then
          gfx.set( table.unpack( colors.linecolor6 ) )
        else
          gfx.set( table.unpack( colors.linecolor5 ) )
        end
        gfx.rect( gfx.x-3, gfx.y, fw, fh-1+nextElement )
        if ( curElement > 0 ) then
          gfx.set( table.unpack( colors.textcolor ) )
          gfx.printf("%s", patternNames[ix+scrollx][curElement])
        else
        end
      else
        gfx.set( table.unpack( colors.textcolor ) )
        gfx.printf("...")
      end
    end
  end
  
  -- Vertical lines
  for ix=xStart,xEnd+1 do
    gfx.rect( xOrigin + fw*(ix+1), yOrigin, 1, gfx.h-yOrigin )
  end
  
  ------------------------------
  -- Clipboard block drawing
  ------------------------------
  local cp = self.cp
  if ( cp.ystart > -1 ) then
    local xl  = clamp(0, fov.width,  cp.xstart - fov.scrollx)
    local xe  = clamp(0, fov.width,  cp.xstop  - fov.scrollx)  
    local yl  = clamp(0, fov.height, cp.ystart - fov.scrolly)
    local ye  = clamp(0, fov.height, cp.ystop  - fov.scrolly)
    gfx.set(table.unpack(colors.copypaste))    
    if ( cp.all == 0 ) then   
      gfx.rect(xOrigin + (1+xl) * fw, yOrigin + (2+yl) * fh, fw * ( xe - xl + 1 ), fh * ( ye - yl + 1 ) )
    else
      gfx.rect(xOrigin + fw, yOrigin + (2+yl) * fh, fw * ( xEnd - xStart + 1 ), fh * ( ye - yl + 1 ) )
    end
  end
  
  -- Cursor
  gfx.set( table.unpack( colors.linecolor3 ) )
  gfx.rect( xOrigin + fw * ( 1 + xrel ) + 1, xOrigin + ( 2 + yrel ) * fh, fw - 1, fh )
  local curElement = patterns[self.xpos][self.ypos]
  if ( curElement and curElement > 0 ) then
    if ( self.renaming == 1 ) then
      gfx.set( table.unpack( colors.changed ) )
    else
      gfx.set( table.unpack( colors.textcolor ) )          
    end
    gfx.x = xOrigin + fw * ( 1 + xrel ) + 3
    gfx.y = xOrigin + ( 2 + yrel ) * fh
    gfx.printf("%s", patternNames[self.xpos][curElement])
  end
  gfx.set( table.unpack( colors.textcolor ) )
  
  -- Tick counts
  local xs = xOrigin + fw - 5
  for iy=0,ymax do
    str = string.format( "%3d", 16 * (iy +scrolly)  )
    gfx.x = xs - gfx.measurestr( str )
    gfx.y = yOrigin + (iy+2)*fh
    gfx.printf( str )
  end
  
  
  -- Header lines
  gfx.set( table.unpack( colors.textcolor ) )
  gfx.rect( xOrigin+fw, yOrigin, fw * (xEnd-xStart+1), 1 )
  gfx.rect( xOrigin+fw, yOrigin + fh-1, fw * (xEnd-xStart+1), 1 )
  gfx.rect( xOrigin+fw, yOrigin + 2*fh-1, fw * (xEnd-xStart+1), 1 )
  
  -- Pattern names
  local X = gfx.w - self.cfg.nameSize + 5
  gfx.x = X
  gfx.y = fh
  gfx.printf( "Track patterns/items" )
  local chars = seq.chars
  for i,v in pairs( self.patternNames[self.xpos] ) do
    gfx.x = X
    gfx.y = (2+i) * fh
    gfx.printf( "%s. %s", chars:sub(i,i), v )
  end
  
  ------------------------------
  -- Play location indicator
  ------------------------------
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local playLoc = self:getPlayLocation() / rps - scrolly

  gfx.x = xOrigin + (fov.width+1)*fw + 3
  local tw = fw * (xEnd-xStart+1) - 1
  local xc = 25
  local yc = 11
  if ( playLoc < 0 ) then   
      gfx.set(table.unpack(colors.linecolor3))     
      triangle(xc, yc+1, 3, -1)        
      gfx.set(table.unpack(colors.linecolor3))
      triangle(xc, yc, 5, -1)
  elseif ( playLoc > height ) then
      gfx.set(table.unpack(colors.linecolor3))
      triangle(xc, yc-1, 3, 1)           
      gfx.set(table.unpack(colors.linecolor3))
      triangle(xc, yc, 5, 1)    
  else
      gfx.set(table.unpack(colors.linecolor4))
      gfx.rect(xOrigin + fw + 1, yOrigin + 2 * fh + fh * playLoc, tw, 2)
  end

  local markerLoc = reaper.GetCursorPosition() / rps - scrolly
  if ( markerLoc > 0 and markerLoc < height ) then
    gfx.set(table.unpack(colors.linecolor4))
    gfx.rect(xOrigin + fw + 1, yOrigin + 2 * fh + fh * markerLoc, tw, 2)
  end
  
  local lStart, lEnd = reaper.GetSet_LoopTimeRange2(0, false, 1, 0, 0, false)
  lStart = lStart / rps - scrolly
  lEnd = lEnd / rps - scrolly    
  if ( ( lStart >= 0 ) and ( lStart <= height ) ) then
    gfx.set(table.unpack(colors.loopcolor))
    gfx.rect(xOrigin + fw + 1, yOrigin + 2 * fh + fh * lStart, tw, 1)
  end
  if ( ( lEnd >= 0 ) and ( lEnd <= height ) ) then
    gfx.set(table.unpack(colors.loopcolor))
    gfx.rect(xOrigin + fw + 1, yOrigin + 2 * fh + fh * lEnd, tw, 1)
  end
end

------------------------------
-- Force selector in range
------------------------------
-- forceY indicates that a certain row must be in view!
function seq:forceCursorInRange(forceY)
  local fov = self.fov
  if ( self.xpos < 0 ) then
    self.xpos = 0
  end
  local yTarget = forceY or self.ypos
  if ( yTarget < 0 ) then
    yTarget = 0
  end
  if ( self.ypos < 0 ) then
    self.ypos = 0
  end  
  if ( self.xpos > self.max_xpos - 1 ) then
    self.xpos = math.floor( self.max_xpos - 1 )
  end
  if ( yTarget > self.max_ypos - 1 ) then
    yTarget = math.floor( self.max_ypos - 1 )
  end
  if ( self.ypos > self.max_ypos - 1 ) then
    self.ypos = math.floor( self.max_ypos - 1 )
  end  
  -- Is the cursor off fov?
  if ( ( yTarget - fov.scrolly ) > self.fov.height ) then
    self.fov.scrolly = yTarget - self.fov.height
  end
  if ( ( yTarget - fov.scrolly ) < 1 ) then
    self.fov.scrolly = yTarget
  end
    
  -- Is the cursor off fov?
  if ( ( self.xpos - fov.scrollx ) > self.fov.width ) then
    self.fov.scrollx = self.xpos - self.fov.width
  end
  if ( ( self.xpos - fov.scrollx ) < 1 ) then
    self.fov.scrollx = self.xpos
  end    
end

function seq:computeSize()
  self.fov.width = math.floor( ( gfx.w - self.cfg.nameSize - .99 * self.cellw ) / self.cellw ) - 1
  self.fov.height = math.floor( gfx.h / self.cellh ) - 3
  
  self.max_xpos = reaper.CountTracks(0) --self.fov.width
  self.max_ypos = 4096
end

local function inputs( name )
  -- Bitmask oddly enough doesn't behave as expected
  local control = gfx.mouse_cap & 4
  if ( control > 0 ) then control = 1 end  
  local shift   = gfx.mouse_cap & 8
  if ( shift > 0 ) then shift = 1 end
  local alt     = gfx.mouse_cap & 16
  if ( alt > 0 ) then alt = 1 end

  local checkMask = keys[name]
  if ( checkMask[1] == control ) then
    if ( checkMask[2] == alt ) then
      if ( checkMask[3] == shift ) then
        if ( lastChar == checkMask[4] ) then
          return true
        end
      end
    end
  end
  
  return false
end

function seq:resetShiftSelect()
  local cp = self.cp
  self:forceCursorInRange()
  if ( cp.lastShiftCoord ) then
    cp.lastShiftCoord = nil
    self:resetBlock()
  end
end

function seq:dragBlock(cx, cy)
  local cp = self.cp
  local xp, yp
  if ( not cx ) then
    xp = self.xpos
    yp = self.ypos
  else
    xp = cx
    yp = cy
  end
  
  if ( not cp.lastShiftCoord ) then
    cp.lastShiftCoord = {}
    cp.lastShiftCoord.x = xp
    cp.lastShiftCoord.y = yp
  end
  local xstart, xend, ystart, yend
  if ( xp > cp.lastShiftCoord.x ) then
    xstart  = cp.lastShiftCoord.x
    xend    = xp
  else
    xstart  = xp
    xend    = cp.lastShiftCoord.x
  end
  if ( yp > cp.lastShiftCoord.y ) then
    ystart  = cp.lastShiftCoord.y
    yend    = yp
  else
    ystart  = yp
    yend    = cp.lastShiftCoord.y
  end
  
  cp.xstart  = xstart
  cp.xstop   = xend
  cp.all     = 0
  cp.ystart  = ystart
  cp.ystop   = yend
end

function seq:mend(track, row)
  local trackItems = self.trackItems
  local poolGUIDs = self.poolGUIDs
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  
  -- Figure out how long we can make it...
  local mindist = self:findNextItem(track, row)

  -- Lengthen the indexed midi item
  local cTrack = reaper.GetTrack(0, track)
  for i,v in pairs(trackItems) do
    if ( v[2] == cTrack ) then
      local pos = reaper.GetMediaItemInfo_Value( v[1], "D_POSITION" )
      local len = reaper.GetMediaItemInfo_Value( v[1], "D_LENGTH" )
      if ( math.floor( pos / rps + 0.0001 ) <= row and math.floor( (pos+len)/rps + 0.0001 ) >= row ) then
        local GUID = v[4]
        local poolItem = poolGUIDs[GUID]
        if ( poolItem ) then
          local itemLen = reaper.GetMediaItemInfo_Value( poolItem[1], "D_LENGTH" )
          local maxLen = (row*rps - pos) + mindist
          if ( itemLen > maxLen ) then
            itemLen = maxLen
          end
          reaper.SetMediaItemInfo_Value( v[1], "D_LENGTH", itemLen )
        end
      end
    end
  end
end

function seq:deleteRange(track, row)
  local trackItems = self.trackItems
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  
  -- Delete 
  local cTrack = reaper.GetTrack(0, track)
  for i,v in pairs(trackItems) do
    if ( v[2] == cTrack ) then
      local pos = reaper.GetMediaItemInfo_Value( v[1], "D_POSITION" )
      if ( math.floor( pos / rps + 0.0001 ) == row ) then
        reaper.DeleteTrackMediaItem(v[2], v[1])
      end
    end
  end
  
  if ( self.cfg.automation == 1 ) then
    -- Automation items
    local deletedAutomation
    for envIdx = 0,reaper.CountTrackEnvelopes(cTrack)-1 do
      local trackEnv = reaper.GetTrackEnvelope(cTrack, envIdx)
      for i=0,reaper.CountAutomationItems(trackEnv)-1 do
        local d_pos = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POSITION", 0, false)
        if ( math.floor( d_pos / rps + 0.0001 ) == row ) then
          --reaper.DeleteTrackMediaItem(v[2], v[1])
          if not deletedAutomation then
            --reaper.SelectAllMediaItems(0, false)
            reaper.Main_OnCommand(40289, 0) -- Deselect all items
            deletedAutomation = 1
          end
          reaper.GetSetAutomationItemInfo(trackEnv, i, "D_UISEL", 1, true)
        else
          reaper.GetSetAutomationItemInfo(trackEnv, i, "D_UISEL", 0, true)
        end
      end
    end
  
    if ( deletedAutomation ) then
      reaper.Main_OnCommand(40006, 0) -- Delete automation items
    end
  end
  
  seq:updateData()
end

function seq:delete()
  self:deleteRange(self.xpos, self.ypos, 0, 0)
  reaper.UpdateArrange()
  
  if ( self.ypos > 0 ) then
    seq:mend(self.xpos, self.ypos-1)
  end
  reaper.UpdateArrange()
end

function seq:backspace()
  self:deleteRange(self.xpos, self.ypos, 0, 0)
  self:insert(nil, self.ypos+1, -1)
  if ( self.ypos > 0 ) then
    seq:mend(self.xpos, self.ypos-1)
  end  
  
  reaper.UpdateArrange()
end

function seq:insert(xpos, ypos, sign)
  local cTrack = reaper.GetTrack(0, xpos or self.xpos)
  local row = ypos or self.ypos
  
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local delta = (sign or 1) * rps
  
  -- Media items
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    -- Only deal with media items on this track
    if ( reaper.GetMediaItem_Track(mediaItem) == cTrack ) then
      local d_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      if ( d_pos < postMusic ) then
        if ( math.floor( d_pos / rps + 0.0001 ) >= row ) then
          reaper.SetMediaItemInfo_Value(mediaItem, "D_POSITION", d_pos + delta)
        else
          local d_len = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
          if ( math.floor( (d_pos + d_len) / rps + 0.0001 ) > row ) then
            -- Grow/Shrink this one!
            reaper.SetMediaItemInfo_Value(mediaItem, "D_LENGTH", d_len + delta)
          end
        end
      end
    end  
  end
  
  -- Automation items
  if ( self.cfg.automation == 1 ) then
    for envIdx = 0,reaper.CountTrackEnvelopes(cTrack)-1 do
      local trackEnv = reaper.GetTrackEnvelope(cTrack, envIdx)
      for i=0,reaper.CountAutomationItems(trackEnv)-1 do
        local d_pos = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POSITION", 0, false)
        if ( d_pos < postMusic ) then
          if ( math.floor( d_pos / rps + 0.0001 ) >= row ) then
            reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POSITION", d_pos + delta, true)
          else
            local d_len = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_LENGTH", 0, false)
            if ( math.floor( (d_pos + d_len) / rps + 0.0001 ) > row ) then
              -- Grow/Shrink this one!
              reaper.GetSetAutomationItemInfo(trackEnv, i, "D_LENGTH", d_len + delta, true)
            end
          end
        end
      end
    end
  end
  
  reaper.UpdateArrange()
end

function seq:beginBlock()
  local cp = self.cp
  if ( cp.ystart == self.ypos ) then
    cp.all = 1 - cp.all
  end
  cp.xstart = self.xpos
  cp.ystart = self.ypos  
  if ( cp.ystart > cp.ystop ) then
    cp.ystop  = self.ypos
  end
  if ( cp.xstart > cp.xstop ) then
    cp.xstop  = self.xpos
  end
  
  cp.lastShiftCoord = nil
end

function seq:endBlock()
  local cp = self.cp
  if ( self.ypos < cp.ystart ) then
    self:resetBlock()
  end
  if ( ( cp.ystop == self.ypos ) and ( cp.xstop == self.xpos ) ) then
    cp.all = 1 - cp.all
  end
  cp.xstop = self.xpos  
  cp.ystop = self.ypos
  
  cp.lastShiftCoord = nil
end

function seq:resetBlock()
  local cp = self.cp
  cp.ystart  = -1
  cp.ystop   = -1
  cp.all     =  0
  cp.xstart  = -1
  cp.xstop   = -1
end

function seq:terminateAt(track, row)
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local cTrack = reaper.GetTrack(0, track or self.xpos)
  
  -- Media items
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    -- Only deal with media items on this track
    if ( reaper.GetMediaItem_Track(mediaItem) == cTrack ) then
      local d_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      if ( d_pos < postMusic ) then
        if ( math.floor( d_pos / rps + 0.0001 ) < row ) then
          local d_len = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
          if ( math.floor( (d_pos + d_len) / rps + 0.0001 ) >= row ) then
            reaper.SetMediaItemInfo_Value(mediaItem, "D_LENGTH", row*rps - d_pos, true)
          end
        end
      end
    end  
  end
  
  -- Automation items
  if ( self.cfg.automation == 1 ) then
    for envIdx = 0,reaper.CountTrackEnvelopes(cTrack)-1 do
      local trackEnv = reaper.GetTrackEnvelope(cTrack, envIdx)
      for i=0,reaper.CountAutomationItems(trackEnv)-1 do
        local d_pos = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POSITION", 0, false)
        if ( d_pos < postMusic ) then
          if ( math.floor( d_pos / rps + 0.0001 ) < row ) then
            local d_len = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_LENGTH", 0, false)
            if ( math.floor( (d_pos + d_len) / rps + 0.0001 ) >= row ) then
              -- Grow/Shrink this one!
              reaper.GetSetAutomationItemInfo(trackEnv, i, "D_LENGTH", row*rps - d_pos, true)
            end
          end
        end
      end
    end
  end
end

function seq:findNextItem(track, row)
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local cTrack = reaper.GetTrack(0, track)

  local minDist = 10000000000000
  local item = nil
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    -- Only deal with media items on this track
    if ( reaper.GetMediaItem_Track(mediaItem) == cTrack ) then
      local d_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      if ( d_pos < postMusic ) then
        if ( math.floor( d_pos / rps + 0.0001 ) > row ) then
          if ( d_pos < minDist ) then
            minDist = d_pos - row*rps
            item = mediaItem
          end
        end
      end
    end  
  end

  return minDist,item
end

function seq:addItem( idx )
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  
  -- Actually paste the new pattern
  local GUID = self.idxToGUID[self.xpos][ idx ]
  local v = self.poolGUIDs[ GUID ]

  if ( v ) then
    -- Delete what we are overwriting
    self:deleteRange(self.xpos, self.ypos, 0, 0)

    -- Shorten what we are cutting into
    seq:terminateAt(self.xpos, self.ypos)

    -- Deselect everything, select our track and media item of interest
    --reaper.Main_OnCommand(40289, 0) -- Deselect items
    local m_pos = reaper.GetMediaItemInfo_Value(v[1], "D_POSITION")
    self:selectMediaItem(v[1])
    local curTrack = v[2]
    reaper.SetOnlyTrackSelected(curTrack)
    
    -- Copy and move to where we want to paste
    reaper.Main_OnCommand(40698, 0) -- Copy selected items
    reaper.SetEditCurPos2(0, self.ypos*rps, false, false)
    
    -- Check how much space we have before pasting
    local mindist = self:findNextItem(self.xpos, self.ypos)
    
    -- Paste stuff
    reaper.Main_OnCommand(41072, 0) -- Paste pooled
    local mediaItem = reaper.GetSelectedMediaItem(0, 0)
    local len = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
    if ( mindist < len ) then
      len = mindist
    end
    reaper.SetMediaItemInfo_Value(mediaItem, "D_LENGTH", len)
    
    if ( self.cfg.automation == 1 ) then
      -- Copy automation items as well
      for envIdx = 0,reaper.CountTrackEnvelopes(curTrack)-1 do
        local env = reaper.GetTrackEnvelope(curTrack, envIdx)
        
        -- See if there's an automation item to go with this item.
        for i=0,reaper.CountAutomationItems(env)-1 do
          local e_pos = reaper.GetSetAutomationItemInfo(env, i, "D_POSITION", 0, false)
          if ( e_pos == m_pos ) then
            local poolidx = reaper.GetSetAutomationItemInfo(env, i, "D_POOL_ID", 0, false)
            reaper.InsertAutomationItem(env, poolidx, self.ypos*rps, len)
          end
        end
      end
    end
  end
end

function seq:updateMidiName(inGUID, name)
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    local take = reaper.GetActiveTake(mediaItem)
    if ( reaper.TakeIsMIDI(take) ) then
      local retval, GUID = reaper.BR_GetMidiTakePoolGUID(take)
      if ( inGUID == GUID ) then
        reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
      end
    end
  end
end

function seq:gotoRow(row)
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local loc = reaper.AddProjectMarker(0, 0, self.ypos * rps, 0, "", -1)
  reaper.GoToMarker(0, loc, 0)
  reaper.DeleteProjectMarker(0, loc, 0)
end

function seq:rename(track, row)
  -- Media items
  local name, GUID
  local cTrack = reaper.GetTrack(0, track)
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    -- Only deal with media items on this track
    if ( reaper.GetMediaItem_Track(mediaItem) == cTrack ) then
      local d_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      if ( d_pos < postMusic ) then
        if ( math.floor( d_pos / rps + 0.0001 ) == row ) then
          local take = reaper.GetActiveTake(mediaItem)
          if ( reaper.TakeIsMIDI(take) ) then
            local retval
            retval, GUID = reaper.BR_GetMidiTakePoolGUID(take)
            retval, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
          end
        end
      end
    end
  end

  return GUID, name
end

function seq:renamePattern()
  local GUID, name = self:rename(self.xpos, self.ypos)
  if ( GUID ) then
    self.GUID = GUID
    self.oldMidiName = name
    self.midiName = name
    self.renaming = 1
  end
end

function seq:renameTrack(track)
  -- Media items
  local name, GUID
  local cTrack = reaper.GetTrack(0, track)
  self.renaming = 2
  local jnk, str = reaper.GetTrackName(cTrack, "")
  self.trackName = str
  self.renameTrackIdx = track
end

function seq:updateTrackName(track, name)
  local cTrack = reaper.GetTrack(0, track)
  reaper.GetSetMediaTrackInfo_String(cTrack, "P_NAME", name, true)
end

local function mouseStatus()
  local leftbutton  = gfx.mouse_cap & 1
  local rightbutton = gfx.mouse_cap & 2
  local middlebutton = gfx.mouse_cap & 64
  if ( rightbutton > 0 ) then
    rightbutton = 1
  end
  if ( middlebutton > 0 ) then
    middlebutton = 1
  end
  return leftbutton, rightbutton, middlebutton
end

function seq:toggleMute(trackidx)
  local cTrack = reaper.GetTrack( 0, trackidx )
  local mute = reaper.GetMediaTrackInfo_Value(cTrack, "B_MUTE")
  if ( mute == 1 ) then
    reaper.SetMediaTrackInfo_Value( cTrack, "B_MUTE", 0 )
  else
    reaper.SetMediaTrackInfo_Value( cTrack, "B_MUTE", 1 )
     
    -- If it was solo, un-solo!
    if ( reaper.GetMediaTrackInfo_Value( cTrack, "I_SOLO" ) > 0 ) then
      reaper.SetMediaTrackInfo_Value( cTrack, "I_SOLO", 0 )
    end
  end
end

function seq:toggleSolo(trackidx)
  local cTrack = reaper.GetTrack( 0, trackidx )
  local wasSolo = reaper.GetMediaTrackInfo_Value( cTrack, "I_SOLO" ) > 0;
  if ( wasSolo ) then
    reaper.SetMediaTrackInfo_Value( cTrack, "I_SOLO", 0 )
  else
    -- If solo'd, make sure it is not muted
    reaper.SetMediaTrackInfo_Value( cTrack, "B_MUTE", 0 )
    reaper.SetMediaTrackInfo_Value( cTrack, "I_SOLO", 1 )
  end
end

function seq:getPlayLocation()
  if ( reaper.GetPlayState() == 0 ) then
    return reaper.GetCursorPosition()
  else
    return reaper.GetPlayPosition()
  end
end

function seq:calcGridCoord()
  local fw            = self.cellw
  local fh            = self.cellh
  local fov           = self.fov
  local scrollx       = fov.scrollx
  local scrolly       = fov.scrolly
  local ymax          = fov.height
  local xOrigin       = 0
  local yOrigin       = 0
  local xEnd          = fov.width
  
  local Inew = math.floor( gfx.mouse_x / fw ) + scrollx
  local Jnew = math.floor( gfx.mouse_y / fh ) + scrolly
  
  return Inew, Jnew
end

function seq:setLoopToPattern()
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  
  reaper.GetSet_LoopTimeRange2(0, true, true, self.ypos*rps, (self.ypos+1)*rps, true)
end

function seq:setLoopStart()
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local lPos, lEnd = reaper.GetSet_LoopTimeRange2(0, false, 1, 0, 0, false)
  
  lPos = self.ypos*rps
  if ( lPos >= lEnd ) then
    lEnd = lPos + rps
  end
  reaper.GetSet_LoopTimeRange2(0, true, true, lPos, lEnd, true)
end

function seq:setLoopEnd()
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local lPos, lEnd = reaper.GetSet_LoopTimeRange2(0, false, 1, 0, 0, false)
  
  lEnd = self.ypos * rps
  if ( lPos >= lEnd ) then
    lPos = lEnd - rps
  end
  reaper.GetSet_LoopTimeRange2(0, true, true, lPos, lEnd, true)    
end

function seq:processMouseActions()
  local gfx                 = gfx
  local fw                  = self.cellw
  local fh                  = self.cellh
  local fov                 = self.fov
  local scrollx             = fov.scrollx
  local scrolly             = fov.scrolly
  local left, right, middle = mouseStatus()
  local ctime               = reaper.time_precise()
  local lastLeft            = self.lastLeft
  
  if ( left == 1 ) then
    if ( gfx.mouse_y < fh ) then
    elseif ( gfx.mouse_y > fh and gfx.mouse_y < 2*fh ) then
      -- Mute / Solo handling
      local cTrack = math.floor( gfx.mouse_x / fw )
      if ( lastLeft == 0 ) then
        if ( gfx.mouse_x - fw * cTrack ) < 0.5 * fw then
          self:toggleMute(scrollx + cTrack-1)
        else
          self:toggleSolo(scrollx + cTrack-1)
        end
      end
    else
      -- Click inside the grid
      local Inew, Jnew = seq:calcGridCoord()

      if ( Inew and Jnew ) then        
        if ( lastLeft == 0 ) then
          -- Move the cursor pos on initial click
          seq:resetShiftSelect()
          --seq:dragBlock(Inew+fov.scrollx, Jnew+fov.scrolly)
          self.xpos = Inew - 1
          self.ypos = Jnew - 2
          self:forceCursorInRange()
        else
          -- Change selection if it wasn't the initial click
          seq:dragBlock(Inew+fov.scrollx-1, Jnew+fov.scrolly-2)
        end
      end
    end
    
    self.lastLeft = 1
    self.lastLeftTime = reaper.time_precise()
  else
    self.lastLeft = 0
  end
  
  if ( right == 1 ) then
    if ( gfx.mouse_y < fh and self.lastRight == 0 ) then
      local cTrack = math.floor( gfx.mouse_x / fw )
      if ( cTrack < reaper.CountTracks(0) ) then
        seq:renameTrack(scrollx + cTrack - 1)
      end
    elseif ( gfx.mouse_y > 2 * fh ) then
      local Inew, Jnew = seq:calcGridCoord()
      if ( Inew and Jnew ) then        
        self.xpos = Inew - 1
        self.ypos = Jnew - 2
        self:forceCursorInRange()
        self:resetShiftSelect()
        self:renamePattern()
      end
    end
    
    self.lastRight = 1
    self.lastRightTime = reaper.time_precise()
  else
    self.lastRight = 0
  end
  
  if ( middle == 1 ) then
    if ( gfx.mouse_y > (2 * fh) and self.lastMiddle == 0 ) then
      local Inew, Jnew = seq:calcGridCoord()
      self.xpos = Inew - 1
      self.ypos = Jnew - 2
      self:forceCursorInRange()
      if ( Inew and Jnew ) then
        seq:uniqueifyElement(self.xpos, self.ypos)
      end
    end
    self.lastMiddle = 1
  else
    self.lastMiddle = 0
  end
end

local function updateLoop()
  prevChar = lastChar
  lastChar = gfx.getchar()
  seq:updateData()
  seq:updateGUI()
  
  if ( seq.renaming == 0 ) then
    seq:processMouseActions()
  end
  
  if lastChar ~= -1 then
    if ( seq.renaming == 0 ) then
      if inputs('left') then
        seq.xpos = seq.xpos - 1
        seq:resetShiftSelect()
      elseif inputs('right') then
        seq.xpos = seq.xpos + 1
        seq:resetShiftSelect()
      elseif inputs('up') then
        seq.ypos = seq.ypos - 1
        seq:resetShiftSelect()
      elseif inputs('down') then
        seq.ypos = seq.ypos + 1
        seq:resetShiftSelect()
      elseif inputs('insert') then
        seq:insert()
        if ( seq.ypos > 0 ) then
          seq:mend(seq.xpos, seq.ypos-1)
        end
      elseif inputs('remove') then
        seq:backspace()      
      elseif inputs('pgup') then
        seq.ypos = seq.ypos - seq.cfg.page
        seq:resetShiftSelect()
      elseif inputs('pgdown') then
        seq.ypos = seq.ypos + seq.cfg.page
        seq:resetShiftSelect()    
      elseif inputs('shiftleft') then
        seq:dragBlock()
        seq.xpos = seq.xpos - 1
        seq:forceCursorInRange()
        seq:dragBlock()
      elseif inputs('shiftright') then
        seq:dragBlock()
        seq.xpos = seq.xpos + 1
        seq:forceCursorInRange()
        seq:dragBlock()
      elseif inputs('shiftup') then
        seq:dragBlock()
        seq.ypos = seq.ypos - 1
        seq:forceCursorInRange()
        seq:dragBlock()
      elseif inputs('shiftdown') then
        seq:dragBlock()
        seq.ypos = seq.ypos + 1
        seq:forceCursorInRange()
        seq:dragBlock()
      elseif inputs('shiftpgdn') then
        seq:dragBlock()
        seq.ypos = seq.ypos + seq.cfg.page
        seq:forceCursorInRange()
        seq:dragBlock()
      elseif inputs('shiftpgup') then
        seq:dragBlock()
        seq.ypos = seq.ypos - seq.cfg.page
        seq:forceCursorInRange()
        seq:dragBlock()
      elseif inputs('shifthome') then
        seq:dragBlock()
        seq.ypos = 0
        seq:forceCursorInRange()
        seq:dragBlock()
      elseif inputs('shiftend') then
        seq:dragBlock()
        seq.ypos = seq.rows
        seq:forceCursorInRange()
        seq:dragBlock()
      elseif inputs('setloopstart') then
        seq:setLoopStart()
      elseif inputs('setloopend') then
        seq:setLoopEnd()
      elseif inputs('setloop') then
        seq:setLoopToPattern()
      elseif inputs('rename') then
        seq:renamePattern()
      elseif ( inputs('delete') ) then
        modified = 1
        reaper.Undo_OnStateChange2(0, "Tracker: Delete (Del)")
        seq:delete()
      elseif ( inputs('delete2') ) then
        modified = 1
        reaper.Undo_OnStateChange2(0, "Tracker: Delete (Del)")
        seq:delete()
        seq.ypos = seq.ypos + seq.advance
      elseif ( inputs('playfrom') ) then
        seq:gotoRow(seq.ypos)
        reaper.Main_OnCommand(40044, 0)
      elseif ( inputs('toggle') ) then
        reaper.Main_OnCommand(40044, 0)
      elseif ( seq.charCodes[lastChar] ) then
        seq:addItem( seq.charCodes[ lastChar ] )
        lastChar = 0
      end
    elseif ( seq.renaming == 1 ) then
      -- Renaming pattern
      if inputs( 'enter' ) then
        seq.renaming = 0
      elseif inputs( 'escape' ) then
        seq.midiName = seq.oldMidiName
        seq:updateMidiName(seq.GUID, seq.midiName)
        seq.renaming = 0
      elseif inputs( 'remove' ) then
        seq.midiName = seq.midiName:sub(1, seq.midiName:len()-1)
        seq:updateMidiName(seq.GUID, seq.midiName)
      else
        if ( pcall( function () string.char(lastChar) end ) ) then
          if ( lastChar > 0 ) then
            local str = string.char( lastChar )
            seq.midiName = string.format( '%s%s', seq.midiName, str )
            seq:updateMidiName(seq.GUID, seq.midiName)
          end
        end
      end
    elseif ( seq.renaming == 2 ) then
      -- Renaming pattern
      if inputs( 'enter' ) then
        seq.renaming = 0
      elseif inputs( 'escape' ) then
        seq.trackName = seq.oldTrackName
        seq:updateTrackName(seq.renameTrackIdx, seq.trackName)
        seq.renaming = 0
      elseif inputs( 'remove' ) then
        seq.trackName = seq.trackName:sub(1, seq.trackName:len()-1)
        seq:updateTrackName(seq.renameTrackIdx, seq.trackName)
      else
        if ( pcall( function () string.char(lastChar) end ) ) then
          if ( lastChar > 0 ) then
            local str = string.char( lastChar )
            seq.trackName = string.format( '%s%s', seq.trackName, str )
            seq:updateTrackName(seq.renameTrackIdx, seq.trackName)
          end
        end
      end      
    end
  
    reaper.defer(updateLoop)
  else
    seq:terminate()
  end
end

local function Main()
  local wpos = seq:loadConfig("_wpos.cfg", {})  
  local width = wpos.w or 200
  local height = wpos.h or 200
  local xpos = wpos.x or 200
  local ypos = wpos.y or 200
  
  seq:loadColors("renoiseB")
  seq:loadColors( "buzz" ) 
  seq:loadKeys( "default" )
  gfx.init(scriptName, width, height, 0, xpos, ypos)
  seq:computeSize()
  
  reaper.defer(updateLoop)
end

Main()

-- GetSetAutomationItemInfo(TrackEnvelope* env, int autoitem_idx, const char* desc, double value, bool is_set)
-- D_POOL_ID: double *, automation item pool ID (as an integer); edits are propagated to all other automation items that share a pool ID
-- D_POSITION: double *, automation item timeline position in seconds
-- D_LENGTH: double *, automation item length in seconds
