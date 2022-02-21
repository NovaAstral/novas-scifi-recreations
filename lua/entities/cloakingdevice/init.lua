AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')


ENT.WireDebugName = "Cloaking Device"

function ENT:SpawnFunction(ply, tr)
	local ent = ents.Create("cloakingdevice")
	ent:SetPos(tr.HitPos + Vector(0, 0, 20))
	ent:Spawn()
	return ent 
end 

function ENT:Initialize()

	util.PrecacheModel("models/hunter/misc/cone1x05.mdl")
	util.PrecacheSound("misc/cloak_romulan.wav")
	util.PrecacheSound("misc/decloak_romulan.wav")
	
	self.Entity:SetModel("models/hunter/misc/cone1x05.mdl")
	
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	self.Entity:DrawShadow(false)
	
	local phys = self.Entity:GetPhysicsObject()
	
	self.NTime = 0
	
	if(phys:IsValid()) then
		phys:SetMass(100)
		phys:EnableGravity(true)
		phys:Wake()
	end

	self.JumpCoords = {}
	self.Inputs = WireLib.CreateSpecialInputs(self.Entity,{"Activate"})
	self.Outputs = WireLib.CreateSpecialOutputs(self.Entity,{"Active"});
end

function ENT:TriggerInput(iname, value)
	if(iname == "Activate") then
		if(value >= 1) then
			if (CurTime()-self.NTime) > 4 and !timer.Exists("wait") then
				self.NTime = CurTime()
				self.Entity:EmitSound("misc/cloak_romulan.wav",100,100)
				timer.Create("wait",1.5,1,function() end)
				timer.Create("invisible",0.5,1,function() self.Entity:SetVisible(false) end) --set this back to false later!
	
				local plys = player.GetAll()
				local ConstrainedEnts = constraint.GetAllConstrainedEntities(self.Entity)
	
				for _, ply in pairs(plys) do
					local tracedown = util.TraceLine({
						start = ply:GetPos(),
						endpos = ply:GetPos() + Vector(0,0,-200)
					})
	
					if(tracedown.Entity:IsValid()) then
						--ply:SetVisible(false)
					end
				end
			else
				self.Entity:EmitSound("buttons/combine_button_locked.wav",100,100)
			end
		else
			self.Entity:EmitSound("misc/decloak_romulan.wav",100,100)
			timer.Create("visible",0.5,1,function() self.Entity:SetVisible(true) end)
		end
	end
end


function ENT:SetVisible(visible) --Thanks to The17thDoctor for this function

	if visible == nil then --If nothing is given, visible is set to true by default.
		visible = true
	end
	
	local ConstrainedEnts = constraint.GetAllConstrainedEntities(self.Entity)
	
	for _, entity in pairs(ConstrainedEnts) do
		entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
		local color = entity:GetColor()

		if visible then
			color.a = color.a
		else
			color.a = 0
		end
		entity:SetColor(color)
	end
end

function ENT:PreEntityCopy()
	if WireAddon then
		duplicator.StoreEntityModifier(self,"WireDupeInfo",WireLib.BuildDupeInfo(self.Entity))
	end
end

function ENT:PostEntityPaste(ply, ent, createdEnts)
	if WireAddon then
		local emods = ent.EntityMods
		if not emods then return end
		WireLib.ApplyDupeInfo(ply, ent, emods.WireDupeInfo, function(id) return createdEnts[id] end)
	end
end

function ENT:OnRemove()
	timer.Remove("wait")
	timer.Remove("visible")
	timer.Remove("invisible")
	timer.Remove("soundwait")
	self.Entity:StopSound("misc/cloak_romulan.wav")
	self.Entity:StopSound("misc/decloak_romulan.wav")
end
