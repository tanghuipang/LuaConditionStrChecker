
function IsTable(arg)
    return type(arg) == "table"
end

function IsBoolean(arg)
    return type(arg) == "boolean"
end

function IsNumber(arg)
    return type(arg) == "number"
end

function IsString(arg)
    return type(arg) == "string"
end

function IsFunction(arg)
    return type(arg) == "function"
end

function IsUserData(arg)
    return type(arg) == "userdata"
end

function IsThread(arg)
    return type(arg) == "thread"
end

-- #FFFFFFFF 转换为 CS.UnityEngine.Color
function HexToColor(hexColor)
	if not IsString(hexColor) then
		U3dError("HexToColor not a valid hex color string:", hexColor)
		return Color.white
	end

	if IsNilOrEmpty(hexColor) then
		U3dError("HexToColor not a valid hex color string:", hexColor)
		return Color.white	
	end

	local start = 1
	if string.sub(hexColor, 1, 1) == "#" then
		start = 2
	end

	local color = {}
	for i = 1, 4 do
		local str = string.sub(hexColor, start + (i-1) * 2, start + i * 2 - 1)
		if IsNilOrEmpty(str) then
			str = "FF"
		end
		local x = tonumber("0x" .. str)
		if x == nil then
			U3dError("HexToColor not a valid hex color string:", hexColor)
			return Color.white
		end
		color[i] = x
	end

	return Color(color[1] / 255, color[2] / 255, color[3] / 255, color[4] / 255)
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function ToNumber(_number, defaultValue)
    if type(_number) == "string" then return tonumber(_number) or defaultValue or -1; end
    if _number == nil or type(_number) ~= "number" then return defaultValue or -1; end
    return _number;
end

function IsNullOrEmpty(pStr)
	if type(pStr) ~= "string" then
		return true;
	end
	if pStr == nil or pStr == "" then
		return true;
	end
	return false;
end