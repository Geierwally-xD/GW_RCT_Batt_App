--[[
	---------------------------------------------------------
    Battery Percentage application converts capacity used (mAh)
	to percentage-range 100-0% from full to empty battery. 
	
	Possibility to define a 3-position switch to select between
	3 different size packs. If no switch is defined only battery
	1 is used.
	
	Voice announcement of battery percentage with switch
	
	Also app makes a LUA controls (switch) that can be used as
	any other switch, voices, alarms etc.
	
	Telemetry-screne on main-screen with Battery-
	symbol. Symbol is realtime - Charge gets lower on use.
	
	Localisation-file has to be as /Apps/GW_BATT/lang/xx/locale.jsn
	
	French translation courtesy from Daniel Memim
	Italian translation courtesy from Fabrizio Zaini
	Czech and Slovak translations by Michal Hutnik
	---------------------------------------------------------
	Based on Battery Percentage by Tero Salminen RC-Thoughts.com
	---------------------------------------------------------
	Released by Geierwally 11 2017
	---------------------------------------------------------
	1 add voltage limit check with own alarm control
	2 draw battery symbol and text red on capacity- 
	  or voltage alarm (grayed on 14 and 16 transmitters)
	3 increased stepwith for differnt battery types (capa intBoxes)  
	4 one app for all transmitters 14, 16, 24
	5 bugfix storage lack on 14 and 16 transmitters
	6 3 capacity alerts and 1 voltage alert configurable
	---------------------------------------------------------
--]]

--------------------------------------------------------------------------------
-- Locals for the application
local sens, sensid, senspa, vSens, vSensid, vSenspa, nCell, vLimit 
local telVal, telVoltageVal, trans, capAlarm, voltageAlarm
local res = 0, lbl1, lbl2, lbl3
local alarm1 = {30,30,30}
local alarm2 = {0,0,0} 
local alarm3 = {0,0,0} 
local Sw1, Sw2, Sw3, SimVolt, SimCap
local anGo, anSw
local vF1Played, vF2Played, vF3Played
local lbl = {}
local capa = {0,0,0}
local sensorLalist = {"..."}
local sensorIdlist = {"..."}
local sensorPalist = {"..."}
local tSet0 = 0
local tSet1 = 0
local anTime = 0,0,0,0
local akku = 1 
local capIncrease = 100
local battVersion = nil
local tStr0 = 0
local tStr1 = 0
local prevVoltage = 0
local colorScreen = false


--------------------------------------------------------------------------------
-- Read translations
--------------------------------------------------------------------
local function setLanguage()
  -- Set language
  local lng=system.getLocale();
  local file = io.readall("Apps/GW_Batt/lang/"..lng.."/locale.jsn")
  local obj = json.decode(file)  
  if(obj) then
    trans = obj
  end
end

--------------------------------------------------------------------------------
-- Read available sensors for user to select
local sensors = system.getSensors()
for i,sensor in ipairs(sensors) do
	if (sensor.label ~= "") then
		table.insert(sensorLalist, string.format("%s", sensor.label))
		table.insert(sensorIdlist, string.format("%s", sensor.id))
		table.insert(sensorPalist, string.format("%s", sensor.param))
	end
