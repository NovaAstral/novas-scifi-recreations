include('shared.lua')

language.Add( "Cleanup_transporterpad", "Transporter Pad")
language.Add( "Cleaned_transporterpad", "Cleaned up Transporter Pad")

function ENT:Draw()
   self:DrawEntityOutline( 0.0 )
   self.Entity:DrawModel()	
end

function ENT:DrawEntityOutline()
return
end
