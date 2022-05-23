AnimalInputEvent = {
    MOVE_SUCCESS = 0,
	MOVE_ERROR_NO_PERMISSION = 1,
	MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST = 2,
	MOVE_ERROR_STORAGE_DOES_NOT_EXIST = 3,
	MOVE_ERROR_INVALID_CLUSTER = 4,
	MOVE_ERROR_ANIMAL_NOT_SUPPORTED = 5,
	MOVE_ERROR_NOT_ENOUGH_SPACE = 6,
	MOVE_ERROR_NOT_ENOUGH_ANIMALS = 7,
	MOVE_ERROR_NOT_ENOUGH_MONEY = 8
}
local AnimalInputEvent_mt = Class(AnimalInputEvent, Event)

InitObjectClass(AnimalInputEvent, "AnimalInputEvent")

function AnimalInputEvent.emptyNew()
    return Event.new(AnimalInputEvent_mt)
end

function AnimalInputEvent.new(sourceObject, storage, clusterId, numAnimals)
    local self = AnimalInputEvent.emptyNew()
    self.sourceObject = sourceObject
    self.storage = storage
    self.clusterId = clusterId
    self.numAnimals = numAnimals

    return self
end

function AnimalInputEvent.newServerToClient(errorCode)
    local self = AnimalInputEvent.emptyNew()
    self.errorCode = errorCode

    return self
end

function AnimalInputEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.sourceObject)
		NetworkUtil.writeNodeObject(streamId, self.storage)
		streamWriteInt32(streamId, self.clusterId)
		streamWriteUInt8(streamId, self.numAnimals)
    else
        streamWriteUIntN(streamId, self.errorCode, 3)
    end
end

function AnimalInputEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
		self.sourceObject = NetworkUtil.readNodeObject(streamId)
		self.storage = NetworkUtil.readNodeObject(streamId)
		self.clusterId = streamReadInt32(streamId)
		self.numAnimals = streamReadUInt8(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
	end

	self:run(connection)
end

function AnimalInputEvent:run(connection)
    if not connection:getIsServer() then
        local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
		local farm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
		local farmId = farm.farmId
		local errorCode = AnimalInputEvent.validate(self.sourceObject, self.storage, self.clusterId, self.numAnimals, farmId)

		if errorCode ~= nil then
			connection:sendEvent(AnimalInputEvent.newServerToClient(errorCode))

			return
		end

        -- remove animals from source object
        local cluster = self.sourceObject:getClusterById(self.clusterId)
        cluster:changeNumAnimals(-self.numAnimals)
        local clusterSystem = self.sourceObject:getClusterSystem()
        clusterSystem:updateNow()

        -- add fill level to storage
        local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster:getSubTypeIndex())
        local fillType = g_fillTypeManager:getFillTypeByIndex(subType.fillTypeIndex)
        local fillLevel = self.storage:getFillLevel(fillType.index)

        local fillLevelPerAnimal = self.storage.animalTypeToLitres[subType]
        local deltaFillLevel = fillLevelPerAnimal * self.numAnimals-- * cluster:getAgeFactor() * math.max(cluster:getHealthFactor(), 0.1)

        self.storage:setFillLevel(fillLevel + deltaFillLevel, fillType.index)

        connection:sendEvent(AnimalInputEvent.newServerToClient(AnimalInputEvent.MOVE_SUCCESS))
    else
        g_messageCenter:publish(AnimalInputEvent, self.errorCode)
    end
end

function AnimalInputEvent.validate(sourceObject, storage, clusterId, numAnimals, farmId)
    if sourceObject == nil then
        return AnimalInputEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST
    end

    if storage == nil then
        return AnimalInputEvent.MOVE_ERROR_STORAGE_DOES_NOT_EXIST
    end

    if not g_currentMission.accessHandler:canFarmAccess(farmId, sourceObject) then
		return AnimalInputEvent.MOVE_ERROR_NO_PERMISSION
	end

    if not g_currentMission.accessHandler:canFarmAccess(farmId, storage) then
        return AnimalInputEvent.MOVE_ERROR_NO_PERMISSION
    end

    local cluster = sourceObject:getClusterById(clusterId)

    if cluster == nil then
        return AnimalInputEvent.MOVE_ERROR_INVALID_CLUSTER
    end

    if cluster:getNumAnimals() < numAnimals then
        return AnimalInputEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS
    end
end