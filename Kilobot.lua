------------------------------------------------------------------------------ 
-- Following few lines automatically added by V-REP to guarantee compatibility 
-- with V-REP 3.1.3 and earlier: 
colorCorrectionFunction=function(_aShapeHandle_) 
    local version=sim.getInt32Param(sim.intparam_program_version) 
    local revision=sim.getInt32Param(sim.intparam_program_revision) 
    if (version<30104)and(revision<3) then 
        return _aShapeHandle_ 
    end 
    return '@backCompatibility1:'.._aShapeHandle_ 
end 
------------------------------------------------------------------------------ 
 
 
------------------------------------------------------------------------------ 
-- Following few lines automatically added by V-REP to guarantee compatibility 
-- with V-REP 3.1.3 and later: 
if (sim_call_type==sim.syscb_init) then 
    sim.setScriptAttribute(sim.handle_self,sim.childscriptattribute_automaticcascadingcalls,false) 
end 
if (sim_call_type==sim.syscb_cleanup) then 
 
end 
if (sim_call_type==sim.syscb_sensing) then 
    sim.handleChildScripts(sim_call_type) 
end 
if (sim_call_type==sim.syscb_actuation) then 
    if not firstTimeHere93846738 then 
        firstTimeHere93846738=0 
    end 
    sim.setScriptAttribute(sim.handle_self,sim.scriptattribute_executioncount,firstTimeHere93846738) 
    firstTimeHere93846738=firstTimeHere93846738+1 
 
