function postHttpMsg(url, params, timeout)
	local http = sz.i82.http
	local headers = json.encode({asokey = "haha"})
	
	params = params or {}

	local jsonparams = json.encode(params)
	local escapedparams = http.build_request(jsonparams)
	ilog("request: "..url.."\n params:"..jsonparams, false)
	local status_resp, headers_resp, body_resp = http.post(url, timeout or 30, headers, escapedparams)
	ilog("status:"..status_resp..", body:"..body_resp, false)
	
	local rsp = {
		status = status_resp,
		headers = json.decode(headers_resp or "{}"),
		body = body_resp,
		json = isJsonString(body_resp) and json.decode(body_resp) or {}
	}
	
	if status_resp ~= gc.httpCode.ok then
		toast("status:"..status_resp..", body:"..json.encode(rsp.json), 2)
		mSleep(2500)
	end
	
	if string.find(status_resp, "host or service not provided") and rt.repaireNetwork then
		--repairNetwork()
	end

	return rsp
end

function postJSON(url, params, timeout)
	local http = require("szocket.http")
	local body_resp = {}

	params = params or {}
	local post_data = json.encode(params);  

	ilog("postJSON request: "..url.."\n params:"..post_data, false)
	http.TIMEOUT = timeout or 30
	local res, status_resp, headers_resp = http.request{  
		url = url,  
		method = "POST",  
		headers = {
			["Content-Type"] = "application/json",  
			["Content-Length"] = #post_data,  
		},  
		source = ltn12.source.string(post_data),  
		sink = ltn12.sink.table(body_resp)  
	}  

	ilog("status:"..status_resp..", body:".. (body_resp[1] or "nil"), false)

	local rsp = {
		status = status_resp,
		headers = headers_resp,
		body = body_resp[1],
		json = isJsonString(body_resp[1]) and json.decode(body_resp[1]) or {}
	}

	if status_resp ~= gc.httpCode.ok then
		toast("status:"..status_resp..", body:"..json.encode(rsp.json), 2)
		mSleep(2500)
	end

	if string.find(status_resp, "host or service not provided") and rt.repaireNetwork then
		--repairNetwork()
	end

	return rsp
end

function downloadFile(url, path)
	local http = sz.i82.http
	ilog("download.."..url, false)
    local status, headers, body = http.get(url, 100)
    if status == gc.httpCode.ok then
        local file = io.open(path, "wb")
        if file then
            file:write(body)
            file:close()
            return status
        else
            return -1
        end
    else
        return status
    end
end

