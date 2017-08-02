----- ================
----- Redstone SSD API
----- ================

local sides = require("sides")
local component = require("component")
local robot = component.robot
local rs = component.redstone
local bit = require("bit32")

if robot == nil then
  error("ssd api is only available on a robot")
end
if rs == nil then
  error("no redstone hardware installed")
end

local ssd = {}

local function getInput(side)
  value = rs.getInput(side)
  if value > 0 then
    return true
  end
  return false
end

----- Head functions

local vpos = 0 -- vertical position
local odd = true

local function getToBaseHeight()
  while vpos > 0 do
    if not robot.move(sides.up) then
      error("cannot move up")
    end
    vpos = vpos-1
  end
end

function ssd.rewind()
  if vpos > 0 then
    getToBaseHeight()
  end
  while true do
    if not robot.move(sides.back) then
      if getInput(sides.back) then
        return true
      end
      robot.turn(false)
    end
  end
  odd = true
  return true
end

function ssd.forward()
  if not vpos == 0 then
    return false
  end
  if not robot.move(sides.front) then
    robot.turn(odd)
    if not robot.move(sides.front) then
      robot.turn(not odd)
      return false
    end
    robot.turn(odd)
    odd = not odd
  end
  return true
end

local function placeBlock()
  local slot = 0
  while slot < 16 do
    if robot.place(sides.bottom) then
      return true
    else
      slot = slot+1
      robot.select(slot)
    end
  end
  return false
end

local function writeBack(byte)
  if not vpos == 7 then
    error("improper head position")
  end
  for x = 7,1,-1 do
    if not (bit.band(bit.lshift(1,x), byte) == 0) then
      if not placeBlock() then
        getToBaseHeight()
        return false,
        "Failed to place bit block."
      end
    end
    if not robot.move(sides.up) then
      error("cannot move up")
    end
    vpos = vpos-1
  end
  if not (bit.band(1, byte) == 0) then
    if not placeBlock() then
      return false,
      "Failed to place (final) bit block."
    end
  end
  return true
end

-- Returns -1 in case of error
function ssd.read()
  local byte = 0
  for x = 0,7,1 do
    if getInput(sides.bottom) then
      byte = bit.bor(byte, bit.lshift(1,x))
      robot.swing(sides.bottom)
    end
    if x < 7 then
      if not robot.move(sides.bottom) then
        getToBaseHeight()
        return -1, "Cannot move down."
      end
      vpos = vpos+1
    end
  end
  writeBack(byte)
  return byte
end

function ssd.write(byte)
  while vpos < 7 do
    if robot.detect(sides.bottom) then
      robot.swing(sides.bottom)
    end
    if not robot.move(sides.down) then
      getToBaseHeight()
      return false,
      "Failed to erase the sector."
    end
    vpos = vpos+1
  end
  if robot.detect(sides.bottom) then
    robot.swing(sides.bottom)
    if robot.detect(sides.bottom) then
      getToBaseHeight()
      return false,
      "Failed to erase the sector (final bit)."
    end
  end
  return writeBack(byte)
end

----- IO functions

local str = require("string")

function ssd.eof()
  if robot.detect(sides.front) then
    robot.turn(odd)
    if robot.detect(sides.front) then
      return true
    end
    robot.turn(not odd)
  end
  return false
end

function ssd.readString(n)
  if ssd.eof() then
    return ""
  end
  bytes = ""
  for x = 1,n do
    b, m = ssd.read()
    if b < 0 then
      return nil, m
    end
    bytes = bytes..str.char(b)
    if not ssd.forward() then
      break
    end
  end
  return bytes
end

-- If successful, returns number of bytes written
function ssd.writeString(s)
  if ssd.eof() then
    return 0
  end
  bytes = 0
  for c in str.gmatch(s, ".") do
    x, m = ssd.write(str.byte(c))
    if not x then
      return nil, m
    end
    bytes = bytes + 1
    if not ssd.forward() then
      break
    end
  end
  return bytes
end

return ssd
