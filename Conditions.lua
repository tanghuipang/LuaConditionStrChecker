-- functions for check one condition
-- notice: all params must be string
require "Util"
local conditionFunctions = {}
local hp = 1

-- eg functions
function conditionFunctions.IsTrue(value)
    return string.lower(value) == "true"
end

-- to support multiple param, set NeedMultiParam to true
conditionFunctions.NeedMultiParam = true
function conditionFunctions.IsBigger(value, compareTo)
    return ToNumber(value) > ToNumber(compareTo)
end

function conditionFunctions.IsDead()
    -- hp = GetHpSomewhere()
    return hp <= 0
end

function conditionFunctions.IsHpBiggerThan(value)
    -- hp = GetHpSomewhere()
    return ToNumber(value) > hp
end

return conditionFunctions