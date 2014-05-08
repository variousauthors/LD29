--[[
    Input events and input checking

    Mappings:
]]--

Input = {}
Input.mappings = {
    left = {
        {"k", "left"},
        {"j", "dpleft"}
    },

    right = {
        {"k", "right"},
        {"j", "dpright"}
    },

    jump = {
        {"k", " "},
        {"k", "up"},
        {"j", "a"}
    }
}
Input.joystick = love.joystick.getJoysticks()[1]

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
    if not Input.mappings[name] then
        return false
    end

    for k, v in pairs(Input.mappings[name]) do
        if v[1] == "k" then
            if love.keyboard.isDown(v[2]) then return true end
        elseif v[2] == "j" then
            if this.joystick.isGamepadDown(v[2]) then return true end
        end
    end

    return false
end
