function getNewDate(srcDateTime, interval, dateUnit)  
    local Y = string.sub(srcDateTime,1,4)  
    local M = string.sub(srcDateTime,5,6)  
    local D = string.sub(srcDateTime,7,8)  
    local H = string.sub(srcDateTime,9,10)  
    local MM = string.sub(srcDateTime,11,12)  
    local SS = string.sub(srcDateTime,13,14)  
   
    local dt1 = os.time{year=Y, month=M, day=D, hour=H,min=MM,sec=SS}  
    local ofset = 0
  
    if dateUnit =='DAY' then  
        ofset = 60 *60 * 24 * interval  
    elseif dateUnit == 'HOUR' then  
        ofset = 60 *60 * interval      
	elseif dateUnit == 'MINUTE' then  
        ofset = 60 * interval  
    elseif dateUnit == 'SECOND' then  
        ofset = interval  
    end  
   
    local newTime = os.date("*t", dt1 + tonumber(ofset))  
    return newTime  
end  

function curTime()
	return os.time()
end

function curDate()
	return os.date("%Y-%m-%d %H:%M:%S")
end

function isTimeAfter(newTime, oldTime, threshold)
	return newTime - oldTime > threshold
end