local InitState = class("InitState", State)

local machineConfigFile = gc.tsResPath.."machine.conf"

function InitState:initialize(name)
	State.initialize(self, name)
end

function InitState:enteredState()
	unlockDevice()
	setWifiEnable(true)
	--setAirplaneMode(false)

	clearLog()
	pressHomeButton()

	self:loadMachineConfig()
	return gc.ok
end

function InitState:loadMachineConfig()
	if not isFileExist(machineConfigFile) then
		ilog("终端尚未注册")
		while true do
			local machineId, modelType = dialogInput("注册终端", "终端序号（数字）#型号（5c,5s,6）", "提交")
			mSleep(1000)

			ilog("typed machineId: "..machineId..", modelType: "..modelType)
			machineId = tonumber(machineId)
			if machineId and table.contains({"5c", "5s", "6"}, modelType) then
				local params = {
					machineId = machineId,
					modelType = modelType,
					deviceId = getDeviceID(),
				}

				--local rsp = postHttpMsg(gc.url.registerMachine, params)
				--if rsp.status == gc.httpCode.ok then					
					if writeJsonAtPath(machineConfigFile, params) then
						ilog("写入machine.conf成功")
						mSleep(1000)
						break
					else
						ilog("写入machine.conf失败，请重试")
					end
				--end
			else
				dialog("输入错误，请重新输入", 30)
			end

			mSleep(1000)
		end
	end

	rt.machineConfig = readJsonAtPath(machineConfigFile)
	ilog("machine.conf "..json.encode(rt.machineConfig), false)

	ilog("loading ".. rt.machineConfig.modelType .. " configuration")
	reloadModule("iphone"..rt.machineConfig.modelType)
end

return InitState