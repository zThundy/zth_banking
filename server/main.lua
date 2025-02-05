assert(lib.checkDependency('ox_lib', '3.20.0', true))

QBCore = exports["qb-core"]:GetCoreObject()

local function getPlayerIdentifier(player)
    return player.PlayerData.citizenid
end

local function getPlayerFromId(source)
    return QBCore.Functions.GetPlayer(source)
end

local function getPlayerFromCitizenId(citizenId)
    return QBCore.Functions.GetPlayerByCitizenId(citizenId)
end

local function getPlayerAccounts(player)
    return player.PlayerData.money["bank"]
end

local function getName(player)
    return player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
end

local function logTransaction(identifier, description, accountName, amount, isIncome)
    MySQL.insert.await('INSERT INTO fd_banking_transactions (identifier, description, type, amount, date, isIncome) VALUES (?, ?, ?, ?, NOW(), ?)', { identifier, description, accountName, amount, isIncome })
end

local function getCompanyUsers(jobName)
    local usersInJob = {}
    local managementUsers = MySQL.query.await('SELECT * FROM fd_banking_management')

    for _, user in pairs(managementUsers) do
        if user.job == jobName then
            table.insert(usersInJob, {
                name = user.name,
                id = user.identifier,
                isboss = true
            })
        end
    end

    for _, player in ipairs(QBCore.Functions.GetPlayers()) do
        local _Player = getPlayerFromId(player)
        if _Player.PlayerData.job.name == jobName then
            table.insert(usersInJob, {
                name = getName(_Player),
                id = getPlayerIdentifier(_Player),
                isboss = _Player.PlayerData.job.isboss
            })
        end
    end

    -- remove duplicates
    local unique = {}
    local uniqueUsers = {}
    for _, user in ipairs(usersInJob) do
        if not unique[user.id] then
            table.insert(uniqueUsers, user)
            unique[user.id] = true
        end
    end

    table.sort(uniqueUsers, function(a, b)
        return a.name < b.name
    end)

    return uniqueUsers
end

CreateThread(function()
    while not MySQL do Wait(1000) end

    local queries = {
        [[
            CREATE TABLE IF NOT EXISTS `fd_banking_transactions` (
                `id` INT NOT NULL AUTO_INCREMENT,
                `identifier` VARCHAR(255) NOT NULL,
                `description` VARCHAR(255) NOT NULL,
                `type` VARCHAR(255) NOT NULL,
                `amount` DECIMAL(10, 2) NOT NULL,
                `date` DATE NOT NULL,
                `isIncome` BOOLEAN NOT NULL,
                PRIMARY KEY (`id`)
            ) ENGINE = InnoDB;
        ]],
        [[
            CREATE TABLE IF NOT EXISTS `fd_banking_management` (
                `id` INT NOT NULL AUTO_INCREMENT,
                `identifier` VARCHAR(255) NOT NULL,
                `name` VARCHAR(255) NOT NULL,
                `job` VARCHAR(255) NOT NULL,
                PRIMARY KEY (`id`)
            ) ENGINE = InnoDB;
        ]]
    }

    MySQL.transaction(queries, function(success)
        if success then
            print("^2[fd_banking]^7 Database setup complete.")
        else
            print("^1[fd_banking]^7 Database setup failed.")
        end
    end)
end)

lib.callback.register("fd_banking:server:getHistory", function(source)
    local Player = getPlayerFromId(source)
    local identifier = getPlayerIdentifier(Player)
    local result = MySQL.query.await('SELECT * FROM fd_banking_transactions WHERE identifier = ? ORDER BY id DESC LIMIT 50', { identifier })
    return result
end)

lib.callback.register("fd_banking:server:deleteHistory", function(source)
    local Player = getPlayerFromId(source)
    local identifier = getPlayerIdentifier(Player)
    MySQL.query.await('DELETE FROM fd_banking_transactions WHERE identifier = ?', { identifier })
    return true
end)

lib.callback.register("fd_banking:server:getWeeklySummary", function(source)
    local Player = getPlayerFromId(source)
    local identifier = getPlayerIdentifier(Player)
    local receivedResult = MySQL.query.await('SELECT SUM(amount) as totalReceived FROM fd_banking_transactions WHERE identifier = ? AND isIncome = ? AND DATE(date) >= DATE(NOW() - INTERVAL 7 DAY) LIMIT 50', { identifier, true })
    local totalReceived = receivedResult[1].totalReceived or 0
    local usedResult = MySQL.query.await('SELECT SUM(amount) as totalUsed FROM fd_banking_transactions WHERE identifier = ? AND isIncome = ? AND DATE(date) >= DATE(NOW() - INTERVAL 7 DAY) LIMIT 50', { identifier, false })
    local totalUsed = usedResult[1].totalUsed or 0
    return {
        totalReceived = totalReceived,
        totalUsed = totalUsed,
    }
end)

