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

function writeJsonAtPath(filePath, content, mode)
	mode = mode or "w"
	return writeFileString(filePath, json.encode(content), mode)
end

function readJsonAtPath(filePath)
	return json.decode(readFileString(filePath))
end
