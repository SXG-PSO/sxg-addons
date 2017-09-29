local core_mainmenu = require("core_mainmenu")
local cfg = require("registers.configuration")
local lib_theme_loaded, lib_theme = pcall(require, "Theme Editor.theme")
local optionsLoaded, options = pcall(require, "registers.options")
local optionsFileName = "addons/registers/options.lua"
local firstPresent = true
local ConfigurationWindow
local RegisterPtr = 0x00A954B0

if optionsLoaded then
  options.configurationEnableWindow = options.configurationEnableWindow == nil and true or options.configurationEnableWindow
  options.enable = options.enable == nil and true or options.enable
  options.EnableWindow = options.EnableWindow == nil and true or options.EnableWindow
  options.useCustomTheme = options.useCustomTheme == nil and false or options.useCustomTheme
  options.NoTitleBar = options.NoTitleBar or ""
  options.NoResize = options.NoResize or ""
  options.Transparent = options.Transparent == nil and false or options.Transparent
  options.fontScale = options.fontScale or 1.0
  options.X = options.X or 100
  options.Y = options.Y or 100
  options.Width = options.Width or 150
  options.Height = options.Height or 80
  options.showDecimal = options.showDecimal or false
  options.Changed = options.Changed or false
else
  options = {
    configurationEnableWindow = true,
    enable = true,
    EnableWindow = true,
    useCustomTheme = false,
    NoTitleBar = "",
    NoResize = "",
    Transparent = false,
    fontScale = 1.0,
    X = 100,
    Y = 100,
    Width = 1100,
    Height = 575,
    showDecimal = true,
	Changed = false
	}
end

local function SaveOptions(options)
  local file = io.open(optionsFileName, "w")
  if file ~= nil then
    io.output(file)

    io.write("return {\n")
    io.write(string.format("  configurationEnableWindow = %s,\n", tostring(options.configurationEnableWindow)))
    io.write(string.format("  enable = %s,\n", tostring(options.enable)))
    io.write("\n")
    io.write(string.format("  EnableWindow = %s,\n", tostring(options.EnableWindow)))
    io.write(string.format("  useCustomTheme = %s,\n", tostring(options.useCustomTheme)))
    io.write(string.format("  NoTitleBar = \"%s\",\n", options.NoTitleBar))
    io.write(string.format("  NoResize = \"%s\",\n", options.NoResize))
    io.write(string.format("  Transparent = %s,\n", tostring(options.Transparent)))
    io.write(string.format("  fontScale = %s,\n", tostring(options.fontScale)))
    io.write(string.format("  X = %s,\n", tostring(options.X)))
    io.write(string.format("  Y = %s,\n", tostring(options.Y)))
    io.write(string.format("  Width = %s,\n", tostring(options.Width)))
    io.write(string.format("  Height = %s,\n", tostring(options.Height)))
	io.write(string.format("  showDecimal = %s,\n", tostring(options.showDecimal)))
    io.write(string.format("  Changed = %s,\n", tostring(options.Changed)))
    io.write("}\n")

    io.close(file)
  end
end

local function readReg()
	RegAddr = pso.read_u32(RegisterPtr)
	imgui.Columns(8)
	local numRows = 31 --is actually 32 rows
	local currentRow = 0
	local currentColumn = 0
	if RegAddr ~= 0 then
		for index=0,255 do
			local offsetTarget = index*4
			local printValue = string.format("---")
			local thisregister = pso.read_u32(RegAddr + offsetTarget)
			local displayIndex = string.format("R%i",index)
			if index <10 then
				displayIndex = string.format("  R%i",index)
			end
			if index >=10 and index <100 then
				displayIndex = string.format(" R%i",index)
			end			
			--always displays an index number so the list doesnt move around
			imgui.TextColored(1.0, 0.4, 0.0, 1.0, displayIndex)
			imgui.SameLine()

			if thisregister >=0 then				
				if thisregister >65000 then 
					--print out the register if it's a crazy number
					printValue = string.format("%0X", thisregister)
					imgui.TextColored(1.0,1.0,0.0,1.0, printValue)
				else
					printValue = string.format('%08X', thisregister)
					--Makes non-zero registers green
					if thisregister > 0 then
						imgui.TextColored(0.0,1.0,0.0,1.0, printValue)
						if options.showDecimal == true then
							imgui.SameLine()
							local printDecimal = string.format(": %i",thisregister)
							imgui.TextColored(0.0,1.0,0.0,1.0, printDecimal)
						end
					else
						--makes 0 values turn grey
						imgui.TextColored(0.5,0.5,0.5,1.0, printValue)
					end
				end				
			else
				--print register if for whatever reason a register doesnt fit any defined numbers
				printValue = string.format("%0X",thisregister) 
				imgui.TextColored(1.0,1.0,0.5,1.0, printValue)
			end
			currentRow = currentRow + 1
			if currentRow > numRows then
				imgui.NextColumn()
				currentRow = 0
				currentColumn = currentColumn + 1
			end
			--imgui.

		end
	end
end

-- config setup and drawing
local function present()
  if options.configurationEnableWindow then
    ConfigurationWindow.open = true
    options.configurationEnableWindow = false
  end

  ConfigurationWindow.Update()
  if ConfigurationWindow.changed then
    ConfigurationWindow.changed = false
    SaveOptions(options)
  end

  if options.enable == false then
    return
  end
  
  if lib_theme_loaded and options.useCustomTheme then
    lib_theme.Push()
  end
  
  if options.Transparent == true then
    imgui.PushStyleColor("WindowBg", 0.0, 0.0, 0.0, 0.0)
  end

  if options.EnableWindow then

    if firstPresent or options.Changed then
      options.Changed = false
      
      imgui.SetNextWindowPos(options.X, options.Y, "Always")
      imgui.SetNextWindowSize(options.Width, options.Height, "Always");
    end
    
    if imgui.Begin("All Registers ", nil, { options.NoTitleBar, options.NoResize }) then
      imgui.SetWindowFontScale(options.fontScale)
	  readReg();
    end
    imgui.End()
  end
  
  if options.Transparent == true then
    imgui.PopStyleColor()
  end
  
  if lib_theme_loaded and options.useCustomTheme then
    lib_theme.Pop()
  end
  
  if firstPresent then
    firstPresent = false
  end
end


local function init()
  ConfigurationWindow = cfg.ConfigurationWindow(options, lib_theme_loaded)

  local function mainMenuButtonHandler()
    ConfigurationWindow.open = not ConfigurationWindow.open
  end

  core_mainmenu.add_button("Registers", mainMenuButtonHandler)
  
  if lib_theme_loaded == false then
    print("lib_theme couldn't be loaded")
  end
  
  return {
    name = "Registers",
    version = "0.1.0",
    author = "SXG",
    description = "Reads registers",
    present = present
  }
end

return {
  __addon = {
    init = init
  }
}