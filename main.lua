--[[============================================================================
bystrano.QZ.QZ.xrnx/main.lua
============================================================================]]--

--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

local options = renoise.Document.create("QZPreferences") {
  show_debug_prints = false,
  repeat_interval = 200
}

renoise.tool().preferences = options


--------------------------------------------------------------------------------
-- key bindings
--------------------------------------------------------------------------------

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

renoise.tool():add_midi_mapping{
  name = "QZ:Play next pattern in sequencer",
  invoke = function(msg)
    dbg_print_midi_msg(msg)

    if msg:is_trigger() or ((msg:is_abs_value() or msg:is_rel_value()) and msg.int_value > 0) then
      play_next_pattern_in_sequencer_antirepeat()
    end
  end
}


--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

-- main action

function play_next_pattern_in_sequencer()
  local t = renoise.song().transport
  local pos = t.playback_pos

  pos.sequence = pos.sequence + 1
  if pos.sequence > renoise.song().transport.song_length.sequence then
    pos.sequence = 1
  end

  pos.line = 1

  dbg_print("play next pattern in sequencer")

  t:start_at(pos)
end

-- This is a rate-limited version of play_next_pattern_in_sequencer. We use it
-- to prevent double triggering via MIDI.
_repeat_lock = false
function play_next_pattern_in_sequencer_antirepeat()

  if not _repeat_lock then
    _repeat_lock = true
    renoise.tool():add_timer(repeat_unlock, options.repeat_interval.value)
    play_next_pattern_in_sequencer()
  end
end

function repeat_unlock()

  if renoise.tool():has_timer(repeat_unlock) then
    renoise.tool():remove_timer(repeat_unlock)
  end

  _repeat_lock = false
end


--------------------------------------------------------------------------------
-- debug hook
--------------------------------------------------------------------------------

_AUTO_RELOAD_DEBUG = function()
  handle_auto_reload_debug_notification()
end

function handle_auto_reload_debug_notification()

  dbg_print("** auto_reload_debug notification")
end

function dbg_print(msg)

  if (options.show_debug_prints.value) then
    print(("bystrano.QZ.QZ: %s"):format(msg))
  end
end

function dbg_print_midi_msg(msg)

  dbg_print(">> got midi_mapping message :")

  dbg_print(("  msg:is_trigger(): %s"):format(
      msg:is_trigger() and "yes" or "no"))
  dbg_print(("  msg:is_switch(): %s"):format(
      msg:is_switch() and "yes" or "no"))
  dbg_print(("  msg:is_rel_value(): %s"):format(
      msg:is_rel_value() and "yes" or "no"))
  dbg_print(("  msg:is_abs_value(): %s"):format(
      msg:is_abs_value() and "yes" or "no"))
  dbg_print(("  msg.int_value: %d"):format(
      msg.int_value))
  dbg_print(("  msg.boolean_value: %s"):format(
      msg.boolean_value and "true" or "false"))
end
