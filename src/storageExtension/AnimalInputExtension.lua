AnimalInputExtension = {}

AnimalInputExtension.BACKUP_ANIMAL_TO_LITRES = {
	["COW"] = 1500,
	["HORSE"] = 1000,
	["SHEEP"] = 250,
	["PIG"] = 500,
	["CHICKEN"] = 100
}

AnimalInputExtension.animalTypeToLitres = {}

function AnimalInputExtension:loadStorageExtension(components, xmlFile, key, i3dMappings)
    if table.size(self.fillTypes) == 0 then
		return false
	end

    xmlFile:iterate(key .. ".capacity", function (_, capacityKey)
		local isAnimalFillType = xmlFile:getBool(capacityKey .. "#isAnimalFillType", false)
        local fillTypeName = xmlFile:getValue(capacityKey .. "#fillType")

        if isAnimalFillType then
            local animalType = g_currentMission.animalSystem:getTypeByName(fillTypeName)

            if animalType ~= nil then
                AnimalInputExtension.animalTypeToLitres[animalType] = xmlFile:getInt(capacityKey .. "#litersPerAnimal", AnimalInputExtension.BACKUP_ANIMAL_TO_LITRES[animalType] or 500)
            end
        end
	end)

    return true
end

function AnimalInputExtension.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".playerTrigger#node", "", "") 
end

function AnimalInputExtension:loadAnimalTrigger(components, xmlFile, key, customEnv, i3dMappings)
    local animalTriggerNode = xmlFile:getValue(key .. ".playerTrigger#node", nil, components, i3dMappings)

    if animalTriggerNode ~= nil then
        self.animalTrigger = AnimalLoadingTrigger.new(self.isServer, self.isClient)
    end
end

Storage.load = Utils.appendedFunction(Storage.load, AnimalInputExtension.loadStorageExtension)

ProductionPoint.registerXMLPaths = Utils.appendedFunction(ProductionPoint.registerXMLPaths, AnimalInputExtension.registerXMLPaths)
ProductionPoint.load = Utils.appendedFunction(ProductionPoint.load, AnimalInputExtension.loadAnimalTrigger)