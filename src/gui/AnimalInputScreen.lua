AnimalInputScreen = {
    TRANSPORTATION_FEE = 200,
	SELECTION_NONE = 0,
	SELECTION_SOURCE = 1,
    L10N = {
        "ERROR_TRAILER_LEFT"
    },
    PROFILE = {
        LIST_ITEM_NEUTRAL = "shopCategoryItem",
        NEGATIVE_BALANCE = "shopMoneyNeg",
        POSITIVE_BALANCE = "shopMoney"
    },
    CONTROLS = {
        -- animals-part
        HEADER_SOURCE = "headerSource",
        LIST_SOURCE = "listSource",
        BALANCE_ELEMENT = "balanceElement",
        INFO_ICON = "infoIcon",
        INFO_TITLE = "infoName",
        INFO_TITLES = "infoTitle",
        INFO_VALUES = "infoValue",
        INFO_BOX = "infoBox",
        INFO_PRICE = "infoPrice",
        INFO_FEE = "infoFee",
        INFO_TOTAL = "infoTotal",
        INFO_DESCRIPTION = "infoDescription",
        Num_ANIMALS_ELEMENT = "numAnimalsElement",
        --production part
        STORAGE_LIST_BOX = "storageistBox",
        STORAGE_LIST = "storageList",
        -- control buttons
        BUTTON_SELECT = "buttonSelect",
        BUTTON_APPLY = "buttonApply"
    },
    STATUS_BAR = {
        LOW = 0.2,
        HIGH = 0.8
    }
}

local AnimalInputScreen_mt = Class(AnimalInputScreen, ScreenElement)

function AnimalInputScreen.new(custom_mt)
	local self = ScreenElement.new(nil, custom_mt or AnimalInputScreen_mt)

	self:registerControls(AnimalInputScreen.CONTROLS)

	self.isSourceSelected = true
	self.isOpen = false
	self.lastBalance = 0
	self.selectionState = AnimalInputScreen.SELECTION_NONE

	return self
end

function AnimalInputScreen.createFromExistingGui(gui)
	local controller = gui:getController()
	local newGui = AnimalInputScreen.new()

	newGui:setController(controller)

	return newGui
end

function AnimalInputScreen:setController(controller)
	self.controller = controller

	self.controller:setAnimalsChangedCallback(self.onAnimalsChanged, self)
	self.controller:setActionTypeCallback(self.onActionTypeChanged, self)
	self.controller:setSourceActionFinishedCallback(self.onSourceActionFinished, self)
	self.controller:setErrorCallback(self.onError, self)
end

function AnimalInputScreen:getController()
	return self.controller
end

function AnimalInputScreen:onError(text)
	g_gui:showInfoDialog({
		text = text,
		dialogType = DialogElement.TYPE_WARNING
	})
end


function AnimalInputScreen:onGuiSetupFinished()
	AnimalInputScreen:superClass().onGuiSetupFinished(self)
	self.numAnimalsElement:setTexts({
		"1"
	})

	local orig = self.listSource.onFocusEnter

	function self.listSource.onFocusEnter(...)
		orig(...)

		return self:onFocusEnterList(true, self.listSource, self.listTarget)
	end

    self.storageList:setDataSource(self)
end

function AnimalInputScreen:onOpen()
    AnimalInputScreen:superClass().onOpen(self)

    self.isOpen = true
    self.isUpdating = false

    g_gameStateManager:setGameState(GameState.MENU_ANIMAL_SHOP)
	g_depthOfFieldManager:pushArea(0, 0, 1, 1)
	self:updateScreen()

    if self.listSource:getItemCount() > 0 then
		FocusManager:setFocus(self.listSource)
	end
end

function AnimalInputScreen:onClose()
    AnimalInputScreen:superClass().onClose(self)
    self.controller:reset()

    self.isOpen = false

    g_currentMission:resetGameState()
	g_currentMission:showMoneyChange(MoneyType.NEW_ANIMALS_COST)
	g_currentMission:showMoneyChange(MoneyType.SOLD_ANIMALS)
	g_messageCenter:unsubscribeAll(self)
	g_depthOfFieldManager:popArea()
end

function AnimalInputScreen:onVehicleLeftTrigger()
    if self.isOpen then
        g_gui:showInfoDialog({
			text = g_i18n:getText(AnimalInputScreen.L10N.ERROR_TRAILER_LEFT),
			callback = self.onClickOkVehicleLeft,
			target = self
		})
    end
end

function AnimalInputScreen:onClickOkVehicleLeft()
    self:onClickBack()
end

