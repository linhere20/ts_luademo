local thread = require('thread')
local thread_id1 = thread.create(function()
	
	nLog("1234")	
	
	thread_id2 = thread.createSubThread(function()
		
			thread_id3 = thread.createSubThread(function()
				thread.setTimeout(3000)
				for i=1,10 do
					nLog("协程3：".. i)
					mSleep(1000)
				end
			end,{
				catchBack = function(exp)
					if exp.msg == "timeout" then
						nLog("timeout3")
					else
						error("xxx")
					end
					
				end
			})
			--thread.wait(thread_id3)
		
		
		for i=1,10 do
			nLog("协程2：".. i)
			mSleep(1000)
		end
		
		
		
		
	end,{
		catchBack = function(exp)
			if exp.msg == "timeout" then
				nLog("timeout2")
			else
				error("xxx")
			end
			
		end
	})
	thread.wait(thread_id2)
	
	
    for i=1,10 do
        nLog("协程1：".. i)
        mSleep(1000)
    end
	
end,{
		catchBack = function(exp)
			if exp.msg == "timeout" then
				nLog("timeout1")
				thread.stop("1311")
			else
				error("xxx")
			end
			
		end
	})
thread.wait(thread_id1)


 for i=1,10 do
        nLog("main：".. i)
        mSleep(1000)
    end

--mSleep(5000)
--thread.stop(thread_id1)--关闭协程1
--thread.waitAllThreadExit()--等待所有协程结束，只能用于主线程