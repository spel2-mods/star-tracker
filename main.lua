---@diagnostic disable: lowercase-global

meta = {
	name = "Star Tracker",
	version = "0.1",
	description = "Displays pet score, quests, aggro",
	author = "fienestar",
	online_safe = true,
}

local Quest = {
	YANG = 1,
	PARSLEY = 2,
	PARSNIP = 3,
	PARMESAN = 4,
	VAN_HORSING = 5,
	MADAME_TUSK = 6,
	SPARROW = 7,
	BEG = 8,

	QUEST_END = 8,
}

local tracker = {
	quests = {
		[Quest.YANG] = false,
		[Quest.PARSLEY] = false,
		[Quest.PARSNIP] = false,
		[Quest.PARMESAN] = false,
		[Quest.VAN_HORSING] = false,
		[Quest.MADAME_TUSK] = false,
		[Quest.SPARROW] = false,
		[Quest.BEG] = false,
	},

	pet = {
		type = 0,
		count = 0,
		count_in_level = 0
	},

	tun_aggro = 0,
	shopkeeper_aggro = 0,
	kills_npc = 0,
	kali_favor = 0,

	images = {
		quest = {
			[Quest.YANG] = 0,
			[Quest.PARSLEY] = 0,
			[Quest.PARSNIP] = 0,
			[Quest.PARMESAN] = 0,
			[Quest.VAN_HORSING] = 0,
			[Quest.MADAME_TUSK] = 0,
			[Quest.SPARROW] = 0,
			[Quest.BEG] = 0,
		},
		pet = {
			[1] = 0,
			[2] = 0,
			[3] = 0,
			[4] = 0
		},
		tun = 0,
		shopkeeper = 0,
	},

	draw_config = {
		image_size = 0.06,
		margin_size = 0.025
	},
}

function tracker:reset()
	for i = 1, Quest.QUEST_END do
		self.quests[i] = false
	end

	self.pet.type = 0
	self.pet.count = 0
	self.pet.count_in_level = 0

	self.tun_aggro = 0
	self.shopkeeper_aggro = 0
	self.kills_npc = 0
	self.kali_favor = 0
end

function tracker:loadImages()
	for i = 1, 8 do
		self.images.quest[i] = create_image('images/quest-' .. i .. '.png')
	end

	for i = 1, 4 do
		self.images.pet[i] = create_image('images/pet-' .. i .. '.png')
	end

	self.images.tun = create_image('images/tun-1.png')
	self.images.shopkeeper = create_image('images/shopkeeper-1.png')
end

---@param quests QuestsInfo
function tracker:updateQuests(quests)
	-- yang
	self.quests[Quest.YANG] = state.quests.yang_state >= YANG.ONE_TURKEY_BOUGHT

	-- jungle sisters
	self.quests[Quest.PARSLEY] = state.quests.jungle_sisters_flags & 1 ~= 0
	self.quests[Quest.PARSNIP] = state.quests.jungle_sisters_flags & 2 ~= 0
	self.quests[Quest.PARMESAN] = state.quests.jungle_sisters_flags & 4 ~= 0

	-- van horsing
	self.quests[Quest.VAN_HORSING] = state.quests.van_horsing_state >= VANHORSING.SHOT_VLAD

	-- sparrow
	self.quests[Quest.SPARROW] = state.quests.sparrow_state == SPARROW.FINAL_REWARD_THROWN

	-- madame tusk
	self.quests[Quest.MADAME_TUSK] = state.quests.madame_tusk_state >= TUSK.PALACE_WELCOME_MESSAGE

	-- beg
	self.quests[Quest.BEG] = state.quests.beg_state == BEG.TRUECROWN_THROWN
end

---@param items Items
function tracker:updateSavedPets(items)
	self.pet.count_in_level = items.saved_pets_count

	for i = 1, self.pet.count_in_level do
		if items.saved_pets[i] ~= 0 then
			if self.pet.type == 0 then
				self.pet.type = items.saved_pets[i] - 325
			elseif items.saved_pets[i] - 325 ~= self.pet.type then
				self.pet.type = 4

			end
		end
	end
end

---@param state StateMemory
function tracker:updateSpecialScores(state)
	self.tun_aggro = state.merchant_aggro
	self.shopkeeper_aggro = state.shoppie_aggro_next
	self.kills_npc = state.kills_npc
	self.kali_favor = state.kali_favor
end

---@param state StateMemory
function tracker:update(state)
	self:updateQuests(state.quests)
	self:updateSavedPets(state.items)
	self:updateSpecialScores(state)
end

---@param draw_ctx GuiDrawContext
---@param quest integer
---@param basex number
---@param basey number
function tracker:drawQuest(draw_ctx, quest, basex, basey)
	local image = self.images.quest[quest]

	draw_ctx:draw_image(image, basex - self.draw_config.image_size, basey, basex, basey - self.draw_config.image_size*3/2, 0, 0, 1, 1, rgba(255, 255, 255, 200))
	basex = basex - self.draw_config.image_size + self.draw_config.margin_size

	return basex, basey
