require "State"
require "StateMgr"

gc = gc or {}

gc.ok = "ok"
gc.fail = "fail"
gc.this = "this"
gc.loop = "loop"
gc.err = "err"
gc.continue = "continue"
gc.timeout = "timeout"

gc.states = {
	InitState = "InitState",
	MonitorState = "MonitorState",
	Page1State = "Page1State",
	Page2State = "Page2State"
}

gc.taskFlow = {

	BeforeStartState = function(params)
		ilog("execute this function before each task.")
	end,
	
	mainTask = {
		--默认初始状态
		StartState = gc.states.InitState,

		InitState = {
			ok = gc.states.MonitorState,
		}
	},

	demoTask = {
		--超时，毫秒
		Timeout = 1000 * 60 * 10,

		BeforeStartState = function(params)
			ilog("execute this function before specific task. UserData:"..params.userData)
		end,
		
		StartState = gc.states.Page1State,

		Page1State = {
			ok = gc.states.Page2State,
		},
		Page2State = {
			ok = nil,
		},
	}
}

State.static.addHook({
	id = "0",
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
})
