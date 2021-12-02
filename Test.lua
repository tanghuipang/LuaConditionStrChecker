local Checker = require "Checker"

local isTrue1 = Checker.CheckCondition("IsTrue:false")
local isTrue2 = Checker.CheckCondition("IsTrue:true")
local res = Checker.CheckCondition("!IsDead&IsBigger:2,1")
local res2 = Checker.CheckCondition("!(IsDead&IsBigger:2,1)|IsTrue:true")

assert(not isTrue1)
assert(isTrue2)
assert(res)
assert(res2)