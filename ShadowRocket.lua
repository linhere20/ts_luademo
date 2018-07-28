local ShadowRocket = class("ShadowRocket", State)

local bid = "com.liguangming.Shadowrocket"
local pingHost = "https://www.google.com"
local shadowRocketDataBase = appDataPath(bid).."/Documents/Shadowrocket.sqlite*"
local ssResultFile = "/private/var/mobile/Library/Preferences/shadowrocket_result.json"
local ssConfigFile = gc.tsResPath.."ss.conf"

function ShadowRocket:enteredState()
	if not gc.enableSS then
		return gc.ok
	end
	
	self.connectFailedCount = 1
	return self.fetchSSConfig, 0
end

function ShadowRocket:fetchSSConfig()
	local rsp = postJSON(gc.url.getVPS, {})
	if rsp.status == gc.httpCode.ok and rsp.json.code == 0 then
		self.ssConfig = rsp.json
		
		if not isFileExist(ssConfigFile) then
			return self.clear, 0
		end
		
		local localConfig = readJsonAtPath(ssConfigFile)
		if localConfig.sType ~= self.ssConfig.sType or localConfig.sHost ~= self.ssConfig.sHost or localConfig.sPassword ~= self.ssConfig.sPassword or localConfig.sMethod ~= self.ssConfig.sMethod or localConfig.sPort ~= self.ssConfig.sPort  then
			return self.clear, 0
		end
		
		setVPNEnable(true)
		return self.waitConnection
	end
	
	return self.fetchSSConfig, 3000
end

function ShadowRocket:clear()
	setVPNEnable(false)
	os.execute("rm "..ssResultFile)
	os.execute("killall -9 Shadowrocket")
	os.execute("rm "..shadowRocketDataBase)
	return self.switch, 0
end

function ShadowRocket:switch()
	local currentServer = self.ssConfig
	ilog(string.format("switch %s: %s", currentServer.sType, currentServer.sHost))
	
	local config = nil
	if currentServer.sType == "ss" then
		config = currentServer.sMethod..":"..currentServer.sPassword.."@"..currentServer.sHost..":"..currentServer.sPort
	elseif currentServer.sType == "socks" then
		config = currentServer.sUser..":"..currentServer.sPassword.."@"..currentServer.sHost..":"..currentServer.sPort
	end
	
	local schema = currentServer.sType.."://"..config:base64_encode()
	openURL(schema)
	return self.waitCreated, 1000
end

function ShadowRocket:waitCreated()
	if self:isStateUnitTimeout(1000 * 10) then 
		return self.clear
	end
	
	if not isFileExist(ssResultFile) then
		return self.waitCreated
	end
	
	local resStr = readFileString(ssResultFile)
	ilog(resStr)
	mSleep(1000)
	
	local result = json.decode(resStr)
	if result.status == "success" then
		setVPNEnable(true)
		return self.waitConnection
	else
		return self.clear
	end
end

function ShadowRocket:waitConnection()
	if self:isStateUnitTimeout(1000 * 10) then
		return self.clear
	end
	
	local vpnStatus = getVPNStatus()
	toast("ss status:"..vpnStatus.status)
	if vpnStatus.status == "已连接" then
		return self.waitNetworkAvailable
	end

	return self.waitConnection
end

function ShadowRocket:waitNetworkAvailable()
	if self:isStateUnitTimeout(1000 * 20) then
		if self.connectFailedCount > 3 then
			setVPNEnable(false)
			ilog("无网络连接")
			mSleep(2000)
			return self.fetchSSConfig
		end
		self.connectFailedCount = self.connectFailedCount + 1
		
		return self.clear
	end
	
	local http = sz.i82.http
	
	local status, headers, body = http.get(pingHost)
	if status == gc.httpCode.ok then
		ilog("network available")
		writeJsonAtPath(ssConfigFile, self.ssConfig)
		return gc.ok
	end
	ilog(pingHost..", status: "..status)
	mSleep(2000)
	return self.waitNetworkAvailable
end

return ShadowRocket
