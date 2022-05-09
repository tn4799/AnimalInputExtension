AnimalScreenTrailerStorage = {
	L10N = {
		NAME = "ui_productionPoint",
		MOVE_TO_STORAGE = "shop_moveToProduction",
		MOVE_TO_TRAILER = "shop_moveToTrailer",
		CONFIRM_MOVE_TO_STORAGE = "shop_confirmMoveToProduction",
		CONFIRM_MOVE_TO_TRAILER = "shop_doYouWantToMoveAnimalsToTrailer"
	}
}
AnimalScreenTrailerStorage_mt = Class(AnimalScreenTrailerStorage, AnimalScreenBase)

function AnimalScreenTrailerStorage.new(trailer, storage, customMt)
    local self = AnimalScreenBase.new(customMt or AnimalScreenTrailerStorage_mt)
    self.trailer = trailer -- source
    self.storage = storage --target

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

	return math.min(maxNumAnimals, item:getNumAnimals(), self.husbandry:getNumOfFreeAnimalSlots())
end

function AnimalScreenTrailerStorage:applySource(itemIndex, numItems)
	
end

function AnimalScreenTrailerStorage:onAnimalMovedToStorage(errorCode)
	
end

function AnimalScreenTrailerStorage:onAnimalMovedToTrailer(errorCode)
	
end

function AnimalScreenTrailerStorage:onAnimalsChanged(obj, clusters)
	
end