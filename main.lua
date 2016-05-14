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
  print("play next pattern in sequencer")
end


-- handle_auto_reload_debug_notification

function handle_auto_reload_debug_notification()
  if (options.show_debug_prints.value) then
    print("com.renoise.ExampleTool: ** auto_reload_debug notification")
  end
end
