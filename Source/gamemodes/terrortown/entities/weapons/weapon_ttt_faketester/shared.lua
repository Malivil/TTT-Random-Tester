local faketesterenabled = CreateConVar("ttt_faketester_enabled", 1, {
    FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED
}, "Should the Fake Tester be enabled?")
if not faketesterenabled:GetBool() then return end
if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("shared.lua")
    util.AddNetworkString("ft result")
    util.AddNetworkString("ft failed")
    resource.AddFile("materials/VGUI/ttt/icon_randomtest.vmt")
else
    SWEP.PrintName = "Fake Tester"
    SWEP.Slot = 7

    SWEP.ViewModelFOV = 70

    SWEP.EquipMenuData = {
        type = "weapon",
        desc = "The Fake Tester will negate the random tester\n and pick a random person and test it.\nIt will output the opposite of the role. \n\nRight click to play Gaben."
    };

    SWEP.Icon = "vgui/ttt/icon_faketest.vtf"
    SWEP.ViewModelFlip = false
end

function SWEP:Precache() util.PrecacheSound("weapons/gaben.wav") end

SWEP.Author = "Gamefreak"

SWEP.Base = "weapon_tttbase"

SWEP.HoldType = "normal"

SWEP.ViewModel = "models/weapons/gamefreak/v_wiimote_meow.mdl"
SWEP.WorldModel = "models/weapons/gamefreak/w_wiimote_meow.mdl"

SWEP.DrawCrosshair = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 3

SWEP.Kind = WEAPON_ROLE
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true

SWEP.AllowDrop = true
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.NoSights = true

SWEP.Delay = 10
SWEP.TextDelay = 5

function SWEP:OnRemove()
    if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and
        self.Owner:Alive() then RunConsoleCommand("lastinv") end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
    self:EmitSound("weapons/gaben.wav", 500)
end

