-- Utils.lua
-- Utility functions for Elemental Battlegrounds

local Utils = {}

-- Services
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Constants
local TAU = math.pi * 2

-- Math functions
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.map(value, inMin, inMax, outMin, outMax)
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

function Utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function Utils.round(value, decimalPlaces)
    local factor = 10 ^ (decimalPlaces or 0)
    return math.floor(value * factor + 0.5) / factor
end

-- Table functions
function Utils.shallowCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end

function Utils.deepCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = Utils.deepCopy(v)
        end
        copy[k] = v
    end
    return copy
end

function Utils.mergeTables(t1, t2)
    local result = Utils.shallowCopy(t1)
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

-- Instance functions
function Utils.createInstance(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

function Utils.createParticleEmitter(part, particleType, properties)
    local emitter = Instance.new("ParticleEmitter")
    
    -- Default properties
    local defaultProps = {
        LightEmission = 0.5,
        LightInfluence = 0,
        Size = NumberSequence.new(0.5, 1),
        Texture = "rbxassetid://242877004",
        Lifetime = NumberRange.new(0.5, 1),
        Rate = 20,
        Speed = NumberRange.new(5),
        SpreadAngle = Vector2.new(0, 360)
    }
    
    -- Type-specific properties
    if particleType == "fire" then
        defaultProps = Utils.mergeTables(defaultProps, {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 0))
            }),
            Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(0.5, 1.5),
                NumberSequenceKeypoint.new(1, 0)
            }),
            Speed = NumberRange.new(2, 5),
            Lifetime = NumberRange.new(0.5, 1.5),
            Rate = 30,
            LightEmission = 1,
            LightInfluence = 1
        })
    elseif particleType == "water" then
        defaultProps = Utils.mergeTables(defaultProps, {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 230, 255))
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Speed = NumberRange.new(3, 6),
            Lifetime = NumberRange.new(0.5, 1),
            Rate = 20
        })
    end
    
    -- Apply properties
    for property, value in pairs(Utils.mergeTables(defaultProps, properties or {})) do
        emitter[property] = value
    end
    
    emitter.Parent = part
    return emitter
end

-- Raycasting
function Utils.raycast(origin, direction, params, ignoreList)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = params.FilterType or Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = ignoreList or {}
    raycastParams.IgnoreWater = params.IgnoreWater or true
    
    return workspace:Raycast(origin, direction, raycastParams)
end

