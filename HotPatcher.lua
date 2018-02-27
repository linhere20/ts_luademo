local HotPatcher = class("HotPatcher", State)

local versionFile = gc.tsResPath.."version.txt"
local versionTmpFile = gc.tsResPath.."version_tmp.txt"
local luatarFile = gc.tsResPath.."lua.tar.gz"
local debtarFile = gc.tsResPath.."deb.tar.gz"
local luaPath = gc.userPath .. "/lua/"
local tweakPath = gc.userPath .. "/tweak/"

function HotPatcher:enteredState()
	if not gc.enableHotPatch then
		return gc.ok
	end
	
	self.localVersion = nil
	self.serverVersion = nil

	return self.loadVersion, 500
end

function HotPatcher:loadVersion()
	if isFileExist(versionFile) then
		self.localVersion = readJsonAtPath(versionFile)
	end

	local status = downloadFile(gc.url.version, versionTmpFile)
	if status ~= gc.httpCode.ok then
		ilog("version.txt download failed. status:"..status)
		ilog("更新版本文件失败，重试...")
		mSleep(2000)
		return self.loadVersion
	else 
		self.serverVersion = readJsonAtPath(versionTmpFile)
		return self.patch, 0
	end
end

function HotPatcher:patch()
	local diff = self:diff()
	self:printLog(diff)

	if diff.updateScript then
		if not self:patchScript() then
			return self.enteredState
		end
	end

	if diff.updateDeb then
		if not self:patchDeb() then
			return self.enteredState
		end
	end

	mv(versionTmpFile, versionFile)

	if diff.updateDeb then
		ilog("插件更新后注销机器...")
		mSleep(2000)
		osCommand("killall -9 SpringBoard")
		mSleep(8000)
		lua_restart()
	end

	if diff.updateScript then
		lua_restart()
	end

	return gc.ok
end


function HotPatcher:diff()
	local diff = {
		updateScript = false,
		updateDeb = false
	}

	if not self.serverVersion then
		return diff
	end

	if not self.localVersion then
		diff.updateScript = true
		diff.updateDeb = true
		return diff
	end

	if self.serverVersion.script ~= self.localVersion.script then
		diff.updateScript = true
	end

	if self.serverVersion.plugin ~= self.localVersion.plugin then
		diff.updateDeb = true
	end

	return diff
end

function HotPatcher:patchScript()
	ilog("patching lua.tar.gz...")
	mSleep(1000)
	local status = downloadFile(gc.url.luatar, luatarFile)
	if status ~= gc.httpCode.ok then
		ilog("lua.tar.gz download failed. status:"..status)
		return false
	else
		local flag = tarx(luatarFile, luaPath)
		if flag then
			ilog("tar -zxvf lua.tar.gz")
		else
			ilog("tar lua.tar.gz failed")
			return false
		end
		ilog("patched lua.tar.gz")
		mSleep(1000)
		return true
	end
end

function HotPatcher:patchDeb()
	ilog("patching deb.tar.gz...")
	mSleep(1000)
	osCommand("rm -rf "..tweakPath.."*")
	local status = downloadFile(gc.url.debtar, debtarFile)
	if status ~= gc.httpCode.ok then
		ilog("deb.tar.gz download failed. status:"..status)
		return false
	else
		local flag = tarx(debtarFile, tweakPath)
		if flag then
			ilog("tar -zxvf deb.tar.gz")
		else
			ilog("tar -zxvf deb.tar.gz failed")
			return false
		end
		local res = io.popen("dpkg -i " .. tweakPath .."*.deb 2>&1 | grep \"error processing\"")
		if res then
			local s = res:read("*all")
			if s ~= "" then
				ilog("有插件安装错误\n" .. s)
				return false
			end
			return true
		else
			ilog("插件安装错误")
			return false
		end
	end
end

function HotPatcher:printLog(diff)
	if not diff.updateScript and not diff.updateDeb then
		ilog("脚本和插件已为最新")
		return
	end

	local info = "待更新资源["
	if diff.updateScript then
		info = info.." lua.tar.gz "
	end
	if diff.updateDeb then
		info = info.." deb.tar.gz "
	end
	info = info.."]"
	ilog(info)
	mSleep(500)
end


return HotPatcher
