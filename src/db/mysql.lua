---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by norguhtar.
--- DateTime: 26.02.19 15:05
---

local status, mysql = pcall(require,"luasql.mysql")

if status then
    return mysql
else
    return nil
end