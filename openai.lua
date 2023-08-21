local Socket = require("socketio")
local basalt = require("basalt")
local json = require("json")

socket = Socket:new("ws://raspi.local:81")
local namespace = "minecraft-control"
socket:initSocketIo(namespace)

local main = basalt.createFrame()
    :setBackground(colors.black)
    :setTheme({ButtonBG=colors.black, ButtonText=colors.lightGray})
local inputbox = main:addInput()
    :setInputType("text")
    :setDefaultText("...")
    :setPosition(3, "{parent.h - 3}")
    :setSize("{parent.w - 5}", 1)

local scroll = main:addScrollableFrame()
    :setDirection("vertical")
    :setPosition(3, 3)
    :setSize("{parent.w - 5}", "{parent.h - 10}")
    :setBackground(colors.black)
    :setForeground(colors.lightGray)

local list = scroll:addTextfield()
    :setPosition(1, 1)
    :setBackground(colors.black)
    :setForeground(colors.lightGray)

local commandBuffer = ""
local conversationId = "21"

function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function addMessageToBox(message) 
    local charcnt = 0
    local buf = ""
    for w in message:gmatch("%S+") do 
        charcnt = charcnt + #w
        if charcnt > 21 then
            list:addLine(trim(buf))
            buf = w
            charcnt = #w
        else
            buf = buf .. " " .. w
        end
    end

    if #buf > 0 then
        list:addLine(buf)
    end
end

function sendToAi(text)
    local toSend = json.encode({prompt = text, conversationId = conversationId})
    socket:emit("openai-action", toSend, namespace)
end

function messageHandler(message, namespace)
    local event = message[1]
    local data = message[2]
    conversationId = data.conversationId
    local textAnwser = data.response.choices[1].message.content
    addMessageToBox(prettyPrint(textAnwser, 1))
end

local function runUpdates()
    while true do
        local message = socket.websocket.receive()
        if message then
            socket:handleMessage(message, messageHandler)
        end
    end
end

function prettyPrint(text, role)
    if role == 0 then
        return "[You] " .. text
    elseif role == 1 then
        return "[AI] " .. text
    end
end
  
function inputOnKey(self, event, key)
    if #commandBuffer == 0 then
        return false
    end

    if key == keys.enter then
        addMessageToBox(prettyPrint(commandBuffer, 0))
        sendToAi(commandBuffer)
        inputbox:setValue("")
        commandBuffer = ""
    end
end

inputbox:onChange(function(self, event, text)
    commandBuffer = text
end)

inputbox:onKey(inputOnKey)

parallel.waitForAll(basalt.autoUpdate, runUpdates)