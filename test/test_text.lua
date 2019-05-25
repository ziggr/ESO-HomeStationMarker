package.path = package.path..";test/?.lua;lang/?.lua"
luaunit = require("luaunit")

TestText = {}

function TestText.TestOne()
    luaunit.assertEquals("one", "one")
end


os.exit( luaunit.LuaUnit.run() )