local function GetFakeTesterPlayer()
    local result = {}
    for _, v in RandomPairs(player.GetAll()) do
        if v:IsTerror() and v:GetRole() ~= ROLE_DETECTIVE and not v:GetNWBool("RTTested") then
            table.insert(result, v)
        end
    end
    return result[math.random(1, #result)]
end

function SWEP:OnDrop() self:Remove() end

local function IsTraitorTeam(ply)
    return ply:IsTraitor() or ply:IsHypnotist() or ply:IsAssassin()
end

function SWEP:HandleMessages(ply)
    if not IsValid(ply) then
        net.Start("ft failed")
        net.Send(self.Owner)
        return
    end
    local role, nick = ply:GetRole(), ply:Nick()
    local owner, ownerNick = self.Owner, self.Owner:Nick()
    local rolestring = ply:GetRoleString()
    local id = ply:EntIndex()
    local txtDelay = self.TextDelay

    ply:SetNWBool("FTTested", true)

    if timer.Exists("FT Timer" .. id) then return end

    local innocentroles = {}
    local evilroles = {}
    for _, v in pairs(player.GetAll()) do
        if v:GetRole() ~= ROLE_DETECTIVE then
            if v:GetRole() == ROLE_TRAITOR or v:GetRole() == ROLE_HYPNOTIST or v:GetRole() == ROLE_ASSASSIN or
                v:GetRole() == ROLE_KILLER or v:GetRole() == ROLE_VAMPIRE or v:GetRole() == ROLE_ZOMBIE then
                table.insert(evilroles, v:GetRole())
            else
                table.insert(innocentroles, v:GetRole())
            end
        end
        if timer.Exists("RT Timer " .. v:EntIndex()) then
            self.Delay = timer.TimeLeft("RT Timer " .. v:EntIndex())
            timer.Remove("RT Timer " .. v:EntIndex())
        end
    end
    util.PrecacheSound("weapons/prank.mp3")

    timer.Create("FT Timer " .. id, self.Delay, 1, function()
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local valid = IsValid(ply)
        role, nick = valid and ply:GetRole() or role,
                     valid and ply:Nick() or nick

        if IsTraitorTeam(owner) and IsTraitorTeam(ply) then
            if table.Count(innocentroles) > 0 then
                role = innocentroles[math.random(table.Count(innocentroles))]
            else
                role = ROLE_INNOCENT
            end
        else
            if table.Count(evilroles) > 0 then
                role = evilroles[math.random(table.Count(evilroles))]
            else
                role = ROLE_TRAITOR
            end
        end
        rolestring = ROLE_STRINGS[role]

        DamageLog("FTester:\t" .. ownerNick .. "[" .. owner:GetRoleString() ..
                      "] fake tested " .. nick .. "[" .. rolestring .. "]")

        net.Start("ft result")
        net.WriteEntity(ply)
        net.WriteUInt(role, 4)
        net.WriteString(rolestring)
        net.WriteString(nick)
        net.WriteUInt(txtDelay, 8)
        net.Broadcast()

    end)
end

local function PrintFakeCenteredText(txt, delay, color)
    if hook.GetTable()["FT Draw Text"] then
        hook.Remove("HUDPaint", "FT Draw Text")
        hook.Add("HUDPaint", "FT Draw Text", function()
            draw.DrawText(txt, "CloseCaption_Bold", ScrW() * 0.5, ScrH() * 0.2,
                          color, TEXT_ALIGN_CENTER)
        end)
        timer.Adjust("FT Remove Text", delay, 1, function()
            hook.Remove("HUDPaint", "FT Draw Text")
            hook.Remove("TTTEndRound", "FT Remove Text")
            hook.Remove("TTTPrepareRound", "FT Remove Text")
        end)
    else
        hook.Add("HUDPaint", "FT Draw Text", function()
            draw.DrawText(txt, "CloseCaption_Bold", ScrW() * 0.5, ScrH() * 0.2,
                          color, TEXT_ALIGN_CENTER)
        end)
        hook.Add("TTTEndRound", "FT Remove Text", function()
            hook.Remove("HUDPaint", "FT Draw Text")
            hook.Remove("TTTEndRound", "FT Remove Text")
            hook.Remove("TTTPrepareRound", "FT Remove Text")
            timer.Remove("FT Remove Text")
        end)
        hook.Add("TTTPrepareRound", "FT Remove Text", function()
            hook.Remove("HUDPaint", "FT Draw Text")
            hook.Remove("TTTEndRound", "FT Remove Text")
            hook.Remove("TTTPrepareRound", "FT Remove Text")
            timer.Remove("FT Remove Text")
        end)
        timer.Create("FT Remove Text", delay, 1, function()
            hook.Remove("HUDPaint", "FT Draw Text")
            hook.Remove("TTTEndRound", "FT Remove Text")
            hook.Remove("TTTPrepareRound", "FT Remove Text")
        end)
    end
end

local function GetFakeRoleColor(role, ply)
    return not (IsValid(ply) and ply:IsTerror()) and COLOR_ORANGE or ROLE_COLORS[role]
end

if CLIENT then
    net.Receive("ft failed", function()
        chat.AddText("Fake Tester: ", COLOR_WHITE,
                     "The Fake Tester couldn't find any valid players.")
    end)

    net.Receive("ft result", function()
        local ply, role, roleString, Nick, txtDelay, lply = net.ReadEntity(),
                                                            net.ReadUInt(4),
                                                            net.ReadString(),
                                                            net.ReadString(),
                                                            net.ReadUInt(8),
                                                            LocalPlayer()
        local roleColor, textColor = GetFakeRoleColor(role, ply), COLOR_WHITE
        local valid = IsValid(ply)
        local nick = valid and Nick or "\"" .. Nick .. "\" (unconnected)"

        if valid then
            if not (valid and ply:IsTerror()) then
                chat.AddText("Random Tester: ", roleColor, nick, textColor,
                             " was ", roleColor, roleString, textColor, "!")
                surface.PlaySound("weapons/prank.mp3")
            else
                if lply:IsTerror() then
                    PrintFakeCenteredText(nick .. " is " .. roleString .. "!",
                                          txtDelay, roleColor)
                end
                chat.AddText("Random Tester: ", roleColor, nick, textColor,
                             " is ", roleColor, roleString, textColor, "!")
            end
        end
        chat.PlaySound()
    end)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Delay)
    if CLIENT then return end
    if GetRoundState() == ROUND_ACTIVE then
        self:HandleMessages(GetFakeTesterPlayer())
    end
    self:Remove()
end

hook.Add("TTTPrepareRound", "Remove FT Timer", function()
    for k, v in pairs(player.GetAll()) do
        timer.Remove("FT Timer " .. v:EntIndex())
    end
end)
