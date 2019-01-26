--set this script up to the Anything event
local args = {...}


local settings
local defaults = {
  resolution  = 64,
  size        = 1/5, --hud size
  mapRadius   = 32,  --how many blocks from center to show
  pos         = {5, 5},
  alpha       = .75,
  refreshRate = 3000, --applies to chunks you already mapped, not edge chunks
  mapsFolder  = "maps"
}
local function grabSettings()
  local mutex = newMutex("theincgi.minimap#settings")
  if not mutex.tryLock() then return end
  local settings = getSettings()
  --log(settings.theincgi)
  if not( settings.theincgi and settings.theincgi.minimap) then
    settings.theincgi = settings.theincgi or {}
    settings.theincgi.minimap = {}
    settings.save()
  end
  settings = settings.theincgi.minimap
  setmetatable(settings, {__index=defaults})
  mutex.unlock()
  return settings
end
local function resetSettings()
  local s = getSettings()
  local the = s.theincgi or {}
  the.minimap = {}
  s.theincgi = the
  s.save()
end

local MiniMap = {}
MiniMap.chunks    = {} --chunks[dim][x][y] {{},...} surface colors
MiniMap.waypoints = {} --waypoints[i] = {x,y,z; color,text}
MiniMap.settings = grabSettings()
MiniMap.tmpImg   = image.new(16,16)
MiniMap.lastUpdate = -1
MiniMap.topographyMode = false
MiniMap.topographySensitivity = 8
settings = MiniMap.settings

function MiniMap.genHud()
  local res = settings.resolution
  MiniMap.tex = MiniMap.tex or image.new(res, res)
  MiniMap.tex.graphics.setColor(0xFF888888)
  MiniMap.tex.graphics.fillRect(1,1,res,res)
  local size = math.floor(hud2D.getSize() * settings.size)
  if MiniMap.img then MiniMap.img.destroy() end
  --log("Creating element with size ",size)
  MiniMap.img = hud2D.newImage(MiniMap.tex, settings.pos[1], settings.pos[2], size, size)
  MiniMap.img.setOpacity(.5)
  MiniMap.img.enableDraw()  
  --log(MiniMap.img)
end
function MiniMap.clearHud()
  if MiniMap.img then MiniMap.img.destroy() MiniMap.img = nil end
end

function MiniMap.getMapFileName()
  return string.format("%s/%s.map",settings.mapsFolder,getWorld().name)
end

function MiniMap.scanAll(optR)
  local px, _, pz = getPlayerBlockPos()
  local cx, cz = math.floor(px/16), math.floor(pz/16)
  for r = 0, optR or 11 do
    MiniMap.radialScan(cx, cz, r)
  end
end

function MiniMap.isChunkComplete(sChunk)
end

function MiniMap.scanUnscanned(optR)
  local px, _, pz = getPlayerBlockPos()
  local cx, cz = math.floor(px/16), math.floor(pz/16)
  local dim = getPlayer().dimension
  r = r or 11
  
  for z = cz - r, cz+r do
    for x = cx - r, cx+r do
      if not(
        MiniMap.chunks and
        MiniMap.chunks[dim] and
        MiniMap.chunks[dim][x] and
        MiniMap.chunks[dim][x][z] and
        MiniMap.isChunkComplete( MiniMap.chunks[dim][x][z] and
        getBlock(x*16,0,z*16) --chunk is also loaded
        )
      ) then
        MiniMap.scanChunk(x,z)
      end
    end
  end
end

--scans the square "circle" of chunks at r chunks away from x, z
--used during startup
--start at 0, out to 11
function MiniMap.radialScan(x, z, r)
  --top row
  for cx=x-r, x+r do
    MiniMap.scanChunk(cx, z-r)
  end
  --right col, minus because z is flipped (right hand rule)
  for cz=z-r+1,z+r do
    MiniMap.scanChunk(x+r, cz)
  end 
  --bottom backwards
  for cx=x+r-1, x-r, -1 do
    MiniMap.scanChunk(cx, z+r)
  end
  --left up
  for cz=z+r-1, z-r, -1 do
    MiniMap.scanChunk(x-r, cz)
  end
  --log(MiniMap.chunks)
end

function MiniMap.valueOf(x,z)
  local block, y
  for y = 255, 0, -1 do
    block = getBlock(x, y, z)
    if not block then return false end --chunk unloaded
    if block and block.id~="minecraft:air" then
      block.mapColor.height = y
      return block.mapColor
    end
  end
  return {color={0,0,0}, height=false}
