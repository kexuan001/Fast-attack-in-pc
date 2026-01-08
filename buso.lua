
_G.FastAttack = true
_G.TargetPlayers = true
_G.AttackDelay = 0.05 -- 攻擊間隔，數字越小打越快。建議 0.03~0.07 之間。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net", 5)
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")

local lastAttack = 0

-- 1. 輕量化雷達 (只抓一個最優目標)
local function GetBestTarget()
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local Best = nil
    local MinDist = 100000 

    for _, folder in pairs({workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("Characters")}) do
        if folder then
            for _, e in pairs(folder:GetChildren()) do
                local H = e:FindFirstChild("Head")
                local Hum = e:FindFirstChild("Humanoid")
                if H and Hum and Hum.Health > 0 and e ~= Player.Character then
                    -- 檢查 PVP 鎖定
                    if _G.TargetPlayers or not Players:GetPlayerFromCharacter(e) then
                        local d = (H.Position - Root.Position).Magnitude
                        if d < MinDist and not e:FindFirstChildOfClass("ForceField") then
                            MinDist = d
                            Best = {e, H}
                        end
                    end
                end
            end
        end
    end
    return Best
end

-- 2. 幽靈閃現循環
if _G.FastAttackLoop then _G.FastAttackLoop:Disconnect() end

_G.FastAttackLoop = RunService.Heartbeat:Connect(function()
    if not _G.FastAttack then return end
    if tick() - lastAttack < _G.AttackDelay then return end
    
    local Char = Player.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    local Tool = Char and Char:FindFirstChildOfClass("Tool")
    if not Root or not Tool then return end

    local Target = GetBestTarget()
    if Target then
        lastAttack = tick()
        local TChar = Target[1]
        local THead = Target[2]
        local OldCF = Root.CFrame

        -- [幽靈閃現技術]：只閃過去 0.01 秒
        Root.CFrame = THead.CFrame * CFrame.new(0, 0, 3) 
        
        -- 發送關鍵封包
        RegisterAttack:FireServer(0)
        local AttackData = {{TChar, THead}}
        RegisterHit:FireServer(THead, AttackData)
        RegisterHit:FireServer(THead, AttackData)

        -- 瞬間閃回
        Root.CFrame = OldCF
    end
end)

print("--- 4060 幽靈閃現版已啟動 (修正無效問題) ---")
