EIO_OPEN = 0
EIO_CLOSE = 1
EIO_PING = 2
EIO_PONG = 3
EIO_MESSAGE = 4
EIO_UPGRADE = 5
EIO_NOOP = 6

SIO_CONNECT = 0
SIO_DISCONNECT = 1
SIO_EVENT = 2
SIO_ACK = 3
SIO_CONNECT_ERROR = 4
SIO_BINARY_EVENT = 5
SIO_BINARY_ACK = 6

json = require("json")

Socket = {websocket = {}, namespace = "", pingTimeoutDelay = 0, socketIoActive = false, triedToActiave = false, sid = ""}
function Socket:getUrl (serverUrl)
    return serverUrl .. "/socket.io/?EIO=4&transport=websocket"
end

function Socket:new (url)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.url = url
    o.websocket = assert(http.websocket(o:getUrl(url)))
    return o
end

function Socket:initSocketIo (namespace)
    if self.triedToActiave then
        print("Socket.io to be initialized")
        return
    end
    self.triedToActiave = true
    self.websocket.send("40/" .. namespace)
    local message = socket.websocket.receive()
    if message then
        self:handleMessage(message, function (data, namespace)
            
        end)
    end
end

function Socket:handleSocketIo (message, callback)
    if not socketIoActive then
        print("How did we get here?")
        self:initSocketIo()
    end
    local eioType = tonumber(message:sub(1, 1))
    local sioType = tonumber(message:sub(2, 2))
    local messageNamespace = message:sub(message:find("/") + 1, message:find(",") - 1)
    local messageData = message:sub(message:find(",") + 1, -1)
    local parsedData = json.decode(messageData)
    if sioType == SIO_CONNECT then
        print("Socketio connected")
        self.socketIoActive = true
        self.sid = parsedData.sid
    elseif sioType == SIO_DISCONNECT then
        print("Socketio disconnected")
        self.websocket.close()
    elseif sioType == SIO_EVENT then
        callback(parsedData, messageNamespace)
    end
end

function Socket:emit (event, data, namespace)
    if not socketIoActive then
        print("Should've initialized socket.io")
        self:initSocketIo()
    end
    self.websocket.send("42/" .. namespace .. ",[\"" .. event .. "\"," .. json.encode(data) .. "]")
end

function Socket:handleMessage (message, callback) 
    local eioType = tonumber(message:sub(1, 1))
    
    if eioType == EIO_OPEN then
        print("Socket opened")
        data = json.decode(message:sub(2, -1))
        self.pingTimeoutDelay = data.pingTimeout + data.pingInterval
    elseif eioType == EIO_CLOSE then
        self.websocket.close()
    elseif eioType == EIO_PING then
        self.websocket.send(EIO_PONG)
    elseif eioType == EIO_PONG then
        print("Pong received")
    elseif eioType == EIO_MESSAGE then
        self:handleSocketIo(message, callback)
    elseif eioType == EIO_UPGRADE then
        print("Socket ??????? upgraded")
    elseif eioType == EIO_NOOP then
        print("Noop received")
    end
end

socket = Socket:new("ws://raspi.local:81")
local namespace = "krakow-sensory"
socket:initSocketIo(namespace)
socket:emit("listen-sensor", "tempC", namespace)
while true do
    local message = socket.websocket.receive()
    if message then
        socket:handleMessage(message, function (data, namespace)
            print("Received data from " .. namespace)
            print(data[1])
            print(data[2])
        end)
    end
end