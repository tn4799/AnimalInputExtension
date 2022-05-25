AnimalInputTrigger = {}
local AnimalInputTrigger_mt = Class(AnimalInputTrigger)

InitObjectClass(AnimalInputTrigger, "AnimalInputTrigger")

function AnimalInputTrigger.new(isServer, isClient)
    local self = Object.new(isServer, isClient, AnimalInputTrigger_mt)
    self.customEnvironment = g_currentMission.loadingMapModName
    self.triggerNode = nil
    self.title = g_i18n:getText(AnimalScreenTrailerStorage.L10N.NAME)
    self.animals = nil
    self.activatable = AnimalInputTriggerActivateable.new(self)
    --self.isPlayerInRange = false
    self.loadingVehicle = nil
    self.activatedTarget = nil

    return self
end

function AnimalInputTrigger:load(node, storage, production)
    self.storage = storage
    self.production = production

    self.triggerNode = node

    if node ~= nil then
        addTrigger(self.triggerNode, "triggerCallback", self)
    else
        Logging.error("missing trigger node for AnimalInputTrigger")

        return
    end
end

function AnimalInputTrigger:delete()
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)

	if self.triggerNode ~= nil then
		removeTrigger(self.triggerNode)

		self.triggerNode = nil
	end

	self.storage = nil
end

function AnimalInputTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if onEnter or onLeave then
        local vehicle = g_currentMission.nodeToObject[otherId]

        if vehicle ~= nil and vehicle.spec_livestockTrailer ~= nil then
            if onEnter then
                self:setLoadingTrailer(vehicle)
            elseif onLeave then
                if vehicle == self.loadingVehicle then
                    self:setLoadingTrailer(nil)
                end

                if vehicle == self.activatedTarget then
                    g_animalInputScreen:onVehicleLeftTrigger()
                end
            end
        --[[elseif g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
            if onEnter then
                self.isPlayerInRange = true
            else
                self.isPlayerInRange = false
            end

            self:updateActivateableObject()]]
        end
    end
end

function AnimalInputTrigger:updateActivateableObject()
    if self.loadingVehicle ~= nil then -- or self.isPlayerInRange
        g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
    elseif self.loadingVehicle == nil then --and not self.isPlayerInRange
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    end
end

function AnimalInputTrigger:setLoadingTrailer(loadingVehicle)
    if self.loadingVehicle ~= nil and self.loadingVehicle.setLoadingTrigger ~= nil then
        self.loadingVehicle:setLoadingTrigger(nil)
    end

    self.loadingVehicle = loadingVehicle

	if self.loadingVehicle ~= nil and self.loadingVehicle.setLoadingTrigger ~= nil then
		self.loadingVehicle:setLoadingTrigger(self)
	end

	self:updateActivateableObject()
end

function AnimalInputTrigger:showAnimalScreen()
    if self.loadingVehicle == nil then
        g_gui:showInfoDialog({
			text = g_i18n:getText("shop_messageNoLoadingTrailer")
		})

        return
    end

    local controller = nil

    if self.loadingVehicle ~= nil then
        controller = AnimalScreenTrailerStorage.new(self.loadingVehicle, self.storage, self.production)
    --elseif self.loadingVehicle == nil and self.isPlayerInRange then --preparation for future version to buy animals
        --controller = AnimalScreenDealerStorage(self.storage)
    end

    if controller ~= nil then
        controller:init()
        g_animalInputScreen:setController(controller)
        g_gui:showGui("AnimalInputScreen")
    end
end

function AnimalInputTrigger:openAnimalMenu()
    self:showAnimalScreen()

    self.activatedTarget = self.loadingVehicle
end

AnimalInputTriggerActivateable = {}
local AnimalInputTriggerActivateable_mt = Class(AnimalInputTriggerActivateable)

function AnimalInputTriggerActivateable.new(animalInputTrigger)
    local self = setmetatable({}, AnimalInputTriggerActivateable_mt)
    self.owner = animalInputTrigger
    self.activateText = g_i18n:getText("animals_openAnimalScreen") -- standard translation from giants

    return self
end

function AnimalInputTriggerActivateable:getIsActivatable()
    if g_gui.currentGui ~= nil then
        return false
    end

    if not g_currentMission:getHasPlayerPermission("tradeAnimals") then
		return false
	end

    local canAccess = self.owner.storage == nil or self.owner.production:getOwnerFarmId() == g_currentMission:getFarmId()

    if not canAccess then
        return false
    end

    local rootAttachervehicle = nil

    if self.owner.loadingVehicle ~= nil then
        rootAttachervehicle = self.owner.loadingVehicle.rootVehicle
    end

    return rootAttachervehicle == g_currentMission.controlledVehicle -- or self.owner.isPlayerInRange
end

function AnimalInputTriggerActivateable:run()
    self.owner:openAnimalMenu()
end

function AnimalInputTriggerActivateable:getDistance(x, y, z)
    if self.owner.triggerNode ~= nil then
        local tx, ty, tz = getWorldTranslation(self.owner.triggerNode)

        return MathUtil.vector3Length(x - tx, y - ty, z - tz)
    end

    return math.huge
end