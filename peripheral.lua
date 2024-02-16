local Socket = require("socketio")

socket = Socket:new("ws://raspi.local:81")
local namespace = "minecraft-control"
socket:initSocketIo(namespace)

local red = peripheral.wrap("back")

socket:emit("listen-sensor", "control/game/minecraft/spawn/central/base/entranceway/front_door", namespace)

local function handleCommand(data)
    if data[2] == "open" then
        red.setOutput("bottom", true)
    elseif data[2] == "close" then
        red.setOutput("bottom", false)
    end
end

local function runUpdates()
    while true do
        local message = socket.websocket.receive()
        if message then
            socket:handleMessage(message, function (data, namespace)
                print("handling message " .. data[1] .. " " .. data[2])
                handleCommand(data)
            end)
        end
    end
end

parallel.waitForAll(runUpdates)