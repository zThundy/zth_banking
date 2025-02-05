local hashings = require("libs/hashings")

QBCore = exports["qb-core"]:GetCoreObject()

local function getPlayerAccounts()
    return QBCore.Functions.GetPlayerData().money
end

local function getPlayer()
    return QBCore.Functions.GetPlayerData()
end

local function getUserDisplayName()
    local Player = getPlayer()
    return Player.charinfo.firstname .. " " .. Player.charinfo.lastname
end

local function isBoss()
    local Player = getPlayer()
    return Player.job.isboss
end

RegisterNUICallback("fd_banking:client:getLocales", function(_, cb)
    cb(lib.getLocales())
end)

RegisterNUICallback("fd_banking:client:hideUI", function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback("fd_banking:client:phoneOption", function(_, cb)
    cb(Config.LBPhone)
end)

-- Banks
RegisterNetEvent('fd_banking:client:open:bank')
AddEventHandler('fd_banking:client:open:bank', function()
	Wait(100)
    SendNUIMessage({ action = "openBank" })
    SetNuiFocus(true, true)
end)

CreateThread(function()
    for id, location in pairs(Config.BankLocations.Coords) do
        exports.ox_target:addBoxZone({
            name = "bank_" .. id,
            coords = location,
            size = Config.BankLocations.Interaction.size,
            options = {
                {
                    event = "fd_banking:client:open:bank",
                    icon = "fas fa-credit-card",
                    label = locale("openBank"),
                },
            },
        })

        local blip = AddBlipForCoord(location)
        SetBlipSprite(blip, Config.BankLocations.Blips.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.BankLocations.Blips.scale)
        SetBlipColour(blip, Config.BankLocations.Blips.color)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.BankLocations.Blips.name)
        EndTextCommandSetBlipName(blip)
    end
end)

CreateThread(function()
    for _, ATM_Models in ipairs(Config.ATM_Models) do
        exports.ox_target:addModel(ATM_Models, {
            icon = "fas fa-solid fa-money-bills",
            label = locale("openATM"),
            event = "fd_banking:client:open:atm",
            canInteract = function(_, distance)
                return distance < 2.5
            end,
        })
    end
end)

-- ATMs
RegisterNetEvent('fd_banking:client:open:atm')
AddEventHandler('fd_banking:client:open:atm', function()
    Wait(100)
    ATM_Animation()
    local ATM_Currency = "USD"
    local isInMexico = exports["fd_mexico"]:checkifInsideMexico()
    if isInMexico then ATM_Currency = "MXN" end
    SendNUIMessage({ action = "openATM", data = ATM_Currency })
    SetNuiFocus(true, true)
end)

function ATM_Animation()
	lib.playAnim(cache.ped, Config.ATM_Animation.dict, Config.ATM_Animation.name, 8.0, -8.0, -1, Config.ATM_Animation.flag, 0, false, 0, false)
    Wait(GetAnimDuration(Config.ATM_Animation.dict,Config.ATM_Animation.name) * 1000)
    ClearPedTasks(cache.ped)
end

RegisterNUICallback("fd_banking:client:fetchCreditCard", function(data, cb)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local identifier = PlayerData.citizenid
    lib.callback("fd_paymentsystem:getCustomerPin", false, function(cardPin)
        local hidden = false
        if not cardPin then
            hidden = true
            cardPin = "00000"
        end

        local hs = hashings("md5")
        hs:update(identifier)
        local cardNumber = hs:hexdigest()
        cardNumber = cardNumber:gsub("%a", function(c) return math.abs(string.byte(c) - 96) end)
        cardNumber = cardNumber:sub(1, 16)

        cb({
            isDisabled = hidden,
            name = getUserDisplayName(),
            number = cardNumber,
            cvv = "521",
            pin = tostring(cardPin),
        })
    end)
end)

RegisterNUICallback("fd_banking:client:changePin", function(data, cb)
    if data.pin and data.pin:len() ~= 5 then
        cb({ success = false })
        return
    end
    TriggerServerEvent("fd_paymentsystem:changePin", data.pin)
    cb({ success = true })
end)

RegisterNUICallback("fd_banking:client:requestCard", function(data, cb)
    TriggerEvent("fd_paymentsystem:requestCard")
    cb({ success = true })
end)

