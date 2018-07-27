local Page2State = class("Page2State", State)

function Page2State:initialize(name)
	State.initialize(self, name)
end

function Page2State:enteredState()
	ilog("cache.count: " .. self.cache.count)
	return self.wait3
end

function Page2State:reenteredState()
	return self.enteredState
end

function Page2State:wait3()
	return self.wait4
end

function Page2State:wait4()
	return gc.ok
end

return Page2State