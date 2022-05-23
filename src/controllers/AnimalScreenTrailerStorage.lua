source(g_currentModDirectory .."src/controllers/events/AnimalInputEvent.lua")

AnimalScreenTrailerStorage = {
	L10N = {
		NAME = "ui_productionPoint",
		MOVE_TO_STORAGE = "shop_moveToProduction",
		MOVE_TO_TRAILER = "shop_moveToTrailer",
		CONFIRM_MOVE_TO_STORAGE = "shop_confirmMoveToProduction",
		CONFIRM_MOVE_TO_TRAILER = "shop_doYouWantToMoveAnimalsToTrailer"
	},
	MOVE_TO_STORAGE_ERROR_CODE_MAPPING = {
		[AnimalInputEvent.MOVE_SUCCESS] = {
			text = "shop_movedToStorage",
			warning = false
		},
		[AnimalInputEvent.MOVE_ERROR_NO_PERMISSION] = {
			text = "shop_messageNoPermissionToTradeAnimals",
			warning = true
		},
		[AnimalInputEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST] = {
			text = "shop_messageTrailerDoesNotExist",
			warning = true
		},
		[AnimalInputEvent.MOVE_ERROR_STORAGE_DOES_NOT_EXIST] = {
			text = "shop_messageStorageDoesNotExist",
			warning = true
		},
		[AnimalInputEvent.MOVE_ERROR_INVALID_CLUSTER] = {
			text = "shop_messageInvalidCluster",
			warning = true
		},
		[AnimalInputEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED] = {
			text = "shop_messageAnimalTypeNotSupported",
			warning = true
		},
		[AnimalInputEvent.MOVE_ERROR_NOT_ENOUGH_SPACE] = {
			text = "shop_messageNotEnoughSpaceAnimals",
			warning = true
		},
		[AnimalInputEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS] = {
			text = "shop_messageNotEnoughAnimals",
			warning = true
		}
	}
}
AnimalScreenTrailerStorage_mt = Class(AnimalScreenTrailerStorage, AnimalScreenBase)

function AnimalScreenTrailerStorage.new(trailer, storage, inputs, customMt)
    local self = AnimalScreenBase.new(customMt or AnimalScreenTrailerStorage_mt)
    self.trailer = trailer -- source
    self.storage = storage --target
	self.inputs = inputs

    return self
end

function AnimalScreenTrailerStorage:initSourceItems()
	self.sourceItems = {}
	local clusters = self.trailer:getClusters()

	if clusters ~= nil then
		for _, cluster in ipairs(clusters) do
			local item = AnimalItemStock.new(cluster)

			table.insert(self.sourceItems, item)
		end
	end
end

function AnimalScreenTrailerStorage:getSourceName()
	local name = self.trailer:getName()
	local currentAnimalType = self.trailer:getCurrentAnimalType()

	if currentAnimalType == nil then
		return name
	end

	local used = self.trailer:getNumOfAnimals()
	local total = self.trailer:getMaxNumOfAnimals(currentAnimalType)

	return string.format("%s (%d / %d)", name, used, total)
end

function AnimalScreenTrailerStorage:getSourceActionText()
	return g_i18n:getText(AnimalScreenTrailerStorage.L10N.MOVE_TO_STORAGE)
end

function AnimalScreenTrailerStorage:getApplySourceConfirmationText(itemIndex, numItems)
	local text = g_i18n:getText(AnimalScreenTrailerStorage.L10N.CONFIRM_MOVE_TO_STORAGE)
	local item = self.sourceItems[itemIndex]

	return string.format(text, numItems, item:getName())
end

function AnimalScreenTrailerStorage:getSourcePrice()
	return false, 0, 0, 0
end

function AnimalScreenTrailerStorage:getSourceMaxNumAnimals(itemIndex)
	local item = self.sourceItems[itemIndex]
	local maxNumAnimals = self:getMaxNumAnimals()

	return math.min(maxNumAnimals, item:getNumAnimals())--TODO: change to animals that fit into storage, self.trailer:getNumOfFreeAnimalSlots())
end

function AnimalScreenTrailerStorage:applySource(itemIndex, numItems)
	local item = self.sourceItems[itemIndex]
	local clusterId = item:getClusterId()
	local errorCode = AnimalInputEvent.validate(self.trailer, self.storage, clusterId, numItems, self.trailer:getOwnerFarmId())

	if errorCode ~= nil then
		local data = AnimalScreenTrailerStorage.MOVE_TO_STORAGE_ERROR_CODE_MAPPING[errorCode]

		self.errorCallback(g_i18n:getText(data.text))

		return false
	end

	local text = g_i18n:getText(AnimalScreenTrailerStorage.L10N.MOVE_TO_STORAGE)

	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, text)
	g_messageCenter:subscribe(AnimalInputEvent, self.onAnimalMovedToStorage, self)
	g_client:getServerConnection():sendEvent(AnimalInputEvent.new(self.trailer, self.storage, clusterId, numItems))

	return true
end

function AnimalScreenTrailerStorage:onAnimalMovedToStorage(errorCode)
	g_messageCenter:unsubscribe(AnimalInputEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)

	local data = AnimalScreenTrailerStorage.MOVE_TO_STORAGE_ERROR_CODE_MAPPING[errorCode]

	self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))

	self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))
end

function AnimalScreenTrailerStorage:onAnimalsChanged(obj, clusters)
	
end