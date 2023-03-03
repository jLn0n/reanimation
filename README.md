# reanimation

reanimation script becus bored
this repo is now archived because of recent changes of roblox

## Script

```lua
local config = {
	Velocity = Vector3.xAxis * -30.05, -- velocity, doesn't get applied when `UseBuiltinNetless` is false
	UseBuiltinNetless = true
}
getgenv().ReanimationAPI = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/jLn0n/reanimation/main/r6-permadeath.lua"))(config)
```

## TODOs

- [ ] Create bot, semi-bot, and other things
- [ ] Modularize this thing
