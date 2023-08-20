local Socket = require("socketio")
local basalt = require("basalt")

socket = Socket:new("ws://raspi.local:81")
local namespace = "krakow-sensory"
socket:initSocketIo(namespace)
socket:emit("listen-sensor", "tempC", namespace)

local monitor = peripheral.wrap("top")
local monitorFrame = basalt.addMonitor()
monitorFrame:setMonitor(monitor)
local main = monitorFrame:addFrame():setSize("{parent.w / 2}", "{parent.h}"):setBackground(colors.lightGrey)

main:addLabel()
    :setText("Temp")
    :setPosition("{(parent.w / 2) - (self.w / 2)}", 2)
    :setTextAlign("center")
    :setForeground(colors.red)

local temp = main:addLabel("0C"):setPosition("{(parent.w / 2) - (self.w / 2)}", 4):setTextAlign("center")

local tempPane = main
    :addPane()
    :setPosition("{(parent.w / 2) - (self.w / 2)}", "{ parent.h / 5 }")
    :setSize("{(parent.w - 4)}", "{parent.h / 2}")
    :setBackground(colors.red)


local function runUpdates()
    while true do
        local message = socket.websocket.receive()
        if message then
            socket:handleMessage(message, function (data, namespace)
                print("Received data from " .. namespace)
                print(data[1])
                print(tostring(data[2]/30) .. "C")
                local newPos = "parent.h * " .. data[2]/50
                temp:setPosition("{(parent.w / 2 - (self.w / 2))}", "{" .. newPos .. " - 3}")
                temp:setText((tostring(data[2]) .. "C"))
                tempPane:setSize("{(parent.w - 4)}", "{" .. newPos .. "}"):setPosition("{(parent.w / 2) - (self.w / 2)}", "{" .. newPos .. "}")
            end)
        end
    end
end

parallel.waitForAll(basalt.autoUpdate, runUpdates)

