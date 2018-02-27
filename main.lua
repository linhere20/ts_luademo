require "TSLib"
sz = require "sz"
json = sz.json
thread = require "thread"
class = require "middleclass"
require "dateutil"
require "fileutil"
require "httputil"
require "funcutil"
require "osutil"
require "tableutil"
require "tsutil"
require "config"
require "dialogactions"
require "runtimedata"
require "ilog"
require "State"

State.static.stateHooks = {
	{
		before = function(state) 
			--做心跳
			local curTime = curTime()
			if isTimeAfter(curTime, rt.lastHeartbeatTime or curTime, gc.heartbeatDuration) then
				rt.lastHeartbeatTime = curTime
				--postHttpMsg(gc.url.heartbeat)
			end

			--处理全局弹窗
			local status = processDialog(state)
			if status ~= nil then
				return status
			end
		end,
		hookList = {".*"},
		whiteList = {gc.states.InitState}
	}
}

function main()
	local stateMgr = StateMgr:new("mainTask")
	stateMgr:start()
end

local status, err = tryCatch(main)
if not status then
	ilog("occur an exception causes the program crashed!")
	ilog("errInfo: "..err)
	--error(err) --throw an exception to the TouchSprite
	dialog(err, 30)
	lua_restart()
end

