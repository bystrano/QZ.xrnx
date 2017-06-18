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
    if (options.show_debug_prints.value) then
      print("bystrano.QZ.QZ >> got midi_mapping message :")

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

  if (options.show_debug_prints.value) then
    print("bystrano.QZ.QZ: play next pattern in sequencer")
  end

  playback_pos_jump(pos)
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

  local idle_observable = renoise.tool().app_idle_observable
  -- new calls cancel previous ones
  if idle_observable:has_notifier(wait_for_playback_pos_change) then
    idle_observable:remove_notifier(wait_for_playback_pos_change)
  end
  idle_observable:add_notifier(wait_for_playback_pos_change)

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


--------------------------------------------------------------------------------
-- debug hook
--------------------------------------------------------------------------------

_AUTO_RELOAD_DEBUG = function()
  handle_auto_reload_debug_notification()
end

function handle_auto_reload_debug_notification()
  if (options.show_debug_prints.value) then
    print("bystrano.QZ.QZ: ** auto_reload_debug notification")
  end
end
