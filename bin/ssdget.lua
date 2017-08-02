local ssd = require('ssd')
local shell = require('shell')
local fs = require('filesystem')
local io = require('io')

local args, options = shell.parse(...)
local f = io.stdout

if #args > 0 then
    local path = args[1]
    f, msg = fs.open(path, 'wb')
    if f == nil then
        print('File error: ' .. msg)
        return
    end
end

ssd.rewind()

while true do
    data, msg = ssd.readString(1)
    if data == nil then
        print('Read error: ' .. msg)
        break
    end

    if #data == 0 then
        break
    end

    ok, msg = f:write(data)
    if not ok then
        print('Write error: ' .. msg)
        break
    end
end

if #args > 0 then f:close() end
ssd.rewind()