RegisterNetEvent("QBCore:Server:OnMoneyChange", function(source, moneyType, amount, direction, reason)
    if moneyType ~= "bank" then return end

    local Player = getPlayerFromId(source)
    local identifier = getPlayerIdentifier(Player)

    if reason == "unknown" then
        reason = locale("transaction_description")
    end

    logTransaction(identifier, reason, moneyType, math.abs(amount), direction == "add")
end)

lib.callback.register("fd_banking:server:getTransactionStats", function(source)
    local Player = getPlayerFromId(source)
    local identifier = getPlayerIdentifier(Player)

    local result = MySQL.query.await('SELECT COUNT(*) as totalCount, SUM(amount) as totalAmount FROM fd_banking_transactions WHERE identifier = ?', { identifier })
    local transactionData = MySQL.query.await('SELECT amount, date, isIncome, id FROM fd_banking_transactions WHERE identifier = ? ORDER BY date DESC LIMIT 50', { identifier })

    local transactionDataPositive = {}
    local transactionDataNegative = {}
    for _, data in ipairs(transactionData) do
        if data.isIncome then
            table.insert(transactionDataPositive, data)
        else
            data.amount = data.amount * -1
            table.insert(transactionDataNegative, data)
        end
    end

    return {
        totalCount = result[1].totalCount,
        totalAmount = result[1].totalAmount,
        transactionData = {
            positive = transactionDataPositive,
            negative = transactionDataNegative,
        },
    }
end)

lib.callback.register("fd_banking:server:getUser", function(source)
    local Player = getPlayerFromId(source)
    if not Player then
        return false
    end
    return {
        name = getName(Player),
        identifier = getPlayerIdentifier(Player),
    }
end)

lib.callback.register("fd_banking:server:ATMwithdraw", function(source, amount, type)
    local Player = getPlayerFromId(source)
    local bankBalance = getPlayerAccounts(Player)
    local conversionRate = exports['fd_dualcurrency']:GetConversionRate()

    if type == "MXN" then
        bankBalance = bankBalance * conversionRate
    elseif type == "USD" then
    end
    
    if bankBalance >= amount then
        if type == "MXN" then
            local bankamount = math.ceil(amount / conversionRate)
            Player.Functions.RemoveMoney("bank", bankamount, "Prelievo MXN")
            Player.Functions.AddMoney("mexcash", amount)
        elseif type == "USD" then
            Player.Functions.RemoveMoney("bank", amount, "Prelievo USD")
            Player.Functions.AddMoney("cash", amount)
        end
        return true
    else
        return false
    end
end)

lib.callback.register("fd_banking:server:ATMdeposit", function(source, amount, type)
    local Player = getPlayerFromId(source)
    local cashBalance = nil
    local conversionRate = exports['fd_dualcurrency']:GetConversionRate()
    
    if type == "MXN" then
        cashBalance = Player.PlayerData.money["mexcash"]
    elseif type == "USD" then
        cashBalance = Player.PlayerData.money["cash"]
    end

    if cashBalance >= amount then
        if type == "MXN" then
            Player.Functions.RemoveMoney("mexcash", amount)
            amount = math.ceil(amount / conversionRate)
            Player.Functions.AddMoney("bank", amount, "Versamento MXN")
        elseif type == "USD" then
            Player.Functions.RemoveMoney("cash", amount)
            Player.Functions.AddMoney("bank", amount, "Versamento USD")
        end
        return true
    else
        return false
    end
end)

lib.callback.register("fd_banking:server:fetchCompanyInfo", function(source)
    local Player = getPlayerFromId(source)
    local jobName = Player.PlayerData.job.name
    local jobLabel = Player.PlayerData.job.label

    local account = exports['qb-management']:GetAccount(jobName)
    if not account then return { success = false } end

    return {
        success = true,
        name = jobLabel,
        balance = account,
        users = getCompanyUsers(jobName),
    }
end)