end
--------------------------------------------------------------------------------
-- Draw the telemetry windows
local function printTelem() 
	local txtr,txtg,txtb
	local bgr,bgg,bgb = lcd.getBgColor()
	if (bgr+bgg+bgb)/3 >128 then
		txtr,txtg,txtb = 0,0,0
		else
		txtr,txtg,txtb = 255,255,255
	end	
	if (telVal == "-") then
		lcd.drawRectangle(5,9,26,55)
		lcd.drawFilledRectangle(12,6,12,4)
		lcd.drawText(145 - lcd.getTextWidth(FONT_MAXI,"-%"),10,"-%",FONT_MAXI)
		lcd.drawText(145 - lcd.getTextWidth(FONT_MINI,"Geierwally"),54,"Geierwally",FONT_MINI)
	else
		lcd.drawRectangle(5,9,26,55) 
		lcd.drawFilledRectangle(12,6,12,4)
		chgY = (64-(telVal*0.54))
		chgH = ((telVal*0.54))
		if((capAlarm == true)or(voltageAlarm == true)) then
			if(colorScreen == true)then
				lcd.setColor(200,0,0) 
				lcd.drawFilledRectangle(6,chgY,24,chgH)
			else
				lcd.drawFilledRectangle(6,chgY,24,chgH,125)
			end	
			if(system.getTime() % 2 == 0) then
				if(capAlarm == false) then
					if(colorScreen == true)then
						lcd.setColor(txtr,txtg,txtb)
					end	
				end
				lcd.drawText(145 - lcd.getTextWidth(FONT_MAXI,string.format("%s%%",telVal)),10,string.format("%s%%",telVal),FONT_MAXI)
			else
				if (voltageAlarm == true) then
					lcd.drawText(145 - lcd.getTextWidth(FONT_MAXI,string.format("%s V",telVoltageVal)),10,string.format("%s V",telVoltageVal),FONT_MAXI)
				end
			end
			if(colorScreen == true)then
				lcd.setColor(txtr,txtg,txtb)
			end	
		else
			if(colorScreen == true)then
				lcd.setColor(0,196,0)
			end	
			lcd.drawFilledRectangle(6,chgY,24,chgH)
			if(colorScreen == true)then
				lcd.setColor(txtr,txtg,txtb)
			end		
			lcd.drawText(145 - lcd.getTextWidth(FONT_MAXI,string.format("%s%%",telVal)),10,string.format("%s%%",telVal),FONT_MAXI) 	
		end	
		------only for simulation without connected telemetry
		lcd.drawText(145 - lcd.getTextWidth(FONT_MINI,"Geierwally"),53,"Geierwally",FONT_MINI)
	end
end
--------------------------------------------------------------------------------
-- Store settings when changed by user
local function sensorChanged(value)
	sens=value
	system.pSave("sens",value)
	sensid = string.format("%s", sensorIdlist[sens])
	senspa = string.format("%s", sensorPalist[sens])
	if (sensid == "...") then
		sensid = 0
		senspa = 0
	end
	system.pSave("sensid",sensid)
	system.pSave("senspa",senspa)
end
local function voltageSensorChanged(value)
	vSens=value
	system.pSave("vSens",value)
	vSensid = string.format("%s", sensorIdlist[vSens])
	vSenspa = string.format("%s", sensorPalist[vSens])
	if (vSensid == "...") then
		vSensid = 0
		vSenspa = 0
	end
	system.pSave("vSensid",vSensid)
	system.pSave("vSenspa",vSenspa)
end
local function voltageLimitChanged(value)
	vLimit = value
	system.pSave("vLimit",value)
end
local function numberOfCellsChanged(value)
	nCell = value
	system.pSave("nCell",value)
end
local function capIncreaseChanged(value)
	capIncrease = value
	system.pSave("capIncrease",value)
end


-----------------
local function lblChanged(value)
	lbl[akku]=nil
	lbl[akku]=value
	if(akku ==3)then
		system.pSave("lbl3",value)
	elseif(akku ==2)then
		system.pSave("lbl2",value)
	else
		system.pSave("lbl1",value)
	end
	-- Redraw telemetrywindow if label is changed by user
	system.registerTelemetry(1,lbl[akku],2,printTelem)
end

-----------------
local function SwChanged1(value)
	Sw1 = value
	system.pSave("Sw1",value)
end
local function SwChanged2(value)
	Sw2 = value
	system.pSave("Sw2",value)
end
local function SwChanged3(value)
	Sw3 = value
	system.pSave("Sw3",value)
end

-- ------only for simulation without connected telemetry
-- local function SimCapChanged(value)
	-- SimCap = value
	-- system.pSave("SimCap",value)
-- end
-- ------only for simulation without connected telemetry
-- local function SimVoltChanged(value)
	-- SimVolt = value
	-- system.pSave("SimVolt",value)
-- end
	
-----------------
local function capaChanged(value)
	capa[akku]=value
	system.pSave("capa",capa)
end
-----------------
local function alarm1Changed(value)
	alarm1[akku]=value
	system.pSave("alarm1",alarm1)
end
local function alarm2Changed(value)
	alarm2[akku]=value
	system.pSave("alarm2",alarm2)
end
local function alarm3Changed(value)
	alarm3[akku]=value
	system.pSave("alarm3",alarm3)
end
-----------------
local function anSwChanged(value)
	anSw = value
	system.pSave("anSw",value)
