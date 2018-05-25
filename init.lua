--[[
Sprint mod for Minetest
Author: Sergey Ivanov
Latest-Ver: github.com/nyarmith/minetest-sprint-mod/
]]

--"local" required to restrict visibility to just this file
local PLAYERS = {}
local STOPPED, MOVING, SPRINTING = 0,1,2
local W_SPRINT_TIMER = 0.4  --timeout for w double-tap
local SPRINT_SPEED, SPRINT_JUMP = 1.5, 1.35

--we call this every time a player joins
local  function joinHandler( player )
  local uname = player:get_player_name()
  PLAYERS[uname] = {
    state = STOPPED,
    taptime = 1,
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
    -- STOPPED => MOVING => SPRINTING
    --   ^          v           v
    --   |          |           |
    --   \__________+___________/
    -------------------------
    --
    local isMoving = player:get_player_control()["up"]

    --stopped?
    if isMoving == false then
      -- if I've stopped sprinting, reset my physics settings
      if pinfo["state"] == SPRINTING then
        player:set_physics_override({speed=1.0,jump=1.0})
      end
      PLAYERS[uname]["state"] = STOPPED

    --*have I just started moving within the SPRINT_TIMER ?
    elseif isMoving == true  and pinfo["state"] == STOPPED and 
      pinfo["taptime"] + W_SPRINT_TIMER > time then 
      PLAYERS[uname]["state"] = SPRINTING
      player:set_physics_override( {speed=SPRINT_SPEED, jump=SPRINT_JUMP} )


    --*otherwise record this as the previous taptime
    elseif isMoving == true  and pinfo["state"] == STOPPED then
      PLAYERS[uname]["taptime"] = time
      PLAYERS[uname]["state"] = MOVING
    end
  end
end

-- register functions to their events
minetest.register_on_joinplayer(joinHandler)
minetest.register_on_leaveplayer(leaveHandler)
minetest.register_globalstep(globalStepHandler)
