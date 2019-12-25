local inspect = require("inspect")

local dm = require('data-mapper')
local schema = require('data-mapper.schema')
local cond = require("data-mapper.cond")
local config = require('config')

local contacttype = dm.entity:new{
    schema = 'client',
    table = 'contacttype',
    pk = 'sid',
    fields = {
        sid = {
            type = 'string'
        },
        name = {
            type = 'string'
        }
    }
}

local contact = dm.entity:new{
    schema = 'client',
    table = 'contact',
    pk = 'uid',
    fields = {
        uid = {
            type = 'string'
        },
        info = {
            type = 'string'
        },
        sid_contacttype = {
            type = 'string',
            alias = 'contacttype',
            foreign_key = true,
            table = 'contacttype'
        }
    }
}

local validate = dm.entity:new{
    schema = 'oauth',
    table = 'validate',
    pk = 'uid',
    fields = {
        uid = {
            type = 'string'
        },
        code = {
            type = 'string'
        }
    }
}

local role = dm.entity:new{
    table = 'role',
    pk = 'uid',
    fields = {
        uid = {
            type = 'string'
        },
        name = {
            type = 'string'
        }
    }
}

local invite = dm.entity:new{
    table = 'invite',
    pk = 'uid',
    fields = {
        uid = {
            type = 'string'
        },
        uid_contact = {
            type = 'string',
            alias =  'contact',
            foreign_key = true,
            table = 'contact'
        },
        uid_role = {
            type = 'string',
            alias = 'role',
            foreign_key = true,
            table ='role'
        },
        uid_validate = {
            type = 'string',
            alias = 'validate',
            foreign_key = true,
            table = 'validate'
        },
        tsfrom = {
            type = 'string',
        },
        tsto = {
            type = 'string'
        }
    }
}

--for key,table in pairs(schema.tables) do
--    print(string.format("got keys %s %s", key,inspect(table.table)))
--end

local function add_node(parent, type, value)
    local node = {
        type = type,
        value = value,
        parent = parent or null
    }
    if parent then
        parent.sub = parent.sub or {}
        table.insert(parent.sub, node)
    end
    return node
end

local root  = add_node(null, 'select', null)
local child = add_node(root, 'table', role)
local child = add_node(root, 'table', contact)
local join = add_node(child, 'table', contacttype )

local function show_tree(node)
    local build_sql = ""
    if node.type == 'select' then
        build_sql = string.format("%s%s", build_sql, 'SELECT * FROM')
    elseif node.type == 'table' then
        local parent
        if node.parent and node.parent.type then
            parent = node.parent.value
        end
        local entity = node.value
        if parent then
            build_sql = string.format("%s.%s AS %s JOIN", parent.schema, parent.table, parent:get_prefix())
        end
        build_sql = string.format('%s %s.%s AS %s ', build_sql, entity.schema, entity.table, entity:get_prefix())
    end
    --elseif node.type == 'join' then
    --    local list = {}
    --    table.insert(list, node.parent.value:get_prefix())
    --    for key, value in pairs(node.value) do
    --        table.insert(list, key)
    --        table.insert(list, value)
    --    end
    --    print(string.format('JOIN %s.%s = %s', unpack(list)))
    --end
    if node.sub then
        for _,child in pairs(node.sub) do
            build_sql = string.format( "%s%s", build_sql, show_tree(child))
        end
    else
        if node.type == 'table'
    end
    return build_sql
end

print(show_tree(root))

--local test = contact:select():join('contacttype'):join('invite'):join('role')
--print(test:build_sql())
--for _, entity in pairs(test.entities) do
--    print(inspect(entity.table))
--
--end
-- local test = cond:_and({ token, access = "NULL" },{ token, tscreate = "now()", ">=" }, { client, status = true })
--print(test)