end
--------------------------------------------------------------------------------
-- Draw the main form (Application inteface)
-- Initialize with page 1
local function initForm(subform)
	-- If we are on first page build the form for display
	if(subform == 1) then
		form.setButton(1,trans.btn1,HIGHLIGHTED)
		form.setButton(2,trans.btn2..akku,ENABLED)
		
		form.addRow(1)
		form.addLabel({label="--- Geierwally  ---",font=FONT_BOLD})
		
		form.addRow(1)
		form.addLabel({label=trans.Label,font=FONT_BOLD})
		
		form.addRow(2)
		form.addLabel({label=trans.Sensor})
		form.addSelectbox(sensorLalist,sens,true,sensorChanged)
		
		form.addRow(2)
		form.addLabel({label=trans.VSensor,width=220})
		form.addSelectbox(sensorLalist,vSens,true,voltageSensorChanged)
		
		form.addRow(1)
		form.addLabel({label=trans.symSettings,font=FONT_BOLD})

		form.addRow(2)
		form.addLabel({label=trans.capInc,width=220})
		form.addIntbox(capIncrease,10,100,100,0,10,capIncreaseChanged)		
		
		form.addRow(2)
		form.addLabel({label=trans.Switch.." 1"})
		form.addInputbox(Sw1,true,SwChanged1)
		
		form.addRow(2)
		form.addLabel({label=trans.Switch.." 2"})
		form.addInputbox(Sw2,true,SwChanged2)
		
		form.addRow(2)
		form.addLabel({label=trans.Switch.." 3"})
		form.addInputbox(Sw3,true,SwChanged3)
		
		-- ------only for simulation without connected telemetry
		-- form.addRow(2)
		-- form.addLabel({label="simCellVoltage"})
		-- form.addInputbox(SimVolt,true,SimVoltChanged)
		-- ------only for simulation without connected telemetry
		-- form.addRow(2)
		-- form.addLabel({label="simCapacity"})
		-- form.addInputbox(SimCap,true,SimCapChanged)
		
		form.addRow(2)
		form.addLabel({label=trans.anSw,width=220})
		form.addInputbox(anSw,true,anSwChanged)
		
		form.addRow(1)
		form.addLabel({label="Powered by Geierwally - "..battVersion.." ",font=FONT_MINI, alignRight=true})
		
		form.setFocusedRow (1)
		formID = 1
		else
		-- If we are on second page build the form for display
		if(subform == 2) then
			form.setButton(1,trans.btn1,ENABLED)
			form.setButton(2,trans.btn2..akku,HIGHLIGHTED)
			
			form.addRow(1)
			form.addLabel({label="--- Geierwally ---",font=FONT_BOLD})
			
			form.addRow(1)
			form.addLabel({label=trans.Settings1..akku,font=FONT_BOLD})
			
			form.addRow(2)
			form.addLabel({label=trans.LabelW,width=160})
			form.addTextbox(lbl[akku],14,lblChanged)
			
			form.addRow(2)
			form.addLabel({label=trans.nCell,width=220})
			form.addIntbox(nCell,1,24,3,0,1,numberOfCellsChanged)					

			form.addRow(2)
			form.addLabel({label=trans.vLimit,width=220})
			form.addIntbox(vLimit,310,420,330,2,1,voltageLimitChanged)

			form.addRow(2)
			form.addLabel({label=trans.Capa,width=180})
			form.addIntbox(capa[akku],0,32767,2400,0,capIncrease,capaChanged)
			
			form.addRow(1)
			form.addLabel({label=trans.Alm,font=FONT_BOLD})
			
			form.addRow(2)
			form.addLabel({label=trans.AlmVal.."1"})
			form.addIntbox(alarm1[akku],0,100,0,0,1,alarm1Changed)
			
			form.addRow(2)
			form.addLabel({label=trans.AlmVal.."2"})
			form.addIntbox(alarm2[akku],0,100,0,0,1,alarm2Changed)
			
			form.addRow(2)
			form.addLabel({label=trans.AlmVal.."3"})
			form.addIntbox(alarm3[akku],0,100,0,0,1,alarm3Changed)
			
			form.addRow(1)
			form.addLabel({label="Powered by Geierwally - "..battVersion.." ",font=FONT_MINI, alignRight=true})
			
			form.setFocusedRow (1)
			formID = 2
			else
			-- If we are on third page build the form for display

		end
	end
end
--------------------------------------------------------------------------------
-- Re-init correct page if navigation buttons are pressed
local function keyPressed(key)
	if(key==KEY_1) then
		form.reinit(1)
	end
	if(key==KEY_2) then
		form.reinit(2)
	end
