function isTestMode()
	return gc.mode == "test"
end

function doDelay(delay, callback, _self, ...)
	if type(callback) ~= "function" then
		return
	end

	mSleep(delay or 0)
	
	if _self then
		return callback(_self, ...)
	else
		return callback(...)
	end
end

function reloadModule(moduleName)
	if not moduleName then
		return
	end
	
	--if package.loaded[moduleName] then
		package.loaded[moduleName] = nil
	--end
	return require(moduleName)
end

function tryCatch(func, ...)
	local status, err = pcall(func, ...)
	return status, err
end

function tryCatchAndDoAgain(times, func, ...)
	local status, err
	while(times > 0) do
		status, err = tryCatch(func, ...)
		if status then
			return
		end
		times = times - 1
		mSleep(3000)
	end
	error(err)
end

function isJsonString(str)
	local status, err = tryCatch(json.decode, str)
	return status
end

function isIphone5x()
	return table.contains({"5c", "5s"}, _g.modelType)
end
	
function isIphone6()
	return _g.modelType == "6" 
end

function isRegisterTask()
	if  rt.taskData and rt.taskData.taskType == "registertask" then
		return true
	end
	
	return false
end

function isDownloadTask()
	if  rt.taskData and rt.taskData.taskType == "downloadtask" then
		return true
	end
	
	return false
end