end

---@param draw_ctx GuiDrawContext
---@param basex number
---@param basey number
function tracker:drawQuests(draw_ctx, basex, basey)
	quest_options = {
		[Quest.YANG] = options["yang"],
		[Quest.PARSLEY] = options["jungle sisters"],
		[Quest.PARSNIP] = options["jungle sisters"],
		[Quest.PARMESAN] = options["jungle sisters"],
		[Quest.VAN_HORSING] = options["van horsing"],
		[Quest.MADAME_TUSK] = options["madame tusk"],
		[Quest.SPARROW] = options["sparrow"],
		[Quest.BEG] = options["beg"],
	}

	local exists = false

	for i = Quest.QUEST_END, 1, -1 do
		if self.quests[i] and quest_options[i] then
			basex, basey = self:drawQuest(draw_ctx, i, basex, basey)
			exists = true
		end
	end

	return exists
end

---@param draw_ctx GuiDrawContext
---@param image IMAGE
---@param score integer
---@param basex number
---@param basey number
---@param color integer
function tracker:drawScore(draw_ctx, image, score, basex, basey, color)
	local text = tostring(score)

	local text_width, text_height = draw_text_size(18, text)
	basex = basex - text_width - self.draw_config.margin_size / 4
	draw_ctx:draw_text(basex, basey + text_height / 6, 18, text, color)

	draw_ctx:draw_image(image, basex - self.draw_config.image_size, basey, basex, basey - self.draw_config.image_size*3/2, 0, 0, 1, 1, rgba(255, 255, 255, 200))
	basex = basex - self.draw_config.image_size

	return basex, basey
end

---@param draw_ctx GuiDrawContext
---@param basex number
---@param basey number
function tracker:drawScores(draw_ctx, basex, basey)
	if self.pet.count + self.pet.count_in_level ~= 0 then
		basex, basey = self:drawScore(draw_ctx, self.images.pet[self.pet.type], self.pet.count + self.pet.count_in_level, basex, basey, rgba(255, 255, 255, 200))
	end

	if self.shopkeeper_aggro ~= 0 then
		basex, basey = self:drawScore(draw_ctx, self.images.shopkeeper, self.shopkeeper_aggro, basex, basey, rgba(255, 100, 100, 200))
	end

	if self.tun_aggro ~= 0 then
		basex, basey = self:drawScore(draw_ctx, self.images.tun, self.tun_aggro, basex, basey, rgba(255, 100, 100, 200))
	end
end

---@param draw_ctx GuiDrawContext
function tracker:draw(draw_ctx)
	local basex = 0.95
	local basey = 0.82

	if self:drawQuests(draw_ctx, basex, basey) then
		basex = 0.95
		basey = basey - self.draw_config.image_size*3/2
	end

	self:drawScores(draw_ctx, basex, basey)
end

function tracker:onTransition()
	self.pet.count = self.pet.count + self.pet.count_in_level
	self.pet.count_in_level = 0
end

tracker:loadImages()

display_options = { "yang", "jungle sisters", "van horsing", "sparrow", "madame tusk", "beg", "saved pets", "shopkeeper aggro", "tun aggro" }

for i = 1, #display_options do
	local option = display_options[i]
	register_option_bool(option, "Display " .. option, "", true)
end

display_options[#display_options+1] = "hide-at-constellation"
register_option_bool("hide-at-constellation", "Hide at constellation", "", false)

set_callback(function(save_ctx)
    local save_data_str = json.encode({
		["version"] = "0.1",
		["options"] = options
	})
    save_ctx:save(save_data_str)
end, ON.SAVE)

set_callback(function(load_ctx)
    local save_data_str = load_ctx:load()
    if save_data_str ~= "" then
        local save_data = json.decode(save_data_str)
		if save_data.options then
			options = save_data.options

			for i = 1, #display_options do
				local option = display_options[i]
				if options[option] == nil then
					options[option] = false
				end
			end
		end
    end
end, ON.LOAD)

local get_state = function()
	return state
end

if get_local_state then
	get_state = get_local_state
	---@cast get_state fun(): StateMemory
end

set_callback(function()
	tracker:onTransition()
end, ON.LEVEL)

local event_need_reset = { ON.RESET, ON.MENU }
for i = 1, #event_need_reset do
	local event = event_need_reset[i]
	set_callback(function()
		tracker:reset()
	end, event)
end

set_callback(function()
	if options["hide-at-constellation"] then
		tracker:reset()
	end
end, ON.CONSTELLATION)

set_callback(function()
	local state = get_state()
	tracker:update(state)
end, ON.GAMEFRAME)

set_callback(function(
	draw_ctx ---@cast draw_ctx GuiDrawContext
)
    if get_state().pause == 0 then
		tracker:draw(draw_ctx)
    end
end, ON.GUIFRAME)