------------------------------------------------------------------------------ 
 
 
-- Kilobot Model
        -- K-Team S.A. --initial version
        -- 2013.06.24
        
        -- Andrei G. Florea --curent kilolib (kilobotics.com) adapted version
        -- 09 November 2015
        
        -- Add your own program in function loop() , after the comment "user program code goes below"
    
    if (sim.getScriptExecutionCount()==0) then 
    
        -- Check if we have a controller in the scene:
        i=0
        while true do
            h=sim.getObjects(i,sim.handle_all)
            if h==-1 then break end
            if simGetObjectCustomData(h,4568)=='kilobotcontroller' then
                foundCtrller=true
                break
            end
            i=i+1
        end
        if not foundCtrller then
            sim.displayDialog('Error',"The KiloBot could not find a controller.&&nMake sure to have exactly one 'Kilobot_Controller' model in the scene.",sim.dlgstyle_ok,false,nil,{0.8,0,0,0,0,0},{0.5,0,0,1,1,1})
        end
    
    
        -- save some handles
        KilobotHandle=sim.getObjectHandle(sim.handle_self) 
    
        LeftMotorHandle=sim.getObjectHandle('Kilobot_Revolute_jointLeftLeg')
        RightMotorHandle=sim.getObjectHandle('Kilobot_Revolute_jointRightLeg')
    
        MsgSensorsHandle=sim.getObjectHandle('Kilobot_MsgSensor')
        fullname=sim.getNameSuffix(name)
    
        sensorHandle=sim.getObjectHandle("Kilobot_Proximity_sensor")
        BaseHandle=sim.getObjectHandle("BatHold")
    
        visionHandle=sim.getObjectHandle("Vision_sensor")
        --BatGraphHandle=sim.getObjectHandle("BatGraph") -- should be uncommented only for one robot
    
        half_diam=0.0165 -- half_diameter of the robot base
        
        RATIO_MOTOR = 10/255 -- ratio for getting 100% = 1cm/s or 45deg/s
    
        -- 4 constants that are calibration values used with the motors
        kilo_turn_right     = 200 -- value for cw motor to turn the robot cw in place (note: ccw motor should be off)
        kilo_turn_left    = 200 -- value for ccw motor to turn the robot ccw in place (note: cw motor should be off) 
        kilo_straight_right  = 200 -- value for the cw motor to move the robot in the forward direction
        kilo_straight_left = 200 -- value for the ccw motor to move the robot in the forward direction 


        -- message synopsys (follows kilobotics.com/message.h):
        -- msg = {type, data} where
        --         msg_type = uint8_t (MSG_TYPE_* see below)
        --         data = uint8_t[9] (table of 9 uint8_t)


        --special message codes (message_type_t)
        MSG_TYPE_NORMAL = 0
        MSG_TYPE_PAUSE = 4
        MSG_TYPE_VOLTAGE = 5
        MSG_TYPE_RUN = 6
        MSG_TYPE_CHARGE = 7
        MSG_TYPE_RESET = 8

        --blink auxiliaries
        DELAY_BLINK = 100 --ms
        blink_in_progress = 0
        timexp_blink = 0

        -- enum directions
        DIR_STOP = 0
        DIR_STRAIGHT = 1
        DIR_LEFT = 2
        DIR_RIGHT = 3

        --direction global vars
        direction = DIR_STOP
        direction_prev = DIR_STOP

        -- for battery management
        battery_init = 8000000  -- battery initial charged value
        battery =  battery_init    -- battery simulator (~5h with 2 motors and 3 colors at 1 level)
        factMoving = 100        -- factor for discharging during moving
        moving = 0                -- for battery discharging    1: one motor, 2: 2 motors, 0: not moving
        factCPU = 10            -- factor for discharging during cpu
        cpu=1                    -- cpu state: sleep = 0, active = 1
        factLighting = 40        -- factor for discharging during lighting
        lighting=0                -- for battery managing
        bat_charge_status=0        -- battery charge status 0= no, 1, yes    
        
        charge_rate=400         -- charge rate
        charge_max= battery_init-- battery_init*99.9/100 -- end of charge detection
    
        reset_substate    = 0
        -------------------------------------------------------------------------------------------------------------------------------------------
        --global variables
        -------------------------------------------------------------------------------------------------------------------------------------------
        
        rt = 0
        at = 0
        st = 0
        kt ={}
        et = true
        --ut = 0
        
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- Functions similar to C API
        -------------------------------------------------------------------------------------------------------------------------------------------
        --called for each received message (of type == MSG_TYPE_NORMAL)
        -- @param msg_data (uint8_t[9] in C) : data contained in the message
        -- @param distance (uint8_t in C) : measured distance from the sender
        function message_rx(msg_data, distance)
            --sim.addStatusbarMessage("Message[1] = " .. msg_data[1] .. " received with distance = " .. distance)
        end

        --called to construct every sent message
        --should be restricted to a 9 unsigned int table (as is the case for real kilobots)
        --@return msg = {type, data} where
        --         msg_type = uint8_t (MSG_TYPE_* see synopsys)
        --         data = uint8_t[9] (table of 9 uint8_t)
        function message_tx()
            --sim.addStatusbarMessage("Message built");
            return {msg_type=MSG_TYPE_NORMAL, data={11, 22, 33, 44, 55, 66, 77, 88, 99}}
        end

        --called after each successfull message transmission
        function message_tx_success()
            --sim.addStatusbarMessage("Message sent");
        end

        --function called only once at simmulation start (or after clicking Reset from the controller)
        --You should put your inital variable you would like to reset inside this function for your program.
        function setup()
            -- get unique robot id from "robotID" parameter
            kilo_uid = sim.getScriptSimulationParameter(sim.handle_self, "robotID", false)
            --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self) .. ": kilo_uid=" .. kilo_uid)
        end    
        
        function loop()
        --/////////////////////////////////////////////////////////////////////////////////////
        --//user program code goes below.  this code needs to exit in a resonable amount of time
        --//so the special message controller can also run
        --/////////////////////////////////////////////////////////////////////////////////////
    
        --/////////////////////////////////////////////////////////////////////////////////////
        --//
        --//  In the example below, the robot moves and display its distance 
        --//  to other robots with its color led.
        --//  
        --////////////////////////////////////////////////////////////////////////////////////
            --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self).." ambient light:"..get_ambient_light())
            local collision, dist, dp = sim.readProximitySensor(sensorHandle)
            local result, distance, detectedPoint = sim.checkProximitySensor(sensorHandle,senderHandle)
            --print(sim.getSimulationTime())
            --print(dist)
            --print(distance)
            --ccw or cw = 7.8431372642517
            --print(direction)
            if (distance ~= nil)  then 
				distance= distance + half_diam
				-- if the obstacle is another robot, light up the robot	
				if(distance < 90) then
                    moving_time()
                    --waitalgorithm()
                    --WAIT()
					--choice()
                    --STRAIGHT
                --elseif(distance > 90) then
                  --  set_motion(DIR_STRAIGHT)
				else
					return
				end
			elseif (distance == nil) then
                st = 0
                set_motion(DIR_STRAIGHT)
                if (dist ~= nil) then
                    dist = dist + half_diam --0.0165 -- half_diameter of the robot base
                    if (dist < 0.0800) then
                        --choice()
                        moving_wall()
                    else
                        return
                    end
                elseif (dist == nil) then
                    rt=0
                    at=0
                    kt={}
                    et=true
                end
            end
            --blink(0, 1, 0)
        --////////////////////////////////////////////////////////////////////////////////////
        --//END OF USER CODE
        --////////////////////////////////////////////////////////////////////////////////////
        end
        
        -------------------------------------------------------------------------------------------------------------------------------------------
        -------------------------------------------------------------------------------------------------------------------------------------------
        
        
        function waitalgorithm()
        --Kilobot ambient light:0.38039216399193
        --89.665541366229
        
        --Kilobot ambient light:0.99215686321259
        --95.763493544628
            --light minimum = 0.36078432202339 ??
            wmax = 100 -- maximum waiting time
            emax = 1 -- maximum sensor value
            exyz= get_ambient_light() -- ambient light value
            offset = 1
            steepness = 90 * (3.14/180)
            e = 2.71
            wt = (wmax/(1+(e^-((exyz + offset)*steepness))))
            return (math.floor(wt))
        end
        
        function choice()
        --choicevariable = sim.getBoolParam(choice())
        --DIR_STOP = 0
        --DIR_STRAIGHT = 1
        --DIR_LEFT = 2
        --DIR_RIGHT = 3
            if et == true then
                local choice = math.random(2)
                if (direction_prev == 1) or (direction_prev == 0) then
                    if choice == 1 then
                        set_motion(DIR_LEFT)
                    elseif choice == 2 then
                        set_motion(DIR_RIGHT)
                    end
                elseif (direction_prev == 2) then
                    set_motion(DIR_LEFT)
                elseif (direction_prev == 3) then
                    set_motion(DIR_RIGHT)
                end
            elseif et == false then
                set_motion(DIR_LEFT)
            end
        end
        
        function moving_time()
            rollrange()
            wa = waitalgorithm() * 10
            if st >= (wa) then
                if st < (wa+at) then -- demora 200 pra dar meia volta
                    st = st + 1
                    
                    choice() -- problema 3232323232
                    checkerror()
                elseif st >= (wa+at) then
                    set_motion(DIR_STRAIGHT)
                end
            elseif st < (wa) then
                st = st + 1
                set_motion(DIR_STOP)
            end
        end
        
        function moving_wall()
            rollrange()
            rt = rt + 1
            if rt >(55) and rt <= (at+55) then
                choice() -- problema 3232323232
                checkerror()
            else
                set_motion(DIR_STRAIGHT)
            end
        end
        
        function get_ambient_light()
            result,auxValues1,auxValues2=sim.readVisionSensor(visionHandle)
            if (auxValues1) then

                return auxValues1[11] -- return average intensity
            else
                return -1
            end
        end
        
        function rollrange()
            if at == 0 then
                at = math.random(125,275)
                return at
            elseif at ~= 0 then
                return at
            end
        end
        
        function checkerror()
            --print(direction)
            da = direction
            table.insert(kt,da)
            if (kt[1] == kt[2] or kt[2] == nil) then
                --return true
                et = true
            elseif kt[1] ~= kt[2] then
                --return false
                et = false
            end
            --print(kt)
            --print(et)
        end
        
        -- Set direction of motion
        -- @param dir_new : new direction to go, one of (DIR_STOP, DIR_STRAIGHT, DIR_LEFT, DIR_RIGHT)
        function set_motion(dir_new)
            if (dir_new == DIR_STOP) then
                set_motor(0, 0)

            elseif (dir_new == DIR_STRAIGHT) then
                set_motor(kilo_straight_right, kilo_straight_left)

            elseif (dir_new == DIR_LEFT) then
                set_motor(0, kilo_turn_left)

            elseif (dir_new == DIR_RIGHT) then
                set_motor(kilo_turn_right, 0)
            end


            direction_prev = direction
            direction = dir_new
        end

        --blinks LED for DELAY_BLINK interval
        -- @param r : red value (0-3)
        -- @param g : green value (0-3)
        -- @param b : blue value (0-3)
        function blink(r, g, b)
            blink_in_progress = 1
            --sim.addStatusbarMessage("<-- time = ".. sim.getSimulationTime());
            timexp_blink = sim.getSimulationTime() + DELAY_BLINK / 1000.0
            --sim.addStatusbarMessage("-- timexp_blink = ".. timexp_blink);
            set_color(r, g, b)
        end

        -- Set motor speed PWM values for motors between 0 (off) and 255 (full on, ~ 1cm/s) for cw_motor and ccw_motor 
        function set_motor(cw_motor,ccw_motor)
        -- Set speed
            sim.setJointTargetVelocity(RightMotorHandle,ccw_motor*RATIO_MOTOR)
            sim.setJointTargetVelocity(LeftMotorHandle,cw_motor*RATIO_MOTOR)
    
            -- for battery managing
            if ((cw_motor == 0) and (ccw_motor==0)) then
                moving=0
            elseif ((cw_motor == 0) or (ccw_motor==0)) then
              moving=1    
            else
            -- both moving
              moving=2
            end
    
        end

        -- Set LED color
        -- @param r : red value (0-3)
        -- @param g : green value (0-3)
        -- @param b : blue value (0-3)
        function set_color(r,g,b)
            sim.setShapeColor(colorCorrectionFunction(BaseHandle),"BODY",0,{r*0.6/3.0+0.1, g*0.6/3.0+0.1, b*0.6/3.0+0.1})
            lighting=r+g+b
        end
    
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- END Functions similar to C API
        -------------------------------------------------------------------------------------------------------------------------------------------
    
        enable_tx = 0 -- to turn on/off the transmitter
        senderID = nil
    
        special_mode = 1
        run_program = 0
        special_mode_message = MSG_TYPE_RESET --start the robot with a reset (to call setup() only once during start-up)
    
        function receive_data()
            -- receive latest message and process it
            
            data,senderID,dataHeader,dataName=sim.receiveData(0,"Message",MsgSensorsHandle)
            
            if (data ~= nil) then
                senderHandle= sim.getObjectAssociatedWithScript(senderID)
                udata=sim.unpackInt32Table(data)
                
                --reconstruct message structure
                message = {msg_type = udata[1], 
                            data = {udata[2], udata[3], udata[4], udata[5], udata[6], udata[7], udata[8], udata[9], udata[10]}}

                --sim.addStatusbarMessage("message[msg_type] = " .. message["msg_type"]);

                -- special message
                if (message["msg_type"] > MSG_TYPE_NORMAL) then
                    special_mode_message = message["msg_type"]
                    special_mode = 1
    
                else
                    --normal message processing

                    result, distance, detectedPoint = sim.checkProximitySensor(sensorHandle,senderHandle)
                    
                    -- if the distance was extracted corectly
                    if (result == 1) then
                        distance = (distance + half_diam) * 1000  -- distance in mm + 1/2diameter of robot
                        -- send the message contents to user processing with distance
                        message_rx(message["data"], distance)
                    end
                end
            else    
                --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self).." no received data")
            end
        end
    
        irstart=sim.getSimulationTime()
    
        function send_data() -- send data from ir every 0.2s, at a max distance of 7cm (ONLY if kilobot is in normal running state)
            newir=sim.getSimulationTime()
            --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self).." enable_tx:"..enable_tx.."  irstart:"..irstart.."  newir:"..newir)
            if ((enable_tx==1) and (newir-irstart>0.2) and (run_program == 1)) then
                local new_msg = message_tx() --the user function is resposible for composing the message
                --serialize (msg_type, data[1], data[2], ... data[9]) and send message
                sim.sendData(sim.handle_all,0,"Message",
                    sim.packInt32Table({new_msg["msg_type"], new_msg["data"][1], new_msg["data"][2], new_msg["data"][3], new_msg["data"][4], new_msg["data"][5],
                        new_msg["data"][6], new_msg["data"][7], new_msg["data"][8], new_msg["data"][9]}),
                    MsgSensorsHandle,0.07,3.1415,3.1415*2,0.8)

                --message transmission ok => notify the user
                message_tx_success()

                --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self).." sent a mesage")
                irstart=newir
            end 
            
        end
    
        -- Measure battery voltage, returns voltage in .01 volt units
        -- for example if 394 is returned, then the voltage is 3.94 volts 
        function measure_voltage()
            return battery*420/battery_init
        end
    
        -- Measure if battery is charging, returns 0 if no, 1 if yes 
        function measure_charge_status()
            return bat_charge_status
        end
    
        substate=0 -- sub state for state machine of message
    
        -- battery management
        function update_battery()
            dt=sim.getSimulationTimeStep()
            battery=battery-factLighting*lighting-factMoving*moving-factCPU*cpu
            --sim.setGraphUserData(BatGraphHandle,"Battery",battery)  -- should be uncommented only for one robot
        end
    
        delay_start=sim.getSimulationTime()
    
            -- wait for x milliseconds  global variable delay_start should be initialised with:  delay_start=sim.getSimulationTime()
        function _delay_ms(x)
            --sim.wait(x/1000.0,true)
                if ((sim.getSimulationTime()-delay_start)>=(x/1000.0)) then
                    return 1
                end
            return 0
        end
    
        -------------------------------------------------
        -- other initialisations
    
        --kilo_uid = math.random(0, 255) -- set robot id
    
        -- get number of other robots
    
        NUMBER_OTHER_ROBOTS=0
        objIndex=0
        while (true) do
            h=sim.getObjects(objIndex,sim.object_shape_type)
            if (h<0) then
                break
            end
            objIndex=objIndex+1
            --sim.addStatusbarMessage("objIndex: "..objIndex)
            if ((simGetObjectCustomData(h,1834746)=="kilobot") and (KilobotHandle ~= h))then
                NUMBER_OTHER_ROBOTS=NUMBER_OTHER_ROBOTS+1
                --sim.addStatusbarMessage("NUMBER_OTHER_ROBOTS: "..NUMBER_OTHER_ROBOTS)
            end
        end    
    
        --sim.addStatusbarMessage("number of robots found: "..robotnb)
    
    
    end
    
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- main script loop
    
    sim.handleChildScripts(sim_call_type)
    
    update_battery() -- update battery value
    
    receive_data() -- received data by ir
    
    send_data() -- send data by ir
    
    --special message controller, handles controll messages like sleep and resume program
    if(special_mode==1) then
    
        run_program=0
    
        special_mode=0
        set_motor(0,0)
    
        -- modes for different values of special_mode_message     
        --0x01 bootloader (not implemented)
        --0x02 sleep (not implemented)
        --0x03 wakeup, go to mode 0x04
        --0x04 Robot on, but does nothing active
        --0x05 display battery voltage
        --0x06 execute program code
        --0x07 battery charge
        --0x08 reset program
    
    
        if(special_mode_message==0x02) then
          -- sleep    
            wakeup=0
            --enter_sleep();//will not return from enter_sleep() untill a special mode message 0x03 is received    
        elseif((special_mode_message==0x03)or(special_mode_message==MSG_TYPE_PAUSE)) then
          --wakeup / Robot on, but does nothing active
            enable_tx=0
            
            --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self).." substate: "..substate) 
    
            -- make the led blink
            if (substate==0) then    
                set_color(3,3,0)
                substate=substate+1
                delay_start=sim.getSimulationTime()
            elseif (substate==1) then
                if (_delay_ms(50)==1) then 
                    substate=substate+1
                end
            elseif (substate==2) then
                set_color(0,0,0)
                substate=substate+1
                delay_start=sim.getSimulationTime()
            elseif (substate==3) then
                if (_delay_ms(1300)==1) then
                    substate=0
                end
            end
    
            enable_tx=1
            special_mode=1
        
        elseif(special_mode_message==MSG_TYPE_VOLTAGE) then
         -- display battery voltage
            enable_tx=0
    
            if(measure_voltage()>400) then
                set_color(0,3,0)
            elseif(measure_voltage()>390) then
                set_color(0,0,3)
            elseif(measure_voltage()>350) then
                set_color(3,3,0)
            else
                set_color(3,0,0)
            end
    
            enable_tx=1
            --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self).." Voltage: "..measure_voltage().."  battery:"..battery)
        elseif (special_mode_message==MSG_TYPE_RUN) then
            --execute program code
            enable_tx=1
            run_program=1
            substate = 0
            --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self).." special mode Run") 
            --no code here, just allows special_mode to end 
    
        elseif (special_mode_message==MSG_TYPE_CHARGE) then
         --battery charge
            enable_tx=0
            --if(measure_charge_status()==1) then
            
            if (battery<charge_max) then
                if (substate==0) then    
                    set_color(1,0,0)
                    substate=substate+1
                    delay_start=sim.getSimulationTime()
                elseif (substate==1) then
                    if (_delay_ms(50)==1) then 
                        substate=substate+1
                    end
                elseif (substate==2) then
                    set_color(0,0,0)
                    substate=substate+1
                    delay_start=sim.getSimulationTime()
                elseif (substate==3) then
                    if (_delay_ms(300)==1) then
                        substate=0
                    end
                end
            
                battery=battery+charge_rate
            
                if (battery>battery_init) then
                    battery=battery_init
                end
            end
            special_mode=1
    
    
    
            enable_tx=1
        elseif (special_mode_message==MSG_TYPE_RESET) then
            
            if (reset_substate==0)    then
            --reset
            enable_tx=0
            setup()
            run_program = 0
            special_mode_message = MSG_TYPE_RESET
            reset_substate = reset_substate + 1
            -- wait some time for stopping messages
            --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self).." start resetting") 
            delay_reset=sim.getSimulationTime()
            elseif (sim.getSimulationTime()-delay_reset>=1.5) then      
                special_mode_message = 3
                reset_substate    = 0
            else
                while (sim.receiveData(0,"Message",MsgSensorsHandle)) do 
                    --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self).." empty message buffer") 
                end
            end
            
            special_mode = 1
    
        end
    
    end
    
    if(run_program==1) then
        
        --sim.addStatusbarMessage(sim.getScriptName(sim.handle_self).." process Run") 
        if (blink_in_progress == 1) then
            if (sim.getSimulationTime() >= timexp_blink) then
                --sim.addStatusbarMessage("--> time = ".. sim.getSimulationTime());
                blink_in_progress = 0;
                set_color(0, 0, 0);
            end
        else
            loop()
        end
    
    end
    
    
    if (sim.getSimulationState()==sim.simulation_advancing_lastbeforestop) then
        -- Put some restoration code here
        set_color(0,0,0)
    end
 
 
------------------------------------------------------------------------------ 
-- Following few lines automatically added by V-REP to guarantee compatibility 
-- with V-REP 3.1.3 and later: 
end 
------------------------------------------------------------------------------ 