end
--scan the surface of this chunk
function MiniMap.scanChunk(cx, cz)
  --log(string.format("&3&BChunk <%d, %d>", cx, cz))
  local startDim = getPlayer().dimension
  local chunk = {}
  local x,z = cx*16, cz*16
  for bx=x, x+15 do
    chunk[bx-x] = {}
    local row = chunk[bx-x]
    for bz=z, z+15 do
      --log(string.format("&7Chunk <%d, %d>: %d, %d", cx, cz, bx, bz))
      local val = MiniMap.valueOf(bx, bz)
      if val then
        row[bz-z] = val
      else
        return --chunk became unloaded
      end
    end
  end
  local endDim = getPlayer().dimension
  if startDim~=endDim then return end --invalid data for dim
  MiniMap.chunks[endDim] = MiniMap.chunks[endDim] or {}
  MiniMap.chunks[endDim][cx] = MiniMap.chunks[endDim][cx] or {}
  MiniMap.chunks[endDim][cx][cz] = chunk
  --log(#chunk,"&c_", #(chunk[0]))
  MiniMap.updateImage()
end

function MiniMap.updateImage()
  local mutex = newMutex("theincgi.minimap.updateImg")
  if not mutex.tryLock() then return end --single instance
  local dim = getPlayer().dimension
  local img = MiniMap.tex
  local g = img.graphics
  local px, py, pz = getPlayerBlockPos()
  
  local minChunkX = math.floor((px - settings.mapRadius)/16)
  local minChunkZ = math.floor((pz - settings.mapRadius)/16)
  local maxChunkX = math.ceil((px + settings.mapRadius)/16)
  local maxChunkZ = math.ceil((pz + settings.mapRadius)/16)
  for chunkZ = minChunkZ, maxChunkZ do
    for chunkX = minChunkX, maxChunkX do
     -- log(string.format("&5&BUpdating Chunk &7<%d, %d>",chunkX, chunkZ))
      MiniMap.drawChunkToImg(chunkX, chunkZ, dim, px,py, pz)
      
    end
  end
  g.setColor(0xFFFF0000)
  local iw, ih = img.getSize()
  local rad = 3
  local a,b,c,d = iw/2-rad/2, ih/2-rad/2, rad, rad 
  g.fillOval(a,b,c,d)
  img.update()
  MiniMap.lastUpdate = os.millis()
  mutex.unlock()
end

function MiniMap.drawChunkToImg(chunkX, chunkZ, dim, px, py, pz)
  local img = MiniMap.tex
  local g = img.graphics
  local blockSpace = (settings.mapRadius*2+1) --num chunks fit
  local space = blockSpace / 16
  local cWid, cHei = math.floor(math.max(img.getWidth()/space,1)), math.floor(math.max(img.getHeight()/space,1))
  
  local tmp = MiniMap.tmpImg
  if not(MiniMap.chunks and
         MiniMap.chunks[dim] and
         MiniMap.chunks[dim][chunkX] and
         MiniMap.chunks[dim][chunkX][chunkZ]) then return
          end
  
  local data = MiniMap.chunks[dim][chunkX][chunkZ]
  --log(chunkX, chunkZ)
  --if(chunkX==0 and chunkZ==0)then log(data) end
  MiniMap.loadToBuffer(data, tmp, py)
  tmp.graphics.setColor(0x03FF0000)
  tmp.graphics.fillRect(0,0,15,15)
  local iWid, iHei = img.getSize()
  local drawX, drawY = iWid/2, iHei/2
  local dontShowGrid = 1
  drawX, drawY = drawX + chunkX*(cWid-dontShowGrid), drawY + chunkZ*(cHei-dontShowGrid)
  local playerOffsetX = px * cWid/16
  local playerOffsetZ = pz * cHei/16
  --log(playerOffsetX)
  drawX, drawY = drawX - playerOffsetX, drawY - playerOffsetZ
  g.drawImage(tmp, drawX, drawY, cWid, cHei)
end

--(sChunk, img)
--draws a chunk into a 16x16 img
function MiniMap.loadToBuffer(sChunk, img, playerY)
  img.graphics.clearRect(1,1,16,16)
  local topo = MiniMap.topographyMode or false
  local topoSens = MiniMap.topographySensitivity or 20
  if not sChunk then log("&cNONE") return end
  if #sChunk ~= 15 or #(sChunk[0])~=15 then 
    error("incorrect "..tostring(#sChunk).." "..tostring(#(sChunk[0])),2) end
  for y = 0, 15 do
    local row = sChunk[y]
    if row then
      for x = 0, 15 do
        local color
        if topo then
          h = row[x].height
          h = math.map(h, playerY-topoSens, playerY+topoSens, 0, 255)/255
          h = math.max(0, math.min(h, 1))
          h = h*h
          color = {h,h,h,1}
        else
          color = row[x]
        end
        --log(color)
        img.setPixel(y+1, x+1, color)
      end
    end
  end  
end

function MiniMap.loadMapFromFile()
end

function MiniMap.saveMapToFile()
  --map format:
  --waypoints section:
  --int #waypoints
  --int x, int y, int z, int 1RGB, varLenString name
  --Chunks section:
  --int #chunks
  --int x, int z HRGB,HRGB,HRGB.... 16x16
end

--gui with a dragable map
function MiniMap.openGui()
end

return MiniMap
