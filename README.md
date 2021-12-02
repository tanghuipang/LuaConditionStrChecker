## Useage
To check combined conditions in config files or scripts.

## How to
### define single condition checkfunctions
Put simple condition check functions in Conditions.lua, such as:
    function IsDead() ... end
    function IsHpBiggerThan(value) ... end

### check condition string
Check condition in string:
```lua
    local checker = require "Checker"
    local condStr = "!IsDead&IsHpBiggerThan:3"
    isOK = checker.CheckCondition(condStr)
```
use ! as 'not', & as 'and', | as 'or'. use : between function name and params.