local Vector = run("Vector.lua")

theincgi.worldEdit.dirs = {
  north = Vector:new{ 0, 0,-1},
  east  = Vector:new{ 1, 0, 0},
  west  = Vector:new{-1, 0, 0},
  south = Vector:new{ 0, 0, 1},
  up    = Vector:new{ 0, 1, 0},
  down  = Vector:new{ 0,-1, 0},
}                                
theincgi.worldEdit.dirs["x+"] = theincgi.worldEdit.dirs.east
theincgi.worldEdit.dirs["x-"] = theincgi.worldEdit.dirs.west
theincgi.worldEdit.dirs["y+"] = theincgi.worldEdit.dirs.up
theincgi.worldEdit.dirs["y-"] = theincgi.worldEdit.dirs.down
theincgi.worldEdit.dirs["z+"] = theincgi.worldEdit.dirs.south
theincgi.worldEdit.dirs["z-"] = theincgi.worldEdit.dirs.north

function theincgi.worldEdit.updateSelection()
  local we = theincgi.worldEdit
  local clear = "block:minecraft:blocks/glass"
  local red =  "block:minecraft:blocks/glass_red"
  local blue = "block:minecraft:blocks/glass_light_blue"
  we.h3d = we.h3d or {}
  we.h3d.up    = we.h3d.up or hud3D.newPane("xz")
  we.h3d.down  = we.h3d.down or hud3D.newPane("xz")
  we.h3d.north = we.h3d.north or hud3D.newPane("xy")
  we.h3d.east  = we.h3d.east or hud3D.newPane("yz")
  we.h3d.south = we.h3d.south or hud3D.newPane("xy")
  we.h3d.west  = we.h3d.west or hud3D.newPane("yz")
  we.h3d.block1 = we.h3d.block1 or hud3D.newBlock()
  we.h3d.block2 = we.h3d.block2 or hud3D.newBlock()
  we.h3d.block1.changeTexture(red)
  we.h3d.block2.changeTexture(blue)
  we.h3d.block1.xray()
  we.h3d.block2.xray()
  --log(we.h3d.block1.getPos())
  if we.pos1 and we.pos2 then
    local q1, q2 = we.pos1:min(we.pos2), we.pos1:max(we.pos2)
    q2 = q2+1
    local dim = q2-q1
    
    we.h3d.up.setSize(dim[1], dim[3])
    we.h3d.up.setPos(q1[1],q2[2]+.005,q1[3])
    we.h3d.up.changeTexture(clear)
    
    we.h3d.down.setSize(dim[1],dim[3])
    we.h3d.down.setPos( q1[1],q1[2]-.005,q1[3] )
    we.h3d.down.changeTexture(clear)
    
    we.h3d.north.setSize(dim[1], dim[2])  --north neg z
    we.h3d.north.setPos(q1[1],q1[2],q2[3]+.005)
    we.h3d.north.changeTexture(clear)
    
    we.h3d.south.setSize(dim[1], dim[2])
    we.h3d.south.setPos(q1[1],q1[2],q1[3]-.005)
    we.h3d.south.changeTexture(clear)
    
    we.h3d.west.setSize(dim[3], dim[2])
    we.h3d.west.setPos(q1[1]-.005,q1[2],q1[3])
    we.h3d.west.changeTexture(clear)
    
    we.h3d.east.setSize(dim[3], dim[2])
    we.h3d.east.setPos(q2[1]+.005,q1[2],q1[3])
    we.h3d.east.changeTexture(clear)
    
    we.h3d.block1.setPos( table.unpack(we.pos1) )
    we.h3d.block2.setPos( table.unpack(we.pos2) )
    
    we.h3d.block1.enableDraw()
    we.h3d.block2.enableDraw()
    we.h3d.up.enableDraw()
    we.h3d.down.enableDraw()
    we.h3d.north.enableDraw()
    we.h3d.east.enableDraw()
    we.h3d.south.enableDraw()
    we.h3d.west.enableDraw()
  elseif we.pos1 or we.pos2 then
    local m = we.pos1 or we.pos2
    --log(m)
    if(we.pos1)then
      we.h3d.block1.setPos( table.unpack(m) )
      we.h3d.block1.enableDraw()
      we.h3d.block2.disableDraw()
    else
      we.h3d.block2.setPos( table.unpack(m) )
      we.h3d.block1.disableDraw()
      we.h3d.block2.enableDraw()
    end
    
    
    
    we.h3d.up.disableDraw()
    we.h3d.down.disableDraw()
    we.h3d.north.disableDraw()
    we.h3d.east.disableDraw()
    we.h3d.south.disableDraw()
    we.h3d.west.disableDraw()
  else
  
    we.h3d.up.disableDraw()
    we.h3d.down.disableDraw()
    we.h3d.north.disableDraw()
    we.h3d.east.disableDraw()
    we.h3d.south.disableDraw()
    we.h3d.west.disableDraw()
    
    we.h3d.block1.disableDraw()
    we.h3d.block2.disableDraw()
  end
end
