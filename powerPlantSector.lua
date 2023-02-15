-- Type: lua script
-- Name: Power Plant Sector
-- Desc: This script is used to control the power plant sector of the power plant. It is used to control the turbines.
-- Auth: DEVIX


function ProcessEvents()
    local events = {}
    while true do
        local e, s, v = event.pull(0)
        if not e then break end
        local event = {}
        event.e = e
        event.s = s
        event.v = v
        table.insert(events, event)
    end
    return events
end

function HasEvent(events, event, source)
    for _,event in ipairs(events) do
        if event.s == source and event.e == event then return true end
    end
    return false
end

function SetButtonState(button, actual, state)
    if (state == actual) then return actual end

    if (state) then
        button:setColor(0, 255, 0, 0.0005)
    else
        button:setColor(0, 255, 0, 0)
    end

    return state
end


function MakePanel(id, turbine)
    local panel = {}
    panel.water = {}
    panel.fuel = {}
    panel.steam = {}
    panel.instance = component.proxy(id)


    panel.fuel.button = panel.instance:getModule(1, 0)
    panel.fuel.button:setColor(0, 255, 0, 0)
    panel.fuel.poten = panel.instance:getModule(0, 0)
    panel.fuel.gauge = panel.instance:getModule(0, 1)
    panel.fuel.poten.max = 10
    panel.fuel.buttonState = false
    panel.fuel.valve = component.proxy(component.findComponent("valve fuel sector1 " .. turbine)[1])

    panel.water.button = panel.instance:getModule(3, 0)
    panel.water.button:setColor(0, 255, 0, 0)
    panel.water.poten = panel.instance:getModule(2, 0)
    panel.water.gauge = panel.instance:getModule(2, 1)
    panel.water.poten.max = 10
    panel.water.buttonState = false
    panel.water.valve = component.proxy(component.findComponent("valve water sector1 " .. turbine)[1])

    panel.steam.button = panel.instance:getModule(1, 4)
    panel.steam.button:setColor(0, 255, 0, 0)
    panel.steam.buttonState = false
    panel.steam.poten = panel.instance:getModule(0, 4)
    panel.steam.gauge = panel.instance:getModule(0, 5)
    panel.steam.valve = component.proxy(component.findComponent("valve steam sector1 " .. turbine)[1])
    panel.steam.tank = component.proxy(component.findComponent("tank steam sector1 " .. turbine)[1])

    event.listen(panel.fuel.button)
    event.listen(panel.water.button)
    event.listen(panel.fuel.poten)
    event.listen(panel.water.poten)
    event.listen(panel.steam.button)
    event.listen(panel.steam.poten)

    return panel
end


event.ignoreAll()
event.clear()

local panels = {}
panels[1] = MakePanel("8C7923A8477C62CCBED216B780DC80F4", "turbine5")
panels[2] = MakePanel("D13F78784A2BC8A653671E86433D6DF0", "turbine4")
panels[3] = MakePanel("C87EA6424473E935583088846C352287", "turbine3")
panels[4] = MakePanel("555E9FC94F756470FAB8D0A9AB6E6476", "turbine2")
panels[5] = MakePanel("F2D0D5F04ECA666B9F7F55B4365268FE", "turbine1")


function ProcessPanel(panel, events)
    for _,v in ipairs(events) do
        if (v.s == panel.water.button and v.e == "Trigger") then
            panel.water.buttonState = SetButtonState(panel.water.button, panel.water.buttonState, not panel.water.buttonState)
        elseif (v.s == panel.fuel.button and v.e == "Trigger") then
            panel.fuel.buttonState = SetButtonState(panel.fuel.button, panel.fuel.buttonState, not panel.fuel.buttonState)
        elseif (v.s == panel.steam.button and v.e == "Trigger") then
            panel.steam.buttonState = SetButtonState(panel.steam.button, panel.steam.buttonState, not panel.steam.buttonState)
            if (panel.steam.buttonState) then panel.steam.valve.userFlowLimit = 5 end
        elseif (v.s == panel.fuel.poten and v.e == "valueChanged" and panel.fuel.buttonState) then
            panel.fuel.valve.userFlowLimit = v.v * 5 /10
        elseif (v.s == panel.water.poten and v.e == "valueChanged" and panel.water.buttonState) then
            panel.water.valve.userFlowLimit = v.v * 5 /10
        elseif (v.s == panel.steam.poten and v.e == "valueChanged" and panel.steam.buttonState) then
            panel.steam.valve.userFlowLimit = v.v * 5 /10
        end
    end

    if (not panel.fuel.buttonState and panel.fuel.valve.flowLimit) then panel.fuel.valve.userFlowLimit = 0 end
    if (not panel.water.buttonState and panel.water.valve.flowLimit) then panel.water.valve.userFlowLimit = 0 end
    if (not panel.steam.buttonState and panel.steam.valve.flowLimit) then panel.steam.valve.userFlowLimit = 0 end

    if not HasEvent(events, panel.fuel.poten, "valueChanged") then
        panel.fuel.poten.value = math.floor(panel.fuel.valve.userFlowLimit * 10 / 5)
    end
    if not HasEvent(events, panel.water.poten, "valueChanged") then
        panel.water.poten.value = math.floor(panel.water.valve.userFlowLimit * 10 / 5)
    end
    if not HasEvent(events, panel.steam.poten, "valueChanged") then
        panel.steam.poten.value = math.floor(panel.steam.valve.userFlowLimit * 10 / 5)
    end

    panel.fuel.gauge.limit = panel.fuel.valve.flowLimitPct
    panel.fuel.gauge.percent = panel.fuel.valve.flowPct

    panel.water.gauge.limit = panel.water.valve.flowLimitPct
    panel.water.gauge.percent = panel.water.valve.flowPct

    panel.steam.gauge.percent = panel.steam.tank.fluidContent / panel.steam.tank.maxFluidContent
    panel.steam.gauge.limit = panel.steam.valve.flowLimitPct

end

while true do
    local events = ProcessEvents()

    for _,panel in ipairs(panels) do
        ProcessPanel(panel, events)
    end
end