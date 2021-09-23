include('shared.lua')

language.Add( "Cleanup_warpdrive", "FTL Drive")
language.Add( "Cleaned_warpdrive", "Cleaned up FTL Drive")

function ENT:Draw()
   self:DrawEntityOutline( 0.0 )
   self.Entity:DrawModel()	
end

function ENT:DrawEntityOutline()
return
end
