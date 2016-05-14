--[[============================================================================
com.renoise.ExampleTool.xrnx/main.lua
============================================================================]]--

-- XRNX Bundle Layout:

-- Tool scripts must describe themself through a manifest XML, to let Renoise
-- know which API version it relies on, what "it can do" and so on, without
-- actually loading it. See "manifest.xml" in this exampel tool for more info
-- please
--
-- When the manifest loads and looks OK, the main file of the tool will be
-- loaded. This  is this file -> "main.lua".
--
-- You can load other files from here via LUAs 'require', or simply put
-- all the code in here. This file simply is the main entry point of your tool.
-- While initializing, you can register your tool with Renoise, by creating
-- keybindings, menu entries or listening to events from the application.
-- We will describe all this below now:


--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

-- tools can have preferences, just like Renoise. To use them we first need
-- to create a renoise.Document object which holds the options that we want to
-- store/restore
local options = renoise.Document.create("QZPreferences") {
  show_debug_prints = false
}

-- then we simply register this document as the main preferences for the tool:
renoise.tool().preferences = options

-- show_debug_prints is now a persistent option which gets saved & restored
-- for upcoming Renoise seesions, program launches.
-- the preferences file for tools is saved inside the tools bundle as
-- "preferences.xml"


--------------------------------------------------------------------------------
-- key bindings
--------------------------------------------------------------------------------

-- you can also define keybindings for your script, which will be activated and
-- mapped by the user just as any other key binding in Renoise.
-- Keybindings can be global (apploied everywhere in the GUI) or can be local
-- to a specific part of the GUI, liek the Pattern Editor.
--
-- Again, have a look at "Renoise.ScriptingTool.API.txt" in the documentation
-- folder for a complete reference.

renoise.tool():add_keybinding {
  name = "Global:QZ:Play next pattern in sequencer",
  invoke = function(repeated)
    if (not repeated) then -- we ignore soft repeated keys here
      play_next_pattern_in_sequencer()
    end
  end
}


--------------------------------------------------------------------------------
-- midi mappings
--------------------------------------------------------------------------------

-- Tools also can extend Renoises internal MIDI mapping set. This way you can
-- add MIDI mappings to control your tool, or also write tools which do nothing
-- more than extending Renoises default MIDI mapping set.
--
-- Have a look at "Renoise.ScriptingTool.API.txt" in the documentation
-- folder for a complete reference. Also have a look at the GlobalMidiActions.lua
-- file for examples mappings (this is Renoises complete default MIDI mapping set)
-- and more descriptions of the passed message parameter.

renoise.tool():add_midi_mapping{
  name = "QZ:Play next pattern in sequencer",
  invoke = function(msg)
    if (options.show_debug_prints.value) then
      print("com.renoise.ExampleTool: >> got midi_mapping message :")

      print(("  msg:is_trigger(): %s)"):format(
        msg:is_trigger() and "yes" or "no"))
      print(("  msg:is_switch(): %s)"):format(
        msg:is_switch() and "yes" or "no"))
      print(("  msg:is_rel_value(): %s)"):format(
        msg:is_rel_value() and "yes" or "no"))
      print(("  msg:is_abs_value(): %s)"):format(
        msg:is_abs_value() and "yes" or "no"))

      print(("  msg.int_value: %d)"):format(
        msg.int_value))
      print(("  msg.boolean_value: %s)"):format(
        msg.boolean_value and "true" or "false"))
    end

    if msg:is_trigger() or ((msg:is_abs_value() or msg:is_rel_value()) and msg.int_value > 0) then
      play_next_pattern_in_sequencer()
    end
  end
}


--------------------------------------------------------------------------------
-- debug hook
--------------------------------------------------------------------------------

-- This hook helps you testing & debugging your script while editing
-- it with an external editor or with Renoises built in script editor:
--
-- As soon as you save your script outside of the application, and then
-- focus the app (alt-tab to it for example), your script will get instantly
-- reloaded and your notifier is called.
-- You can put a test function into this notifier, or attach to a remote
-- debugger like RemDebug or simply nothing, just enable the auto-reload
-- functionality by setting _AUTO_RELOAD_DEBUG = true .
--
-- When editing script with Renoises built in editor, tools will automatically
-- reload as soon as you hit "Run Script", even if you don't have this notifier
-- set, but you nevertheless can use this to automatically invoke a test
-- function.
---
-- Note: When reloading the script causes an error, the old, last running
-- script instance will continue to run.
--
-- Finally: Changes in the actions menu may not be updated for new tools,
-- unless you reload all tools manually with 'Reload Tools' in the menu.

_AUTO_RELOAD_DEBUG = function()
  handle_auto_reload_debug_notification()
end

-- or _AUTO_RELOAD_DEBUG = true


--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

-- show_dialog

function play_next_pattern_in_sequencer()
  local t = renoise.song().transport
  local pos = t.playback_pos

  pos.sequence = pos.sequence + 1
  pos.line = 1

  if (options.show_debug_prints.value) then
    print("play next pattern in sequencer")
  end

  playback_pos_jump(pos)
end

-- makes the playback jump to another position.
--
-- this is different than trigger_sequence, because it will keep the currently
-- playing samples playing.
-- Also,if the song is not playing, we start the playback.
_playback_target_pos = {
  sequence = 1,
  line = 1
}
function playback_pos_jump(pos)

  -- The playback_pos change we want to do can take a while, so save it in a
  -- global variable and add an idle notifier that will start the playback as
  -- soon as it's done.
  _playback_target_pos = {
    sequence = pos.sequence,
    line = pos.line
  }
  renoise.tool().app_idle_observable:add_notifier(wait_for_playback_pos_change)
  renoise.song().transport.playback_pos = pos
end

function wait_for_playback_pos_change()
  local t = renoise.song().transport

  -- We check if the playback_pos already is in the right position
  if t.playback_pos.line == _playback_target_pos.line and t.playback_pos.sequence == _playback_target_pos.sequence then
    renoise.tool().app_idle_observable:remove_notifier(wait_for_playback_pos_change)
    t:start(renoise.Transport.PLAYMODE_CONTINUE_PATTERN)
  end
end

-- handle_auto_reload_debug_notification

function handle_auto_reload_debug_notification()
  if (options.show_debug_prints.value) then
    print("bystrano.QZ.QZ: ** auto_reload_debug notification")
  end
end
