local curDate = os.date("%Y-%m-%d")
local logName = "aso_"..curDate
local writeFile = true
local writeToast = true
local holdLogDay = 10
initLog(logName, 0)

function ilog(content, wToast)
	if not content then
		return
	end
	
	local nDate = os.date("%Y-%m-%d")
	if nDate ~= curDate then
		closeLog(logName)
		curDate = nDate
		logName = "aso_"..curDate
		initLog(logName, 0)
	end
	
	local outWithDate = "[DATE] "..content
	
	if writeToast and wToast ~= false then
		toast(content, 1)
	end
	
	nLog(outWithDate)
	
	if writeFile then
		wLog(logName, outWithDate)
	end
end

function itoast(content)
	if not content then
		return
	end
	
	local outWithDate = "[DATE] "..content
	toast(content, 1)
	nLog(outWithDate)
end

function clearLog()
	local logList = getFileList(gc.tsLogPath.."aso_*")

	local curTime = os.date("%Y%m%d%H%M%S")
	local holdLogList = {}
	for i = 1, holdLogDay do
		local newTime = getNewDate(curTime, -i, "DAY")  
		local logDay = string.format(gc.tsLogPath..'aso_%d-%02d-%02d.log', newTime.year, newTime.month, newTime.day)
		table.insert(holdLogList, logDay)
	end
	table.insert(holdLogList, gc.tsLogPath..logName..".log")
	
	for i = 1, #logList do
		local ele = logList[i]
		if not table.contains(holdLogList, ele) then
			rm(ele)
		end
	end
end
