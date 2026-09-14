if SERVER then
	AddCSLuaFile()
end

DEFINE_BASECLASS("weapon_tttbase")

SWEP.HoldType = "normal"

if CLIENT then
    SWEP.PrintName = "Shotgun Trap"
    SWEP.Slot = 2

    SWEP.ViewModelFlip = false
    SWEP.ViewModelFOV = 69

    SWEP.Icon = "vgui/ttt/icon_shotgun_trap"
end

SWEP.Base = "weapon_tttbase"

SWEP.Kind = WEAPON_EQUIP1
SWEP.builtin = false

SWEP.CanBuy = {ROLE_TRAITOR}

SWEP.Primary.Ammo = "AirboatGun"
SWEP.Primary.Delay = 0
SWEP.Primary.Recoil = 0
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 0
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Sound = "ambient/energy/spark5.wav"

SWEP.AutoSpawnable = false
SWEP.Spawnable = false

SWEP.AllowDrop = false

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"

SWEP.EntityToSpawn = "ttt_shotgun_trap"
SWEP.EntityToSpawnsModel = "models/shotgun_trap/tur3.mdl"

local MAX_DISTANCE = 100

if SERVER then
	function SWEP:PrimaryAttack()
		if not IsValid(self.Owner) then return end
		
		local tr = self.Owner:GetEyeTrace()
		local dist = tr.StartPos:Distance(tr.HitPos)
		
		if dist > MAX_DISTANCE then return end
		
		if tr.Hit and tr.HitPos then
			self:SpawnTrap(tr.HitPos)
			self:Remove()
		end
	end

	function SWEP:SpawnTrap(pos)
		local ent = ents.Create(self.EntityToSpawn)
		if IsValid(ent) then
			ent:SetPos(pos)
			ent:SetAngles(Angle(0, self.Owner:EyeAngles().y, 0))
			ent:Spawn()
			ent:Activate()
			
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(false)
				phys:Sleep()
			end
		end
	end
end

if CLIENT then
	function SWEP:PrimaryAttack() end
	
	function SWEP:Think()
        local tr = self.Owner:GetEyeTrace()
        if tr.Hit and tr.HitPos then
            if not IsValid(self.modelPreview) then
                self.modelPreview = ClientsideModel(self.EntityToSpawnsModel)
                self.modelPreview:SetMaterial("models/debug/debugwhite")
                self.modelPreview:SetRenderMode(RENDERMODE_TRANSALPHA)
            end
			
			local dist = tr.StartPos:Distance(tr.HitPos)
			
			if dist > MAX_DISTANCE then
				self.modelPreview:SetColor(Color(255, 0, 0, 150))
			else
				self.modelPreview:SetColor(Color(0, 255, 255, 150))
			end
			
            self.modelPreview:SetPos(tr.HitPos)
            self.modelPreview:SetAngles(Angle(0, self.Owner:EyeAngles().y, 0))
        end
    end
	
	function SWEP:Holster()
		if IsValid(self.modelPreview) then
			self.modelPreview:Remove()
		end
		return true
	end

	function SWEP:OnRemove()
		if IsValid(self.modelPreview) then
			self.modelPreview:Remove()
		end
	end
end