lib.callback.register("fd_banking:server:depositCompany", function(source, amount, currency)
    local Player = getPlayerFromId(source)
    local jobName = Player.PlayerData.job.name
    local playerBankAmount = getPlayerAccounts(Player)
    local account = exports['qb-management']:GetAccount(jobName)
    if not account then return { success = false } end
    if type(amount) ~= "number" then amount = tonumber(amount) end

    if currency == "MXN" then
        amount = math.ceil(amount / exports['fd_dualcurrency']:GetConversionRate())
    end

    if amount > 0 and playerBankAmount >= amount then
        Player.Functions.RemoveMoney("bank", amount, locale("company_transaction_deposit"))
        exports['qb-management']:AddMoney(jobName, amount)
        local account = exports['qb-management']:GetAccount(jobName)
        local remaningBalance = getPlayerAccounts(Player) - amount
        local remaningMexBalance = math.floor(remaningBalance * exports['fd_dualcurrency']:GetConversionRate())
        return { success = true, balance = account, remaningBalance = remaningBalance, remaningMexBalance = remaningMexBalance }
    else
        return { success = false }
    end
end)

lib.callback.register("fd_banking:server:withdrawCompany", function(source, amount, currency)
    local Player = getPlayerFromId(source)
    local jobName = Player.PlayerData.job.name
    local account = exports['qb-management']:GetAccount(jobName)
    if not account then return { success = false } end
    if type(amount) ~= "number" then amount = tonumber(amount) end

    if currency == "MXN" then
        amount = math.ceil(amount / exports['fd_dualcurrency']:GetConversionRate())
    end

    if amount > 0 and account >= amount then
        Player.Functions.AddMoney("bank", amount, locale("company_transaction_withdraw"))
        exports['qb-management']:RemoveMoney(jobName, amount)
        local account = exports['qb-management']:GetAccount(jobName)
        local remaningBalance = getPlayerAccounts(Player) + amount
        local remaningMexBalance = math.floor(remaningBalance * exports['fd_dualcurrency']:GetConversionRate())
        return { success = true, balance = account, remaningBalance = remaningBalance, remaningMexBalance = remaningMexBalance }
    else
        return { success = false }
    end
end)

lib.callback.register("fd_banking:server:toggleCompanyAccess", function(source, isRemoving, userName, userId)
    -- check if the user doesn't exist on the management table, if not add it and add the other user if is not removing
    local Player = getPlayerFromId(source)
    local jobName = Player.PlayerData.job.name
    local account = exports['qb-management']:GetAccount(jobName)
    if not account then return { success = false } end

    local PlayerIdentifier = getPlayerIdentifier(Player)
    local result = MySQL.query.await('SELECT * FROM fd_banking_management WHERE identifier = ? AND job = ?', { PlayerIdentifier, jobName })
    if not result[1] then
        MySQL.query.await('INSERT INTO fd_banking_management (identifier, name, job) VALUES (?, ?, ?)', { PlayerIdentifier, getName(Player), jobName })
    end
    if PlayerIdentifier == userId then return { success = false } end
    if isRemoving ~= 0 then
        local RemovingPlayer = getPlayerFromCitizenId(userId)
        if not RemovingPlayer then return { success = false } end
        if RemovingPlayer.PlayerData.job.name == jobName and RemovingPlayer.PlayerData.job.isboss then return { success = false } end
        MySQL.query.await('DELETE FROM fd_banking_management WHERE identifier = ? AND job = ?', { userId, jobName })
    else
        MySQL.query.await('INSERT INTO fd_banking_management (identifier, name, job) VALUES (?, ?, ?)', { userId, userName, jobName })
    end

    return { success = true, users = getCompanyUsers(jobName) }
end)

lib.callback.register("fd_banking:server:canAccessCompanies", function(soruce)
    local Player = getPlayerFromId(source)
    local isBoss = Player.PlayerData.job.isboss
    local jobName = Player.PlayerData.job.name
    if isBoss then
        local PlayerIdentifier = getPlayerIdentifier(Player)
        local result = MySQL.query.await('SELECT * FROM fd_banking_management WHERE identifier = ? AND job = ?', { PlayerIdentifier, jobName })
        if not result[1] then
            MySQL.query.await('INSERT INTO fd_banking_management (identifier, name, job) VALUES (?, ?, ?)', { PlayerIdentifier, getName(Player), jobName })
        end
        return true
    else
        -- check if the user is on db
        local PlayerIdentifier = getPlayerIdentifier(Player)
        local result = MySQL.query.await('SELECT * FROM fd_banking_management WHERE identifier = ? AND job = ?', { PlayerIdentifier, jobName })
        if not result[1] then
            return false
        end
        return true
    end
end)