local MainState = class("MainState", State)

function MainState:enteredState()
	return self.getTask
end

function MainState:reenteredState()
	return self.enteredState
end

function MainState:getTask()
	local taskType = "demoTask"
	
	local stateMgr = StateMgr:new(taskType)
	stateMgr:start({
		--stateName = gc.states.Page1State,
		--timeout = 1500000, 
		userData = "user defined string",
		timeoutHandler = function(mgr)
			ilog("stateMgr timeout:"..mgr.name)
		end
	})
	
	mSleep(1000)
	
	return self.getTask
end

return MainState