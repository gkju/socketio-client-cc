local Socket = require("socketio")
local basalt = require("basalt")

socket = Socket:new("ws://raspi.local:81")
local namespace = "krakow-sensory"
socket:initSocketIo(namespace)

local sensors = {
    {
        topic = "tempC",
        name = "Temp",
        unit = "C",
        color = colors.red,
        maxValue = 50,
    },
    {
        topic = "humRH",
        name = "Hum",
        unit = "RH",
        color = colors.blue,
        maxValue = 100,
    },
    {
        topic = "presPa",
        name = "Pres",
        unit = "Pa",
        color = colors.green,
        maxValue = 110000,
    },
}

for i,v in ipairs(sensors) do
    socket:emit("listen-sensor", v.topic, namespace)
end

local monitorFrame = basalt.addMonitor()
monitorFrame:setMonitor("top")

monitorFrame:setBackground(colors.black)

local handlers = {}

local function NumberPrettyPrint(num)
    if num > 1000000 then
        return tostring(math.floor(num / 1000000)) .. "M"
    elseif num > 1000 then
        return tostring(math.floor(num / 1000)) .. "k"
    else
        return tostring(string.format("%.3f", num))
    end
end

local function addSensor(topic, name, unit, color, no, cnt)
    local sensor = sensors[no]
    local basePosition = {x = "{(parent.w /" .. cnt .. ") * " .. no - 1 .. "}", y = 1}
    local baseSize = {w = "{(parent.w /" .. cnt .. ") " .. "}", h = "{parent.h}"}

    local oldframe = monitorFrame:addFrame()
        :setPosition(basePosition.x, basePosition.y)
        :setSize(baseSize.w, baseSize.h)

    local frame = oldframe:addFrame():setSize("{parent.w - 4}", "{parent.h - 4}"):setPosition(2,2):setBorder(sensors[no].color)

    local legend = oldframe:addLabel()
        :setForeground(colors.white)
        :setFontSize(1)
        :setText(" " .. name .. " [" .. unit .. "] ")
        :setPosition("{parent.w / 2 - self.w / 2}", 2)

    local view = frame
        :addLabel()
        :setForeground(colors.white)
        :setFontSize(1)
        :setText("00000")
        :setPosition("{parent.w / 2 - self.w / 2}", "{parent.h - 1}")
        :setBackground(sensor.color)

    local paneWidth = "parent.w - 7"
    local viewPaneHeight = "parent.h - 7"
    local paneX = 4
    local paneY = 3

    frame:addPane()
        :setPosition(2, 2)
        :setSize("{" .. paneWidth .. " + 2}", "{" .. viewPaneHeight .. " + 2}")
        :setBackground(colors.grey)

    frame:addPane()
        :setPosition(paneX, paneY)
        :setSize("{" .. paneWidth .. "}", "{parent.h - 5}")
        :setBackground(sensor.color)
    
    local viewPane = frame:addPane()
        :setPosition(paneX, paneY)
        :setSize("{" .. paneWidth .. "}", "{" .. viewPaneHeight .. "}")
        :setBackground(colors.black)

    oldframe:updateZIndex(frame, 2)
    oldframe:updateZIndex(legend, 3)

    return function (value)
        local newPaneHeight = "{(" .. viewPaneHeight .. ") * (1 - ( " .. value .. " / " .. sensor.maxValue .. " )) }"
        viewPane:setSize("{" .. paneWidth .. "}", newPaneHeight)
        view:setText(" " .. tostring(NumberPrettyPrint(value)) .. sensor.unit .. " ")
    end
end

for i,v in ipairs(sensors) do
    handlers[v.topic] = addSensor(v.topic, v.name, v.unit, v.color, i, #sensors)
end

local function runUpdates()
    while true do
        local message = socket.websocket.receive()
        if message then
            socket:handleMessage(message, function (data, namespace)
                print("handling message" .. data[1])
                handlers[data[1]](data[2])
            end)
        end
    end
end

parallel.waitForAll(basalt.autoUpdate, runUpdates)