AnimalInputStorageExtension = {
    BACKUP_ANIMAL_TO_LITRES = {
        ["COW_SWISS_BROWN"] = 1500,
        ["COW_HOLSTEIN"] = 1500,
        ["COW_ANGUS"] = 1500,
        ["COW_LIMOUSIN"] = 1500,
        ["PIG_LANDRACE"] = 500,
        ["PIG_BLACK_PIED"] = 500,
        ["PIG_BERKSHIRE"] = 500,
        ["SHEEP_LANDRACE"] = 250,
        ["SHEEP_STEINSCHAF"] = 250,
        ["SHEEP_SWISS_MOUNTAIN"] = 250,
        ["SHEEP_BLACK_WELSE"] = 250,
        ["HORSE_GRAY"] = 1000,
        ["HORSE_PINTO"] = 1000,
        ["HORSE_PALOMINO"] = 1000,
        ["HORSE_CHESTNUT"] = 1000,
        ["HORSE_BAY"] = 1000,
        ["HORSE_BLACK"] = 1000,
        ["HORSE_SEAL_BROWN"] = 1000,
        ["HORSE_DUN"] = 1000,
        ["CHICKEN"] = 100,
        ["CHICKEN_ROOSTER"] = 100
    },
    GENERAL_BACKUP_VALUE = 4000
}


function AnimalInputStorageExtension:loadStorageExtension(superFunc, components, xmlFile, key, i3dMappings)
    local returnValue = superFunc(self, components, xmlFile, key, i3dMappings)

    if table.size(self.fillTypes) == 0 then
		return false
	end

    self.animalTypeToLitres = {}
    xmlFile:iterate(key .. ".capacity", function (_, capacityKey)
		local isAnimalFillType = xmlFile:getBool(capacityKey .. "#isAnimalFillType", false)

        if isAnimalFillType then
            local fillTypeName = xmlFile:getValue(capacityKey .. "#fillType")
            local animalType = g_currentMission.animalSystem:getSubTypeByName(fillTypeName)

            if animalType ~= nil then
                self.animalTypeToLitres[animalType.name] = xmlFile:getInt(capacityKey .. "#litersPerAnimal", AnimalInputStorageExtension.BACKUP_ANIMAL_TO_LITRES[animalType.name] or AnimalInputStorageExtension.GENERAL_BACKUP_VALUE)
            end
        end
	end)

    return returnValue
end

function AnimalInputStorageExtension.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".animalInputTrigger#node", "", "")
end

function AnimalInputStorageExtension:loadAnimalTrigger(superFunc, components, xmlFile, key, customEnv, i3dMappings)
    local returnValue = superFunc(self, components, xmlFile, key, customEnv, i3dMappings)
    self.animalTriggerNode = xmlFile:getValue(key .. ".animalInputTrigger#node", nil, components, i3dMappings)

    if self.animalTriggerNode ~= nil then
        self.animalTrigger = AnimalInputTrigger.new(self.isServer, self.isClient)
        self.animalTrigger:load(animalTriggerNode, self.storage, self)
    end

    return returnValue
end

function AnimalInputStorageExtension:deleteAnimalTrigger()
    if self.animalTriggerNode ~= nil then
	removeTrigger(self.animalTriggerNode)
	self.animalTriggerNode = nil
    end
end

function Storage:getAnimalTypeToLitresByAnimalType(animalType)
    return self.animalTypeToLitres[animalType.name] or AnimalInputStorageExtension.BACKUP_ANIMAL_TO_LITRES[animalType.name] or AnimalInputStorageExtension.BACKUP_ANIMAL_TO_LITRES
end

Storage.load = Utils.overwrittenFunction(Storage.load, AnimalInputStorageExtension.loadStorageExtension)

ProductionPoint.registerXMLPaths = Utils.appendedFunction(ProductionPoint.registerXMLPaths, AnimalInputStorageExtension.registerXMLPaths)
ProductionPoint.load = Utils.overwrittenFunction(ProductionPoint.load, AnimalInputStorageExtension.loadAnimalTrigger)
ProductionPoint.delete = Utils.prependedFunction(ProductionPoint.delete, AnimalInputStorageExtension.deleteAnimalTrigger)
