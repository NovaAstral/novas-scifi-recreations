AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "SBEP Drive"

function ENT:SpawnFunction(ply, tr)
	local ent = ents.Create("sbepdrive")
	ent:SetPos(tr.HitPos + Vector(0,0,0))
	ent:Spawn()

	return ent
end 

-- This is modified from the SBEP Warp Drive

function ENT:Initialize()
	util.PrecacheModel("models/Slyfo/ftl_drive.mdl")
	util.PrecacheSound("warp drives/sbep_warp.mp3")
	util.PrecacheSound("warp drives/warp_error.mp3")

	self.Entity:SetModel("models/Slyfo/ftl_drive.mdl")

	timer.Simple(0,function() -- Because Creator doesn't get set until after init >:(
		if(self.Entity:GetModel() ~= "models/slyfo/ftl_drive.mdl") then -- GetModel returns entirely lowercase
			self.Entity:GetCreator():SendLua("GAMEMODE:AddNotify(\"You must install Spacebuild Enhancement Pack (SBEP)!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
			self.Entity:Remove()
			return
		end
	end)


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
	self.Inputs = WireLib.CreateSpecialInputs(self.Entity,{"Warp","Destination"},{[2] = "VECTOR"}); 
end

function ENT:TriggerInput(iname, value)
	if(iname == "Destination") then
		self.JumpCoords.Vec = value
	elseif(iname == "Warp" and value >= 1) then
		self.JumpCoords.Dest = self.JumpCoords.Vec

		if (CurTime()-self.NTime) > 3 and !timer.Exists("wait") and self.JumpCoords.Dest ~= self.Entity:GetPos() and util.IsInWorld(self.JumpCoords.Dest) then
			self.NTime=CurTime()
			self.Entity:EmitSound("warp drives/sbep_warp.mp3",100,100)
			
			timer.Create("wait",0.5,1,function() self.Entity:Jump() end, self)

			for _, ply in pairs(player.GetAll()) do
				local tracedown = util.TraceLine({
					start = ply:GetPos(),
					endpos = ply:GetPos() + Vector(0,0,-200)
				})

				if(tracedown.Entity:IsValid()) then
					local ConstrainedEnts = constraint.GetAllConstrainedEntities(self.Entity)

					if ConstrainedEnts[tracedown.Entity] ~= nil then
						PlyPos = tracedown.Entity:WorldToLocal(ply:GetPos())

						timer.Create("plytp", 0.52, 1, function() 
							ply:SetPos(tracedown.Entity:LocalToWorld(PlyPos)) 
						end)
					end
				end
			end
		else
			self.Entity:EmitSound("warp drives/warp_error.mp3",100,100)
		end
	end
end

function ENT:Jump()
	local WarpDrivePos = self.Entity:GetPos()
	local ConstrainedEnts = constraint.GetAllConstrainedEntities(self.Entity)

	for _, entity in pairs(ConstrainedEnts) do	
		if(IsValid(entity)) then
			self:SharedJump(entity)
		end
	end
end

function ENT:SharedJump(ent)
	local WarpDrivePos = self.Entity:GetPos()
	local phys = ent:GetPhysicsObject()

	if !(ent:IsPlayer() or ent:IsNPC()) then 
		ent=phys
	end

	if(!phys:IsMoveable()) then
		phys:EnableMotion(true)
		phys:EnableMotion(false)
	end

	ent:SetPos(self.JumpCoords.Dest + (ent:GetPos() - WarpDrivePos))

	phys:Wake()
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
	self.Entity:StopSound("")
	self.Entity:StopSound("")
end
