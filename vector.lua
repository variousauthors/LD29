-- @param _construct: map args   --> object
-- @param tcurtsnoc_: map object --> args
Klass = function (_construct, tcurtsnoc_)
    local constructor

    local function copy(o)
        return constructor(tcurtsnoc_(o))
    end

    constructor = function (...)
        local instance = _construct(unpack({...}))

        instance.copy = function ()
            return copy(instance)
        end

        return instance
    end

    return constructor
end

Point = Klass((function ()
    local constructor = function (x, y)
        local x, y = x, y

        local instance = {
            getX = function ()
                return x
            end,

            getY = function ()
                return y
            end,

            setX = function (n)
                x = n
            end,

            setY = function (n)
                y = n
            end,
        }

        return instance
    end

    local copy = function (o)
        return o.getX(), o.getY()
    end

    return constructor, copy
end)())

Vector = Klass((function ()
    local constructor

    _constructor = function (x, y)
        local p = Point(x, y)

        p.length = function ()
            return math.sqrt(p.getX() ^ 2 + p.getY() ^ 2)
        end

        -- returns a new vector with a length of 1
        p.to_unit = function ()
            local mag = p.length()

            if mag == 0 then return Vector(0, 0) end

            return Vector(p.getX() / mag, p.getY() / mag)
        end

        p.dot = function (o)
            local x = p.getX() * o.getX()
            local y = p.getY() * o.getY()

            return constructor(x, y)
        end

        p.plus = function (o)
            local x = p.getX() + o.getX()
            local y = p.getY() + o.getY()

            return constructor(x, y)
        end

        return p
    end

    constructor = _constructor

    local copy = function (o)
        return o.getX(), o.getY()
    end

    return constructor, copy
end)())
