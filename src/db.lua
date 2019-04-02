---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by norguhtar.
--- DateTime: 26.02.19 13:02
---

local postgres = require('data-mapper.db.postgres')
local mysql = require('data-mapper.db.mysql')

local db = {}

function db:new(obj)
    obj = obj or {}

    local config = obj.config
    if config.driver == "postgres" then
        return postgres:new(obj)
    elseif config.driver == "mysql" then
        return mysql:new(obj)
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end

return db