
require "Util"

local function FindAll(str, char, result)
	local idx = 1
	local pos = nil
	if result == nil then result = {} end
	local prevCount = #result
	repeat
		pos = str:find(char, idx, true)
		if pos ~= nil then
			idx = pos + 1
			table.insert(result, {pos = pos, char = char})
		end
	until pos == nil

	return result, #result - prevCount
end

local NOT = string.byte('!')
local OPEN = string.byte('(')
local CLOSE = string.byte(')')
local TOKEN = string.byte('$')
local function SliceConditionStr(str, pieces)
	local tier = 0
	local start = 0
	local endPos = nil
	if pieces == nil then pieces = {} end
	for i = 1, str:len() do
		local b = str:byte(i)
		if b == OPEN then
			tier = tier + 1
			start = i
		elseif b == CLOSE then
			tier = tier - 1
			if tier < 0 then
				error("SyntexError:括号不匹配", str)
				return nil
			elseif tier == 0 then
				endPos = i
				local key = tostring(#pieces)
			end
		end
	end

	if tier > 0 then
		error("SyntexError:括号不匹配", str)
		return nil
	end

	if start == 0 then
		return str
	end
end

local function ParseLeafCondition(str, directTable, conditionFuncs)
	if not IsString(str) then
		error("invalid string:", str)
		return nil
	end
	local i = 1
	local is_not = false
	while string.byte(str, i) == NOT do
		is_not = not is_not
		i = i + 1
	end
	if string.byte(str, 1) == TOKEN then

	end
	str = string.sub(str, i)
	local params = string.split(str, ':')
	local func = conditionFuncs[params[1]] or _G[params[1]] -- 判断函数可以是Condition中的或者全局函数 
	if IsFunction(func) then
		table.remove(params, 1)
		local param -- 传入的参数,注意根据参数数量不同,填入的内容也不同
		if #params == 0 then
			param = nil
		elseif #params == 1 then
			param = params[1]
		else
			param = params
		end
		return {is_not = is_not, is_leaf = true, func = func, param = param}
	else
		local id = ToNumber(str, -1)
		if id == -1 then
			error("不是正确的条件语句:" .. str)
			return nil
		end
		local res = {is_not = is_not, is_leaf = false, redirect = id}
		table.insert(directTable, res)
		return res
	end
end

-- 解析不含任何括号的条件
local function ParseSubCondition(str, directTab, conditionFuncs)
	local result = {}
	local subs = string.split(str, '|')
	local orConditions = {}
	for _, sub in ipairs(subs) do
		local s = string.split(sub, '&')
		if #s == 1 then
			local con = ParseLeafCondition(sub, directTab, conditionFuncs)
			if con ~= nil then
				table.insert(orConditions, con)
			end
		else
			local andConditions = {}
			for _, ss in ipairs(s) do
				local leafCondition = ParseLeafCondition(ss, directTab, conditionFuncs)
				if leafCondition ~= nil then
					table.insert(andConditions, leafCondition)
				end
			end
			if #andConditions == 0 then
				-- 本节点中没有任何东西
			elseif #andConditions == 1 then
				table.insert(orConditions, andConditions[1])
			else
				table.insert(orConditions, {is_and = true, sub_conditions = andConditions})
			end
		end
	end
	if #orConditions == 0 then
		return nil
	elseif #orConditions == 1 then
		return orConditions[1]
	else
		return {is_or = true, sub_conditions = orConditions}
	end
end

-- 解析为树状结构
local function CreateTree(conditionStr, allParenthesis)
	local root = {st = 0, en = #conditionStr + 1, id = 0, parent = nil, children = {}}
	local stack = {} -- 当前进入第几层括号
	local maxTier = -1
	local id = 1
	local this = root
	for i = 1, #allParenthesis do
		local item = allParenthesis[i]
		if item.char == '(' then
			table.insert(stack, item)
			this = {children = {}, parent = this}
			this.id = id; id = id + 1
			table.insert(this.parent.children, this)
		elseif item.char == ')' then
			if #stack == 0 then
				error("SyntexError: 括号匹配不正确", conditionStr)
				return nil
			end
			this.st = table.remove(stack).pos
			this.en = item.pos

			this = this.parent
			if maxTier < #stack then maxTier = #stack end
		end
	end

	return root
end

local function BuildTokenConditionStr(token, rawStr)
	if #token.children > 0 then
		local tkStr = ''
		local prevChild = nil
		for j = #token.children, 1, -1 do
			local child = token.children[j]
			BuildTokenConditionStr(child, rawStr)
			local endPos 
			if prevChild == nil then endPos = token.en - 1 else endPos = prevChild.st - 1 end
			tkStr = child.id .. string.sub(rawStr, child.en + 1, endPos) .. tkStr
			prevChild = child
		end
		tkStr = string.sub(rawStr, token.st + 1, prevChild.st - 1) .. tkStr
		token.str = tkStr
	else
		token.str = string.sub(rawStr, token.st + 1, token.en - 1)
	end
end

local function BuildTokenCondition(token, allTokenCon, redirectTab, conditionFuncs)
	if allTokenCon == nil then allTokenCon = {} end
	if redirectTab == nil then redirectTab = {} end
	local con = ParseSubCondition(token.str, redirectTab, conditionFuncs)
	allTokenCon[token.id] = con

	for _, tk in ipairs(token.children) do
		BuildTokenCondition(tk, allTokenCon, redirectTab, conditionFuncs)
	end

	return con
end

local function ParseCondition(conditionStr, conditionFuncs)
	if IsNullOrEmpty(conditionStr) then return nil end
	local allParenthesis = {}
	local _, openCount = FindAll(conditionStr, '(', allParenthesis)
	local _, closeCount = FindAll(conditionStr, ')', allParenthesis)
	if openCount ~= closeCount then
		error("SyntexError: 括号数目不匹配", conditionStr)
		return nil
	end

	if openCount == 0 then
		return ParseSubCondition(conditionStr, nil, conditionFuncs)
	end

	table.sort(allParenthesis, function(a, b)
		return a.pos < b.pos
	end)
	if allParenthesis[1].char ~= '(' then
		error("SyntexError: 括号匹配不正确", conditionStr)
		return nil
	end

	local root = CreateTree(conditionStr, allParenthesis)

	local rawStr = conditionStr -- 保存一下原始字符串，否则执行过程中被改了字符串会变
	-- 生成token对象对应字符串，将其中的括号内容替换为对应的tokenId
	BuildTokenConditionStr(root, rawStr)
	local allTokenCon = {}
	local needDirectCon = {}
	local condition = BuildTokenCondition(root, allTokenCon, needDirectCon, conditionFuncs)
	for _, v in pairs(needDirectCon) do
		v.redirect_condition = allTokenCon[v.redirect]
		if v.redirect_condition == nil then
			error("不是正确的目标条件" .. v.str)
		end
	end

	return condition
end

local Parser = {}

function Parser.ParseCondition(conditionstr, conditionFunctions)
    return ParseCondition(conditionstr, conditionFunctions)
end

return Parser