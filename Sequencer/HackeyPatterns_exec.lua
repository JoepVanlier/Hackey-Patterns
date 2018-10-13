--[[
@description Hackey-Patterns: An interface plugin for REAPER 5.x and up designed to mimick the sequencer in Jeskola Buzz.
@author: Joep Vanlier
@links
  https://github.com/JoepVanlier/Hackey-Patterns
@license MIT
@version 0.26
@about 
  ### Hackey-Patterns
  #### What is it?
  A lightweight sequencer plugin for REAPER 5.x and up.
  
  Usage
  Hackey Patterns provides an alternative way for visualizing and manipulating timeline in REAPER.
   
  Happy sequencin' :)
--]]

--[[
 * Changelog:
 * v0.27 (2018-10-13)
   + Fixes in mending behaviour.
   + Fix nil bug when number of tracks is changing.
 * v0.26 (2018-10-13)
   + Make sure HT isn't opened on OFF symbols or wave media items.
   + Make sure OFF symbols cannot be uniqueified.
   + Only update internal data when user is interacting with the plugin.
   + Fix display location of wave data.
 * v0.25 (2018-10-13)
   + Fix redraw bug
   + Added OFF marker (still a known bug with opening hackey trackey on such a tiny item)
 * v0.24 (2018-10-12)
   + Allow visualization of mute status.
   + Improved renoise color scheme.
   + Added zoom (+/-)
   + Added panic (F12)
   + Added theme switching (F11)
 * v0.23 (2018-10-09)
   + Added option to follow track column.
   + Added option to follow location.
 * v0.22 (2018-10-08)
   + Added some checking for empty tables
   + Preserve ordering
 * v0.21 (2018-10-07)
   + Fix issue with pattern coloring.
   + Default mousewheel scrolls 4, shift mousewheel scrolls 1.
   + Added more use of the position stack to make sure positions are preserved when executing commands.
   + Added command for Open HT (enter is default).
   + Added insert / remove / clear row (CTRL+Backspace/Insert/Delete)
 * v0.20 (2018-10-07)
   + Add tab/shift+tab for movement along columns.
   + Add mousewheel movement.
 * v0.19 (2018-10-07)
   + Fixed issue with pattern precision when calculating pattern display.
   + Added global eps parameter rather than using hardcoded values everywhere.
 * v0.18 (2018-10-07)
   + Add pattern deletion button (deletes it from the pool and song)
   + Added undo and redo
   + Added usage highlighting when hovering over patterns in pattern list
 * v0.17 (2018-10-07)
   + Added subtle whole row highlighting for current line.
 * v0.16 (2018-10-07)
   + Integrated with Hackey Trackey (doubleclick a pattern in the sequencer)
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

scriptName = "Hackey Patterns v0.26"
postMusic = 500

hackeyTrackey = "Tracker tools/Tracker/tracker.lua"

seq                 = {}
seq.fov             = {}
seq.fov.scrollx     = 0
seq.fov.scrolly     = 0
seq.fov.width       = 6
seq.fov.height      = 6
seq.fov.scrollpat   = 0
seq.xpos            = 0
seq.ypos            = 0
seq.res             = 16
seq.patterns        = {}
seq.renaming        = 0

seq.lastLeft    = 1
seq.lastLeftTime = 0

seq.posList = {}

seq.cfg = {}
seq.cfg.nChars        = 9
seq.cfg.nameSize      = 160
seq.cfg.page          = 4
seq.cfg.automation    = 1
seq.cfg.boxsize       = 8
seq.cfg.largeScroll   = 4
seq.cfg.followRow     = 1
seq.cfg.patternLines  = 30
seq.cfg.followTrackSelection = 1
seq.cfg.theme         = "renoise"
  
seq.advance       = 1
seq.cfg.zoom      = 1
seq.eps           = 0.000001

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
    keys.playfrom       = { 0,    0,  1,    13 }            -- Shift + Enter
    keys.hackeytrackey  = { 0,    0,  0,    13 }            -- Enter
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
    keys.help           = { 0,    0,  0,    26161 }         -- F1
    keys.advancedown    = { 0,    0,  0,    26164 }         -- F4
    keys.advanceup      = { 0,    0,  0,    26165 }         -- F5
    keys.theme          = { 0,    0,  0,    6697265 }       -- F11   
    keys.panic          = { 0,    0,  0,    6697266 }       -- F12
    keys.setloop        = { 1,    0,  0,    12 }            -- CTRL + L
    keys.setloopstart   = { 1,    0,  0,    17 }            -- CTRL + Q
    keys.setloopend     = { 1,    0,  0,    23 }            -- CTRL + W
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
    keys.tab            = { 0,    0,  0,    9 }             -- Tab
    keys.shifttab       = { 0,    0,  1,    9 }             -- SHIFT + Tab
    keys.follow         = { 1,    0,  0,    6 }             -- CTRL + F
    keys.deleteRow      = { 1,    0,  0,    6579564 }       -- Ctrl + Del
    keys.closeTracker   = { 1,    0,  0,    6697266 }       -- Ctrl + F12
    keys.nextTrack      = { 1,    0,  1,    1919379572.0 }  -- CTRL + Shift + ->
    keys.prevTrack      = { 1,    0,  1,    1818584692.0 }  -- CTRL + Shift + <-
    
    keys.insertRow      = { 1,    0,  0,    6909555 }       -- Insert row CTRL+Ins
    keys.removeRow      = { 1,    0,  0,    8 }             -- Remove Row CTRL+Backspace  
    
    keys.m0             = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.m25            = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.m50            = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.m75            = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned
    keys.off2           = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned    
    keys.renoiseplay    = { 0,    0,  0,    500000000000000000000000 }    -- Unassigned

    keys.zoomin         = { 0,    0,  0,    43 }            -- +
    keys.zoomout        = { 0,    0,  0,    45 }            -- -
    
    keys.shiftpgdn      = { 0,    0,  1,    1885824110 }    -- Shift + PgDn
    keys.shiftpgup      = { 0,    0,  1,    1885828464 }    -- Shift + PgUp
    keys.shifthome      = { 0,    0,  1,    1752132965 }    -- Shift + Home
    keys.shiftend       = { 0,    0,  1,    6647396 }       -- Shift + End
    
    help = {
      { 'Shift + Note', 'Advance column after entry' },
      { 'Insert/Backspace/-', 'Insert/Remove/Note OFF' },   
      { 'CTRL + Insert/Backspace', 'Insert Row/Remove Row' },
      { 'Del/.', 'Delete' }, 
      { 'Space/Return', 'Play/Play From' },
      { 'CTRL + L', 'Loop pattern' },
      { 'CTRL + Q/W', 'Loop start/end' },
      { 'Shift + +/-', 'Transpose selection' },
      { 'CTRL + B/E', 'Selection begin/End' },
      { 'SHIFT + Arrow Keys', 'Block selection' },
      { 'CTRL + C/X/V', 'Copy / Cut / Paste' },
      { 'Shift + Del', 'Delete block' },
      { 'CTRL + (SHIFT) + Z', 'Undo / Redo' }, 
      { 'SHIFT + Alt + Up/Down', '[Res]olution Up/Down' },
      { 'SHIFT + Alt + Enter', '[Res]olution Commit' },  
      { 'F4/F5', '[Adv]ance De/Increase' },
      { 'F11/F12', 'Switch Theme / Panic' },
      { 'CTRL + Left/Right', 'Switch MIDI item/track' },   
      { 'CTRL + Shift + Left/Right', 'Switch Track' },         
      { 'CTRL + D', 'Duplicate pattern' },
      { 'CTRL + N', 'Rename pattern' },
      { 'CTRL + R', 'Play notes' },
      { '+/-', 'Zoom in/out' },
      { 'CTRL + +/-', 'Advanced col options' },
    }
  end
end

seq.colorschemes = {"buzz", "it", "hacker", "renoise"}
function seq:loadColors(colorScheme)
  -- If you come up with a cool alternative color scheme, let me know
  self.colors = {}
  self.colors.bar = {}
  self.colors.normal = {}
  self.colors.patternFont = nil
  self.colors.patternFontSize = nil
  local colorScheme = colorScheme or seq.cfg.colorscheme
  if colorScheme == "hacker" then
    self.colors.helpcolor    = {0, .4, .2, 1}
    self.colors.helpcolor2   = {0, .7, .3, 1}
    self.colors.selectcolor  = {0.1, 1.0, 0.4, 1}
    self.colors.selecttext   = {0, 0, 0, 1} -- the cursor
    self.colors.textcolor    = {0, .8, .4, 1}
    self.colors.textcolorbar = {0.05, 1.0, .7, 1}    
    self.colors.headercolor  = {0, .9, .5, 1}
    self.colors.inactive     = {0, .08, .03, 1}    
    self.colors.linecolor    = {0, .1, 0, .4}
    self.colors.linecolor2   = {0, .3, .2, .4}
    self.colors.linecolor3   = {0, .2, 0, 1}
    self.colors.linecolor4   = {.2, .7, .3, .5}
    self.colors.linecolor5   = {0, .5, .4, .3}
    self.colors.loopcolor    = {.2, .7, .2, .5}
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
    self.colors.selecttext       = {0, 0, 0, 1} -- the cursor
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
    self.colors.harmonycolor     = {177/255, 171/255, 116/255, 1.0}
    self.colors.harmonyselect    = {183/255, 255/255, 191/255, 1.0}
    self.colors.helpcolor        = {243/255, 171/255, 116/255, 1.0} -- the functions
    self.colors.helpcolor2       = {178/256, 178/256, 178/256, 1} -- the keys
    self.colors.selectcolor      = {1, 234/256, 20/256, 1} -- the cursor
    self.colors.selecttext       = {0, 0, 0, 1} -- the cursor
    self.colors.textcolor        = {148/256, 148/256, 148/256, 1} --{1/256*60, 1/256*105, 1/256*59, 1} -- main pattern data (rows should all be darker & this should be green)
    self.colors.textcolorbar     = {1, 1, 1, 1}
    self.colors.headercolor      = {215/256, 215/256, 215/256, 1} -- column headers, statusbar etc
    self.colors.inactive         = {35/256,35/256,35/256,55/256} -- {115/256, 115/256, 115/256, 1} -- column headers, statusbar etc    
    self.colors.linecolor        = {18/256,18/256,18/256, 0.6} -- normal row
    self.colors.linecolor2       = {1/256*55, 1/256*55, 1/256*55, 0.6} -- beats (must not have 100% alpha as it's drawn over the cursor(!))
    self.colors.linecolor3       = {1/256*180, 1/256*148, 1/256*120, 1} -- scroll indicating trangle thingy
    self.colors.linecolor5       = {41/256, 41/256, 41/256, 1.0} -- Bar start
    self.colors.copypaste        = {1/256*57, 1/256*57, 1/256*20, 0.66}  -- the selection (should be lighter(not alpha blanded) but is drawn over the data)
    self.colors.scrollbar1       = {98/256, 98/256, 98/256, 1} -- scrollbar handle & outline
    self.colors.scrollbar2       = {19/256, 19/256, 19/256, 1} -- scrollbar background
    self.colors.changed          = {1, 1, 0, 1}
    self.colors.changed2         = {0, .5, 1, .5} -- Only listening
    self.colors.windowbackground = {18/256, 18/256, 18/256, 1}
    self.crtStrength             = 0   
    
    self.colors.linecolor4       = {243/255, 171/255, 116/255, 1.0} -- {1/256*204, 1/256*204, 1/256*68, 1} -- Reaper edit cursor
    self.colors.loopcolor        = {123/255, 149/255, 197/255, 1.0} -- {1/256*204, 1/256*204, 1/256*68, 1} -- lines surrounding loop
    
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
    
    self.colors.selectcolor      = {255/255, 159/255, 88/255, 1.0}
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
  local mix                       = 0.6
  self.colors.linecolor7          = {self.colors.linecolor5[1]*mix+(1-mix)*(self.colors.windowbackground[1]), self.colors.linecolor5[2]*mix+(1-mix)*(self.colors.windowbackground[1]), self.colors.linecolor5[3]*mix+(1-mix)*(self.colors.windowbackground[2]), self.colors.linecolor5[4]}
  self.colors.selectLight         = {self.colors.selectcolor[1], self.colors.selectcolor[2], self.colors.selectcolor[3], .2 * self.colors.selectcolor[4]}
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

function isempty(t)
    for _,_ in pairs(t) do
        return false
    end
    return true
end

------------------------------
-- Scrollbar
------------------------------
scrollbar = {}
function scrollbar.create( w )
  self = {}
  self.w = w
  self.setPos = function ( self, x, y, h )
    self.x = x
    self.y = y
    self.h = h
    
    self.ytop = ytop
    self.yend = yend
  end
  self.setExtent = function( self, ytop, yend )
    self.ytop = ytop
    self.yend = yend
  end
  
  self.mouseUpdate = function(self, mx, my, left)
    local loc
    if ( left == 1 ) then
      if ( ( mx > self.x ) and ( mx < self.x + self.w ) ) then
        if ( ( my > self.y ) and ( my < self.y + self.h ) ) then
          loc = ( my - self.y ) / self.h
        end
      end
      return loc
    end
  end
  
  self.draw = function(self, colors)
    local x = self.x
    local y = self.y
    local w = self.w
    local h = self.h
    local ytop = self.ytop
    local yend = self.yend
    
    gfx.set(table.unpack(colors.scrollbar1))
    gfx.rect(x, y, w, h)
    gfx.set(table.unpack(colors.scrollbar2))
    gfx.rect(x+1, y+1, w-2, h-2)
    gfx.set(table.unpack(colors.scrollbar1))
    gfx.rect(x+2, y + ytop*h+2, w-4, (yend-ytop)*h-3)
  end
  
  return self
end

-- Prep process
function seq:selectMediaItem(item)
  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(item, true)
end

function seq:newName(name)
  local addi = 1
  local repeatIt = 1
  local testName
  
  while ( repeatIt == 1 ) do
    repeatIt = 0
    for i,v in pairs( self.patternNames[self.xpos] ) do
      testName = string.format("%s (%d)", name, addi)
      if ( testName == v ) then
        addi = addi + 1
        repeatIt = 1
      end
    end
  end
  
  return testName
end

function seq:uniqueMIDI(track, row)
  local trackItems = self.trackItems
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local eps = self.eps

  --41613  Item: Remove active take from MIDI source data pool (AKA un-pool, un-ghost, make unique)
  reaper.SelectAllMediaItems(0, false)

  local cTrack = reaper.GetTrack(0, track)
  for i,v in pairs(trackItems) do
    if ( v[2] == cTrack ) then
      local pos = reaper.GetMediaItemInfo_Value( v[1], "D_POSITION" )
      if ( math.floor( pos / rps + eps ) == row ) then
        -- Do not unique-ify OFF symbols
        if ( v[4] == self.offItem[4] ) then
          return
        end
      
        reaper.SetMediaItemInfo_Value( v[1], "B_UISEL", 1 )
        local ret, str = reaper.GetSetMediaItemTakeInfo_String(v[3], "P_NAME", "", false)       
        --self.patternNames[self.xpos][self.patterns[self.xpos][self.ypos]]
        reaper.GetSetMediaItemTakeInfo_String(v[3], "P_NAME", seq:newName(str), true)
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
  local eps = self.eps
  if ( self.cfg.automation == 1 ) then
    for envIdx = 0,reaper.CountTrackEnvelopes(cTrack)-1 do
      local trackEnv = reaper.GetTrackEnvelope(cTrack, envIdx)
      for i=0,reaper.CountAutomationItems(trackEnv)-1 do
        local d_pos = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POSITION", 0, false)
        if ( math.floor( d_pos / rps + eps ) == row ) then
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
  local reaper      = reaper
  local poolGUIDs   = {}
  local trackItems  = {}
  
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
  
  self.poolGUIDs  = poolGUIDs
  self.trackItems = trackItems
  self.maxloc     = maxloc
end
  
function seq:copyUnknownToPool()
  local reaper      = reaper
  local trackItems  = self.trackItems
  local poolGUIDs   = self.poolGUIDs
  
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
  
  -- Deal with the OFF items separately. They are not part of the regular pooling
  local offItem = nil
  for i,v in pairs( poolGUIDs ) do
    local ret, str = reaper.GetSetMediaItemTakeInfo_String(v[3], "P_NAME", "", false )
    if ( str == "__OFF__" ) then
      offItem = {v[1], v[2], v[3], i}
      poolGUIDs[i] = nil
    end
  end
  if ( not offItem ) then
    local cTrack    = reaper.GetTrack(0,0)
    local mediaItem = reaper.CreateNewMIDIItemInProj(cTrack, maxloc[cTrack], reaper.TimeMap2_QNToTime(0, 1) * 0.125, nil)
    local take      = reaper.GetActiveTake(mediaItem)
    local ret, str  = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "__OFF__", true )
    local ret, GUID = reaper.BR_GetMidiTakePoolGUID(take)
    offItem = {mediaItem, cTrack, take, GUID}
  end
  
  self.offItem = offItem
  self.poolGUIDs = poolGUIDs
  self.maxloc = maxloc
  
  self:popPosition()
end

function seq:deleteFromPool(trackidx, poolidx)
  local idxToGUID   = self.idxToGUID
  local poolGUIDs   = self.poolGUIDs
  local trackItems  = self.trackItems
  local GUID        = idxToGUID[trackidx][poolidx]
  
  local poolTable = poolGUIDs[GUID] -- { mediaItem, track, take }
  local mediaItem = poolTable[1]
  local cTrack    = poolTable[2]
  local reaper    = reaper
  
  --------------------------------------------------
  -- Find corresponding automation GUIDs to delete
  --------------------------------------------------
  local m_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  
  reaper.Main_OnCommand(40769, 0) -- Deselect all items  
  reaper.SelectAllMediaItems(0, false)
  
  reaper.SetMediaItemSelected(mediaItem, true)
  
  local automationPoolIDs = {}
  for envIdx = 0,reaper.CountTrackEnvelopes(cTrack)-1 do
    local trackEnv = reaper.GetTrackEnvelope(cTrack, envIdx)
    for i=0,reaper.CountAutomationItems(trackEnv)-1 do
      local d_pos = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POSITION", 0, false)
      if ( d_pos == m_pos ) then
        -- Got one!
        local pool_id = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POOL_ID", 0, false)
        reaper.GetSetAutomationItemInfo(trackEnv, i, "D_UISEL", 1, true)
        automationPoolIDs[pool_id] = 1
      end
    end
  end
  
  -- Check if there are any that aren't in the pool yet.
  for i,v in pairs( trackItems ) do
    local curGUID = v[4]
    local c_pos = reaper.GetMediaItemInfo_Value(v[1], "D_POSITION")
    if ( curGUID == GUID ) then
      -- Find automation on this line
      local autoItems = {}
      for envIdx = 0,reaper.CountTrackEnvelopes(cTrack)-1 do
        local trackEnv = reaper.GetTrackEnvelope(cTrack, envIdx)
        for j=0,reaper.CountAutomationItems(trackEnv)-1 do
          -- See if we have all the automation items that were at the pool represented here.
          if ( reaper.GetSetAutomationItemInfo( trackEnv, j, "D_POSITION", 0, false ) == c_pos ) then
            local curpool_id = reaper.GetSetAutomationItemInfo(trackEnv, j, "D_POOL_ID", 0, false)
            if ( automationPoolIDs[curpool_id] ) then
              autoItems[#autoItems+1] = { trackEnv, j }
            end
          end
        end
      end

      -- Select MIDI item / automation item pairs that fully match only
      if ( #autoItems == #automationPoolIDs ) then
        reaper.SetMediaItemSelected(v[1], true)
        reaper.SetOnlyTrackSelected(cTrack)
        for i,v in pairs( autoItems ) do
          reaper.GetSetAutomationItemInfo(v[1], v[2], "D_UISEL", 1, true)
        end
      else
        -- print("Failed automation match")
      end
    end
  end
  
  reaper.Main_OnCommand(40006, 0) -- Delete automation items
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
      
      guidToPatternIdx[jTrack][self.offItem[4]] = 0
      idxToGUID[jTrack][0] = self.offItem[4]
      patternNames[jTrack][0] = "OFF"
    end
  end
  
  local idx = {}
  for jTrack=0,nTracks-1 do
    idx[jTrack] = 1
  end
  
  -- Sort the GUID table
  local sortedKeys = {}
  for i in pairs(self.poolGUIDs) do
    table.insert(sortedKeys, i)
  end
  table.sort(sortedKeys)
  
  local poolGUIDs = self.poolGUIDs
  for j,w in pairs( sortedKeys ) do
    i = w
    v = poolGUIDs[w]
    
    trackidx = trackToIndex[v[2]]
    index = idx[trackidx]
  
    -- If it hasn't been seen, add it
    if ( not guidToPatternIdx[trackidx][i] ) then
      guidToPatternIdx[trackidx][i] = index
      idxToGUID[trackidx][index]    = i
      
      local str = reaper.GetTakeName(v[3])
      if ( str == "untitled MIDI item" ) then
        patternNames[trackidx][index] = string.format("%02d", index)
      elseif ( str == "" ) then
        patternNames[trackidx][index] = string.format("%02d", index)      
      else
        patternNames[trackidx][index] = fitStr( str, cellw )
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
  seq:saveConfigFile( fn, cfg )
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
  self:saveConfig("seq.cfg", self.cfg)
  gfx.quit()
end

-- Fetch the track names and construct a table which has the tracks.
function seq:fetchTracks()
  local reaper        = reaper
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
  local highlight     = {}
  local trackToIndex  = self.trackToIndex
  local eps           = self.eps
  
  -- Go over all the media items we found that weren't in the pool
  --   trackItems[i] = { mediaItem, track, take, GUID }
  --   guidToPatternIdx[i] = c
  for i=0,self.max_xpos-1 do
    patterns[i] = {}
    highlight[i] = {}
  end
  local dy = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local guidToPatternIdx = self.guidToPatternIdx
  
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0,i)
    local trackIdx = trackToIndex[reaper.GetMediaItemTrack(mediaItem)]
    local pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
    local mute = reaper.GetMediaItemInfo_Value(mediaItem, "B_MUTE")
    local len = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")    
    local ystart = math.floor(pos/dy + eps)
    local yend = math.ceil((pos+len)/dy - eps)
    for q = ystart,yend-1 do
      patterns[trackIdx][q] = -2
      if ( mute == 1 ) then
        highlight[trackIdx][q] = -1
      end
    end
  end
  
  for i,v in pairs(self.trackItems) do
    local trackGUID = v[4]
    local pos = reaper.GetMediaItemInfo_Value(v[1], "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(v[1], "D_LENGTH")
    local mute = reaper.GetMediaItemInfo_Value(v[1], "B_MUTE")
    local ystart = math.floor(pos/dy + eps)
    local yend = math.ceil((pos+len)/dy - eps)
    local q = ystart
    local trackIdx = trackToIndex[v[2]]
    patterns[trackIdx][q] = guidToPatternIdx[trackIdx][trackGUID]
    --print(self.patternNames[trackIdx][guidToPatternIdx[trackIdx][trackGUID]])
    if ( mute == 1 ) then
      highlight[trackIdx][q] = -1
    end
    if ( self.hoverGUID == trackGUID ) then
      highlight[trackIdx][q] = 1
      for q = ystart+1,yend-1 do
        highlight[trackIdx][q] = 1
      end
    end
    for q = ystart+1,yend-1 do
      patterns[trackIdx][q] = -1
    end
  end
  self.patterns     = patterns
  self.highlight    = highlight
end

function seq:_updateData()
  seq:computeSize()
  seq:fetchTracks()
  seq:fetchPatterns()
  seq:copyUnknownToPool()
  seq:buildPatternList()
  seq:populateSequencer()
end

function seq:updateData()
  reaper.PreventUIRefresh(1)
  seq:_updateData()
  reaper.PreventUIRefresh(-1)
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
  local highlight     = self.highlight
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

  ---------------------------------
  -- Draw headers
  ---------------------------------
  local mm = .5*gfx.measurestr("M")
  local ms = .5*gfx.measurestr("S")  
  for ix=xStart,xEnd do
    local xl = xOrigin + fw*(ix+1)
    local cTrack = reaper.GetTrack( 0, ix+scrollx )
    local offs = .5*gfx.measurestr(trackTitles[ix+scrollx])
    gfx.x = xl + .5*fw - offs
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
    gfx.set( table.unpack( colors.inactive ) )
    gfx.rect( xl+.5*fw, yOrigin + 1*fh-1, 1, fh )
  end 
   
  ---------------------------------
  -- Dark alternating colors
  ---------------------------------
  offs = - (scrolly - 8*math.floor(scrolly/8))
  gfx.set( table.unpack( colors.linecolor2 ) )
  for iy = 6+offs,ymax+2,8 do
    gfx.rect( xOrigin, yOrigin + fh * iy, fw, fh )
  end
  gfx.set( table.unpack( colors.linecolor5 ) )
  for iy = 2+offs,ymax+2,8 do
    gfx.rect( xOrigin, yOrigin + fh * iy, fw, fh )
  end
  
  -- Horizontal lines
  for iy=1,ymax do
    gfx.set( table.unpack( colors.inactive ) )
    gfx.rect( xOrigin + 3,  yOrigin + (iy+1)*fh-1, fw * (xEnd-xStart+2)-3, 1 )
  end
  
  ------------------------------------------
  -- Pattern blocks
  ------------------------------------------
  local colors = colors
  gfx.set( table.unpack( colors.textcolor ) )
  for ix=xStart,xEnd do
    for iy=0,ymax do
      gfx.x = xOrigin + (ix+1)*fw + 3
      gfx.y = yOrigin + (iy+2)*fh
      local curElement = patterns[ix+scrollx][iy+scrolly]
      local elementColor = highlight[ix+scrollx][iy+scrolly] or 0
      if ( curElement ) then
        local nextElement = 0
        if ( patterns[ix+scrollx][iy+scrolly+1] ) then
          nextElement = 1
        end
        if ( curElement < -1 ) then
          gfx.set( table.unpack( colors.linecolor6 ) )
        else
          if ( elementColor == 0 ) then
            gfx.set( table.unpack( colors.linecolor5 ) )
          elseif ( elementColor == 1 ) then
            gfx.set( table.unpack( colors.linecolor2 ) )
          elseif ( elementColor == -1 ) then
            gfx.set( table.unpack( colors.linecolor7 ) )            
          end
        end
        gfx.rect( gfx.x-3, gfx.y, fw, fh-1+nextElement )
        if ( curElement >= 0 ) then
          gfx.set( table.unpack( colors.textcolor ) )
          if ( elementColor == -1 ) then
            gfx.printf("%s [M]", patternNames[ix+scrollx][curElement]:sub(1,-4))
          else
            gfx.printf("%s", patternNames[ix+scrollx][curElement])
          end
        else
        end
      else
        gfx.set( table.unpack( colors.textcolor ) )
        gfx.printf("...")
      end
    end
  end
  
  --[[gfx.set( table.unpack( colors.textcolor ) )
  for ix=xStart,xEnd+1 do
    gfx.rect( xOrigin + fw*(ix+1), yOrigin, 1, fh*2 )
  end
  gfx.rect( xOrigin + fw, yOrigin, 1, gfx.h-yOrigin )  ]]--
  
  -- Vertical lines
  gfx.set( table.unpack( colors.inactive ) )
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
  
  -------------------------------------
  -- Cursor
  -------------------------------------
  if ( patterns and not isempty(patterns) ) then
    if ( patterns[self.xpos] ) then
      gfx.set( table.unpack( colors.linecolor3 ) )
      gfx.rect( xOrigin + fw * ( 1 + xrel ) + 1, xOrigin + ( 2 + yrel ) * fh, fw - 1, fh )
      local curElement = patterns[self.xpos][self.ypos]
      if ( curElement and curElement > 0 ) then
        if ( self.renaming == 1 ) then
          gfx.set( table.unpack( colors.changed ) )
        else
          gfx.set( table.unpack( colors.selecttext ) )     --self.colors.selecttext     
        end
        gfx.x = xOrigin + fw * ( 1 + xrel ) + 3
        gfx.y = xOrigin + ( 2 + yrel ) * fh
        gfx.printf("%s", patternNames[self.xpos][curElement])
      end
    end
  end
  
  gfx.set( table.unpack( colors.selectLight ) )
  gfx.rect( 0, xOrigin + ( 2 + yrel ) * fh, (fov.width+2)*fw, fh )
  gfx.set( table.unpack( colors.textcolor ) )
  
  -- Tick counts
  local res = seq.res * self.cfg.zoom
  local xs = xOrigin + fw - 5
  for iy=0,ymax do
    str = string.format( "%3d", res * (iy +scrolly)  )
    gfx.x = xs - gfx.measurestr( str )
    gfx.y = yOrigin + (iy+2)*fh
    gfx.printf( str )
  end
  
  ----------------------------------------------
  -- Header lines
  ----------------------------------------------
  gfx.set( table.unpack( colors.inactive ) )
  gfx.rect( xOrigin+fw, yOrigin, fw * (xEnd-xStart+1), 1 )
  gfx.rect( xOrigin+fw, yOrigin + fh-1, fw * (xEnd-xStart+1), 1 )
  gfx.rect( xOrigin+fw, yOrigin + 2*fh-1, fw * (xEnd-xStart+1), 1 )
   

  -------------------------------------
  -- Draw pattern names
  --------------------------------------
  self.patternScrollbar:setPos( gfx.w - 30, 3*fh, fh * (seq.cfg.patternLines) )
    
  local cfg = self.cfg
  gfx.set( table.unpack( colors.textcolor ) )
  if ( not isempty(patterns) ) then
    local X = gfx.w - cfg.nameSize
    local boxsize = cfg.boxsize
    gfx.x = X 
    gfx.y = fh
    gfx.printf( "Track patterns/items" )
    local chars = seq.chars
    local patternNames = self.patternNames[self.xpos]
    local nP = #patternNames
    
    local scroll
    if ( nP > cfg.patternLines ) then
      scroll = math.floor( fov.scrollpat * (#patternNames - cfg.patternLines + 1) )
    else
      scroll = 0
    end
    local min = scroll
    local max = scroll + cfg.patternLines
    if ( max > nP ) then
      max = nP
    end
    
    local j = 1
    for i=min+1,max do
      local v = patternNames[i]
      local Y = (2+j) * fh
      gfx.line(X, Y, X+boxsize, Y+boxsize)
      gfx.line(X+boxsize, Y, X, Y+boxsize)
      gfx.line(X, Y, X+boxsize, Y)
      gfx.line(X, Y, X, Y+boxsize)
      gfx.line(X+boxsize, Y, X, Y+boxsize)
      gfx.line(X+boxsize, Y, X+boxsize, Y+boxsize)
      gfx.line(X, Y+boxsize, X+boxsize, Y+boxsize)
      gfx.x = X+14
      gfx.y = Y-1
      gfx.printf( "%s. %s", chars:sub(i,i), v )
      j = j + 1
    end
    
    if ( nP > cfg.patternLines ) then
      self.patternScrollbar:setExtent( min / nP, max / nP )
      self.patternScrollbar:draw(colors)
    end
  end
  
  ------------------------------
  -- Play location indicator
  ------------------------------
  local rps = reaper.TimeMap2_QNToTime(0, 1) * cfg.zoom
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
      gfx.rect(xOrigin + fw + 1, yOrigin + 2 * fh + fh * playLoc - 1, tw, 1)
  end

  local markerLoc = reaper.GetCursorPosition() / rps - scrolly
  if ( markerLoc > 0 and markerLoc < height ) then
    gfx.set(table.unpack(colors.linecolor4))
    gfx.rect(xOrigin + fw + 1, yOrigin + 2 * fh + fh * markerLoc - 1, tw, 1)
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
  local eps = self.eps
  for i,v in pairs(trackItems) do
    if ( v[2] == cTrack ) then
      local pos = reaper.GetMediaItemInfo_Value( v[1], "D_POSITION" )
      local len = reaper.GetMediaItemInfo_Value( v[1], "D_LENGTH" )
      if ( math.floor( pos / rps + eps ) <= row and math.floor( (pos+len)/rps + eps ) >= row ) then
        local GUID = v[4]
        local poolItem = poolGUIDs[GUID]
        if ( poolItem ) then
          local itemLen = reaper.GetMediaItemInfo_Value( poolItem[1], "D_LENGTH" )
          local maxLen = (row*rps - pos) + mindist
          if ( itemLen > maxLen ) then
            itemLen = maxLen
          end
          reaper.SetMediaItemInfo_Value( v[1], "D_LENGTH", itemLen )
          
          if ( self.cfg.automation == 1 ) then
            for envIdx = 0,reaper.CountTrackEnvelopes(cTrack)-1 do
              local trackEnv = reaper.GetTrackEnvelope(cTrack, envIdx)
              for i=0,reaper.CountAutomationItems(trackEnv)-1 do
                local d_pos = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POSITION", 0, false)
                local d_len = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_LENGTH", 0, false)                
                if ( math.floor( d_pos / rps + eps ) <= row and math.floor( (d_pos+d_len)/rps + eps ) >= row ) then
                  reaper.GetSetAutomationItemInfo(trackEnv, i, "D_LENGTH", itemLen, true)
                end
              end
            end
          end
        end
      end
    end
  end
end

function seq:deleteRange(track, row, tcnt, rcnt, noupdate)
  local trackItems  = self.trackItems
  local rps         = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local eps         = self.eps
  local reaper      = reaper
  local cTrack      = reaper.GetTrack(0, track)
  
  -- Delete 
  --for i,v in pairs(trackItems) do
  --  if ( v[2] == cTrack ) then
  --    local pos = reaper.GetMediaItemInfo_Value( v[1], "D_POSITION" )
  --    if ( math.floor( pos / rps + eps ) == row ) then
  --      reaper.DeleteTrackMediaItem(v[2], v[1])
  --    end
  --  end
  --end
  
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    if ( mediaItem ) then
      -- Only deal with media items on this track
      if ( reaper.GetMediaItem_Track(mediaItem) == cTrack ) then
        local d_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
        if ( d_pos < postMusic ) then
          if ( math.floor( d_pos / rps + eps ) == row ) then
            reaper.DeleteTrackMediaItem(cTrack, mediaItem)
          end
        end
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
        if ( math.floor( d_pos / rps + eps ) == row ) then
          --reaper.DeleteTrackMediaItem(v[2], v[1])
          if not deletedAutomation then
            --reaper.SelectAllMediaItems(0, false)
            reaper.Main_OnCommand(40769, 0) -- Deselect all items
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
  
  if ( not noupdate ) then
    seq:updateData()
  end
end

function seq:delete()
  self:deleteRange(self.xpos, self.ypos, 0, 0)
  reaper.UpdateArrange()
  
  if ( self.ypos > 0 ) then
    self:mend(self.xpos, self.ypos)
  end
end

function seq:backspace()
  self:deleteRange(self.xpos, self.ypos, 0, 0)
  self:insert(nil, self.ypos+1, -1)
  if ( self.ypos > 0 ) then
    self:mend(self.xpos, self.ypos-1)
  end  
end

-- This has its own function since calling backspace for each cell was slow
function seq:backspaceRow()
  for i=0,reaper.CountTracks()-1 do
    self.xpos = i
    self:deleteRange(self.xpos, self.ypos, 0, 0, 1)
  end
  self:updateData()
  
  for i=0,reaper.CountTracks()-1 do
    self.xpos = i
    self:insert(nil, self.ypos+1, -1)
    if ( self.ypos > 0 ) then
      self:mend(self.xpos, self.ypos-1)
    end
  end
end

function seq:insert(xpos, ypos, sign)
  local cTrack = reaper.GetTrack(0, xpos or self.xpos)
  local row = ypos or self.ypos
  local eps = self.eps
  
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local delta = (sign or 1) * rps
  
  -- Media items
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    -- Only deal with media items on this track
    if ( reaper.GetMediaItem_Track(mediaItem) == cTrack ) then
      local d_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      if ( d_pos < postMusic ) then
        if ( math.floor( d_pos / rps + eps ) >= row ) then
          reaper.SetMediaItemInfo_Value(mediaItem, "D_POSITION", d_pos + delta)
        else
          local d_len = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
          if ( math.floor( (d_pos + d_len) / rps + eps ) >= row ) then
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
          if ( math.floor( d_pos / rps + eps ) >= row ) then
            reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POSITION", d_pos + delta, true)
          else
            local d_len = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_LENGTH", 0, false)
            if ( math.floor( (d_pos + d_len) / rps + eps ) > row ) then
              -- Grow/Shrink this one!
              --reaper.GetSetAutomationItemInfo(trackEnv, i, "D_LENGTH", d_len + delta, true)
            end
          end
        end
      end
    end
  end
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
  local eps = self.eps
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    -- Only deal with media items on this track
    if ( reaper.GetMediaItem_Track(mediaItem) == cTrack ) then
      local d_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      if ( d_pos < postMusic ) then
        if ( math.floor( d_pos / rps + eps ) < row ) then
          local d_len = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
          if ( math.floor( (d_pos + d_len) / rps + eps ) >= row ) then
            reaper.SetMediaItemInfo_Value(mediaItem, "D_LENGTH", row*rps - d_pos, true)
          end
        end
      end
    end  
  end
  
  -- Automation items
  local eps = self.eps
  if ( self.cfg.automation == 1 ) then
    for envIdx = 0,reaper.CountTrackEnvelopes(cTrack)-1 do
      local trackEnv = reaper.GetTrackEnvelope(cTrack, envIdx)
      for i=0,reaper.CountAutomationItems(trackEnv)-1 do
        local d_pos = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_POSITION", 0, false)
        if ( d_pos < postMusic ) then
          if ( math.floor( d_pos / rps + eps ) < row ) then
            local d_len = reaper.GetSetAutomationItemInfo(trackEnv, i, "D_LENGTH", 0, false)
            if ( math.floor( (d_pos + d_len) / rps + eps ) >= row ) then
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
  local eps = self.eps
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    -- Only deal with media items on this track
    if ( reaper.GetMediaItem_Track(mediaItem) == cTrack ) then
      local d_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      if ( d_pos < postMusic ) then
        if ( math.floor( d_pos / rps + eps ) > row ) then
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

function seq:off()
  seq:addItemDirect(self.offItem)
end

function seq:addItem( idx )
  -- Actually paste the new pattern
  local GUID = self.idxToGUID[self.xpos][ idx ]
  local v = self.poolGUIDs[ GUID ]
  self:addItemDirect(v)
end

function seq:addItemDirect(v)
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
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

function seq:getGUID(mediaItem)
  local take = reaper.GetActiveTake(mediaItem)
  if ( reaper.TakeIsMIDI(take) ) then
    local retval
    retval, GUID = reaper.BR_GetMidiTakePoolGUID(take)
    return GUID
  end
end

function seq:startHT(track, row)
  local eps = self.eps
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local cTrack = reaper.GetTrack(0, track)
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    -- Only deal with media items on this track
    if ( reaper.GetMediaItem_Track(mediaItem) == cTrack ) then
      local d_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
        if ( math.floor( d_pos / rps + eps ) == row ) then
          local GUID = self:getGUID(mediaItem)
        
          if ( GUID ) then
            -- Do not unique-ify OFF symbols
            if ( GUID == self.offItem[4] ) then
              return
          end
          reaper.SetProjExtState(0, "MVJV001", "initialiseAtTrack", track)
          reaper.SetProjExtState(0, "MVJV001", "initialiseAtRow", row*rps)
          self:callScript(hackeyTrackey)
        end
      end
    end
  end
end

function seq:rename(track, row)
  -- Media items
  local name, GUID
  local cTrack = reaper.GetTrack(0, track)
  local rps = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  local eps = self.eps
  
  for i=0,reaper.CountMediaItems(0)-1 do
    local mediaItem = reaper.GetMediaItem(0, i)
    -- Only deal with media items on this track
    if ( reaper.GetMediaItem_Track(mediaItem) == cTrack ) then
      local d_pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      if ( d_pos < postMusic ) then
        if ( math.floor( d_pos / rps + eps ) == row ) then
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

local function findCommandID(name)
  local commandID
  local lines = {}
  local fn = reaper.GetResourcePath() .. '//' .. "Reaper-kb.ini"
  for line in io.lines(fn) do
    lines[#lines + 1] = line
  end
  
  for i,v in pairs(lines) do
    if ( v:find(name, 1, true) ) then
      local startidx = v:find("RS", 1, true)
      local endidx = v:find(" ", startidx, true)
      commandID = (v:sub(startidx,endidx-1))
    end
  end
  
  if ( commandID ) then
    return "_" .. commandID
  end
end

function seq:callScript(scriptName)
  if ( not scriptName ) then
    reaper.ShowMessageBox("Error callScript called without specifying a script", "Error", 0)
    return
  end

  local cmdID = findCommandID( scriptName )
  
  if ( cmdID ) then
    local cmd = reaper.NamedCommandLookup( cmdID )
    if ( cmd ) then
      reaper.Main_OnCommand(cmd, 0)
    else
      reaper.ShowMessageBox("Failed to load script "..cmd, "Error", 0)
    end
  end
end

function seq:processMouseActions()
  local seq                 = seq
  local gfx                 = gfx
  local fw                  = self.cellw
  local fh                  = self.cellh
  local fov                 = self.fov
  local scrollx             = fov.scrollx
  local scrolly             = fov.scrolly
  local left, right, middle = mouseStatus()
  local ctime               = reaper.time_precise()
  local lastLeft            = self.lastLeft
  local rps                 = reaper.TimeMap2_QNToTime(0, 1) * self.cfg.zoom
  
  local loc = self.patternScrollbar:mouseUpdate(gfx.mouse_x, gfx.mouse_y, left)
  if ( loc ) then
    self.fov.scrollpat = loc
  end
  
  if ( gfx.mouse_wheel ~= 0 ) then
    local scFactor = 1
    if ( ( gfx.mouse_cap & 8 ) == 0 ) then
      scFactor = self.cfg.largeScroll
    end
  
    self.ypos = self.ypos - scFactor * math.floor( gfx.mouse_wheel / 120 )
    self:resetShiftSelect()
    gfx.mouse_wheel = 0
  end 
  
  if ( left == 1 ) then
    if ( gfx.mouse_y < fh ) then
    elseif ( gfx.mouse_y > fh and gfx.mouse_y < 2*fh ) then
      -- Mute / Solo handling
      local cTrack = math.floor( gfx.mouse_x / fw )
      if ( lastLeft == 0 and cTrack > 0 ) then
        if ( gfx.mouse_x - fw * cTrack ) < 0.5 * fw then
          self:toggleMute(scrollx + cTrack-1)
        else
          self:toggleSolo(scrollx + cTrack-1)
        end
      end
    elseif ( gfx.mouse_x < fw ) then
      reaper.SetEditCurPos2(0, ( math.floor(gfx.mouse_y / fh) - 2 ) * rps, true, false)
    elseif ( gfx.mouse_x < fw * (fov.width+2) ) then
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
          
          local doubleClickInterval = 0.2
          if ( (ctime - self.lastLeftTime) < doubleClickInterval ) then
            self:startHT(self.xpos, self.ypos)
          end
        else
          -- Change selection if it wasn't the initial click
          seq:dragBlock(Inew+fov.scrollx-1, Jnew+fov.scrolly-2)
        end
      end
    else
      -- Pattern / settings area
      if ( lastLeft == 0 ) then
        local boxsize = self.cfg.boxsize
        if ( gfx.mouse_x > gfx.w - self.cfg.nameSize ) then
          if ( gfx.mouse_x < gfx.w - self.cfg.nameSize + boxsize ) then
            i = math.floor((gfx.mouse_y - 2) / fh)-2
            if ( i > 0 ) then
              local pNames = self.patternNames[self.xpos]
              -- Which pattern are we trying to delete?
              if i <= #pNames then
                reaper.Undo_OnStateChange2(0, "Sequencer: Delete from pool")
                reaper.MarkProjectDirty(0)
                local scroll = math.floor( self.fov.scrollpat * (#pNames - self.cfg.patternLines + 1) )
                self:deleteFromPool(self.xpos, i+scroll)
                reaper.UpdateArrange()
              end
            end
          end
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
        reaper.Undo_OnStateChange2(0, "Sequencer: Uniqueify Pattern")
        reaper.MarkProjectDirty(0)
        seq:uniqueifyElement(self.xpos, self.ypos)
      end
    end
    self.lastMiddle = 1
  else
    self.lastMiddle = 0
  end
  
  self.hoverGUID = nil
  if ( gfx.mouse_x > gfx.w - self.cfg.nameSize ) then
    if ( gfx.mouse_x < gfx.w ) then
      i = math.floor((gfx.mouse_y - 2) / fh)-2
      if ( i > 0 ) then
        local pNames = self.patternNames[self.xpos]
        -- Which pattern are we trying to delete?
        if pNames then
          i = i + math.floor( self.fov.scrollpat * (#pNames - self.cfg.patternLines + 1) )
          if i <= #pNames then
            self.hoverGUID = self.idxToGUID[self.xpos][i]
          end
        end
      end
    end
  end
end

function seq:swapTheme()
  local j
  for i,v in pairs( self.colorschemes ) do
    if self.cfg.theme == v then
      j = i
    end
  end
  j = j + 1
  if ( j > #self.colorschemes ) then
    j = 1
  end
   self.cfg.theme = self.colorschemes[j]
   self:loadColors( self.cfg.theme )
end

local function updateLoop()

  if ( not reaper.GetTrack(0,0) ) then
    reaper.ShowMessageBox("Error: This project has no tracks.", "Error", 0)
    gfx.quit()
    return
  end

  prevChar = lastChar
  lastChar = gfx.getchar()
  
  if ( seq.renaming == 0 ) then
    seq:processMouseActions()
  end
  
  -- Only update data when stuff is happening (avoid plugin to constantly mess with the selection when user
  -- may be editing in the arrange view).
  if ( lastChar > 0 or gfx.mouse_cap > 0 or seq.change == 1 or ( seq.lastTrackCount ~= reaper.CountTracks(0) ) ) then
    seq:updateData()
    seq.change = 0
  end
  seq:updateGUI()
  gfx.update()
  seq.lastTrackCount = reaper.CountTracks(0)
  
  if lastChar ~= -1 then
    seq.change = 1
    if ( seq.renaming == 0 ) then
      if inputs('hackeytrackey') then
        seq:startHT(seq.xpos, seq.ypos)
      elseif inputs('theme') then
        seq:swapTheme()
      elseif inputs('left') then
        seq.xpos = seq.xpos - 1
        seq:resetShiftSelect()
      elseif inputs('right') then
        seq.xpos = seq.xpos + 1
        seq:resetShiftSelect()
      elseif inputs('tab') then
        seq.xpos = seq.xpos + 1
        seq:resetShiftSelect()
      elseif inputs('shifttab') then
        seq.xpos = seq.xpos - 1
        seq:resetShiftSelect()
      elseif inputs('up') then
        seq.ypos = seq.ypos - 1
        seq:resetShiftSelect()
      elseif inputs('down') then
        seq.ypos = seq.ypos + 1
        seq:resetShiftSelect()
      elseif inputs('insert') then
        reaper.Undo_OnStateChange2(0, "Sequencer: Insert (Ins)")
        reaper.MarkProjectDirty(0)
        seq:pushPosition()
        seq:insert()
        if ( seq.ypos > 0 ) then
          seq:mend(seq.xpos, seq.ypos-1)
        end
        seq:popPosition()
        reaper.UpdateArrange()
      elseif inputs('insertRow') then
        reaper.Undo_OnStateChange2(0, "Sequencer: Insert Row (InsRow)")
        reaper.MarkProjectDirty(0)
        seq:pushPosition()
        local oldx = seq.xpos
        for i=0,reaper.CountTracks()-1 do
          seq.xpos = i
          seq:insert()
          if ( seq.ypos > 0 ) then
            seq:mend(seq.xpos, seq.ypos-1)
          end
        end
        seq.xpos = oldx
        seq:popPosition()
        reaper.UpdateArrange()
      elseif inputs('removeRow') then
        reaper.Undo_OnStateChange2(0, "Sequencer: Remove Row (RemRow)")
        reaper.MarkProjectDirty(0)
        seq:pushPosition()
        local oldx = seq.xpos
        seq:backspaceRow()
        seq.xpos = oldx
        seq:popPosition()
        reaper.UpdateArrange()
      elseif inputs('remove') then
        reaper.Undo_OnStateChange2(0, "Sequencer: Remove (Rem)")
        reaper.MarkProjectDirty(0)
        seq:pushPosition()
        seq:backspace()   
        seq:popPosition()
        reaper.UpdateArrange()
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
        reaper.Undo_OnStateChange2(0, "Sequencer: Rename (Ren)")
        reaper.MarkProjectDirty(0)
        seq:renamePattern()
        reaper.UpdateArrange()
      elseif inputs('undo') then
        reaper.Undo_DoUndo2(0) 
      elseif inputs('redo') then
        reaper.Undo_DoRedo2(0)
      elseif inputs('deleteRow') then
        reaper.Undo_OnStateChange2(0, "Sequencer: Delete Row (DelRow)")
        reaper.MarkProjectDirty(0)
        seq:pushPosition()
        local oldx = seq.xpos
        for i=0,reaper.CountTracks()-1 do
          seq.xpos = i
          seq:delete()
        end
        seq.xpos = oldx
        seq:popPosition()
        reaper.UpdateArrange()
      elseif ( inputs('off') ) then
        reaper.Undo_OnStateChange2(0, "Sequencer: Off (Off)")
        reaper.MarkProjectDirty(0)
        seq:pushPosition()
        seq:off()
        seq:popPosition()
        reaper.UpdateArrange()        
      elseif ( inputs('delete') ) then
        reaper.Undo_OnStateChange2(0, "Sequencer: Delete (Del)")
        reaper.MarkProjectDirty(0)
        seq:pushPosition()
        seq:delete()
        seq:popPosition()
        reaper.UpdateArrange()
      elseif ( inputs('delete2') ) then
        reaper.Undo_OnStateChange2(0, "Sequencer: Delete (Del)")
        reaper.MarkProjectDirty(0)
        seq:pushPosition()
        seq:delete()
        seq:popPosition()
        reaper.UpdateArrange()
        seq.ypos = seq.ypos + seq.advance
      elseif ( inputs('playfrom') ) then
        seq:gotoRow(seq.ypos)
        reaper.Main_OnCommand(40044, 0)
      elseif ( inputs('toggle') ) then
        reaper.Main_OnCommand(40044, 0)
      elseif ( seq.charCodes[lastChar] ) then
        seq:pushPosition()
        seq:addItem( seq.charCodes[ lastChar ] )
        lastChar = 0
        seq:popPosition()
      elseif ( inputs('zoomin') ) then
        seq.cfg.zoom = seq.cfg.zoom * 2
      elseif ( inputs('zoomout') ) then
        seq.cfg.zoom = seq.cfg.zoom / 2
      elseif ( inputs('panic') ) then
        reaper.Main_OnCommand(40345, 0)
      else
        seq.change = 0
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
  
    if ( seq.cfg.followRow == 1 ) then
      if ( seq.ypos ~= seq.lasty ) then
        local rps = reaper.TimeMap2_QNToTime(0, 1) * seq.cfg.zoom
        reaper.SetEditCurPos2(0, seq.ypos * rps, false, false)
      end
    end
  
    if ( seq.cfg.followTrackSelection == 1 ) then
      if ( seq.xpos ~= seq.lastx ) then
        reaper.PreventUIRefresh(1)
        for i=0,reaper.CountTracks()-1 do
          reaper.SetTrackSelected(reaper.GetTrack(0,i), false)
        end
        reaper.SetTrackSelected(reaper.GetTrack(0,seq.xpos), true)
        
        for i=0,reaper.CountTracks()-1 do
          reaper.CSurf_OnArrow(0, false)
        end
        for i=1,seq.xpos do
          reaper.CSurf_OnArrow(1, false)
        end
        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()
      end
    end
    
    if ( seq.xpos ~= seq.lastx ) then
      seq.fov.scrollpat = 0
    end

    seq.lastx = seq.xpos
    seq.lasty = seq.ypos
        
    -- Check whether we have focus
    --seq.i = (seq.i or 0) + 1
    --print(seq.i)
    --print(gfx.mouse_cap)
    
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
  
--  seq:loadColors("renoise")
  seq.cfg = seq:loadConfig("seq.cfg", seq.cfg)
  seq:loadColors( seq.cfg.theme )
  
  --{"default", "buzz", "it", "hacker", "renoise"}
  
  seq:loadKeys( "default" )
  gfx.init(scriptName, width, height, 0, xpos, ypos)
  seq:computeSize()
  seq.patternScrollbar = scrollbar.create(10)
  
  seq:updateData()
  reaper.defer(updateLoop)
end

Main()

-- GetSetAutomationItemInfo(TrackEnvelope* env, int autoitem_idx, const char* desc, double value, bool is_set)
-- D_POOL_ID: double *, automation item pool ID (as an integer); edits are propagated to all other automation items that share a pool ID
-- D_POSITION: double *, automation item timeline position in seconds
-- D_LENGTH: double *, automation item length in seconds
