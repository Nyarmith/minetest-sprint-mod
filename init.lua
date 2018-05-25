--[[
Sprint mod for Minetest
Author: Sergey Ivanov
Latest-Ver: github.com/nyarmith/minetest-sprint-mod/
]]

--"local" required to restrict visibility to just this file
local PLAYERS = {}
local STOPPED, MOVING, TAPPED, SPRINTING = 0,1,2,3
local W_SPRINT_TIMER = 0.6  --timeout for w double-tap
local SPRINT_SPEED, SPRINT_JUMP = 1.5, 1.35

--we call this every time a player joins
local  function joinHandler( player )
  local uname = player:get_player_name()
  PLAYERS[uname] = {
    state = STOPPED,
    taptime = 0,
  }
end

--we call this every time a player leaves
local function leaveHandler( player )
  local uname = player:get_player_name()
  PLAYERS[uname] = nil
end

--this function runs on everys step, so we use time deltas!
local function globalStepHandler( dtime )
  local time = minetest.get_gametime()

  for uname,pinfo in pairs(PLAYERS) do
    local player = minetest.get_player_by_name(uname)
    if player == nil then
      return;
    end

    --*Sprinting State-Machine(tm)*
    -- STOPPED => MOVING => TAPPED => SPRINTING =>v
    --   ^   \______^______,^  |                  v
    --   |          \__________/                  |
    --   \________________________________________/
    -------------------------
    --
    local isMoving = player:get_player_control()["up"]

    --*have I stopped?
    if isMoving == false and pinfo["state"] == SPRINTING then

      -- then reset my physics settings
      PLAYERS[uname]["state"] = STOPPED
      player:set_physics_override({speed=1.0,jump=1.0})

    --*have I just started moving?
    elseif isMoving == true  and pinfo["state"] == STOPPED then 

      PLAYERS[uname]["state"]   = TAPPED
      PLAYERS[uname]["taptime"] = time

    --*am I tapping mid-run?
    elseif isMoving == false and pinfo["state"] == MOVING  then

      -- then prepare for a potential double-tap
      PLAYERS[uname]["state"]   = TAPPED
      PLAYERS[uname]["taptime"] = time

    --*have I tapped quickly enough after starting movement?
    elseif isMoving == true  and pinfo["state"] == TAPPED and
          pinfo["taptime"] + W_SPRINT_TIMER < time then 

      --then start sprinting
      PLAYERS[uname]["state"] = SPRINTING
      player:set_physics_override( {speed=SPRINT_SPEED, jump=SPRINT_JUMP} )

    --*have I timed out on my tap?
    elseif isMoving == true  and pinfo["state"] == TAPPED and
          pinfo["taptime"] + W_SPRINT_TIMER > time then 

      --resume moving
      PLAYERS[uname]["state"] = MOVING

    end
  end
end

-- register functions to their events
minetest.register_on_joinplayer(joinHandler)
minetest.register_on_leaveplayer(leaveHandler)
minetest.register_globalstep(globalStepHandler)
