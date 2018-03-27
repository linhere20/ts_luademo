local SwitchVPNState = class("SwitchVPNState", State)

local userPath = userPath()
local resPath = userPath .. "/res/"
local vpnConfigFile = resPath.."vpn.conf"
local vpnConfigFileForTweak = "/private/var/mobile/Library/Preferences/vpn_tmp.json"
local vpnNotifyFileForTouchSprite = "/private/var/mobile/Library/Preferences/vpn_notify_touchsprite.json"
local vpnDisconnectedFileForTouchSprite = "/private/var/mobile/Library/Preferences/vpn_disconnected.json"

function SwitchVPNState:initialize(name)
	State.initialize(self, name)
end

function SwitchVPNState:reenteredState()
	return self.enteredState
end

function SwitchVPNState:enteredState()
	self.connectFailCount = 1

	if not gc.enableVPN then
		return gc.ok
	end

	return self.loadVersion, 500
end

function SwitchVPNState:loadVersion()
	setVPNEnable(false)
	local serverVPN = nil
	local localVPN = nil
	local changed = false
	
	if isFileExist(vpnConfigFile) then
		localVPN = json.decode(readFileString(vpnConfigFile))
	end
	
	local rsp = postHttpMsg(gc.url.getVPN)
	if rsp.status ~= gc.httpCode.ok then
		ilog("获取VPN失败，重试...")
		mSleep(2000)
		return self.loadVersion
	end
	
	local serverVPN = rsp.json
	
	if not localVPN then
		self.changed = true
	elseif serverVPN.ip ~= localVPN.ip or serverVPN.account ~= localVPN.account then
		self.changed = true
	end
	
	--[[
	if not changed then
		ilog("vpn配置无需更新")
		return self.waitVPNDisconnected, 0
	end
	]]

	tryWriteFile(vpnConfigFile, rsp.body)
	tryWriteFile(vpnConfigFileForTweak, rsp.body)
	rm(vpnNotifyFileForTouchSprite)
	openURL("prefs:root=General&path=VPN")
	return self.waitVPNCreated
end

function SwitchVPNState:waitVPNCreated()
	if self:isStateUnitTimeout(1000 * 10) then
		return self.loadVersion
	end
	
	if not isFileExist(vpnNotifyFileForTouchSprite) then
		return self.waitVPNCreated
	end
	
	local vpnRes = json.decode(readFileString(vpnNotifyFileForTouchSprite))
	if vpnRes.status == "success" then
		return self.waitVPNDisconnected, 0
	else
		return self.loadVersion
	end
end

function SwitchVPNState:waitVPNDisconnected()
	if self:isStateUnitTimeout(1000 * 30) then
		rm(vpnConfigFile)
		return self.loadVersion
	end
	
	setVPNEnable(false)
	local flag = getVPNStatus()
	if flag.status == "未连接" then
		return self.connectVPN
	else
		return self.waitVPNDisconnected
	end
end

function SwitchVPNState:connectVPN()
	ilog("try connect to vpn...")
	rm(vpnDisconnectedFileForTouchSprite)
	setVPNEnable(true)
	return self.waitVPNConnectResult
end

function SwitchVPNState:waitVPNConnectResult()
	if self:isStateUnitTimeout(1000 * 30) then
		rm(vpnConfigFile)
		return self.loadVersion
	end
	
	if isFileExist(vpnDisconnectedFileForTouchSprite) then
		if self.connectFailCount > 2 then
			rm(vpnConfigFile)
			return gc.this
		else
			return self.waitVPNDisconnected, 0
		end

		self.connectFailCount = self.connectFailCount + 1
	end

	local vpnStatus = getVPNStatus()
	if vpnStatus.status == "已连接" then
		return gc.ok
	else
		return self.waitVPNConnectResult
	end
end

--[[
function SwitchVPNState:fetchIp(thread, params)
	thread.setTimeout(1000 * 30)
	params.timeoutHandler = self.disableconnectVPN
	
	local ip = getNetIP()

	if not ip then
		ilog("获取不到ip地址")
		mSleep(1000)
		return self.disableconnectVPN
	end
	
	ilog(ip)
	rt.ip = ip
	
	writeFileString(userPath().."/res/ip_statistics.txt", currentTimeString().." "..ip, "a")
	
	if isFileExist(gc.ipBanFile) then
		local file = io.open(gc.ipBanFile)
		for line in file:lines() do
			if line:trim() == ip then
				ilog("该ip已被禁用，重新获取ip")
				mSleep(1000)
				return self.disableconnectVPN
			end
		end
	end
	
	mSleep(1000)
	return gc.ok
	
end

function SwitchVPNState:switchAirplaneMode()
	local http = sz.i82.http
	while true do
--		if processDialog() then
--			return gc.err
--		end

		setAirplaneMode(true)
		mSleep(3000)
		setAirplaneMode(false)

		local baidu = "https://www.baidu.com"
		for i = 1, 5 do
			local status, headers, body = http.get(baidu)
			if status == gc.httpCode.ok then
				ilog("network available")
				return gc.ok
			end
			ilog(baidu..", status: "..status)
			mSleep(3000)
		end
	end
end
]]

return SwitchVPNState