
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Homeworld Hyperdrive"

function ENT:SpawnFunction( ply, tr )
	local ent = ents.Create("hwhyperdrive")
	ent:SetPos(tr.HitPos + Vector(0, 0, 20))
	ent:Spawn()
	return ent 
end 

-- This was originally the SBEP Warp Drive.
-- Thought it would be easier to just gut it instead of doing everything that I don't know how yet

function ENT:Initialize()

	util.PrecacheModel( "models/hunter/misc/cone1x05.mdl" )
	util.PrecacheSound( "hyperdrive/hyper_in.wav" )
	util.PrecacheSound("hyperdrive/hyper_out.wav")
	
	self.Entity:SetModel( "models/hunter/misc/cone1x05.mdl" )
	
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	self.Entity:DrawShadow(false)
	
	local phys = self.Entity:GetPhysicsObject()
	
	self.NTime = 0
	
	if ( phys:IsValid() ) then 
		phys:SetMass( 100 )
		phys:EnableGravity( true )
		phys:Wake() 
	end

	self.JumpCoords = {}
	self.SearchRadius = 100
	self.Constrained = 1
	self.Inputs = WireLib.CreateSpecialInputs( self.Entity, { "Warp", "Destination"}, { [2] = "VECTOR"} ); 
end

function ENT:TriggerInput(iname, value)
	if(iname == "Destination") then
		self.JumpCoords.Vec = value
	elseif( iname == "Warp" and value >= 1 ) then
		self.JumpCoords.Dest = self.JumpCoords.Vec

		if (CurTime()-self.NTime)>7 and !timer.Exists( "warpdrivewaittime" ) and self.JumpCoords.Dest~=self.Entity:GetPos() and util.IsInWorld(self.JumpCoords.Dest) then
			self.NTime=CurTime()
			self.Entity:EmitSound("hyperdrive/hyper_in.wav",100,100)
			timer.Create("warpdrivewaittime", 10, 1, function()
			self.Entity:Go()
			timer.Destroy("warpdrivewaittime")
		end, self)
	else self.Entity:EmitSound("buttons/combine_button_locked.wav",100,100) end
end
end

function ENT:Go()
	local WarpDrivePos = self.Entity:GetPos()
	
	if(self.Constrained == 1) then
		self.DoneList = {}
		self.ConstrainedEnts = ents.FindInSphere( self.Entity:GetPos() , self.SearchRadius)
		for _, v in pairs(self.ConstrainedEnts) do
			if v:IsValid() and !self.DoneList[v] then
				self.ToTele = constraint.GetAllConstrainedEntities(v)
				for ent,_ in pairs(self.ToTele)do
					if not (ent.BaseClass and ent.BaseClass.ClassName=="stargate_base" and ent:OnGround()) then
						if ent:IsValid() and ( ent:GetMoveType()==6 or ent:IsPlayer() or ent:IsNPC() ) then
							self.DoneList[ent]=ent
							self:SharedJump(ent)
						end
					end
				end
			end
		end
	else
		self.ConstrainedEnts = constraint.GetAllConstrainedEntities(self.Entity)
		local Peeps = player.GetAll()
		for _, k in pairs(Peeps) do
			if(k:GetPos():Distance(self.Entity:GetPos()) <= self.SearchRadius ) then
				self:SharedJump(k)
			end
		end
		for _, ent in pairs(self.ConstrainedEnts) do
			self:SharedJump(ent)
		end
	end
end

function ENT:SharedJump(ent)
local WarpDrivePos = self.Entity:GetPos()
	local phys = ent:GetPhysicsObject()
	if !(ent:IsPlayer() or ent:IsNPC()) then DoPropSpawnedEffect( ent ) ent=phys end
	ent:SetPos(self.JumpCoords.Dest + (ent:GetPos() - WarpDrivePos) + Vector(0,0,10))
	if(!phys:IsMoveable())then
		phys:EnableMotion(true)
		phys:EnableMotion(false)
	end 
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
	timer.Remove("warpdrivewaittime")
	self.Entity:StopSound("hyperdrive/hyper_in.wav")
	self.Entity:StopSound("hyperdrive/hyper_out.wav")
end
