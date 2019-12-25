---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by norguhtar.
--- DateTime: 06.12.18 11:45
---

local schema = require('data-mapper.schema')
local field = require('data-mapper.field')
local relation = require('data-mapper.relation')

local entity = {
    schema = 'public',
    table = '',
    pk = 'id'
}

function entity:new(obj)
    obj = obj or {}

    if type(obj.fields) == 'table' then
        for key, value in pairs(obj.fields) do
            value.name = key
            obj.fields[key] = field:new(value)
        end
    end

    obj.relation = relation:new{entity = obj}

    setmetatable(obj, self)
    self.__index = self

    schema:add(obj)

    return obj
end

function entity:set_db(db)
    self.db = db
end

function entity:get_prefix(root)
    local prefix = string.sub(self.schema,1,1) .. string.sub(self.table,1,1)
    if root then
        return prefix
    end

    if not self.prefix then
        self.prefix = prefix
    end

    return self.prefix
end

function entity:set_prefix(prefix)
    self.prefix = prefix
    return self.prefix
end

function entity:get_field(name)
    for key, value in pairs(self.fields) do
        if name == value.name or name == value.alias then
            return value
        end
    end
end

function entity:get_foreign_link(table)
    for key, value in pairs(self.fields) do
        if value.foreign_key and value.table and value.table.table == table
        then
            return { table = value.table, used_key = key }
        end
    end
end

function entity:get_table()
    return string.format('%s.%s AS %s', self.schema, self.table, self:get_prefix())
end

function entity:get_col(name)
    name = name or self.pk
    return string.format("%s_%s", self:get_prefix(), name)
end

function entity:mapper(row)
    local res = {}
    local row_idx
    local idx
    for key, field in pairs(self.fields) do
        if not field.hide then
            row_idx = self.prefix .. '_' .. key
            idx = key
            if field.alias then
                row_idx = self.prefix .. '_' .. field.alias
                idx = field.alias
            end
            if row[row_idx:lower()] then
                res[idx] = row[row_idx:lower()]
            end
            if row[row_idx:upper()] then
                res[idx] = row[row_idx:upper()]
            end
        end
    end
    return res
end

function entity:select()
    return self.relation:select()
end

function entity:get(fields)
    if self.db then
        local relation = self.relation:select():where(fields)
        return relation:mapper()
    end
end

function entity:get_by_field(field, value)
    local fields = {}
    fields[field]= value
    return self:get(fields)
end

function entity:get_by_pk(value)
    local list = self:get_by_field(self.pk, value)
    if next(list) then
        return list[1]
    end
end

function entity:add(fields)
    local query = self.relation:insert(fields):build_sql()
    local res = self.db:query(query)
    if next(res) then
        return self:get_by_pk(res[1][self.pk])
    end
end

function entity:update(fields, filter_values)
    local query = self.relation:update(fields):where(filter_values):build_sql()
    local res = self.db:query(query)
    if next(res) then
        return self:get_by_pk(res[1][self.pk])
    end
end

function entity:delete(fields)
    local query = self.relation:delete():where(fields):build_sql()
    local res = self.db:query(query)
    if next(res) then
        return res
    end
end

return entity