-- Tweening
function Utils.tween(instance, properties, duration, style, direction, callback)
    local tweenInfo = TweenInfo.new(
        duration,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(instance, tweenInfo, properties)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

-- Debounce
function Utils.createDebounce(delay)
    local lastCall = 0
    return function()
        local now = tick()
        if now - lastCall >= delay then
            lastCall = now
            return true
        end
        return false
    end
end

-- Signal implementation
local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({
        _bindable = Instance.new("BindableEvent"),
        _connections = {}
    }, Signal)
    return self
end

function Signal:Connect(callback)
    local connection = {}
    local bindableConnection = self._bindable.Event:Connect(function(...)
        callback(...)
    end)
    
    connection.Disconnect = function()
        bindableConnection:Disconnect()
        self._connections[connection] = nil
    end
    
    self._connections[connection] = true
    return connection
end

function Signal:Fire(...)
    self._bindable:Fire(...)
end

function Signal:Destroy()
    for connection in pairs(self._connections) do
        connection:Disconnect()
    end
    self._bindable:Destroy()
end

Utils.Signal = Signal

-- Promise implementation
local Promise = {}
Promise.__index = Promise

function Promise.new(executor)
    local self = setmetatable({
        _status = "pending", -- pending, fulfilled, rejected
        _value = nil,
        _successCallbacks = {},
        _failureCallbacks = {}
    }, Promise)
    
    local function resolve(value)
        if self._status ~= "pending" then return end
        self._status = "fulfilled"
        self._value = value
        
        for _, callback in ipairs(self._successCallbacks) do
            callback(value)
        end
    end
    
    local function reject(reason)
        if self._status ~= "pending" then return end
        self._status = "rejected"
        self._value = reason
        
        for _, callback in ipairs(self._failureCallbacks) do
            callback(reason)
        end
    end
    
    local success, err = pcall(function()
        executor(resolve, reject)
    end)
    
    if not success then
        reject(err)
    end
    
    return self
end

function Promise:then_(onFulfilled, onRejected)
    local nextPromise = Promise.new(function() end)
    
    local function handleCallback(callback, value, resolve, reject)
        if type(callback) ~= "function" then
            resolve(value)
            return
        end
        
        local success, result = pcall(callback, value)
        if success then
            resolve(result)
        else
            reject(result)
        end
    end
    
    local function handleFulfill(value)
        task.defer(function()
            handleCallback(onFulfilled, value, nextPromise.resolve, nextPromise.reject)
        end)
    end
    
    local function handleReject(reason)
        task.defer(function()
            if type(onRejected) == "function" then
                handleCallback(onRejected, reason, nextPromise.resolve, nextPromise.reject)
            else
                nextPromise.reject(reason)
            end
        end)
    end
    
    if self._status == "pending" then
        table.insert(self._successCallbacks, handleFulfill)
        table.insert(self._failureCallbacks, handleReject)
    elseif self._status == "fulfilled" then
        handleFulfill(self._value)
    elseif self._status == "rejected" then
        handleReject(self._value)
    end
    
    return nextPromise
end

function Promise:catch(onRejected)
    return self:then_(nil, onRejected)
end

function Promise:finally(onFinally)
    return self:then_(
        function(value)
            onFinally()
            return value
        end,
        function(reason)
            onFinally()
            return Promise.reject(reason)
        end
    )
end

function Promise.resolve(value)
    return Promise.new(function(resolve)
        resolve(value)
    end)
end

function Promise.reject(reason)
    return Promise.new(function(_, reject)
        reject(reason)
    end)
end

function Promise.all(promises)
    return Promise.new(function(resolve, reject)
        local results = {}
        local completed = 0
        local total = #promises
        
        if total == 0 then
            resolve({})
            return
        end
        
        for i, promise in ipairs(promises) do
            promise:then_(function(value)
                results[i] = value
                completed = completed + 1
                if completed == total then
                    resolve(results)
                end
            end, reject)
        end
    end)
end

Utils.Promise = Promise

-- State machine
local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(states, initialState)
    local self = setmetatable({
        _states = states or {},
        _currentState = nil,
        _stateObjects = {},
        _isTransitioning = false
    }, StateMachine)
    
    -- Initialize state objects
    for name, state in pairs(self._states) do
        self._stateObjects[name] = {
            enter = state.enter or function() end,
            update = state.update or function() end,
            exit = state.exit or function() end
        }
    end
    
    -- Set initial state if provided
    if initialState then
        self:changeState(initialState)
    end
    
    return self
end

function StateMachine:changeState(newState, ...)
    if self._isTransitioning then return end
    if self._currentState == newState then return end
    
    self._isTransitioning = true
    
    -- Exit current state
    if self._currentState and self._stateObjects[self._currentState] then
        self._stateObjects[self._currentState].exit()
    end
    
    -- Change state
    local oldState = self._currentState
    self._currentState = newState
    
    -- Enter new state
    if self._currentState and self._stateObjects[self._currentState] then
        self._stateObjects[self._currentState].enter(oldState, ...)
    end
    
    self._isTransitioning = false
end

function StateMachine:update(dt)
    if self._currentState and self._stateObjects[self._currentState] then
        self._stateObjects[self._currentState].update(dt)
    end
end

function StateMachine:getState()
    return self._currentState
end

Utils.StateMachine = StateMachine

-- Object pooling
local ObjectPool = {}
ObjectPool.__index = ObjectPool

function ObjectPool.new(createFunc, resetFunc, initialSize)
    local self = setmetatable({
        _pool = {},
        _createFunc = createFunc,
        _resetFunc = resetFunc or function() end,
        _inUse = {}
    }, ObjectPool)
    
    -- Pre-create objects
    for i = 1, initialSize or 5 do
        table.insert(self._pool, createFunc())
    end
    
    return self
end

function ObjectPool:get()
    local obj
    
    if #self._pool > 0 then
        obj = table.remove(self._pool)
    else
        obj = self._createFunc()
    end
    
    self._inUse[obj] = true
    return obj
end

function ObjectPool:release(obj)
    if not self._inUse[obj] then return end
    
    self._resetFunc(obj)
    table.insert(self._pool, obj)
    self._inUse[obj] = nil
end

function ObjectPool:clear()
    for obj in pairs(self._inUse) do
        if obj:IsA("Instance") then
            obj:Destroy()
        end
    end
    
    for _, obj in ipairs(self._pool) do
        if obj:IsA("Instance") then
            obj:Destroy()
        end
    end
    
    self._pool = {}
    self._inUse = {}
end

Utils.ObjectPool = ObjectPool

-- Animation utilities
function Utils.playAnimation(humanoid, animationId, priority)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. tostring(animationId)
    
    local track = animator:LoadAnimation(animation)
    track.Priority = priority or Enum.AnimationPriority.Action
    track:Play()
    
    return track
end

-- Sound utilities
function Utils.playSound(soundId, parent, properties)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(soundId)
    
    -- Apply properties
    if properties then
        for prop, value in pairs(properties) do
            sound[prop] = value
        end
    end
    
    sound.Parent = parent or workspace
    sound:Play()
    
    if not properties or properties.Looped ~= true then
        Debris:AddItem(sound, sound.TimeLength + 0.1)
    end
    
    return sound
end

-- String utilities
function Utils.splitString(str, delimiter)
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

function Utils.trimString(str)
    return str:match("^%s*(.-)%s*$")
end

-- Color utilities
function Utils.lerpColor3(a, b, t)
    return Color3.new(
        Utils.lerp(a.R, b.R, t),
        Utils.lerp(a.G, b.G, t),
        Utils.lerp(a.B, b.B, t)
    )
end

-- Random utilities
function Utils.randomFloat(min, max)
    return min + math.random() * (max - min)
end

function Utils.randomInt(min, max)
    return math.floor(Utils.randomFloat(min, max + 1))
end

function Utils.randomChoice(t)
    return t[math.random(#t)]
end

-- Time utilities
function Utils.formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

-- Debug utilities
function Utils.printTable(t, indent)
    indent = indent or 0
    for k, v in pairs(t) do
        local prefix = string.rep("  ", indent)
        if type(v) == "table" then
            print(prefix .. tostring(k) .. ":")
            Utils.printTable(v, indent + 1)
        else
            print(prefix .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

return Utils
