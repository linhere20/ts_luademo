StateMgr = class("StateMgr")

function StateMgr:initialize(name)
	self.name = name
	self.states = {}
	self.current = nil
	self.thread_id = nil
	self.params = {}
end

function StateMgr:getName()
	return self.name
end

function StateMgr:addState(state)
	self.states[state:getName()] = state
end

function StateMgr:removeStateByName(stateName)
	if stateName == self.current:getName() then
		return
	end
	self.states[stateName] = nil
end

function StateMgr:findStateByName(name)
	return self.states[name]
end

function StateMgr:getCurrentState()
	return self.current
end

function StateMgr:isState(stateName)
	if not self.current then
		return false
	end

	return self.current:getName() == stateName
end

function StateMgr:isStateMgrCountOut(maxCount, forState)
	assert(type(maxCount) == "number", "maxCount must be a number")
	forState = forState or "_Null_State_"

	local state = "_StateMgrCount_"..forState
	local count = self.params[state]
	if type(count) == "number" then
		if count >= maxCount then
			return true
		end	
		self.params[state] = count + 1
	else
		self.params[state] = 1
	end

	return false
end

function StateMgr:setTimeout(timeout)
	thread.setTimeout(timeout, self.thread_id)
end

function StateMgr:clearTimeout()
	thread.clearTimeout(self.thread_id)
end

function StateMgr:stop()
	thread.stop(self.thread_id)
end

function StateMgr:start(params)
	params = params or {}
	local stateStatus = nil
	
	assert(type(gc.taskFlow) == "table", "gc.taskFlow must be a table")

	local flow = gc.taskFlow[self.name]
	assert(flow, "no configuration task flow: "..self.name)

	if type(gc.taskFlow.BeforeStartState) == "function" then
		gc.taskFlow.BeforeStartState(params)
	end

	if type(flow.BeforeStartState) == "function" then
		flow.BeforeStartState(params)
	end

	self.params = params
	self.params.flow = flow

	local stateName = params.stateName or flow.StartState

	self.thread_id = thread.create(function()
		if type(params.timeout) == "number" then
			thread.setTimeout(params.timeout)
		elseif type(flow.Timeout) == "number" then
			thread.setTimeout(flow.Timeout)
		end

		while(true) do
			if not self.current then
				stateStatus = self:nextState(stateName)
			else
				local nextStateName = nil
				if type(stateStatus) == "string" then
					local cur = flow[self.current:getName()]
					nextStateName = cur[stateStatus]
				elseif type(stateStatus) == "table" and type(stateStatus._nextState) == "string" then
					nextStateName = stateStatus._nextState
				end
			
				if not nextStateName then
					return stateStatus
				end

				stateStatus = self:nextState(nextStateName)
			end
		end
	end, {
		catchBack = function(exp)
			if exp.msg == "timeout" then
				if State.static.stateLog then
					ilog(self.name.." has been timeout!")
				end
				if params.timeoutHandler ~= nil and type(params.timeoutHandler) == "function" then
					stateStatus = params.timeoutHandler(self)
				end
			end
		end
	})

	State.static.threadWait(thread, self.thread_id)
	return stateStatus
end

function StateMgr:nextState(stateName, ...)
	local nextState = self.states[stateName]
	if not nextState then
		nextState = State.static.createState(stateName)
		nextState:setMgr(self)
		self.states[stateName] = nextState
		
		if self.current then
			nextState.cache = self.current.cache
		end
	end

	ilog("------------------------------------", false)

	if not self.current then
		self.current = nextState
		return self.current:start(self.current.enteredState)
	else
		if self.current == nextState then
			return self.current:start(self.current.reenteredState)
		else
			self.current:exitedState(...)
			self.current = nextState
			return self.current:start(self.current.enteredState)
		end
	end
end
