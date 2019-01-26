local we = theincgi.worldEdit
we.miniMap = {}
local mm = we.miniMap
mm.data = run("../commands/minimap/miniMap.lua")
--Notice that this is relative to worldEdit.lua
--not this script
mm.commands, mm.aToZ = theincgi.worldEdit.loadFolder("commands/minimap/commands")
--log(mm.commands)
--log(mm.aToZ)
