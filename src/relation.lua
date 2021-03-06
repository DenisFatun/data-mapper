---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by norguhtar.
--- DateTime: 29.01.19 10:13
---

local relation = {}

local function validate_values(entity, values)
    local valid_values = {}

    if not values then
        return nil
    end

    for key, value in pairs(values) do
        local flt_field = entity:get_field(key)
        if flt_field then
            if type(value) == 'table' then
                if value.value then
                    if string.lower(value.op) == 'ilike' then
                        value.value = '%' .. value.value .. '%'
                    end
                    valid_values[flt_field.name] = { value = flt_field:get_value(value.value), op = value.op }
                end
            else
                if value == 'NULL' then
                    valid_values[flt_field.name] = { value = 'NULL', op = 'IS' }
                end
                if value ~= nil and value ~= 'NULL' then
                    valid_values[flt_field.name] = { value = flt_field:get_value(value), op = '=' }
                end
            end
        end
    end

    if valid_values == {} then
        return nil
    else
        return valid_values
    end
end

local function has_value(row, key, value)
    if row and row[key] == value then
        return true
    end
    return false
end

function relation:new(obj)
    obj = obj or {}

    obj.entities = {}
    obj.sql = {}

    setmetatable(obj, self)
    self.__index = self
    return obj
end

function relation:rebuid_prefix()
    for _, link in pairs(self.sql.join.link) do
        if self.entity:get_prefix() == link.table:get_prefix() then
            link.table:set_prefix(link.table:get_prefix() .. '_0')
        end
        for _, entity in pairs(self.sql.join.link) do
            if entity.table.table ~= link.table.table and entity.table:get_prefix() == link.table:get_prefix() then
               link.table:set_prefix(link.table:get_prefix() .. '_0')
            end
        end
    end

end

function relation:build_filter(entity)
    local filter = ''

    entity = entity or self.entity

    local prefix = entity:get_prefix()

    if self.sql.where then
        if type(self.sql.where) =='table' and next(self.sql.where) then
            for key, value in pairs(self.sql.where) do
                if filter:len() > 0 then
                    filter = string.format("%s AND %s.%s %s %s", filter, prefix, key, value.op, value.value)
                else
                    filter = string.format("WHERE %s.%s %s %s", prefix, key, value.op, value.value)
                end
            end
        end
        if type(self.sql.where) == 'string' then
            filter = string.format("WHERE %s" , self.sql.where)
        end
    end

    return filter
end

