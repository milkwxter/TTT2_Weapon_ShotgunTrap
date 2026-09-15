if SERVER then
    AddCSLuaFile()
end

DEFINE_BASECLASS("ttt_base_placeable")

if CLIENT then
    ENT.Icon = "vgui/ttt/icon_shotgun_trap"
    ENT.PrintName = "ttt_label_shotgun_trap_name"
end

ENT.Base = "ttt_base_placeable"
ENT.Model = "models/shotgun_trap/tur3.mdl"

ENT.CanHavePrints = false

function ENT:Initialize()
    self:SetModel(self.Model)

    BaseClass.Initialize(self)

    local b = 32

    self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b, b, b))

    if SERVER then
        self:SetMaxHealth(250)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(250)
        end

        self:SetUseType(SIMPLE_USE)
    end
end

if SERVER then
	-- shoot people
	function ENT:Think()
		self:NextThink( CurTime() + 0.5 )
		
		local muzzlePos = self:GetPos()
		local dir = self:GetForward()
		local range = 200
		local angle = 0.8
		for _, ent in ipairs(ents.FindInCone(muzzlePos, dir, range, angle)) do
			if not ent:IsValid() then continue end
			if ent:IsPlayer() and ent:IsActive() then
				self:ShootAtPlayer()
				return true
			end
		end
		
		return true
	end
	
	-- le bullet function
	function ENT:ShootAtPlayer()
		local shootFromHere = self:GetPos() + Vector(0, 0, 60) + (self:GetForward() * 50)
		local bullet = {}
		bullet.Num = 25
		bullet.Src = shootFromHere
		bullet.Dir = self:GetForward()
		bullet.Spread = Vector(0.67, 0.67, 0)
		bullet.Distance = 300
		bullet.Damage = 16
		bullet.Tracer = 1
		bullet.TracerName = "shotgun_trap_tracer"
		bullet.Force = 10
		bullet.HullSize = 0
		self:FireBullets(bullet)
		self:EmitSound("milkwater/shotgun_trap_gunshot.wav")
	end
end

if CLIENT then
    local TryT = LANG.TryTranslation
    local ParT = LANG.GetParamTranslation

    -- handle looking at the trap
    hook.Add("TTTRenderEntityInfo", "HUDDrawTargetID_ShotgunTrap", function(tData)
        local client = LocalPlayer()
        local ent = tData:GetEntity()
		
        if
            not IsValid(client)
            or not client:IsTerror()
            or not client:Alive()
            or not IsValid(ent)
            or tData:GetEntityDistance() > 100
            or ent:GetClass() ~= "ttt_shotgun_trap"
        then
            return
        end

        -- enable targetID rendering
        tData:EnableText()
        tData:EnableOutline()
        tData:SetOutlineColor(Color(255, 0, 0 ))
		
		-- name of entity
        tData:SetTitle(TryT(ent.PrintName))
        
		-- traitors can see ammo left
		local clientTeam = client:GetRealTeam()
		if clientTeam == TEAM_TRAITOR then
			tData:AddDescriptionLine(ParT("ttt2_label_shotgun_trap_targetid_ammo", {ammo = "TODO"}))
		end
		
		-- everyone can see current health of trap
		tData:AddDescriptionLine(ParT("ttt2_label_shotgun_trap_targetid_health", {health = ent:Health()}))
    end)
end
