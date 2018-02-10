function getFileList(path)
    local a = io.popen("ls "..path)
    local f = {}
    for l in a:lines() do
        table.insert(f, l)
    end
    return f
end

function getFileSize(file)
	local f = io.open(file, "r")
	if not f then
		return -1 
	end
	
	local size = f:seek("end")
	f:close()
	return size
end

function writeJsonAtPath(filePath, content)
	writeFileString(filePath, json.encode(content))
end

function readJsonAtPath(filePath)
	return json.decode(readFileString(filePath))
end
