local data = {}

--[[
	Key: rank in group
	Value: required exp

	Experience is assumed to be cumulative. The difference between rank 2 and 3 is 100 exp, meaning you need 150 total exp to be in rank 3. 

	e.g. To be rank 3, you need 150 total experience
]]
data.EXP_LEVELS = {
	[1] = 0,
	[2] = 50,
	[3] = 150,
	[4] = 200,
	[5] = 500,
	[6] = 1000,
	[7] = 1500,
	[8] = 1600,
	[9] = 2000,
	[10] = 5000,
	[11] = 15000,
}

data.ADMIN_LIST = {
	9095598, --hio555
	10205074, --Renewed
}

--[[
	List of all ranks that can give XP, which are not officers
]]
data.STAFF_RANKS = {
	100,
}

--Ranks for roles that can earn xp, inclusive
data.E_RANK_RANGE = { Min = 1, Max = 11 }

--Ranks for roles that can award xp, inclusive
data.O_RANK_RANGE = { Min = 13, Max = 22 }

data.GROUP_ID = 35535718 --dev group currently

data.PASSIVE_XP_AMOUNT = 25 --the amount of xp to be awarded passively
data.PASSIVE_XP_TIME = 100 --time, in seconds, it takes to be awarded xp

data.XP_AWARD_COOLDOWN = 60 --time, in seconds, between xp awards from officers

return data
