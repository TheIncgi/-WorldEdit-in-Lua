--Version 2
local eType, eventType, text = ...
if not(eType=="RELOAD" or eType == "event" and eventType == "ChatSendFilter") then
  return
end


local RELOAD = false
local args = {...}

if eType == "RELOAD" then
  args = {}
  RELOAD = true
  theincgi.worldEdit = {}
end

local DEBUG = false
local Vector = run("Vector.lua")


theincgi = theincgi or {}
theincgi.worldEdit = theincgi.worldEdit or {}


local doSetup = not theincgi.worldEdit.isSetup

if doSetup then
  theincgi.worldEdit = {}
  theincgi.worldEdit.PREFIX = "//"
  theincgi.Vector = Vector
  run("Selection.lua")
  
  --runs each file in a given folder
  function theincgi.worldEdit.runFolder( path )
    if DEBUG then
      log("Loading "..path)
    end
    local fs = filesystem
    if not fs.exists(path) then
      fs.mkDir(path)
    end
    
    for _,file in pairs(fs.list(path)) do
      if not fs.isDir(path.."/"..file) then
        local success, result = pRun(path.."/"..file)
        if( not success )then
          log("&4~~~ Error on: ~~~")
          log("&5"..path.."/"..file)
          log("&c"..result.."\n&4~~~ End of Err ~~~")
        end
      end
    end
  end
  --returns north/south/west/east/up/down
  --combine with theincgi.worldEdit.dirs
  function theincgi.worldEdit.getPlayerDir()
    local p = getPlayer()
    local dir = theincgi.worldEdit.dirs
    local pitch, yaw = p.pitch, p.yaw
    if     pitch <= -45 then return "up"
    elseif 45 <= pitch then return "down"
    elseif -45 <= yaw and yaw < 45 then return  "south"
    elseif 45 <= yaw and yaw < 135 then return  "west"
    elseif 135<= yaw and yaw <= 180 then return "north"
    elseif-180<= yaw and yaw < -135 then return "north"
    elseif-135<= yaw and yaw < -45 then return  "east"
    else
      error(string.format("no dir for <%d, %d>", yaw, pitch)) --logic error somewhere if this ever manages to happen, which it shouldn't
    end
  end
  
  --loads a command from each file in a given path
  --returns hash, alphabatized
  function theincgi.worldEdit.loadFolder( path )
    --theincgi.worldEdit.commands = {}
    local cmdList = {}
    local fs = filesystem
    if not fs.exists(path) then
      error("&5No "..path.." folder exists&c")
    end
    local count = 0
    local keys = {}
    
    for _,file in pairs(fs.list(path)) do
      --if DEBUG then log( "&7Loading: "..file ) end
      if not fs.isDir(path.."/"..file) then
        local success, result = pRun(path.."/"..file)
        if(success)then
          cmdList[ file ] = result
          count = count+1
          keys[count] = file
        else
          log("&c"..result.."\n&4~~~End of Err~~~")
        end
      end
    end
    if DEBUG then
      log("&a"..count.."&f of &a"..#fs.list("commands").." &f commands loaded")
    end
    --create alphabatized cache
    table.sort(keys)
    --theincgi.worldEdit.aToZ = keys
    return cmdList,keys
  end
  
  function theincgi.worldEdit.getPageCount( alph, perPage )
    return math.ceil((#alph) / perPage)
  end
  
  --listCommands(category, prefix, aToZ, cmdList, helpCmd, pageNum, perPage, menuFlavor)
  --category - menu title | prefix // //map ..etc
  --aToZ alphabatized cmds | cmdList commandList
  --helpCmd cmd to pull up this menu ie //map
  --pageNum, perPage, menuFlavor (tooltip)
  function theincgi.worldEdit.listCommands(category, prefix, aToZ, cmdList ,helpCmd, pageNum, perPage, menuFlavor )
    if not aToZ then log("&cErr: No commands loaded") end
    helpCmd = helpCmd.." "
    pageNum = pageNum or 1
    perPage = perPage or 10
    menuFlavor = menuFlavor or ""
    local P = prefix.." "
    log("&7-------------------------")
    log(string.format("&7- &e&B&N%s COMMANDS&7",category),menuFlavor)
    log(string.format("&7-         (&a%3d &fof &a%3d&7)", pageNum, theincgi.worldEdit.getPageCount( aToZ, perPage )))
    log("&7-------------------------")
    for i = (pageNum-1)*perPage+1, pageNum*perPage do
      local cmdName = aToZ[i]
      if not cmdName then break end
      local cmd = cmdList[cmdName]
      if not cmd then error("&5command pressent in aToZ missing in cmdList") end
      if (type(cmd.desc)=="table")then
        log(" &8> &7&T"..P.."&f", P..cmdName, table.unpack(cmd.desc))
      else  
        if not cmd.desc then
          log(" &c> "..P.."&N&O??", "&c"..cmdName.."&f is missing a description &7(&Bdesc&7)")
        else
          log(" &8> &7&T"..P.."&f", P..cmdName, cmd.desc)
        end
      end
    end
    local hasPrev = pageNum>1
    local hasNext = (pageNum)*perPage <= #aToZ
    local actions = {}
    if hasPrev then actions[1] = helpCmd..(pageNum-1) end
    if hasNext then actions[#actions+1] = helpCmd..(pageNum+1) end
    log("&7-------------------------")
    log(string.format("-  &d%s&7                    &d%s",
        hasPrev and "&RPREV" or "    ",
        hasNext and "&RNEXT" or "    "),
        table.unpack(actions))
    log("&7-------------------------")
  end
  
  function theincgi.worldEdit.parse(cmdText, ...)
    if cmdText == nil or cmdText == "" then
      cmdText = "help"
    end
    local cmd = theincgi.worldEdit.commands[cmdText]
    if not cmd then 
      if DEBUG then
        log("&cCommand &7"..cmdText.." &cdoesn't exist")
      end
      return false 
    end
    cmd.func( ... )
    return true
  end
  
  theincgi.worldEdit.isSetup = true
  theincgi.worldEdit.runFolder("init")
  theincgi.worldEdit.commands,
    theincgi.worldEdit.aToZ = 
      theincgi.worldEdit.loadFolder("commands")
end

if not RELOAD then
  if text:sub(1,#theincgi.worldEdit.PREFIX) == theincgi.worldEdit.PREFIX then
    text = text:sub( #theincgi.worldEdit.PREFIX +1 )
    local m = text:gmatch("[%S]+") --non white space
    local args = {}
    local j = m()
    while j ~= nil do
      --log(j)
      args[#args+1] = tonumber(j) or j
      j = m()
    end
    --log(args)
    if not theincgi.worldEdit.parse( table.unpack(args) ) then
      return theincgi.worldEdit.PREFIX .. text --wasnt one of this world edits commands
    end  
  else
    return text
  end
else
  log("&7World edit reloaded")
end
