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

