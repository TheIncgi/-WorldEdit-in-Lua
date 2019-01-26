log("Loading....")
MiniMapInst = false and MiniMapInst or run("miniMap.lua")
local mm = MiniMapInst

log("Generating...")
mm.genHud()
log("Scanning..")
mm.scanAll()
log("Showing...")
sleep(5000)
mm.clearHud()
log("Done")