function relation:build_sql(entity)
    local sql = ''
    local join = ''

    entity = entity or self.entity

    if self.sql and self.sql.type then
        if self.sql.type == 'SELECT' then

            local fields = {}

            local prefix = entity:get_prefix()

            for key, field in pairs(entity.fields) do
                fields[#fields + 1] = prefix .. '.' .. key .. ' AS ' .. prefix .. '_'
                if field.alias then
                    fields[#fields] = fields[#fields] .. field.alias
                else
                    fields[#fields] = fields[#fields] .. key
                end
            end

            if self.sql.join then
                self:rebuid_prefix()
                for _, value in pairs(self.sql.join.link) do
                    local table = value.table
                    if value.type == 'one' then
                        join = string.format('%s JOIN %s ON %s.%s = %s.%s',
                                join,
                                table:get_table(),
                                table:get_prefix(),
                                table.pk,
                                prefix,
                                value.used_key
                        )
                    else
                        join = string.format('%s JOIN %s ON %s.%s = %s.%s',
                                join,
                                table:get_table(),
                                table:get_prefix(),
                                value.used_key,
                                prefix,
                                value.table.pk
                        )
                    end
                    for key, field in pairs(table.fields) do
                        fields[#fields + 1] = table:get_prefix() .. '.' .. key .. ' AS ' .. table:get_prefix() .. '_'
                        if field.alias then
                            fields[#fields] = fields[#fields] .. field.alias
                        else
                            fields[#fields] = fields[#fields] .. key
                        end
                    end
                end
            end

            sql = string.format("SELECT %s FROM %s %s %s",
                    table.concat(fields, ', '), entity:get_table(), join, self:build_filter())
        elseif self.sql.type == 'INSERT' then
            local fields_list = {}
            local values_list = {}

            for key, value in pairs(self.sql.values) do
                if value.value then
                    fields_list[#fields_list + 1] = key
                    values_list[#values_list + 1] = value.value
                end
            end

            sql = string.format("INSERT INTO %s.%s (%s) VALUES (%s) RETURNING %s",
                    entity.schema,
                    entity.table,
                    table.concat(fields_list, ', '),
                    table.concat(values_list, ', '), entity.pk)
        elseif self.sql.type == 'UPDATE' then
            local update_list = ''
            for key, value in pairs(self.sql.values) do
                if value.value then
                    if string.len(update_list) > 0 then
                        update_list = string.format("%s, %s=%s", update_list, key, value.value)
                    else
                        update_list = string.format('%s=%s', key, value.value)
                    end
                end
            end

            return string.format("UPDATE %s SET %s %s RETURNING %s",
                    entity:get_table(),
                    update_list,
                    self:build_filter(), entity.pk)
        elseif self.sql.type == 'DELETE' then
            return string.format("DELETE FROM %s %s",
                    entity:get_table(),
                    self:build_filter())
        end
    end
    return sql
end

function relation:where(values, entity)

    self.sql.where = {}
    entity = entity or self.entity
    if type(values) == 'table' then
        local where = validate_values(entity, values)

        if where and next(where) then
            self.sql.where = where
        end
    else
        self.sql.where = values
    end

    return self

end

function relation:select(entity)

    self.entity = entity or self.entity
    self.sql.type = 'SELECT'
    self.sql.join = { link = {} }

    if self.entity then
        for key, value in pairs(self.entity.fields) do
            if value.foreign_key and value.table and value.fetch then
                self:join(value.table.table)
            end
        end

        return self
    else
        return nil
    end
end

local function has_table(links, table)
    for _, link in pairs(links) do
        if link.table.table == table then
            return true
        end
    end
    return false
end

local function join_link(entity, fentity, type, link)
    type = type or 'one'
    local res
    if type == 'one' then
        res = entity:get_foreign_link(fentity.table)
        if res then
            res.type = type
            return res
        end
    elseif type == 'many' then
        res = fentity:get_foreign_link(entity.table)
        if res then
            res = {
                table = fentity,
                    type = type,
                    used_key = res.used_key
            }
        end
    end
    return res
end

function relation:join(join_table, linkinfo)

    if not self.sql.join then
        self.sql.join = { link = {} }
    end

    local entity = self.entity
    if entity then

        if type(join_table) == 'string' then
            join_table = { table = join_table }
        end

        if not linkinfo then
            linkinfo = { type = 'one' }
        end

        local link = join_link(self.entity, join_table, linkinfo.type, linkinfo.link)
        if link and not has_table(self.sql.join.link, link.table) then
            self.sql.join.link[#(self.sql.join.link)+1] = link
        end
    end

    return self
end

function relation:insert(values, entity)

    entity = entity or self.entity

    local insert_values = validate_values(entity, values)

    if next(insert_values) then
        self.sql.type = 'INSERT'
        self.sql.values = insert_values
        self.entity = entity
        return self
    else
        return nil
    end
end

function relation:update(values, entity)

    entity = entity or self.entity

    local update_values = validate_values(entity, values)

    if update_values then
        self.sql.type = 'UPDATE'
        self.sql.values = update_values
        self.entity = entity
        return self
    else
        return nil
    end
end

function relation:delete(entity)

    self.entity = entity or self.entity
    self.sql.type = 'DELETE'

    if self.entity then
        return self
    else
        return nil
    end
end

function relation:mapper()
    if self.sql.type == 'SELECT' then
        local entity = self.entity
        local query = self:build_sql()
        local db = self.entity.db

        local res = db:query(query)
        local data = {}
        local links_idx = {}
        local links = {}

        if res and next(res) then
            for num, row in pairs(res) do
                if not data[#data] or not has_value(row, entity:get_col(), data[#data][entity.pk]) then
                    data[#data + 1] = entity:mapper(row)
                end
                if self.sql.join then
                    for key, link in pairs(self.sql.join.link) do
                        local link_entity = link.table
                        local link_table = link_entity.table
                        local link_type = link.type
                        if type(data[#data][link_table]) ~= 'table' then
                            data[#data][link_table] = {}
                        end
                        if link_type == 'one' then
                            local link_map = data[#data][link_table]
                            if not link_map or not has_value(row, link_entity:get_col(), link_map[entity.pk]) then
                                link_map = link_entity:mapper(row)
                            end
                            data[#data][link_table] = link_map

                        elseif link_type == 'many' then
                            local link_map = data[#data][link_table]
                            if not link_map[#link_map] or not has_value(row, link_entity:get_col(), link_map[#link_map][entity.pk]) then
                                link_map[#link_map + 1] = link_entity:mapper(row)
                            end
                            data[#data][link_table] = link_map
                        end
                    end
                end
            end
        end

        return data
    end
end

return relation