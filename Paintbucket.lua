-----------------------------------------------------------------------------------------------
-- Client Lua Script for Paintbucket
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Paintbucket Module Definition
-----------------------------------------------------------------------------------------------
local Paintbucket = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Paintbucket:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.colorshift = 0
	self.landlord = false
	self.previewMode = false
	self.active = false

    return o
end

function Paintbucket:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Paintbucket OnLoad
-----------------------------------------------------------------------------------------------
function Paintbucket:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Paintbucket.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	Apollo.LoadSprites("BucketSprite.xml")
end

-----------------------------------------------------------------------------------------------
-- Paintbucket OnDocLoaded
-----------------------------------------------------------------------------------------------
function Paintbucket:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "PaintbucketForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("pb", "OnPaintbucketOn", self)
		Apollo.RegisterEventHandler("HousingFreePlaceDecorSelected", 	"OnFreePlaceDecorSelected", self)
		
		local wndColorShiftFrame = self.wndMain:FindChild("ColorShiftFrame")
		
		self.wndColorLabel = self.wndMain:FindChild("ColorName")
		
		self.colorButtons = {}
		
		local colorOptions = HousingLib.GetDecorColorOptions()
		for idx, tColorShift in pairs(colorOptions) do
			local wndEntry = Apollo.LoadForm(self.xmlDoc, "ColorShiftEntry", wndColorShiftFrame, self)
			local wndSwatch = wndEntry:FindChild("Swatch")
			wndSwatch:SetData(tColorShift)
			wndSwatch:SetSprite(tColorShift.strPreviewSwatch)
			local wndButton = wndEntry:FindChild("Button")
			wndButton:SetData(tColorShift)
			wndButton:SetTooltip(tColorShift.strName)
			self.colorButtons[tColorShift.id] = wndButton
		end
		local nHeight = wndColorShiftFrame:ArrangeChildrenTiles()
		--local nLeft, nTop, nRight, nBottom = wndColorShiftFrame:GetAnchorOffsets()
		--wndColorShiftFrame:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
		
		
		-- decor:GetDecorColor() gives decor's colorshift
		-- window:EnsureChildVisible(element) scrolls to that element
		
		
		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- Paintbucket Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/pb"
function Paintbucket:OnPaintbucketOn()
	self.wndMain:Invoke() -- show the window
end

function Paintbucket:OnFreePlaceDecorSelected(decorSelection)
	if self.landlord then
		self:Paint()
	else
		self:SetDecorPreview()
	end
end


-----------------------------------------------------------------------------------------------
-- PaintbucketForm Functions
-----------------------------------------------------------------------------------------------

function Paintbucket:OnColourPick( wndHandler, wndControl, eMouseButton )
	local dec = self:GetSelectedDecor()
	if dec == nil then return end
	
	self:SetColor(dec:GetDecorColor())
	self:SetColorButton(self.colorshift)
end

function Paintbucket:OnPaint( wndHandler, wndControl, eMouseButton )
	self:Paint()
end

function Paintbucket:Paint()
	local dec = self:GetSelectedDecor()
	if dec == nil then return end
	
	if dec:GetDecorColor() ~= self.colorshift then
		local sendCommand = string.format("/c house decor paint %s %s", dec:GetId(), self.colorshift)
		ChatSystemLib.Command(sendCommand)
	end
end

function Paintbucket:SetColorButton(id)
	for idx, wndEntry in pairs(self.colorButtons) do
		wndEntry:SetCheck(idx == id)
	end
end

function Paintbucket:OnLandlordOn( wndHandler, wndControl, eMouseButton )
	self.landlord = true
end

function Paintbucket:OnLandlordOff( wndHandler, wndControl, eMouseButton )
	self.landlord = false
end

function Paintbucket:OnPreviewModeOn( wndHandler, wndControl, eMouseButton )
	self.previewMode = true
	self:SetDecorPreview()
end

function Paintbucket:OnPreviewModeOff( wndHandler, wndControl, eMouseButton )
	self.previewMode = false
	self:ClearDecorPreview()
end

function Paintbucket:OnClose( wndHandler, wndControl )
	self.active = false
	self:ClearDecorPreview()
end

function Paintbucket:OnOpen( wndHandler, wndControl )
	self.active = true
	self:SetDecorPreview()
end

function Paintbucket:OnCloseButton( wndHandler, wndControl, eMouseButton )
	self.wndMain:Close()
end

---------------------------------------------------------------------------------------------------
-- ColorShiftEntry Functions
---------------------------------------------------------------------------------------------------

function Paintbucket:OnColorSelected( wndHandler, wndControl, eMouseButton )
	self:SetColor(wndControl:GetData().id)
	self:SetColorButton(self.colorshift)
end

function Paintbucket:OnColorUncheck( wndHandler, wndControl, eMouseButton )
	if wndControl:GetData().id == self.colorshift then
		self:SetColor(0)
		self:SetColorButton(0)
	end
end

function Paintbucket:GetSelectedDecor()
	local res = HousingLib.GetResidence()
	if res == nil then return nil end
	local dec = res:GetSelectedDecor()
	if dec == nil or dec:IsPreview() then return nil end
	return dec
end

function Paintbucket:SetColor(color)
	self.colorshift = color
	
	local cs = HousingLib.GetDecorColorInfo(color)
	if cs ~= nil then
		self.wndColorLabel:SetText(cs.strName)
	else
		self.wndColorLabel:SetText("Uncoloured")
	end
	
	self:SetDecorPreview()
end

function Paintbucket:SetDecorPreview()
	local dec = self:GetSelectedDecor()
	if dec ~= nil and self.previewMode and self.active then
		dec:SetColor(self.colorshift)
	end
end

function Paintbucket:ClearDecorPreview()
	local dec = self:GetSelectedDecor()
	if dec ~= nil then
		if dec:GetDecorColor() == self.colorshift then
			dec:SetColor(dec:GetSavedDecorColor())
		end
	end
end

function Paintbucket:PrintTable(table)
	if type(table) == "userdata" then table = getmetatable(table) end
	for k, v in pairs(table) do
		if type(v) == "table" then Print(k .. ": table")
		elseif type(v) == "userdata" then Print(k .. ": userdata")
		elseif type(v) == "boolean" then Print(k .. ": boolean")
		elseif type(v) == "function" then Print(k .. ": function")
		else Print(k .. ": " .. v) end
	end
end

-----------------------------------------------------------------------------------------------
-- Paintbucket Instance
-----------------------------------------------------------------------------------------------
local PaintbucketInst = Paintbucket:new()
PaintbucketInst:Init()
