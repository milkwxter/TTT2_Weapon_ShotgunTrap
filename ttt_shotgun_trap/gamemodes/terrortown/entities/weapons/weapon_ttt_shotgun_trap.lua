if SERVER then
	AddCSLuaFile()
	
	resource.AddFile("materials/vgui/ttt/icon_shotgun_trap.vmt")
	
	-- server convars
	CreateConVar("ttt2_shotguntrap_enable_ammo", 1, { FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Enable limited ammo for the shotgun trap?", 0, 1)
	CreateConVar("ttt2_shotguntrap_default_ammo", 10, { FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Amount of ammo shotgun traps spawn with.", 1, 30)
	CreateConVar("ttt2_shotguntrap_default_health", 250, { FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Amount of health shotgun traps spawn with.", 10, 1000)
	CreateConVar("ttt2_shotguntrap_bullet_damage", 16, { FCVAR_NOTIFY, FCVAR_ARCHIVE }, "How much damage does a single pellet from the trap deal?", 1, 100)
end

DEFINE_BASECLASS("weapon_tttbase")

SWEP.HoldType = "melee"

if CLIENT then
    SWEP.PrintName = "ttt_label_shotgun_trap_name"
    SWEP.Slot = 2

    SWEP.ViewModelFlip = false
    SWEP.ViewModelFOV = 69

    SWEP.Icon = "vgui/ttt/icon_shotgun_trap"

	SWEP.EquipMenuData = {
		type = "item_weapon",
		name = "ttt_label_shotgun_trap_name",
		desc = "ttt_label_shotgun_trap_desc"
	}
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

SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"

SWEP.EntityToSpawn = "ttt_shotgun_trap"
SWEP.EntityToSpawnsModel = "models/shotgun_trap/tur3.mdl"

local MAX_DISTANCE = 100

if SERVER then
	-- remove on death or drop (no one should pick it up)
	function SWEP:OnDrop()
		self:Remove()
	end
	
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
			ent:SetOriginator(self:GetOwner())
			
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(false)
				phys:Sleep()
			end
		end
	end
end

if CLIENT then
	-- stop client from thinking we are a gun and shooting a single bullet when placing a trap
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
	
	-- hide the model preview when it makes sense
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
	
	-- ttt2 help on HUD incase you dont know how to use it
    function SWEP:Initialize()
        self:AddTTT2HUDHelp("ttt2_label_shotgun_trap_help")
        BaseClass.Initialize(self)
    end
	
	-- ttt2 f1 menu convar support
	function SWEP:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_equipment_additional")
		
		ammoEnabled = form:MakeCheckBox({
			serverConvar = "ttt2_shotguntrap_enable_ammo",
			label = "ttt2_label_shotgun_trap_convar_enable_ammo",
		})
		
		form:MakeSlider({
			serverConvar = "ttt2_shotguntrap_default_ammo",
			label = "ttt2_label_shotgun_trap_convar_ammo",
			min = 1,
			max = 30,
			decimal = 0,
			master = ammoEnabled,
		})
		
		form:MakeSlider({
			serverConvar = "ttt2_shotguntrap_default_health",
			label = "ttt2_label_shotgun_trap_convar_health",
			min = 10,
			max = 1000,
			decimal = 0,
		})
		
		form:MakeSlider({
			serverConvar = "ttt2_shotguntrap_bullet_damage",
			label = "ttt2_label_shotgun_trap_convar_bullet_damage",
			min = 1,
			max = 100,
			decimal = 0,
		})
	end
end