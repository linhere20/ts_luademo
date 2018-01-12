local Page2State = class("Page2State", State)

function Page2State:enteredState()
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