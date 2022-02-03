include('shared.lua')

language.Add( "Cleanup_bsgftldrive", "Cloaking Device")
language.Add( "Cleaned_bsgftldrive", "Cleaned up Cloaking Device")

function ENT:Draw()
   self:DrawEntityOutline( 0.0 )
   self.Entity:DrawModel()	
end

function ENT:DrawEntityOutline()
return
end
