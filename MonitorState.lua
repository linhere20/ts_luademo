local MonitorState = class("MonitorState", State)

function MonitorState:initialize(name)
	State.initialize(self, name)
	self.hp = State.static.createState("HotPatcher")
end

function MonitorState:enteredState()
	return self.getTask
end

function MonitorState:reenteredState()
	return self.enteredState
end

function MonitorState:getTask()
	self.hp:start()

	local stateReturn = StateMgr:new("demoTask"):start({
		--stateName = gc.states.Page1State,
		--timeout = 1500, 
		userData = "user defined string",
		timeoutHandler = function(mgr)
			return "timeout"
		end
	})
	ilog("demoTask returned: " .. stateReturn)
	mSleep(2000)
	
	return self.getTask
end

return MonitorState