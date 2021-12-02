local Parser = require "Parser"
local Checker = {}
local unpack = table.unpack or unpack

function Checker.CheckCondObj(condition)
    local res = nil
	if not IsTable(condition) then
		return true	-- 空条件视为真
	end

	if condition.redirect_condition then
		res = Checker.CheckCondObj(condition.redirect_condition)
	elseif condition.is_or then
		for _, v in ipairs(condition.sub_conditions) do
			res = res or Checker.CheckCondObj(v)
		end
	elseif condition.is_and then
		for _, v in ipairs(condition.sub_conditions) do
			if res == nil then -- 默认值nil被视为false，会被短路，故需特殊处理
				res = Checker.CheckCondObj(v)
			else
				res = res and Checker.CheckCondObj(v)
			end
		end
	else	-- 叶子节点，不包含任何子节点，只会被not修饰
        if IsFunction(condition.func) then
            if Checker.conditionFunctions.NeedMultiParam then
                local param = string.split(condition.param, ',')
                res = condition.func(unpack(param))
            else
                res = condition.func(condition.param)
            end

		else
			error("Invalid function:", condition)
		end
	end

	if condition.is_not then
		res = not res
	end
	return res
end

function Checker.CheckCondition(conditionStr)
    if not IsString(conditionStr) then return true end
    Checker.conditionFunctions = require "Conditions"
    local cond = Parser.ParseCondition(conditionStr, Checker.conditionFunctions)

    return Checker.CheckCondObj(cond)
end

return Checker