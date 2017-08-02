local ssd = require('ssd')
local shell = require('shell')
local fs = require('filesystem')
local io = require('io')

local args, options = shell.parse(...)
local f = io.stdin

if #args > 0 then
    local path = args[1]
    f, msg = fs.open(path, 'rb')
    if f == nil then
        print('File error: ' .. msg)
        return
    end
end

ssd.rewind()

while true do
    data, msg = f:read(1)
    if data == nil then
        if not msg == nil then
            print('Read error: ' .. msg)
        end
        break
    end

    bytes, msg = ssd.writeString(data)
    if bytes == nil then
        print('Write error: ' .. msg)
        break
    end

    if bytes == 0 then
        break
    end
end

if #args > 0 then f:close() end
ssd.rewind()