end
---------------------------------------------------------------------------------
-- Runtime functions, read sensor, convert to percentage, keep percentage between 0 and 100 at all times
-- Display on main screen the selected battery and values, take care of correct alarm-value
local function loop()
	local sensor = system.getSensorByID(sensid, senspa)
	local vSensor = system.getSensorByID(vSensid, vSenspa)

	local Sw1, Sw2, Sw3, anGo = system.getInputsVal(Sw1, Sw2, Sw3, anSw)
	local tTime = system.getTime()
	local akkuChanged = false
	local capAlert = false
	
	------only for simulation without connected telemetry
	-- local sensor = {}
	-- local vSensor  = {}
	-- local CapSimVal, VoltSimVal = system.getInputsVal(SimCap,SimVolt)
	-- if((CapSimVal ~= nil)and(VoltSimVal ~= nil))then
		-- sensor["valid"] = true
		-- sensor["value"] = 0
		-- vSensor["valid"] = true
		-- vSensor["value"] = 0
		-- CapSimVal = math.modf(CapSimVal*100) 
		-- CapSimVal = capa[akku]*CapSimVal/100
		-- VoltSimVal = math.modf(VoltSimVal*100) 
		-- VoltSimVal = 1 * VoltSimVal/100 + 3.2
		-- sensor.value = CapSimVal
		-- vSensor.value = VoltSimVal
	-- else
		-- sensor["valid"] = false
		-- sensor["value"] = 0
		-- vSensor["valid"] = false
		-- vSensor["value"] = 0
	-- end
	------only for simulation without connected telemetry

	
	if    (Sw1 ~= nil and Sw1 == 1)then
		if(akku ~=1)then
			akku = 1
			akkuChanged = true
		end	
	elseif(Sw2 ~= nil and Sw2 == 1)then 
		if(akku ~=2)then
			akku = 2
			akkuChanged = true
		end	
	elseif(Sw3 ~= nil and Sw3 == 1)then
		if(akku ~=3)then
			akku = 3
			akkuChanged = true
		end	
	else
		if(akku ~=1)then
			akku = 1
			akkuChanged = true
		end	
	end
	if(akkuChanged == true)then
		system.pSave("akku",akku)
		system.registerTelemetry(1,lbl[akku],2,printTelem)
		form.reinit()
	end
	
	if(vSensor and vSensor.valid) then
	----------------- voltage limit check
	    res = (vSensor.value * 100 / nCell)
		telVoltageVal = string.format("%.2f", (res/100))
		if ((res <= vLimit)and(voltageAlarm == false)) then
		    if(tSet0 == 0) then
				tStr0 = tTime + 4
				tSet0 = 1
			else
				if(tStr0 <= tTime)then -- set voltage alarm after 4 sec
			    	system.setControl(2,1,0,0)
					voltageAlarm = true
					if (system.isPlayback () == false) then
						tStr0 = tTime + 5
						--print("VoltageAlert",res/100)
						if(colorScreen)then
							system.vibration (true,2)
						else
							system.playBeep(1,4000,500) 	
						end
						system.playNumber ((res/100), 2, "V","LowestCell")
					end	
				end
			end
		else
			if(voltageAlarm) then
				if(res >= 400) then --new battery plugged , reset voltage alarm
					system.setControl(2,0,0,0)
					voltageAlarm = false
				else
					if(prevVoltage > res)then
						prevVoltage = res
						if(tStr0 <= tTime)then
							if (system.isPlayback () == false) then
								tStr0 = tTime + 5
								--print("VoltageAlert",res/100)
								if(colorScreen)then
									system.vibration (true,2)
								else
									system.playBeep(1,4000,500) 	
								end
								system.playNumber ((res/100), 2, "V","LowestCell")
							end	
						end	
					end	
				end
			else
				prevVoltage = res
				tSet0 = 0
			end
		end
	else
		voltageAlarm = false
		telVoltageVal = "-"
		tSet0 = 0	
	end	

	if(sensor and sensor.valid)then
	-----------------
		res = (((capa[akku] - sensor.value) * 100) / capa[akku])
		if (res < 0) then
			res = 0
		else
			if (res > 100) then
				res = 100
			end
		end
		telVal = string.format("%.1f", res)

		if(res <= alarm1[akku]) then
			capAlert = true
			if(tSet1 == 0) then
				tStr1 = tTime + 5
				tSet1 = 1
			else
				if(tStr1 <= tTime) then
					if(vF1played == 0 or vF1played == nil) then
						if (system.isPlayback () == false) then
							--print("CapAlert 1",telVal)
							vF1played = 1
							system.setControl(3,1,0,0)
							if(colorScreen)then
								system.vibration (true,2)
							else
								system.playBeep(1,4000,500) 	
							end	
							capAlarm = true
							system.playNumber (telVal, 0, "%","Capacity")
						end	
					end
				end	
			end
		end
		
		if(res <= alarm2[akku]) then
			capAlert = true
			if(tSet2 == 0) then
				tStr2 = tTime + 5
				tSet2 = 1
			else
				if(tStr2 <= tTime) then
					if(vF2played == 0 or vF2played == nil) then
						if (system.isPlayback () == false) then
							--print("CapAlert 2",telVal)
							vF2played = 1
							system.setControl(3,1,0,0)
							if(colorScreen)then
								system.vibration (true,2)
							else
								system.playBeep(1,4000,500) 
							end	
							system.playNumber (telVal, 0, "%","Capacity")
							capAlarm = true
						end	
					end
				end	
			end
		end
		
		if(res <= alarm3[akku]) then
			capAlert = true
			if(tSet3 == 0) then
				tStr3 = tTime + 5
				tSet3 = 1
			else
				if(tStr3 <= tTime) then
					if(vF3played == 0 or vF3played == nil) then
						if (system.isPlayback () == false) then
							--print("CapAlert 3",telVal)
							vF3played = 1
							system.setControl(3,1,0,0)
							if(colorScreen)then
								system.vibration (true,2)
							else
								system.playBeep(1,4000,500)
							end	
							system.playNumber (telVal, 0, "%","Capacity")
							capAlarm = true
						end	
					end
				end	
			end
		end		
		
		if(capAlert == false)then
			capAlarm = false
			system.setControl(3,0,0,0)
			vF1played = 0
			tSet1 = 0
			vF2played = 0
			tSet2 = 0
			vF3played = 0
			tSet3 = 0
		end
