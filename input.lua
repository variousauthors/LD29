--[[
    Input events and input checking

    Mappings:
]]--

Input = {}
Input.mappings = {
    left = {
        {"k", "left"},
        {"j", "dpleft"},
        {"ja", "leftx", -0.2}
    },

    right = {
        {"k", "right"},
        {"j", "dpright"},
        {"ja", "leftx", 0.2}
    },

    jump = {
        {"k", " "},
        {"k", "up"},
        {"j", "a"},
        {"j", "x"}
    }
}

Input.joystick = nil

function love.joystickadded (j)
    local joysticks = love.joystick.getJoysticks()
    if joysticks then
        Input.joystick = joysticks[1]
    end
end

function love.joystickremoved (j)
    local joysticks = love.joystick.getJoysticks()
    if joysticks then
        Input.joystick = joysticks[1]
    end
end

-- I manually entered the mappings in the table above, so this isn't super
-- relevant, but...
function Input.addMapping (name, device, key)
    local mapcode = {}

    if (device == "keyboard") then
        mapcode[1] = "k"
    elseif (device == "joystick") then
        mapcode[1] = "j"
    end

    mapcode[2] = key

    if not Input.mappings[name] then
        Input.mappings[mapping] = {}
    end

    table.insert(Input.mappings[name], mapcode)
    return { name, mapcode }
end

function Input.isPressed (name)
    if not Input.mappings[name] or not love.window.hasFocus() then
        return false
    end

    for k, v in pairs(Input.mappings[name]) do
        if v[1] == "k" then
            if love.keyboard.isDown(v[2]) then return true end
        elseif Input.joystick then
            if v[1] == "j" then
                if Input.joystick:isGamepadDown(v[2]) then return true end
            elseif v[1] == "ja" then
                local axis = Input.joystick:getGamepadAxis(v[2])
                if v[3] >= 0 then
                    if axis >= v[3] then return true end
                else
                    if axis <= v[3] then return true end
                end
            end
        end
    end

    return false
end
