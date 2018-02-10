function table.contains(tab, ele)
	for _, value in pairs(tab) do
		if value == ele then
			return true
		end
	end
	return false
end

function table.isSame(tab1, tab2)
	if not tab1 or not tab2 then
		return false
	end
	
	if #tab1 ~= #tab2 then
		return false
	end
	
	for i = 1, #tab1 do
		if tab1[i] ~= tab2[i] then
			return false
		end
	end
	return true
end

function table.extend(source, target)
	source = source or {}
	target = target or {}

	if type(source) ~= "table" then
		source = {}
	end

	for k, v in pairs(target) do
		local src = source[k]
		local copy = v

		if src ~= copy then
			if copy and type(copy) == "table" then
				local clone = src
				if type(clone) ~= "table" then
					clone = {}
				end

				source[k] = extend(clone, copy)
			else
				source[k] = copy
			end	
		end
	end
	return source
end
