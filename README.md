# data-mapper

Data mapper for lua

## Contents

[API](#api)
+ [Entity](#entity)
+ [Field](#field)
+ [Relation](#relation)
+ [Condition](#condition)

[Dependencies](#dependencies)

[Usage](#usage)

## Dependencies

 - [Pgmoon](https://github.com/leafo/pgmoon "Pgmoon github")
 - [LuaSQL](https://keplerproject.github.io/luasql/index.html "LuaSQL home page")
 
## API

### Entity

Entity - use for description table in database. For example

	local db = require("data-mapper.db"):new{
			config = {
				driver = "postgres",
				host = "localhost",
				port = "5432",
				user = "test",
				password = "testpw",
				database = "test"
			}
		}
    local entity = require('data-mapper.entity')

	local testtype = entity:new{
		table = 'testtype',
		pk = 'sid',
		db = db,
		fields = {
			sid = {
				type = 'string'
			},
			name = {
				type = 'string'
			}
		}
	}

	local test = entity:new{
		table = 'test',
		pk = 'id',
		db = db,
		fields = {
			id = {
				type = 'number'
            },
			sid_testtype = {
                    alias ='testtype',
                    type = 'string',
                    foreign_key = true,
                    table = testtype
            },
            name = {
				type = 'string'
			},
			dt = {
				type = 'string'
            },
            balance = {
				type = 'number'
            }
        }
    }

In entity you can define properties:

 - **schema** - table schema. If not defined used *public*
 - **table** - table name 
 - **pk** - table primary key. If not defined used *id*
 - **prefix** - used table prefix. If not defined used first char from *schema* and *table* for example
    *public.test* get prefix **pt**  
 - **db** - used database 
 - **fields** - defined fields in table
 
 Entity provide those methods:
 
  - [**add**](#add) - insert new record in table and return create record
  - [**update**](#update) - update record in table
  - [**delete**](#delete) - delete record in table
  - [**get_by_pk**](#get_by_pk) - get records from table by primary key value
  - [**get_by_field**](#get_by_field) - get records from table by field value 
  - [**get**](#get) - get records from table by fields parameters

#### add 
For add new record:

	test = test:add({id=1,testtype = 'test1', name='test', dt='1970-01-01'})
	print(inspect(test))
	
	{
        dt = "1970-01-01",
        id = 1,
        name = "test",
        testtype = "test1"
	}

#### update
For update record:

	test = test:update({dt='2018-01-01', name='update-test'}, {id=1})
	print(inspect(test))
	
	{
        dt = "2018-01-01",
        id = 1,
        name = "update-test",
        testtype = "test1"
	}

#### delete 
For delete record:

	test:delete{id=1}
	
#### get_by_pk

	test = test:get_by_pk(1)
	print(inspect(test))
	
	{
		dt = "2018-01-01",
        id = 1,
        name = "update-test",
        testtype = "test1"
    }

#### get_by_field

	test = test:get_by_field('name', 'update-test')
	print(inspect(test))
	{
		dt = "2018-01-01",
        id = 1,
        name = "update-test",
        testtype = "test1"
    }

#### get

Simple usage:

	test = test:get{ id=1, name= "update-test"}
	print(inspect(test))
	{
		dt = "2018-01-01",
        id = 1,
        name = "update-test",
        testtype = "test1"
    }
	
Advanced usage:

	test = test:get{ name = {value = "update", op = 'ilike' }}
	print(inspect(test))
	{
		dt = "2018-01-01",
        id = 1,
        name = "update-test",
        testtype = "test1"
	}
	
Now supported operation:
 * ilike
 * =,<,>,<=,>=
 
This operation also supported in update filter

### Field

Definition fields in entity constructor generate Field object
Field object support 

  * foreign keys  
  * alias
  * prefetch
 
 For example add link one to many
 
    uid_role = {
        type = "string",
        alias = "role",
        table = role,
        foreign_key = true
        fetch = true
    }
 

### Condition

Use condition for complex query in where. Now supported *and*, *or*

#### _and 

For example:

    local sql = user:select():join(orders):where(
       cond:_and(
               { user, name="test" },
               { orders, status = true }
       ))
    

#### _or

For example 

    local sql = user:select():join(orders):where(
       cond:_and(
               { user, name="test" },
               cond:_or(
                    { user, status = true },
                    { user, expires_in = -1 }),
               { orders, status = true }
       ))

You can combine **_or** and **_and** where relation method. Also field in cond support operators
*IN*, *<=*, *>=*, *IS*. 
For example 

    cond:_and({user, name = {op='IN', value = {"test", "test2"} } }) 