function AnimalInputScreen:setSelectionState(state)
    self.listSource:setDisabled(state ~= AnimalInputScreen.SELECTION_NONE)
    self.numAnimalsElement:setDisabled(state == AnimalInputScreen.SELECTION_NONE)

    for _, element in ipairs(self.listSource.elements) do
        element:getAttribute("highlight"):setVisible(state == AnimalInputScreen.SELECTION_SOURCE and self.listSource:getSelectedElement() == element)
    end

    if state ~= AnimalInputScreen.SELECTION_NONE then
        local maxElements = self.controller:getMaxNumAnimals()

        if state == AnimalInputScreen.SELECTION_SOURCE then
            self.buttonApply:setText(self.controller:getSourceActionText())

            local animalIndex = self.listSource.selectedIndex
            maxElements = math.max(1, math.min(maxElements, self.controller:getSourceMaxNumAnimals(animalIndex)))
        end

        local texts = {}

		for i = 1, maxElements do
			table.insert(texts, tostring(i))
		end

        self.numAnimalsElement:setTexts(texts)
		FocusManager:setFocus(self.numAnimalsElement)
    elseif self.selectionState == AnimalInputScreen.SELECTION_SOURCE then
        FocusManager:setFocus(self.listSource)
    end

    self.buttonSelect:setVisible(state == AnimalInputScreen.SELECTION_NONE and self.listSource:getItemCount() > 0)
    self.buttonApply:setVisible(state ~= AnimalInputScreen.SELECTION_NONE)

    self.selectionState = state

    self:updatePrice()
end

function AnimalInputScreen:updateBalanceText()
    local balance = 0

    if g_currentMission ~= nil then
        balance = g_currentMission:getMoney()
    end

    if self.lastBalance ~= balance then
        self.lastBalance = balance

        self.balanceElement:setValue(balance)

        if balance > 0 then
            self.balanceElement:applyProfile(AnimalScreen.PROFILE.POSITIVE_BALANCE)
        else
            self.balanceElement:applyProfile(AnimalScreen.PROFILE.NEGATIVE_BALANCE)
        end
    end
end

function AnimalInputScreen:updatePrice()
    local hasCosts, price, fee, total = self:getPrice()

	self.infoPrice:setValue(0)
	self.infoFee:setValue(0)
	self.infoTotal:setValue(0)
	self.infoPrice:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoFee:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoTotal:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoPrice:setValue(hasCosts and price or "-")
	self.infoFee:setValue(hasCosts and fee or "-")
	self.infoTotal:setValue(hasCosts and total or "-")
end

function AnimalInputScreen:updateInfoBox(isSourceSelected)
    if isSourceSelected == nil then
        isSourceSelected = self.isSourceSelected
    end

    local item = self.controller:getSourceItems()[self.listSource.selectedIndex]

    self.infoIcon:setVisible(item ~= nil)
    self.infoName:setVisible(item ~= nil)

    if item ~= nil then
        self.infoIcon:setImageFilename(item:getFilename())
        self.infoName:setText(item:getName())
        self.infoDescription:setText(item:getDescription())

        local infos = item:getInfos()

        for k, infoTitle in ipairs(self.infoTitle) do
            local info = infos[k]
            local infoValue = self.infoValue[k]

            infoTitle:setVisible(info ~= nil)
            infoValue:setVisible(info ~= nil)

            if info ~= nil then
				infoTitle:setText(infos[k].title)
				infoValue:setText(infos[k].value)
			end
        end

        self:updatePrice()
    end
end

function AnimalInputScreen:getPrice()
    local hasCosts, price, fee, total = nil

    if self.isSourceSelected then
		local animalIndex = self.listSource.selectedIndex
		local numAnimals = self.numAnimalsElement:getState()
		hasCosts, price, fee, total = self.controller:getSourcePrice(animalIndex, numAnimals)
	end

	return hasCosts, price, fee, total
end

function AnimalInputScreen:updateStorage()
    self.storageList:reloadData()
end

function AnimalInputScreen:updateScreen()
    self:updateBalanceText()
	self.listSource:reloadData()
	self.headerSource:setText(self.controller:getSourceName())
	self:updatePrice()
	self:updateInfoBox()
    self:updateStorage()
end

function AnimalInputScreen:getNumberOfItemsInSection(list, section)
    if not self.isOpen then
        return 0
    end

    if list == self.listSource then
        return #self.controller:getSourceItems()
    else
        local production = self.controller.production
        return #production.inputFillTypeIdsArray
    end
end

function AnimalInputScreen:getCellTypeForItemInSection(list, section, index)
	if list == self.storageList then
		if section == 1 then
			return "inputCell"
		end
	end
end

function AnimalInputScreen:populateCellForItemInSection(list, section, index, cell)
    local item = nil

	if list == self.listSource then
		item = self.controller:getSourceItems()[index]

        cell:getAttribute("icon"):setImageFilename(item:getFilename())
        cell:getAttribute("name"):setText(item:getName())
        cell:getAttribute("price"):setValue(item:getPrice())
        cell:getAttribute("highlight"):setVisible(false)
    else
        local fillType = nil
        local production = self.controller.production

        if section == 1 then
            fillType = production.inputFillTypeIdsArray[index]
        end

        if fillType ~= FillType.UNKNOWN then
			local fillLevel = production:getFillLevel(fillType)
			local capacity = production:getCapacity(fillType)
			local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)

			cell:getAttribute("icon"):setImageFilename(fillTypeDesc.hudOverlayFilename)
			cell:getAttribute("fillType"):setText(fillTypeDesc.title)
			cell:getAttribute("fillLevel"):setText(g_i18n:formatVolume(fillLevel, 0))

			self:setStatusBarValue(cell:getAttribute("bar"), fillLevel / capacity, true)
		end
	end