-------------------------
	else
		telVal = "-"
		vF1played = 0
		tSet1 = 0
		vF2played = 0
		tSet2 = 0
		vF3played = 0
		tSet3 = 0
	end 
------------------------	
	
	if(anGo == 1 and telVal ~= "-" and anTime < tTime) then
		if (system.isPlayback () == false) then
			system.playNumber(telVal, 0, "%", trans.anCap)
			anTime = tTime + 3
		end	
	end
    collectgarbage()
end
--------------------------------------------------------------------------------
-- Application initialization
local function init(battVersion_)
	battVersion = battVersion_
	capAlarm = false
	voltageAlarm = false
	telVal = "-"
	telVoltageVal = "-"
	sens = system.pLoad("sens",0)
	sensid = system.pLoad("sensid",0)
	senspa = system.pLoad("senspa",0)
	vSens = system.pLoad("vSens",0)
	vSensid = system.pLoad("vSensid",0)
	vSenspa = system.pLoad("vSenspa",0)
	vLimit = system.pLoad("vLimit",330)
	nCell = system.pLoad("nCell",3)
	capIncrease = system.pLoad("capIncrease",100)
	akku = system.pLoad("akku",1)
	lbl[1] = system.pLoad("lbl1",trans.Batt1)
	lbl[2] = system.pLoad("lbl2",trans.Batt2)
	lbl[3] = system.pLoad("lbl3",trans.Batt3)
	capa = system.pLoad("capa",{2400,2400,2400})
	alarm1 = system.pLoad("alarm1",{30,30,30})
	alarm2 = system.pLoad("alarm2",{0,0,0})
	alarm3 = system.pLoad("alarm3",{0,0,0})
	Sw1 = system.pLoad("Sw1")
	Sw2 = system.pLoad("Sw2")
	Sw3 = system.pLoad("Sw3")
	------only for simulation without connected telemetry
	--SimCap = system.pLoad("SimCap")
	------only for simulation without connected telemetry
	--SimVolt = system.pLoad("SimVolt")
	anSw = system.pLoad("anSw")
	system.registerTelemetry(1,lbl[akku],2,printTelem)
	system.registerControl(2,trans.battVoltageCtrl,trans.battVSw)
	system.registerControl(3,trans.battCtrl,trans.battSw)
	system.registerForm(1,MENU_APPS,trans.appName,initForm,keyPressed)
	local deviceType = system.getDeviceType()
	if(( deviceType == "JETI DC-24")or(deviceTypeF3K == "JETI DS-24"))then
		colorScreen = true -- set display type
	end
end
--------------------------------------------------------------------------------

setLanguage()
--------------------------------------------------------------------
local GW_Batt_Main = {init,loop}
return GW_Batt_Main
