local ScriptEditorService = game:GetService("ScriptEditorService")
local Selection = game:GetService("Selection")
local Aegis = script.Aegis
local DumpParser = require(script.DumpParser)
local Parsed = DumpParser.fetchFromServer()

local toolbar : PluginToolbar = plugin:CreateToolbar("Aegis Converter")
local button : PluginToolbarButton = toolbar:CreateButton("Aegis Converter", "Converts To Aegis", "rbxassetid://15170444338")

local format = "Aegis.new('%s',{"

function vectorFix(v : Vector3)
	return "Vector3.new("..v.X..","..v.Y..","..v.Z..")"
end
function cfFix(v : CFrame)
	local x1, x2, x3 = v.Position.X,v.Position.Y,v.Position.Z
	local x4,x5,x6 = v:ToOrientation()
	local y1, y2 = vectorFix(Vector3.new(x1, x2, x3)), vectorFix(Vector3.new(x4,x5,x6))
	return "CFrame.new("..y1..","..y2..")"
end
function udimFix(v : UDim)
	return "UDim.new("..v.Scale..","..v.Offset..")"
end
function udim2Fix(v : UDim2)
	return "UDim2.new("..v.X.Scale..","..v.X.Offset..","..v.Y.Scale..","..v.Y.Offset..")"
end
function color3Fix(v : Color3)
	return "Color3.new("..v.R..","..v.G..","..v.B..")"
end
function nameCheck(name : string, cache : {})
	table.insert(cache, name)
	local count = 0
	for _, v in pairs(cache) do
		if v == name then count += 1 end
	end
	return name..tostring(count)
end

button.Click:Connect(function()
	local total = {Selection:Get()[1], table.unpack(Selection:Get()[1]:GetDescendants())}
	local outputScript = Instance.new("Script", workspace)
	local finishedStrings = {}
	local nameCache = {}
	local finalOutput = ""
	
	outputScript.Name = "result"
	Aegis:Clone().Parent = outputScript
	
	for index, current : Instance in pairs(total) do
		local dump  = Parsed:GetChangedProperties(current)

		if dump ~= nil then
			local template : Instance = Instance.new(current.ClassName)
			local finalName = nameCheck(current.Name, nameCache)				
			local finishedConstructor : string = "local "..finalName.." = "..string.format(format, current.ClassName)
			
			for _, p : {Name : string} in pairs(dump) do
				
				p = p.Name
				
				if (tostring(template[p]) ~= tostring(current[p])) then
					local property = current[p]
					
					if typeof(current[p]) == "Instance" then property = property:GetFullName() end
					if typeof(current[p]) == "string" then property = "'"..current[p].."'" end
					if typeof(current[p]) == "Vector3" then property = vectorFix(current[p]) end
					if typeof(current[p]) == "CFrame" then property = cfFix(current[p]) end
					if typeof(current[p]) == "UDim2" then property = udim2Fix(current[p]) end
					if typeof(current[p]) == "UDim" then property = udimFix(current[p]) end
					if typeof(current[p]) == "Color3" then property = color3Fix(current[p]) end
					if p == "FontFace" then property = "Font.new('"..current.FontFace.Family.."')" end
					if tostring(property) == "inf" then property = "Vector3.new(math.huge(), math.huge(), math.huge())" end

					local newString : string = p.. " = ".. tostring(property)..";"
					finishedConstructor = finishedConstructor.."\n\t".. newString
				end			
			end
			
			finishedConstructor = finishedConstructor .."\n".. "})"
			table.insert(finishedStrings, finishedConstructor)
		end
	end
	
	finalOutput = "local Aegis = require(script.Aegis)\n"..finalOutput
	
	for _, constructor : string in pairs(finishedStrings) do
		finalOutput = finalOutput .."\n" .. constructor
	end
	
	ScriptEditorService:UpdateSourceAsync(outputScript, function()	return finalOutput end)		
	ScriptEditorService:OpenScriptDocumentAsync(outputScript)
end)

