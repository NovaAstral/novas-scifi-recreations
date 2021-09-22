include('shared.lua')

language.Add( "Cleanup_warpdrive", "Homeworld Hyperdrive")
language.Add( "Cleaned_warpdrive", "Cleaned up Homeworld Hyperdrive")

function ENT:Draw()
   self:DrawEntityOutline( 0.0 )
   self.Entity:DrawModel()	
end

function ENT:DrawEntityOutline()
return
end
