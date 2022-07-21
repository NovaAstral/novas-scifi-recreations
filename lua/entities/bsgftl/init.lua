AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')


ENT.WireDebugName = "FTL Drive"

function ENT:SpawnFunction(ply, tr)
	local ent = ents.Create("bsgftl")
	ent:SetPos(tr.HitPos + Vector(0, 0, 20))
	ent:Spawn()
	return ent 
end 

-- This was originally the SBEP Warp Drive.
-- Thought it would be easier to just gut it instead of doing everything that I don't know how yet

function ENT:Initialize()

	util.PrecacheModel("models/hunter/misc/cone1x05.mdl")
	util.PrecacheSound("ftldrives/ftl_in.wav")
	util.PrecacheSound("ftldrives/ftl_out.wav")
	
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
	self.Inputs = WireLib.CreateSpecialInputs(self.Entity,{"Warp","Destination"},{[2] = "VECTOR"}); 
end

function ENT:TriggerInput(iname, value)
	if(iname == "Destination") then
		self.JumpCoords.Vec = value
	elseif(iname == "Warp" and value >= 1) then
		self.JumpCoords.Dest = self.JumpCoords.Vec

		if (CurTime()-self.NTime) > 4 and !timer.Exists("wait") and self.JumpCoords.Dest ~= self.Entity:GetPos() and util.IsInWorld(self.JumpCoords.Dest) then
			self.NTime=CurTime()
			self.Entity:EmitSound("ftldrives/ftl_in.wav",100,100)
			timer.Create("wait",1.5,1,function() self.Entity:Jump() end, self)
			timer.Create("invisible",0.8,1,function() self.Entity:SetVisible(true) end) --set this back to false later!
			timer.Create("visible",2.5,1,function() self.Entity:SetVisible(true) end)

			local plys = player.GetAll()
			local ConstrainedEnts = constraint.GetAllConstrainedEntities(self.Entity)

			for _, ply in pairs(plys) do
				local tracedown = util.TraceLine({
					start = ply:GetPos(),
					endpos = ply:GetPos() + Vector(0,0,-200)
				})

				if(tracedown.Entity:IsValid()) then
					local const = constraint.Find(tracedown.Entity,self.Entity)
					print(const)

					if(const:IsValid()) then --This will never trigger because const is always nil (it also lua errors)
						PlyPos = tracedown.Entity:WorldToLocal(ply:GetPos())
						--ply:Lock()
						ply:SetParent(tracedown.Entity,-1)
						timer.Create("move", 3, 1, function() ply:UnLock() ply:SetParent(nil,-1) end)
						--timer.Create("plytp", 1.6, 1, function() ply:SetPos(tracedown.Entity:LocalToWorld(PlyPos)) end)
					end
				end
			end
		else
			self.Entity:EmitSound("buttons/combine_button_locked.wav",100,100)
		end
	end
end

function ENT:Jump()
	local WarpDrivePos = self.Entity:GetPos()
	local ConstrainedEnts = constraint.GetAllConstrainedEntities(self.Entity)

	timer.Create("soundwait",0.2,1,function() self.Entity:EmitSound("ftldrives/ftl_out.wav",100,100) end)


	for _, entity in pairs(ConstrainedEnts) do	
		if(IsValid(entity)) then
			self:SharedJump(entity)
		end
	end
-- CAP energy weps are probably sprites, go look at those
	local pos,material = self.Entity:GetPos(),Material("sprites/splodesprite")
	hook.Add("HUDPaint","paintsprites",function()
		cam.Start3D()
			render.SetMaterial(material)
			render.DrawSprite(pos,16,16,color_white) -- Draw the sprite in the middle of the map, at 16x16 in it's original colour with full alpha.
		cam.End3D()
	end)
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

function ENT:SetVisible(visible) --Thanks to The17thDoctor for this function

	if visible == nil then visible = true end --If nothing is given, visible is set to true by default.
	local ConstrainedEnts = constraint.GetAllConstrainedEntities(self.Entity)
	 
	for _, entity in pairs(ConstrainedEnts) do --this is a bad way to do this, it doesn't save the current rendermodes/alphas
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

--[[
function ENT:MakeSprite()
	local pos,material = Vector(0, 0, 0), Material( "sprites/splodesprite" )

	hook.Add("HUDPaint", "paintsprites", function()
  	pos = pos + Vector(1, 0, 0) * RealFrameTime()
  	cam.Start3D()
  	render.SetMaterial(material)
  	render.DrawSprite( pos, 16, 16, color_white)
  	cam.End3D()
end)
end
--]]

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
	self.Entity:StopSound("ftldrives/ftl_in.wav")
	self.Entity:StopSound("ftldrives/ftl_out.wav")
end
