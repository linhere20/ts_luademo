function isFindPos(x, y)
	if x == -1 and y == -1 then
		return false
	end
	return true
end

function tapFuzzyPos(x, y, delay)
	if isFindPos(x, y) then
		tap(x, y)
		mSleep(delay or 1000)
		return true
	end
	return false
end

function pressReturnOrEnter()
	keyDown("ReturnOrEnter")
	keyUp("ReturnOrEnter")
end

function pressHomeButton()
	pressHomeKey(0)
	pressHomeKey(1)
end

function doubleTap(x, y)
	tap(x, y)
	mSleep(30)
	tap(x, y)
end

function clearInputText()
	for var = 1, 64 do
		inputText("\b")
	end
end

function typeInputText(text, x, y)
	if x ~= nil and y ~= nil then
		tap(x, y)
		mSleep(1000)
	end
	clearInputText() 
	inputText(text)
end

function typeInputStr(text, x, y)
	if x ~= nil and y ~= nil then
		tap(x, y)
		mSleep(1000)
	end
	clearInputText() 
	inputStr(text)
end

function typeInputPaste(text, x, y, enter)
	if x ~= nil and y ~= nil then
		tap(x, y)
		mSleep(1000)
	end
	clearInputText() 
	inputPaste(text, enter)
end

function inputPaste(str, enter)
	writePasteboard(str)
	clearInputText()
	keyDown("RightGUI")
	keyDown("v")
	keyUp("v")
	keyUp("RightGUI")
	if enter then
		pressReturnOrEnter()
	end
	mSleep(500)
end

function typeInputPassword(test, x, y)
	if x ~= nil and y ~= nil then
		tap(x, y)
		mSleep(1000)
	end
	clearInputText()
	local keyMap = {
		["!"] = "1",
		["@"] = "2",
		["#"] = "3",
		["$"] = "4",
		["%"] = "5",
		["^"] = "6",
		["&"] = "7",
		["*"] = "8",
		["("] = "9",
		[")"] = "0",
		["_"] = "Hyphen",
		["+"] = "EqualSign",
		["{"] = "OpenBracket",
		["}"] = "CloseBracket",
		["|"] = "Backslash",
--		[")"] = "NonUSPound",
		[":"] = "Semicolon",
		["\""] = "Quote",
		["~"] = "GraveAccentAndTilde",
		["<"] = "Comma",
		[">"] = "Period",
		["?"] = "Slash",
	}
	local symbolKeyMap = {
		["-"] = "Hyphen",
		["="] = "EqualSign",
		["["] = "OpenBracket",
		["]"] = "CloseBracket",
		["\\"] = "Backslash",
--		[")"] = "NonUSPound",
		[";"] = "Semicolon",
		["'"] = "Quote",
		["`"] = "GraveAccentAndTilde",
		[","] = "Comma",
		["."] = "Period",
		["/"] = "Slash",
	}
	for key in string.gmatch(test, ".") do 
		local CapsLockFlag = false
		local LeftShiftFlag = false
		if key:byte()>=65 and key:byte()<=90 then
			CapsLockFlag = true
			key = string.char(key:byte()+32)
		elseif keyMap[key] then
			LeftShiftFlag = true
			key = keyMap[key]
		elseif symbolKeyMap[key] then
			key = symbolKeyMap[key]
		end
		if CapsLockFlag then keyDown("CapsLock") end
		if LeftShiftFlag then keyDown("LeftShift") end
		keyDown(key)
		keyUp(key)
		if LeftShiftFlag then keyDown("LeftShift") end
		if CapsLockFlag then keyDown("CapsLock") end
		mSleep(50)
	end
end
