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
	-- Landlord mode
end


-----------------------------------------------------------------------------------------------
-- PaintbucketForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function Paintbucket:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function Paintbucket:OnCancel()
	self.wndMain:Close() -- hide the window
end


function Paintbucket:OnColourPick( wndHandler, wndControl, eMouseButton )
	local res = HousingLib.GetResidence()
	if res == nil then return end
	local dec = res:GetSelectedDecor()
	if dec == nil then return end
	
	self.colorshift = dec:GetDecorColor()
	self:SetColorButton(self.colorshift)
end

function Paintbucket:OnPaint( wndHandler, wndControl, eMouseButton )
	local res = HousingLib.GetResidence()
	if res == nil then return end
	local dec = res:GetSelectedDecor()
	if dec == nil then return end
	
	local sendCommand = string.format("/c house decor paint %s %s", dec:GetId(), self.colorshift)
	ChatSystemLib.Command(sendCommand)
end

function Paintbucket:SetColorButton(id)
	for idx, wndEntry in pairs(self.colorButtons) do
		wndEntry:SetCheck(idx == id)
	end
end

---------------------------------------------------------------------------------------------------
-- ColorShiftEntry Functions
---------------------------------------------------------------------------------------------------

function Paintbucket:OnColorSelected( wndHandler, wndControl, eMouseButton )
	self.colorshift = wndControl:GetData().id
	self:SetColorButton(self.colorshift)
end

function Paintbucket:OnColorUncheck( wndHandler, wndControl, eMouseButton )
	self:SetColorButton(self.colorshift)
end

-----------------------------------------------------------------------------------------------
-- Paintbucket Instance
-----------------------------------------------------------------------------------------------
local PaintbucketInst = Paintbucket:new()
PaintbucketInst:Init()
