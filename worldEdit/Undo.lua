--TODO use random access file to store world data before each edit
--(would be alot to keep on ram otherwise)
theincgi.worldEdit.history = theincgi.worldEdit.history or {}
local history = theincgi.worldEdit.history
history.prev = {} --for undo
history.next = {} --for redo
function theincgi.worldEdit.history.undo()
  hist
end

function theincgi.worldEdit.history.redo()

end

function theincgi.worldEdit.history.copySelection()
  local entry = {}
  --pos1
  --pos2
  --data
end
