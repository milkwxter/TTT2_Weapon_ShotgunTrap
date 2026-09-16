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
	
	local healthConvar = GetConVar("ttt2_shotguntrap_default_health"):GetInt()
	self:SetHealth(healthConvar)

    if SERVER then
        self:SetMaxHealth(healthConvar)
		
		local ammo = GetConVar("ttt2_shotguntrap_default_ammo"):GetInt()
		self:SetNWInt("shotguntrap_ammo", ammo or 10)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(250)
        end
		
		self.MuzzleOffset = self:GetPos() + Vector(0, 0, 60) + (self:GetForward() * 50)
    end
end

if SERVER then
	-- shoot people
	function ENT:Think()
		-- stop shooting if ammo is enabled and out of ammo
		if GetConVar("ttt2_shotguntrap_enable_ammo"):GetBool() and self:GetCurrentAmmo() <= 0 then return end
		
		-- next think happens after this time
		self:NextThink( CurTime() + 0.5 )
		
		-- shotgun trap scans area in front of it to find a player
		local muzzlePos = self.MuzzleOffset
		local dir = self:GetForward()
		local range = 200
		local angle = 0.8
		for _, ent in ipairs(ents.FindInCone(muzzlePos, dir, range, angle)) do
			if not ent:IsValid() then continue end
			if ent:IsPlayer() and ent:IsActive() then
				-- return early and shoot pellets if we find ANYONE AT ALL
				self:ShootAtPlayer()
				return true
			end
		end
		
		return true
	end
	
	-- le bullet function
	function ENT:ShootAtPlayer()
		-- get convar
		local damageConvar = GetConVar("ttt2_shotguntrap_bullet_damage"):GetInt()
		
		-- create the bullet table
		local bullet = {}
		bullet.Num = 25
		bullet.Src = self.MuzzleOffset
		bullet.Dir = self:GetForward()
		bullet.Spread = Vector(0.67, 0.67, 0)
		bullet.Distance = 300
		bullet.Damage = damageConvar
		bullet.Tracer = 1
		bullet.TracerName = "shotgun_trap_tracer"
		bullet.Force = 10
		bullet.HullSize = 0
		
		-- fire it
		self:FireBullets(bullet)
		
		-- sound effect
		self:EmitSound("milkwater/shotgun_trap_gunshot.wav")
		
		-- deduct ammo if needed
		if GetConVar("ttt2_shotguntrap_enable_ammo"):GetBool() then
			self:DeductAmmo()
		end
	end
	
	-- network var so clients can see ammo
    function ENT:DeductAmmo()
		local ammo = self:GetNWInt("shotguntrap_ammo", 0)
		ammo = ammo - 1
        self:SetNWInt("shotguntrap_ammo", ammo)
    end
end

-- shared getter for ammo
function ENT:GetCurrentAmmo()
    return self:GetNWInt("shotguntrap_ammo", 0)
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
        tData:SetOutlineColor(Color(255, 0, 0))
		
		-- name of entity
        tData:SetTitle(TryT(ent.PrintName))
        
		-- traitors can see ammo left
		local ammoEnabled = GetConVar("ttt2_shotguntrap_enable_ammo"):GetBool()
		if ammoEnabled then
			if client:GetRealTeam() == TEAM_TRAITOR then
				tData:AddDescriptionLine(ParT("ttt2_label_shotgun_trap_targetid_ammo", {ammo = ent:GetCurrentAmmo()}))
			end
		end
		
		-- everyone can see current health of trap
		tData:AddDescriptionLine(ParT("ttt2_label_shotgun_trap_targetid_health", {health = ent:Health()}))
    end)
end
