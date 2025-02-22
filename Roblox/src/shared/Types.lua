export type PlayerProfile = {
	Rank: string,
	Experience: number,
	TimeTracker: number,
	OfficerAwardXPTimestamp: number,
}

export type ExpNotification = {
	NewRank: number,
	NewExp: number,
	DidLevelUp: boolean,
	DeltaExp: number,
}

export type StaffExpTransaction = {
	Recipient: Player,
	Amount: number,
}

return nil
