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

	local taskType = "demoTask"
	
	local stateMgr = StateMgr:new(taskType)
	local stateReturn = stateMgr:start({
		--stateName = gc.states.Page1State,
		--timeout = 1500, 
		userData = "user defined string",
		timeoutHandler = function(mgr)
			ilog("stateMgr timeout:"..mgr.name)
			return "timeout"
		end
	})
	
	mSleep(2000)
	
	return self.getTask
end

return MonitorState