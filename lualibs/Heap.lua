local Heap = {}

-- Heap in lua. Based on algorithms from Algorithms in C by Sedgewick

function Heap:up(k)
	local kdiv = math.floor(k/2)
	local val = self[k]
	while (kdiv > 0 and self.comp(self[kdiv], val)) do
		self[k] = self[kdiv]
		k = kdiv
		kdiv = math.floor(k/2)
	end
	self[k] = val
	return k
end

function Heap:down(k)
	local val = self[k]
	local j
	while(k <= math.floor(#self/2)) do
		j = k+k
		if(j < #self and self.comp(self[j], self[j + 1]))
			then j = j + 1 end
		if(self.comp(self[j], val)) then break end
		self[k], k = self[j], j
	end
	self[k] = val
	return k
end

function Heap:insert(ival)
	table.insert(self, ival)
	return Heap.up(self, #self)
end

function Heap:remove()
	local val = self[1]
	if self[2] then
		self[1] = table.remove(self)
		Heap.down(self, 1)
	else self[1] = nil end
	return val
end

function Heap:clear()
	for i=1, #self do self[i] = nil end
end

function Heap:new(cmp)
	object = {comp = cmp or function(a, b) return a < b end}
	setmetatable(object, self)
	self.__index = self
	return object
end

return Heap