RegisterNUICallback("fd_banking:client:lockCard", function(data, cb)
    -- local success = lib.callback.await("fd_banking:server:lockCard", false)
    cb({ success = true })
end)

RegisterNUICallback("fd_banking:client:getHistory", function(data, cb)
    lib.callback("fd_banking:server:getHistory", false, function(history)
        cb(history)
    end)
end)

RegisterNUICallback("fd_banking:client:deleteHistory", function(data, cb)
    lib.callback("fd_banking:server:deleteHistory", false, function(success)
        cb(success)
    end)
end)

RegisterNUICallback("fd_banking:client:getWeeklySummary", function(data, cb)
    lib.callback("fd_banking:server:getWeeklySummary", false, function(summary)
        cb(summary)
    end)
end)

RegisterNUICallback("fd_banking:client:getTransactionStats", function(data, cb)
    lib.callback("fd_banking:server:getTransactionStats", false, function(stats)
        cb(stats)
    end)
end)

RegisterNUICallback("fd_banking:client:getUser", function(data, cb)
    lib.callback("fd_banking:server:getUser", false, function(user)
        cb(user)
    end)
end)

RegisterNUICallback("fd_banking:client:ATMwithdraw", function(data, cb)
    lib.callback("fd_banking:server:ATMwithdraw", false, function(success)
        cb(success)
    end, data.amount, data.type)
end)

RegisterNUICallback("fd_banking:client:ATMdeposit", function(data, cb)
    local success = lib.callback.await("fd_banking:server:ATMdeposit", false, data.amount, data.type)
    cb(success)
end)

RegisterNUICallback("fd_banking:client:getMoneyTypes", function(data, cb)
    local moneyData = {}
    local PlayerData = QBCore.Functions.GetPlayerData()
    for k, v in pairs(PlayerData.money) do
        table.insert(moneyData, {
            amount = v,
            name = k,
        })
    end

    local conversionRate = exports['fd_dualcurrency']:GetConversionRate()
    cb({ moneyData = moneyData, conversionRate = conversionRate })
end)

RegisterNUICallback("fd_banking:client:fetchCompanyInfo", function(data, cb)
    lib.callback("fd_banking:server:fetchCompanyInfo", false, function(company)
        if company then
            local Currency = "USD"
            local isInMexico = exports["fd_mexico"]:checkifInsideMexico()
            if isInMexico then Currency = "MXN" end
            local conversionRate = exports['fd_dualcurrency']:GetConversionRate()
            company.balanceMex = math.floor(company.balance * conversionRate)
            company.currency = Currency
            company.success = true
        else
            company = { success = false }
        end
        cb(company)
    end)
end)

RegisterNUICallback("fd_banking:client:canAccessCompanies", function(data, cb)
    lib.callback("fd_banking:server:canAccessCompanies", false, function(success)
        cb({ success = success })
    end)
end)

RegisterNUICallback("fd_banking:client:toggleCompanyAccess", function(data, cb)
    -- data: isRemoving, userName, userId
    -- cb all users with new data
    lib.callback("fd_banking:server:toggleCompanyAccess", false, function(users)
        cb(users)
    end, data.isRemoving, data.userName, data.userId)
end)

RegisterNUICallback("fd_banking:client:depositCompany", function(data, cb)
    -- data: amount, currency
    lib.callback("fd_banking:server:depositCompany", false, function(response)
        if not response.success then
            cb({ success = response.success })
            return
        end

        local conversionRate = exports['fd_dualcurrency']:GetConversionRate()
        response.balanceMex = math.floor(response.balance * conversionRate)
        cb({ success = response.success, balance = response.balance, balanceMex = response.balanceMex, rBalance = response.remaningBalance, rBalanceMex = response.remaningMexBalance })
    end, data.amount, data.currency)
end)

RegisterNUICallback("fd_banking:client:withdrawCompany", function(data, cb)
    -- data: amount, currency
    lib.callback("fd_banking:server:withdrawCompany", false, function(response)
        if not response.success then
            cb({ success = response.success })
            return
        end

        local conversionRate = exports['fd_dualcurrency']:GetConversionRate()
        response.balanceMex = math.floor(response.balance * conversionRate)
        cb({ success = response.success, balance = response.balance, balanceMex = response.balanceMex, rBalance = response.remaningBalance, rBalanceMex = response.remaningMexBalance })
    end, data.amount, data.currency)
end)