end

function AnimalInputScreen:setStatusBarValue(statusBarElement, value, lowIsDanger)
	local profile = "ingameMenuProductionStorageBar"

	if lowIsDanger and value < AnimalInputScreen.STATUS_BAR.LOW or not lowIsDanger and AnimalInputScreen.STATUS_BAR.HIGH < value then
		profile = "ingameMenuProductionStorageBarDanger"
	end

	statusBarElement:applyProfile(profile)

	local fullWidth = statusBarElement.parent.absSize[1] - statusBarElement.margin[1] * 2
	local minSize = 0

	if statusBarElement.startSize ~= nil then
		minSize = statusBarElement.startSize[1] + statusBarElement.endSize[1]
	end

	statusBarElement:setSize(math.max(minSize, fullWidth * math.min(1, value)), nil)
end

function AnimalInputScreen:onAnimalsChanged()
    if not self.isUpdating then
        self:updateScreen()
    end
end

function AnimalInputScreen:onActionTypeChanged(actionType, text)
    if text ~= nil then
		g_gui:showMessageDialog({
			visible = true,
			text = text
		})
	else
		g_gui:showMessageDialog({
			visible = false
		})
	end
end

function AnimalInputScreen:onSourceActionFinished(isWarning, text)
    local msgType = DialogElement.TYPE_INFO

	if isWarning then
		msgType = DialogElement.TYPE_WARNING
	end

	g_gui:showInfoDialog({
		text = text,
		dialogType = msgType
	})
	self:setSelectionState(AnimalInputScreen.SELECTION_NONE)
end

function AnimalInputScreen:onSourceListSelectionChanged(list, section, index)
    if not self.isSourceSelected then
		self:onFocusEnterList(true, list, self.listTarget)
	end

	self:updateInfoBox(true)
end

function AnimalInputScreen:onClickBack()
    AnimalInputScreen:superClass().onClickBack(self)

    if self.selectionState == AnimalInputScreen.SELECTION_NONE then
        self:changeScreen(nil)
    else
        self:setSelectionState(AnimalInputScreen.SELECTION_NONE)
    end
end

function AnimalInputScreen:onClickSelect()
    self:setSelectionState(AnimalInputScreen.SELECTION_SOURCE)

    return true
end

function AnimalInputScreen:onClickApply()
    if self.selectionState == AnimalInputScreen.SELECTION_SOURCE then
        local animalIndex = self.listSource.selectedIndex
        local numAnimals = self.numAnimalsElement:getState()
        local text = self.controller:getApplySourceConfirmationText(animalIndex, numAnimals)

        g_gui:showYesNoDialog({
			text = text,
			callback = self.onYesNoSource,
			target = self
		})
    else
        return false
    end

    return true
end

function AnimalInputScreen:onClickNumAnimals()
    self:updatePrice()
end

function AnimalInputScreen:onYesNoSource(yes)
    if yes then
        local animalIndex = self.listSource.selectedIndex
        local numAnimals = self.numAnimalsElement:getState()

        self.controller:applySource(animalIndex, numAnimals)
    end
end

function AnimalInputScreen:onFocusEnterList(isEnteringSourceList, enteredList, previousList)
    if enteredList:getItemCount() == 0 then
        if previousList:getItemCount() > 0 then
            FocusManager:setFocus(previousList)
        end

        return
    end

    FocusManager:unsetFocus(previousList)

    self.isSourceSelected = isEnteringSourceList

    self:updateInfoBox(isEnteringSourceList)

    if enteredList.selectedIndex == 0 then
        enteredList:setSelectedIndex(1)
    end
end

function AnimalInputScreen:getNumberOfItemsInSelection(list, section)
    if not self.isOpen then
        return 0
    end

    return #self.controller:getSourceItems()
end

function AnimalInputScreen:populateCellForItemInSelection(list, section, index, cell)
    local item = self.controller:getSourceItems()[index]

    cell:getAttribute("icon"):setImageFilename(item:getFilename())
	cell:getAttribute("name"):setText(item:getName())
	cell:getAttribute("price"):setValue(item:getPrice())
	cell:getAttribute("highlight"):setVisible(false)
end

function AnimalInputScreen:onListSelectionChanged(list, section, index)
    if self.isAutoUpdatingList then
        return
    end

    self:onSourceListSelectionChanged(list, section, index)
end

function AnimalInputScreen:onSourceListDoubleClick(list, section, index)
    self:setSelectionState(AnimalInputScreen.SELECTION_SOURCE)
end

function AnimalInputScreen:updateChangedList(listElement, fallbackListElement, restoreSelection)
    self.isAutoUpdatingList = true

    listElement:reloadData()

    self.isAutoUpdatingList = false

    if listElement:getItemCount() == 0 then
        FocusManager:setFocus(fallbackListElement)
        fallbackListElement:setSelectedIndex(1)
    end

    self:updateInfoBox()
    self:updatePrice()
end

function AnimalInputScreen:update(dt)
    AnimalInputScreen:superClass().update(self, dt)

    self:updateScreen()
end