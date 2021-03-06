local application
local light = {
    const = { min = 0, max = 1023 },
    leds = {
        r = { pin = 1, bright = 0 },
        g = { pin = 2, bright = 0 },
        b = { pin = 3, bright = 0 },
        c = { pin = 4, bright = 0 },
        h = { pin = 5, bright = 0 }
    },
    bright = {
        day = 960,
        moon = { b = 60, c = 15, h = 25 },
        night = 0
    },
    phase = { last = "", curr = "" }
}
light.transition = {}

function light.transition.day()
    print("DAY MODE")
    for i = 0, light.const.max do
        light.leds.b.bright = light.leds.b.bright > light.const.min and light.leds.b.bright - 1 or light.const.min
        light.leds.c.bright = light.leds.c.bright < light.bright.day and light.leds.c.bright + 1 or light.bright.day
        light.leds.h.bright = light.leds.h.bright < light.bright.day and light.leds.h.bright + 1 or light.bright.day

        pwm.setduty(light.leds.b.pin, light.leds.b.bright)
        pwm.setduty(light.leds.c.pin, light.leds.c.bright)
        pwm.setduty(light.leds.h.pin, light.leds.h.bright)

        tmr.delay(50)
    end
    print(light.leds.b.bright, light.leds.c.bright, light.leds.h.bright)
end

function light.transition.moon()
    print("MOON MODE")
    for i = 0, light.const.max do
        light.leds.b.bright = light.leds.b.bright < light.bright.moon.b and light.leds.b.bright + 1 or light.bright.moon.b
        light.leds.c.bright = light.leds.c.bright > light.bright.moon.c and light.leds.c.bright - 1 or light.bright.moon.c
        light.leds.h.bright = light.leds.h.bright > light.bright.moon.h and light.leds.h.bright - 1 or light.bright.moon.h

        pwm.setduty(light.leds.b.pin, light.leds.b.bright)
        pwm.setduty(light.leds.c.pin, light.leds.c.bright)
        pwm.setduty(light.leds.h.pin, light.leds.h.bright)

        tmr.delay(50)
    end
    print(light.leds.b.bright, light.leds.c.bright, light.leds.h.bright)
end

function light.transition.night()
    print("NIGHT MODE")
    for i = 0, light.const.max do
        light.leds.b.bright = light.leds.b.bright > light.const.min and light.leds.b.bright - 1 or light.bright.night
        light.leds.c.bright = light.leds.c.bright > light.const.min and light.leds.c.bright - 1 or light.bright.night
        light.leds.h.bright = light.leds.h.bright > light.const.min and light.leds.h.bright - 1 or light.bright.night

        pwm.setduty(light.leds.b.pin, light.leds.b.bright)
        pwm.setduty(light.leds.c.pin, light.leds.c.bright)
        pwm.setduty(light.leds.h.pin, light.leds.h.bright)

        tmr.delay(50)
    end
    print(light.leds.b.bright, light.leds.c.bright, light.leds.h.bright)
end

function light.sync()
    now = application.modules.time.getTime()

    local astro = application.modules.astro

    if (now.hour == astro.data.sunrise.hour and now.minute >= astro.data.sunrise.minute) or
            (now.hour > astro.data.sunrise.hour and now.hour < astro.data.sunset.hour) or
            (now.hour == astro.data.sunset.hour and now.minute <= astro.data.sunset.minute) then
        if light.phase.curr ~= "sun" then
            light.phase = { last = light.phase.curr, curr = "sun" }
        end
    elseif (now.hour == astro.data.moonrise.hour and now.minute >= astro.data.moonrise.minute) or
            (now.hour > astro.data.moonrise.hour or now.hour < astro.data.moonset.hour) or
            (now.hour == astro.data.moonset.hour and now.minute <= astro.data.moonset.minute) then
        if light.phase.curr ~= "moon" then
            light.phase = { last = light.phase.curr, curr = "moon" }
        end
    elseif light.phase.curr ~= "night" then
        light.phase = { last = light.phase.curr, curr = "night" }
    end

    tmr.unregister(application.config.props.timers.trans.id)
    tmr.alarm(application.config.props.timers.trans.id, application.config.props.timers.trans.interval, tmr.ALARM_SINGLE, light.check)
end

function light.check()
    if light.phase.last ~= light.phase.curr then
        print(light.phase.last, "->", light.phase.curr)

        light.phase.last = light.phase.curr

        if light.phase.curr == "sun" then
            light.transition.day()
        elseif light.phase.curr == "moon" then
            light.transition.moon()
        else
            light.transition.night()
        end
    end
end

function light.values()
    return {
        name = "light",
        title = "Light",
        value = {
            const = light.const,
            leds = light.leds,
            bright = light.bright,
            phase = light.phase
        }
    }
end

return function(app)
    application = app

    for i, pin in pairs({ light.leds.b.pin, light.leds.c.pin, light.leds.h.pin }) do
        pwm.setup(pin, 100, 0)
        pwm.start(pin)
    end

    application.on("modulesloaded", function ()
        light.sync()

        tmr.alarm(app.config.props.timers.light.id, app.config.props.timers.light.interval, tmr.ALARM_AUTO, light.sync)
    end)

    return light
end