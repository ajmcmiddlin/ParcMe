CREATE TABLE Parking2014 (
	ParkingEventId INTEGER,
	DeviceId INTEGER,
	ArrivalTime TEXT, -- from source
	ArrivalTimeSeconds INTEGER, -- Seconds since midnight
	ArrivalDayOfWeek INTEGER, -- 1-7, 1 is Monday
	ArrivalDayOfMonth INTEGER, -- 1-31
	ArrivalMonth INTEGER, -- 1-12
	ArrivalYear INTEGER,
	DepartureTime TEXT, -- from source
	DepartureTimeSeconds INTEGER, -- Seconds since midnight
	DepartureDayOfWeek INTEGER, -- 1-7, 1 is Monday
	DepartureDayOfMonth INTEGER, -- 1-31
	DepartureMonth INTEGER, -- 1-12
	DepartureYear INTEGER,
	Duration INTEGER,
	PermittedDuraction INTEGER,
	StreetMarker TEXT,
	SignPlateId INTEGER,
	Sign TEXT,
	Area INTEGER,
	AreaName TEXT,
	StreetId INTEGER,
	StreetName TEXT,
	BetweenStreet1Id INTEGER,
	BetweenStreet1Description TEXT,
	BetweenStreet2Id INTEGER,
	BetweenStreet2Description TEXT,
	SideOfStreet INTEGER,
	SideCode TEXT,
	SideName TEXT,
	BayID INTEGER,
	InViolation INTEGER
	--PRIMARY KEY (ParkingEventId, DeviceId, StreetId, BayID)
);
