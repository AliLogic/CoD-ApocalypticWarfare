// Includes
#include <a_samp>

#undef MAX_PLAYERS
	#define MAX_PLAYERS			(100)

#include <sscanf2>
#include <YSF>
#include <a_mysql>
#include <easydialog>
#include <streamer>
#include <timestamptodate>
#include <a_http>
#include <foreach>
#include <timerfix>
#include <Pawn.CMD>

// Defines
#define SERVER_NAME				"Call of Duty: Apocalyptic Warfare"
#define SCRIPT_REV				"v0.1" // Update this everytime a change is done.
#define GMTEXT					"FD "#SCRIPT_REV" [TDM/COD/NWG]"
#define WEBSITE					"www.sa-mp.com"
#define TAG						"[NEG]"

#define PRESSING(%0,%1)			(%0 & (%1))
#define RELEASED(%0)			(((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))
#define PASSWORD_SALT			"786t!t>D<QW*@!)#$>C_)_Agdh"

#if !defined function
	#define function%1(%2)		forward public %1(%2); public %1(%2)
#endif

#if !defined strcpy
	#define strcpy(%0,%1)		strcat((%0[0] = EOS, %0), %1
#endif

#if !defined SetAlpha
	#define SetAlpha(%1,%2)		((%1 & ~0xFF) | (clamp(%2, 0x00, 0xFF)))
#endif

#define	GetPlayerStaffRank(%0)	gStaff[pInfo[%0][AdminLvl]]
#define GetPlayerDonorRank(%0)	gDonor[pInfo[%0][DonorLvl]]

#if !defined FLOAT_INFINITY
	#define FLOAT_INFINITY		(Float: 0x7F800000)
#endif

#define MAX_LOGIN_ATTEMPTS		(3)		// Maximum login attempts
#define MIN_PASSWORD_LENGTH 	(5)		// Minimum password length
#define MAX_PASSWORD_LENGTH 	(20)	// Maximum password length
#define MIN_NICK_LENGTH 		(3)		// Minimum username length
#define MAX_NICK_LENGTH			(20)	// Maximum username length
#define MIN_HELP_LENGTH			(10)	// Minimum help message length
#define MAX_HELP_LENGTH			(90)	// Maximum help message length

#define CAPTURE_TIME    		25		// Time to capture a zone (in seconds)
#define MAX_HELPS				15		// Maximum number of help messages that can be detalt at a time
#define MAX_ZONES				17		// Number of capture zones in the script
#define ADMIN_SKIN				(294)	// Administrator on-duty skin
#define GANGZONE_ALPHA			(80)	// Gangzones alpha value

//#define LOCAL							// If script is running on local host

// MySQL
#if defined LOCAL
	#define MYSQL_HOST			"127.0.0.1"
	#define MYSQL_USERNAME		"root"
	#define MYSQL_DATABASE		"tdm"
	#define MYSQL_PASSWORD		""
#else
	#define MYSQL_HOST			"127.0.0.1"
	#define MYSQL_USERNAME		"SAMP_14"
	#define MYSQL_DATABASE		"SAMP_14"
	#define MYSQL_PASSWORD		"8EmBxJYtPC"
#endif

#define TABLE_USERS				"`fd_users`"
#define TABLE_BANS				"`fd_bans`"
#define TABLE_SETTINGS			"`fd_settings`"

// Modules and their definitions
#define ORDER					ASCEND
#include "..\Modules\MyMSG.pwn"
#include "..\Modules\Mapping.pwn"
#include "..\Modules\RandomMsg.pwn"
#include "..\Modules\Colors.pwn"

// Main
main()
{
	print("\n\t"#SERVER_NAME"\n");
}

// Enumerators, Variables and Arrays
enum
{
	WEAPON_FIST = 0,

	CP_TYPE_SHOP = 1,
	CP_TYPE_ZONE,

	CLASS_ASSAULT = 0,
	CLASS_MARKSMAN,
	CLASS_MEDIC,
	CLASS_BOMBER,
	CLASS_JETTROOPER,
	CLASS_AIRTROOPER,
	CLASS_ENGINEER,
	CLASS_SCOUT,
	CLASS_SPY,
	CLASS_PILOT,
	CLASS_DONOR,

	CP_SNAKEFARM = 0,
	CP_AREA51,
	CP_OILCANARY,
	CP_OILFACTORY,
	CP_QUARRY,
	CP_ARMYRESTAURANT,
	CP_BIGEAR,
	CP_DESERTAIRPORT,
	CP_HOSPITAL,
	CP_LVAIRPORT,
	CP_AMMUNATION,
	CP_MISSILEFACTORY,
	CP_WOODLAND,
	CP_TOXICSHIP,
	CP_THEVILLA,
	CP_CARGOSHIP,
	CP_ROCKETSITE,

	TEAM_UK = 0,
	TEAM_USA,
	TEAM_AFRICA,
	TEAM_AUSTRALIA,
	TEAM_RUSSIA
}

enum (<<= 1)
{
	CMD_DONOR = 1,
	CMD_ADMIN
};

static const gDonor[][9] =
{
	"None",
	"Bronze",
	"Silver",
	"Gold"
};

static const gStaff[][22] =
{
	"Player",
	"Trainee Administrator",
	"Junior Administrator",
	"Senior Admin",
	"Lead Administrator",
	"Supervisor",
	"Server Manager",
	"Community Manager",
	"Community Owner"
};

enum E_SPREE
{
	Spree,
	Score,
	Cash
};
new const gCPSpree[][E_SPREE] =
{
	{3, 1, 500},
	{5, 2, 1500},
	{10, 3, 2500},
	{15, 5, 4000},
	{20, 7, 2500},
	{25, 9, 5000},
	{30, 12, 7500},
	{50, 20, 10000},
	{75, 35, 15000},
	{100, 50, 20000},
	{150, 75, 50000},
	{200, 100, 100000},
	{250, 150, 200000}
};

new const gKillSpree[][E_SPREE] =
{
	{3, 2, 2000},
	{5, 3, 4000},
	{10, 5, 7500},
	{15, 5, 7500},
	{20, 9, 12500},
	{25, 15, 17500},
	{30, 20, 25000},
	{50, 30, 35000},
	{75, 50, 50000},
	{100, 75, 75000},
	{150, 100, 100000},
	{200, 175, 150000},
	{250, 200, 200000}
};

enum E_CMDS
{
	CMDName[15],	
	CMDInfo[60]
};
new const gGeneralCommands[][E_CMDS] =
{
	{"/ranks", "View current server ranks"},
	{"/chelp", "View your current class info"},
	{"/top", "Displays the top players in the server"},
	{"/rules", "View the server rules"},
	{"/helpme", "Seek for help from administrators"},
	{"/getid", "Find ID of a person by entering part of thier name"},
	{"/getids", "Get the list of players sharing part of their nick"},
	{"/donors", "See the server donators"},
	{"/changepass", "Change your account password"},
	{"/changename", "Change your account username"},
	{"/team", "View the amount of players and zones captured by your team"},
	{"/report", "Report a rule breaker to administrators."},
	{"/objective", "View the server objectives"},
	{"/credits", "View server credits"},
	{"/bonus", "View bonus zone and bonus player"},
	{"/teams", "View players in teams"}
};

new const gPlayerCommands[][E_CMDS] =
{
	{"/s", "Send a message to nearby players"},
	{"/r", "Send a message to your team"},
	{"/pm", "Send a private message to a player"},
	{"/dnd", "Toggle private messages"},
	{"/(un)dis", "Disguise as other teams"},
	{"/stats", "View your or other's stats"},
	{"/savestats", "Save your stats"},
	{"/st", "Change teams and classes"},
	{"/sp", "Change your spawn point"},
	{"/kill", "Request death"},
	{"/jetpack", "Spawn a jetpack"},
	{"/heal", "Heal up to four team mates near you"},
	{"/armour", "Armour up to four team mates near you"},
	{"/ignore", "Close all communication ways to a player"},
	{"/spree", "View your or other's spree"},
	{"/suicide", "Suicide to blow up yourself and kill enemies nearby"},
	{"/repair", "Repair your vehicle"},
	{"/raid", "Raid over other team's base"}
};

new const gDonorCommands[][E_CMDS] =
{
	{"/d", "Send a message to donor chat"},
	{"/dcc", "Change your vehicle colors"},
	{"/dnos", "Add Nitrous to your vehicle"},
	{"/dtime", "Change your time"},
	{"/dweather", "Change yur weather"},
	{"/dammo", "Recieve some ammo for your weapon"},
	
	{"/dfix**", "Fix your vehicle"},
	{"/dskin**", "Change your skin"},
	{"/dbike**", "Spawn a NRG-500"},
	{"/darmor**", "Spawn a full armor"},
	{"/dheal**", "Heal yourself"},
	
	{"/dboost***", "Boost yourself and nearby mates with some weapons"},
	{"/dcar***", "Spawn an Infernus"},
	
	{"/dheli***", "Spawn a helicopter"},
	{"/dboat***", "Spawn a Dinghy"}
};

enum E_SHOPWEAPON
{
	sWeaponID,
	sWeaponCost,
	sWeaponAmmo
};
new const gShopWeapons[][E_SHOPWEAPON] =
{
	{WEAPON_M4, 5000, 200},
	{WEAPON_DEAGLE, 3000, 150},
	{WEAPON_SHOTGSPA, 6000, 260},
	{WEAPON_SHOTGUN, 2800, 200},
	{WEAPON_GRENADE, 3500, 3},
	{WEAPON_AK47, 5200, 220},
	{WEAPON_MP5, 1500, 200},
	{WEAPON_ROCKETLAUNCHER, 8200, 4},
	{WEAPON_TEC9, 1000, 240},
	{WEAPON_MOLTOV, 1800, 4},
	{WEAPON_TEARGAS, 400, 4}
};

enum E_SERVER
{
	ReadPM,
	ChatDisabled,
	MaxPing,
	Weather,
	Time,
	Players
};
new sInfo[E_SERVER];

enum E_HELP
{
	HelpOpen,
	HelpBy,
	HelpInfo[MAX_HELP_LENGTH],
	HelpTime
}
new hInfo[MAX_HELPS][E_HELP], Iterator: Helps<MAX_HELPS>;

enum E_SPEC
{
	Spec,
	SpecID,
	Int,
	VW,
	Float: Pos[3]
};
new pSpec[MAX_PLAYERS][E_SPEC];

enum E_ACCOUNT
{
	SQLID,
	Password[65],
	Kills,
	Deaths,
	Heads,
	Captures,
	Cash,
	Score,
	AdminLvl,
	CTag,
	DonorLvl,
	RegDate[12],
	Hours,
	Mins,
	Secs,
	
	Warns,
	Car,
	Mute,
	MuteTime,
	Freeze,
};
new pInfo[MAX_PLAYERS][E_ACCOUNT];

enum E_ANTICHEAT
{
	Weap[13],
	WeapAmmo[13],
	WeapTick
};
new pAntiCheat[MAX_PLAYERS][E_ANTICHEAT];

enum E_CLASS
{
	ClassName[13],
	ClassRank,
	ClassWeap1[2],
	ClassWeap2[2],
	ClassWeap3[2],
	ClassWeap4[2],
	ClassWeap5[2]
};
new const gClass[][E_CLASS] =
{
	{"Assault", 0, {WEAPON_SHOTGSPA, 200}, {WEAPON_DEAGLE, 200}, {WEAPON_M4, 200}, {0, 0}, {0, 0}},
	{"Marksman", 1, {WEAPON_SNIPER, 250}, {WEAPON_SILENCED, 150}, {WEAPON_SHOTGUN, 100}, {WEAPON_TEARGAS, 3}, {WEAPON_KNIFE, 1}},
	{"Medic", 2, {WEAPON_RIFLE, 200}, {WEAPON_DEAGLE, 100}, {WEAPON_TEARGAS, 3}, {WEAPON_TEC9, 150}, {0, 0}},
	{"Bomber", 3, {WEAPON_GRENADE, 8}, {WEAPON_AK47, 150}, {WEAPON_ROCKETLAUNCHER, 3}, {WEAPON_SHOTGUN, 200}, {0, 0}},
	{"Jet Trooper", 4, {WEAPON_UZI, 200}, {WEAPON_SAWEDOFF,  120}, {WEAPON_AK47, 100}, {WEAPON_MOLTOV, 2}, {0, 0}},
	{"Air Trooper", 4, {WEAPON_DEAGLE, 100}, {WEAPON_SHOTGUN, 100}, {WEAPON_CHAINSAW, 1}, {WEAPON_TEARGAS, 5}, {0, 0}},
	{"Engineer", 5, {WEAPON_SHOTGSPA, 100}, {WEAPON_M4, 300}, {WEAPON_DEAGLE, 200}, {WEAPON_ROCKETLAUNCHER, 3}, {0, 0}},
	{"Scout", 5, {WEAPON_SAWEDOFF, 150}, {WEAPON_DEAGLE, 100}, {WEAPON_MP5, 100}, {0, 0}, {0, 0}},
	{"Spy", 7, {WEAPON_KNIFE, 1}, {WEAPON_SHOTGSPA, 150}, {WEAPON_AK47, 200}, {WEAPON_SILENCED, 300}, {WEAPON_TEARGAS, 2}},
	{"Pilot", 8, {WEAPON_TEC9, 100}, {WEAPON_M4, 150}, {WEAPON_SHOTGSPA, 100}, {WEAPON_GRENADE, 4}, {0, 0}},
	{"Donor", 0, {WEAPON_DEAGLE, 300}, {WEAPON_MP5, 200}, {WEAPON_KNIFE, 1}, {WEAPON_MOLTOV, 10}, {WEAPON_SAWEDOFF,  200}}
};

enum E_BONUS
{
	BonusID,
	BonusCash,
	BonusScore,
	BonusPrv,
	BonusTime
};
new gBonusZone[E_BONUS], gBonusPlayer[E_BONUS];

enum E_CP
{
	ZoneName[20],
	Float: ZonePos[4],
	Float: ZoneCP[3],
	Float: ZoneSpawn[4],
	ZoneOwner,
	ZoneAttacker,
	ZoneTick,
	ZoneID,
	Text3D: ZoneLabel,
	ZoneCPID,
	ZoneTimer,
	ZonePlayer
};
new const gZones[MAX_ZONES][E_CP] =
{
	{"Snake Farm",		{-62.500, 2318.359375, 23.4375, 2390.625},			{-36.5458, 2347.6426, 24.1406},		{-26.9154, 2323.7378, 24.1406, 135.0},	NO_TEAM},
	{"Area 51",			{-46.875, 1697.265625, 423.828125, 2115.234375},	{254.0467, 1802.4382, 7.4141}, 		{208.0049, 1873.5392, 13.1470, 0.0},	NO_TEAM},
	{"Oil Canary",		{95.703125, 1339.84375, 287.109375, 1484.375},		{221.0856,1422.6615,10.5859}, 		{0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"Oil Factory",		{529.296875, 1205.078125, 636.71875, 1267.578125},	{558.9932,1221.8896,11.7188}, 		{0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"Quarry", 			{439.453125, 748.046875, 863.28125, 992.1875},		{588.3246,875.7402,-42.4973}, 		{0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"Army Restaurant", {-357.421875, 1707.03125, -253.90625, 1835.9375},	{-314.8433,1773.9176,43.6406},		{0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"Big Ear",			{-437.5, 1513.671875, -244.140625, 1636.71875}, 	{-311.0136,1542.9733,75.5625},		{-289.8035, 1536.1458, 75.5625, 248.0173},	NO_TEAM},
	{"Desert Airport",	{46.7115, 2358.931, 490.4708, 2604.166},			{406.1056,2456.0640,16.5000},		{0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"The Hospital",	{966.796875, 972.65625, 1166.01563, 1160.15625},	{1044.83008, 1013.94354, 10.19003}, {0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"LV Airport",		{1230.46875, 1142.578125, 1640.625, 1798.828125},	{1603.51587, 1178.88391, 13.41670}, {0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"Ammu-Nation", 	{-351.5625, 811.5234375, -284.180, 884.765625},		{-315.79111, 834.14001, 13.44070},	{0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"Missile Factory", {-476.5625, 2195.3125, -351.5625, 2277.34375}, 		{-427.48999, 2205.93652, 41.53221},	{0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"Woodland", 		{-1492.3135, 1946.2755, -1517.4520, 1979.5021}, 	{-1507.4615, 1973.9753, 48.4171},	{0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"Toxic Ship",		{-1480.46875, 1476.5625, -1332.03125, 1519.53125},	{-1433.3490, 1486.6575, 1.8672},	{0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"The Villa",		{-718.75, 917.96875, -644.53125, 976.5625}, 		{-688.13782, 936.66589, 13.04289},	{-691.9613, 939.6481, 13.6328, 269.0418},	NO_TEAM},
	{"Cargo Ship",		{-2531.25, 1526.3672, -2288.0859, 1596.680},		{-2474.13135, 1548.24231, 32.42630}, {0.0, 0.0, 0.0, 0.0},	NO_TEAM},
	{"Rocket Site",		{-843.75, 2371.875, -728.90625, 2453.90625}, 		{-797.59857, 2415.76099, 156.04553}, {0.0, 0.0, 0.0, 0.0},	NO_TEAM}
};

enum E_SHOP
{
	ShopTeam,
	Float: ShopPos[3],
	Text3D: Label,
	ShopCPID
};
new const gShop[][E_SHOP] =
{
	{0, {1091.38049, 1938.48450, 10.53916}}, // United Kingdom
	{1, {-251.47047, 2603.62109, 62.8582}}, // United States
	{2, {-814.8721, 1571.6704, 27.1172}}, // Africa
	{3, {-1395.7142, 2628.1777, 55.9746}}, // Australia
	{4, {-136.4923, 1117.1815, 20.1966}}, // Russia
	{NO_TEAM, {-374.6179, 1548.8802, 75.6091}} // Big Ear
};

enum E_EVENT
{
	Event,
	Join
};
new gEvent[E_EVENT];

enum E_TEAM
{
	TeamName[16],
	TeamColor,
	TeamSkin,
	Float: TeamSpawn1[3],
	Float: TeamSpawn2[3],
	Float: TeamSpawn3[3],
	Float: Base[4],
	TeamBaseID,
	TeamBaseArea
};
new const gTeam[][E_TEAM] =
{
	{
		"United Kingdom",
		0x51AD6CFF, // Green
		124,
		{1112.5555,1893.9420,10.8203},
		{1067.1792,1874.2611,10.8203},
		{1056.7815,1959.6592,10.8203},
		{1016.9058, 1838.6093, 1134.1102, 2043.6521}
	},
	{
		"United States",
		0x4FB4F2FF, // Blue
		287,
		{-146.4213, 2732.7354, 62.7782},
		{-267.8232, 2671.0178, 62.6759},
		{-177.7588, 2691.3469, 62.6875},
		{-353.515625, 2574.21875, -113.28125, 2796.875}
	},
	{
		"Africa",
		0xFF6600FF,
		142,
		{-826.6808, 1447.5480, 14.0498},
		{-749.4841, 1596.6335, 27.1172},
		{-732.7656, 1546.1833, 38.9930},
		{-875.8406, 1389.667, -607.2495, 1623.225}
	},
	{
		"Australia",
		0x7D3093FF, // Purple
		248,
		{-1483.5421, 2645.1912, 58.7281},
		{-1472.9514, 2531.4434, 55.8359},
		{-1529.2646, 2584.8423, 55.8359},
		{-1640.625, 2501.953125, -1359.375, 2748.046875}
	},
	{
		"Russia",
		0x33B4A8FF, // Torquoise (Was 39C9BB)
		285,
		{-42.0783, 1154.6727, 19.7103},
		{-99.1854, 1086.7211, 19.7422},
		{-122.2590, 1165.3926, 19.7422},
		{-309.375, 1024.21875, 103.125, 1211.71875}
	}
};

enum E_RANK
{
	RankName[30],
	RankScore
};
new const gRank[][E_RANK] =
{
	{"Recruit",				0},
	{"Private",				100},
	{"Specialist",			300},
	{"Corporal",			500},
	{"Sergeant",			750},
	{"Sergeant Major",		1000},
	{"Officer",				1500},
	{"Hero",				2500},
	{"Lieutenant",			3500},
	{"Captain",				5000},
	{"Major",				7000},
	{"Colonel",				10000},
	{"Brigadier General",	15000},
	{"Major General",		20000},
	{"General",				30000},
	{"Major General",		100000},
	{"Brigadier General",	150000},
	{"Master Of War",		200000},
	{"God of War",			1000000}
};

enum E_COOLDOWN
{
	DHEAL,
	DARMOR,
	DFIX,
	DBOOST,
	DCAR,
	DSTEALTH,
	DBOAT,
	DBIKE,
	DAMMO,
	DHELI,
	CLASS
};
new pCooldown[MAX_PLAYERS][E_COOLDOWN];

new MySQL: gSQL, pLoginAttempts[MAX_PLAYERS char], PlayerText: StatsTD[MAX_PLAYERS], pRank[MAX_PLAYERS char], pLastPM[MAX_PLAYERS char],
	pClass[MAX_PLAYERS char], pTeam[MAX_PLAYERS char], AntiSK[MAX_PLAYERS], AntiSKt[MAX_PLAYERS], pPauseTimer[MAX_PLAYERS],
	PlayerText: IssuerTD[MAX_PLAYERS], IssuerTDvar[MAX_PLAYERS], PlayerText: PlayerTD[MAX_PLAYERS], PlayerTDvar[MAX_PLAYERS],
	PlayerTDt[MAX_PLAYERS], IssuerTDt[MAX_PLAYERS], pAdmDuty[MAX_PLAYERS char], pLogged[MAX_PLAYERS char], Assist[MAX_PLAYERS] = INVALID_PLAYER_ID,
	PlayerText: VehName[MAX_PLAYERS], VehTDvar[MAX_PLAYERS], Text3D: pLabel[MAX_PLAYERS], pCMDTick[MAX_PLAYERS], Text: AnnounceTD,
	KillSpree[MAX_PLAYERS], CPSpree[MAX_PLAYERS], pHelmet[MAX_PLAYERS char], SpawnPlace[MAX_PLAYERS], DND[MAX_PLAYERS], Text: WebsiteTD,
	SQLCheck[MAX_PLAYERS], pName[MAX_PLAYERS][MAX_PLAYER_NAME], pHelmetObj[MAX_PLAYERS], pGasObj[MAX_PLAYERS], Text: ZoneTextdraw[MAX_ZONES],
	HelpSelected[MAX_PLAYERS], LastSpawn[MAX_PLAYERS] = -1, Text: AssistBox[2], PlayerText: TeamTD[MAX_PLAYERS], Float: AC_Pos[MAX_PLAYERS][3],
	PlayerText: DeathTD[MAX_PLAYERS], PlayerText: KillTD[MAX_PLAYERS], pGas[MAX_PLAYERS char], pIgnoring[MAX_PLAYERS][MAX_PLAYERS], pJoin[MAX_PLAYERS char];

static const WeapSlot[] =
{
	0, 0, 1, 1, 1, 1, 1, 1, 1, 1,
	10, 10, 10, 10, 10, 10, 8, 8,
	8, -1, -1, -1, 2, 2, 2, 3, 3,
	3, 4, 4, 5, 5, 4, 6, 6, 7, 7,
	7, 7, 8, 12, 9, 9, 9, 11, 11, 11
};

static const WeaponNames[55][] =
{
	{"Punch"}, {"Brass Knuckles"}, {"Golf Club"}, {"Nite Stick"}, {"Knife"}, {"Baseball Bat"}, {"Shovel"}, {"Pool Cue"}, {"Katana"}, {"Chainsaw"}, {"Purple Dildo"}, {"Small White Vibrator"},
	{"Large White Vibrator"}, {"Silver Vibrator"}, {"Flowers"}, {"Cane"}, {"Grenade"}, {"Tear Gas"}, {"Molotov Cocktail"}, {""}, {""}, {""}, {"Colt"}, {"Silenced 9mm"}, {"Desert Eagle"},
	{"Shotgun"}, {"Sawed off"}, {"Combat Shotgun"}, {"Micro SMG"}, {"MP5"}, {"AK-47"}, {"M4"}, {"Tec9"}, {"Rifle"}, {"Sniper Rifle"}, {"RPG"}, {"Homing RPG"},
	{"Flamethrower"}, {"Minigun"}, {"C4"}, {"Detonator"}, {"Spraycan"}, {"Fire Extinguisher"}, {"Camera"}, {"Nightvision Goggles"}, {"Thermal Goggles"},
	{"Parachute"}, {"Fake Pistol"}, {""}, {"Vehicle Ram"}, {"Helicopter Blades"}, {"Explosion"}, {""}, {"Drowned"}, {"Collision"}
};

static const VehicleNames[212][] =
{
	{"Landstalker"}, {"Bravura"}, {"Buffalo"}, {"Linerunner"}, {"Perrenial"}, {"Sentinel"}, {"Dumper"},
	{"Firetruck"}, {"Trashmaster"}, {"Stretch"}, {"Manana"}, {"Infernus"}, {"Voodoo"}, {"Pony"}, {"Mule"},
	{"Cheetah"}, {"Ambulance"}, {"Leviathan"}, {"Moonbeam"}, {"Esperanto"}, {"Taxi"}, {"Washington"},
	{"Bobcat"}, {"Mr Whoopee"}, {"BF Injection"}, {"Hunter"}, {"Premier"}, {"Enforcer"}, {"Securicar"},
	{"Banshee"}, {"Predator"}, {"Bus"}, {"Rhino"}, {"Barracks"}, {"Hotknife"}, {"Trailer 1"}, {"Previon"},
	{"Coach"}, {"Cabbie"}, {"Stallion"}, {"Rumpo"}, {"RC Bandit"}, {"Romero"}, {"Packer"}, {"Monster"},
	{"Admiral"}, {"Squalo"}, {"Seasparrow"}, {"Pizzaboy"}, {"Tram"}, {"Trailer 2"}, {"Turismo"},
	{"Speeder"}, {"Reefer"}, {"Tropic"}, {"Flatbed"}, {"Yankee"}, {"Caddy"}, {"Solair"}, {"Berkley's RC Van"},
	{"Skimmer"}, {"PCJ-600"}, {"Faggio"}, {"Freeway"}, {"RC Baron"}, {"RC Raider"}, {"Glendale"}, {"Oceanic"},
	{"Sanchez"}, {"Sparrow"}, {"Patriot"}, {"Quad"}, {"Coastguard"}, {"Dinghy"}, {"Hermes"}, {"Sabre"},
	{"Rustler"}, {"ZR-350"}, {"Walton"}, {"Regina"}, {"Comet"}, {"BMX"}, {"Burrito"}, {"Camper"}, {"Marquis"},
	{"Baggage"}, {"Dozer"}, {"Maverick"}, {"News Chopper"}, {"Rancher"}, {"FBI Rancher"}, {"Virgo"}, {"Greenwood"},
	{"Jetmax"}, {"Hotring"}, {"Sandking"}, {"Blista Compact"}, {"Police Maverick"}, {"Boxville"}, {"Benson"},
	{"Mesa"}, {"RC Goblin"}, {"Hotring Racer A"}, {"Hotring Racer B"}, {"Bloodring Banger"}, {"Rancher"},
	{"Super GT"}, {"Elegant"}, {"Journey"}, {"Bike"}, {"Mountain Bike"}, {"Beagle"}, {"Cropdust"}, {"Stunt"},
	{"Tanker"}, {"Roadtrain"}, {"Nebula"}, {"Majestic"}, {"Buccaneer"}, {"Shamal"}, {"Hydra"}, {"FCR-900"},
	{"NRG-500"}, {"HPV1000"}, {"Cement Truck"}, {"Tow Truck"}, {"Fortune"}, {"Cadrona"}, {"FBI Truck"},
	{"Willard"}, {"Forklift"}, {"Tractor"}, {"Combine"}, {"Feltzer"}, {"Remington"}, {"Slamvan"},
	{"Blade"}, {"Freight"}, {"Streak"}, {"Vortex"}, {"Vincent"}, {"Bullet"}, {"Clover"}, {"Sadler"},
	{"Firetruck LA"}, {"Hustler"}, {"Intruder"}, {"Primo"}, {"Cargobob"}, {"Tampa"}, {"Sunrise"}, {"Merit"},
	{"Utility"}, {"Nevada"}, {"Yosemite"}, {"Windsor"}, {"Monster A"}, {"Monster B"}, {"Uranus"}, {"Jester"},
	{"Sultan"}, {"Stratum"}, {"Elegy"}, {"Raindance"}, {"RC Tiger"}, {"Flash"}, {"Tahoma"}, {"Savanna"},
	{"Bandito"}, {"Freight Flat"}, {"Streak Carriage"}, {"Kart"}, {"Mower"}, {"Duneride"}, {"Sweeper"},
	{"Broadway"}, {"Tornado"}, {"AT-400"}, {"DFT-30"}, {"Huntley"}, {"Stafford"}, {"BF-400"}, {"Newsvan"},
	{"Tug"}, {"Trailer 3"}, {"Emperor"}, {"Wayfarer"}, {"Euros"}, {"Hotdog"}, {"Club"}, {"Freight Carriage"},
	{"Trailer 3"}, {"Andromada"}, {"Dodo"}, {"RC Cam"}, {"Launch"}, {"Police Car (LSPD)"}, {"Police Car (SFPD)"},
	{"Police Car (LVPD)"}, {"Police Ranger"}, {"Picador"}, {"S.W.A.T. Van"}, {"Alpha"}, {"Phoenix"}, {"Glendale"},
	{"Sadler"}, {"Luggage Trailer A"}, {"Luggage Trailer B"}, {"Stair Trailer"}, {"Boxville"}, {"Farm Plow"}, {"Utility Trailer"}
};

stock Hook_SetPlayerPos(playerid, Float:x, Float:y, Float:z)
{
	AC_Pos[playerid][0] = x;
	AC_Pos[playerid][1] = y;
	AC_Pos[playerid][2] = z;

	return SetPlayerPos(playerid, x, y, z);
}
#if defined _ALS_SetPlayerPos
	#undef SetPlayerPos
#else
	#define _ALS_SetPlayerPos
#endif

#define SetPlayerPos Hook_SetPlayerPos

stock Hook_GivePlayerWeapon(playerid, weaponid, ammo)
{
	pAntiCheat[playerid][Weap][WeapSlot[weaponid]] = weaponid;
	pAntiCheat[playerid][WeapAmmo][WeapSlot[weaponid]] = ammo;
	pAntiCheat[playerid][WeapTick] = (gettime() + 7);
	
	return GivePlayerWeapon(playerid, weaponid, ammo);
}
#if defined _ALS_GivePlayerWeapon
	#undef GivePlayerWeapon
#else
	#define _ALS_GivePlayerWeapon
#endif

#define GivePlayerWeapon Hook_GivePlayerWeapon

stock Hook_ResetPlayerWeapons(playerid)
{
	pAntiCheat[playerid][WeapTick] = (gettime() + 7);
	
	for(new i; i < 13; i++)
	{
		pAntiCheat[playerid][Weap][i] = 0;
		pAntiCheat[playerid][WeapAmmo][i] = 0;
	}
	
	return ResetPlayerWeapons(playerid);
}

#if defined _ALS_ResetPlayerWeapons
	#undef ResetPlayerWeapons
#else
	#define _ALS_ResetPlayerWeapons
#endif

#define ResetPlayerWeapons Hook_ResetPlayerWeapons

// Rest of the gamemode
ExitGlobalTDs()
{
	TextDrawDestroy(WebsiteTD);
	TextDrawDestroy(AnnounceTD);
}

InitializeGlobalTDs()
{
	AnnounceTD = TextDrawCreate(320.000000, 158.000000, "_");
	TextDrawAlignment(AnnounceTD, 2);
	TextDrawBackgroundColor(AnnounceTD, 255);
	TextDrawFont(AnnounceTD, 3);
	TextDrawLetterSize(AnnounceTD, 0.600000, 2.400000);
	TextDrawColor(AnnounceTD, -1);
	TextDrawSetOutline(AnnounceTD, 1);
	TextDrawSetProportional(AnnounceTD, 1);
	TextDrawSetSelectable(AnnounceTD, 0);

	WebsiteTD = TextDrawCreate(501.000000, 10.000000, "~b~~h~~h~"#WEBSITE"");
	TextDrawLetterSize(WebsiteTD, 0.300000, 1.000000);
	TextDrawAlignment(WebsiteTD, 1);
	TextDrawColor(WebsiteTD, -1);
	TextDrawSetShadow(WebsiteTD, 0);
	TextDrawSetOutline(WebsiteTD, 1);
	TextDrawFont(WebsiteTD, 3);
	TextDrawSetProportional(WebsiteTD, 1);

	AssistBox[0] = TextDrawCreate(320.000000, 143.000000, "_");
	TextDrawAlignment(AssistBox[0], 2);
	TextDrawBackgroundColor(AssistBox[0], 255);
	TextDrawFont(AssistBox[0], 2);
	TextDrawLetterSize(AssistBox[0], 0.300000, 1.700000);
	TextDrawColor(AssistBox[0], -1);
	TextDrawSetOutline(AssistBox[0], 0);
	TextDrawSetProportional(AssistBox[0], 1);
	TextDrawSetShadow(AssistBox[0], 0);
	TextDrawUseBox(AssistBox[0], 1);
	TextDrawBoxColor(AssistBox[0], 175);
	TextDrawTextSize(AssistBox[0], 3.000000, 84.000000);
	TextDrawSetSelectable(AssistBox[0], 0);

	AssistBox[1] = TextDrawCreate(320.000000, 145.000000, "~l~Assist");
	TextDrawAlignment(AssistBox[1], 2);
	TextDrawBackgroundColor(AssistBox[1], 255);
	TextDrawFont(AssistBox[1], 2);
	TextDrawLetterSize(AssistBox[1], 0.300000, 1.300000);
	TextDrawColor(AssistBox[1], -1);
	TextDrawSetOutline(AssistBox[1], 0);
	TextDrawSetProportional(AssistBox[1], 1);
	TextDrawSetShadow(AssistBox[1], 0);
	TextDrawUseBox(AssistBox[1], 1);
	TextDrawBoxColor(AssistBox[1], 16744447);
	TextDrawTextSize(AssistBox[1], 3.000000, 82.000000);
	TextDrawSetSelectable(AssistBox[1], 0);
	return 1;
}

public OnGameModeInit()
{
	AntiDeAMX();
	SetGameModeText(""GMTEXT"");
	SendRconCommand("weburl "WEBSITE"");
	SendRconCommand("password flake007");

	InitializeSaving();
	LoadBox();
	InitializeGlobalTDs();
	IntializeMapping();
	mysql_pquery(gSQL, "SELECT * FROM "#TABLE_SETTINGS"", "InitializeConfig");

	UsePlayerPedAnims();
	DisableInteriorEnterExits();
	EnableStuntBonusForAll(0);
	DisableNameTagLOS();
	EnableVehicleFriendlyFire();
	
	SetTimer("RandomMessage", 300000, true); // 5 minutes
	SetTimer("StatsTimer", 600000, true); // 10 minutes
	SetTimer("AntiCheat", 1200, false); // 1 second

	gBonusZone[BonusID] = MAX_ZONES;
	gBonusZone[BonusTime] = SetTimer("BonusZone", 600000, false); // 10 minutes

	gBonusPlayer[BonusID] = INVALID_PLAYER_ID;
	gBonusPlayer[BonusTime] = SetTimer("BonusPlayer", 60000, false); // 10 minutes

	new label[65], array[2];

	array[0] = CP_TYPE_SHOP;
	for(new i; i < sizeof gShop; i++)
	{
		array[1] = i;
		label[0] = EOS;
		CreateDynamicMapIcon(gShop[i][ShopPos][0], gShop[i][ShopPos][1], gShop[i][ShopPos][2], 6, 0, 0, .streamdistance = 300.0);
		gShop[i][ShopCPID] = CreateDynamicCP(gShop[i][ShopPos][0], gShop[i][ShopPos][1], gShop[i][ShopPos][2], 2.0, 0, .streamdistance = 50.0);
		Streamer_SetArrayData(STREAMER_TYPE_CP, gShop[i][ShopCPID], E_STREAMER_EXTRA_ID, array, 2);
		CreateDynamicPickup(1210, 1, gShop[i][ShopPos][0], gShop[i][ShopPos][1], gShop[i][ShopPos][2] + 0.5);
		
		if(gShop[i][ShopTeam] != NO_TEAM) format(label, sizeof label, "%s's Shop", gTeam[gShop[i][ShopTeam]][TeamName]);
		else format(label, sizeof label, "Zone Shop");
		CreateDynamic3DTextLabel(label, (gShop[i][ShopTeam] != NO_TEAM) ? (gTeam[gShop[i][ShopTeam]][TeamColor]) : (0xFFFFFFFF), gShop[i][ShopPos][0], gShop[i][ShopPos][1], gShop[i][ShopPos][2], 20.0, .testlos = 0);
	}

	for(new i; i < sizeof gTeam; i++)
	{
		AddPlayerClass(gTeam[i][TeamSkin], 667.7617, 2435.9387, 408.0376, 218.6621, 0, 0, 0, 0, 0, 0);
		gTeam[i][TeamBaseID] = GangZoneCreate(gTeam[i][Base][0], gTeam[i][Base][1], gTeam[i][Base][2], gTeam[i][Base][3]);
		gTeam[i][TeamBaseArea] = CreateDynamicRectangle(gTeam[i][Base][0], gTeam[i][Base][1], gTeam[i][Base][2], gTeam[i][Base][3], 0, 0);

		CreateDynamic3DTextLabel("Spawn Point #1", gTeam[i][TeamColor], gTeam[i][TeamSpawn1][0], gTeam[i][TeamSpawn1][1], gTeam[i][TeamSpawn1][2] + 0.5, 20.0, .testlos = 1);
		CreateDynamic3DTextLabel("Spawn Point #2", gTeam[i][TeamColor], gTeam[i][TeamSpawn2][0], gTeam[i][TeamSpawn2][1], gTeam[i][TeamSpawn2][2] + 0.5, 20.0, .testlos = 1);
		CreateDynamic3DTextLabel("Spawn Point #3", gTeam[i][TeamColor], gTeam[i][TeamSpawn3][0], gTeam[i][TeamSpawn3][1], gTeam[i][TeamSpawn3][2] + 0.5, 20.0, .testlos = 1);
	}

	array[0] = CP_TYPE_ZONE;
	for(new i; i < MAX_ZONES; i++)
	{
		array[1] = i;
		gZones[i][ZoneCPID] = CreateDynamicCP(gZones[i][ZoneCP][0], gZones[i][ZoneCP][1], gZones[i][ZoneCP][2], 3.0, 0, .streamdistance = 150.0);
		Streamer_SetArrayData(STREAMER_TYPE_CP, gZones[i][ZoneCPID], E_STREAMER_EXTRA_ID, array, 2);
		CreateDynamicMapIcon(gZones[i][ZoneCP][0], gZones[i][ZoneCP][1], gZones[i][ZoneCP][2], 19, 0, 0, .streamdistance = 700.0);
		label[0] = EOS;
		gZones[i][ZoneAttacker] = INVALID_PLAYER_ID;
		if(gZones[i][ZoneSpawn][0] != 0.0) CreateDynamic3DTextLabel("Zone Spawn Point", 0xFFFFFFFF, gZones[i][ZoneSpawn][0], gZones[i][ZoneSpawn][1], gZones[i][ZoneSpawn][2] + 0.5, 20.0, .testlos = 1);
		
		if(gZones[i][ZoneOwner] != NO_TEAM)
		{
			gZones[i][ZoneID] = GangZoneCreate(gZones[i][ZonePos][0], gZones[i][ZonePos][1], gZones[i][ZonePos][2], gZones[i][ZonePos][3]);
			format(label, sizeof label, "%s\n{FFFFFF}Controlled by %s", gZones[i][ZoneName], gTeam[gZones[i][ZoneOwner]][TeamName]);
			gZones[i][ZoneLabel] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, gZones[i][ZoneCP][0], gZones[i][ZoneCP][1], gZones[i][ZoneCP][2] + 0.5, 20.0, .testlos = 1);
		}
		else
		{
			gZones[i][ZoneID] = GangZoneCreate(gZones[i][ZonePos][0], gZones[i][ZonePos][1], gZones[i][ZonePos][2], gZones[i][ZonePos][3]);
			format(label, sizeof label, "%s\nUncontrolled", gZones[i][ZoneName]);
			gZones[i][ZoneLabel] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, gZones[i][ZoneCP][0], gZones[i][ZoneCP][1], gZones[i][ZoneCP][2] + 0.5, 20.0, .testlos = 1);
		}

		ZoneTextdraw[i] = TextDrawCreate(577.000000, 200.000000, "*");
		TextDrawAlignment(ZoneTextdraw[i], 2);
		TextDrawBackgroundColor(ZoneTextdraw[i], 255);
		TextDrawFont(ZoneTextdraw[i], 2);
		TextDrawLetterSize(ZoneTextdraw[i], 0.159998, 0.899999);
		TextDrawColor(ZoneTextdraw[i], -1);
		TextDrawSetOutline(ZoneTextdraw[i], 1);
		TextDrawSetProportional(ZoneTextdraw[i], 1);
		TextDrawUseBox(ZoneTextdraw[i], 1);
		TextDrawBoxColor(ZoneTextdraw[i], 100);
		TextDrawTextSize(ZoneTextdraw[i], 0.000000, 111.000000);
		TextDrawSetSelectable(ZoneTextdraw[i], 0);
	}

	print("------------------------------------------------------");
	print("* "#SERVER_NAME"\n* Author: Logic_");
	print("------------------------------------------------------");
	printf("* Total Teams: %d\n* Total Classes: %d\n* Total CPs: %d\n* Total Ranks: %d", sizeof gTeam, sizeof gClass, MAX_ZONES, sizeof gRank);
	print("------------------------------------------------------");
	return 1;
}

public OnGameModeExit()
{
	foreach(new i : Player)
	{
		OnPlayerDisconnect(i, 1);
		if(pIgnoring[i][i]) pIgnoring[i][i] = false;
		if(pIgnoring[i][i]) pIgnoring[i][i] = false;
	}

	for(new i; i < MAX_ZONES; i++)
	{
		DestroyDynamicCP(gZones[i][ZoneCPID]);
		DestroyDynamic3DTextLabel(gZones[i][ZoneLabel]);
	}

	for(new i; i < sizeof gTeam; i++)
	{
		GangZoneDestroy(gTeam[i][TeamBaseID]);
		DestroyDynamicArea(gTeam[i][TeamBaseArea]);
	}

	mysql_close(gSQL);
	UnloadBox();
	ExitGlobalTDs();
	SaveConfig();
	return 1;
}

Float: GetVehicleSpeed(playerid)
{
	new Float: vX = Float: GetPlayerVehicleID(playerid), Float: vY, Float: vZ;
	
	if(_: vX) GetVehicleVelocity(_: vX, vX, vY, vZ);
	else GetPlayerVelocity(playerid, vX, vY, vZ);

	vX = floatpower(vX, 2);
	vY = floatpower(vY, 2);
	vZ = floatpower(vZ, 2);
	return floatmul(floatsqroot(floatadd(floatadd(vX, vY), vZ)), 200.0);
}

function AntiCheat()
{
	new str[140], Float: Speed, Float: X2, Float: Y2, Float: Z2, pAnim, Vehicle, weaponid, time = gettime();

	foreach(new i : Player)
	{
		if(GetPlayerState(i) == PLAYER_STATE_SPECTATING || GetPlayerState(i) == PLAYER_STATE_NONE || GetPlayerState(i) == PLAYER_STATE_WASTED) continue;

		if(pInfo[i][Cash] != GetPlayerMoney(i))
		{
			ResetPlayerMoney(i);
			GivePlayerMoney(i, pInfo[i][Cash]);
		}

		if(GetPlayerWeapon(i) == 36 && !pAdmDuty{i})
		{
			BanPlayer(i, "Anti Cheat", "Heat Seeker RPG", 0);
			break;
		}

		if (IsPlayerInAnyVehicle(i))
		{
			//GetVehiclePos(GetPlayerVehicleID(i), X, Y, Z);
			Speed = GetVehicleSpeed(i);

			Vehicle = GetVehicleModel(GetPlayerVehicleID(i));
			if(Speed >= 300.0 && (Vehicle != 411 && Vehicle != 520 && Vehicle != 476))
			{
				format(str, sizeof str, "* Anti Cheat has suspected %s (%d) for possible vehicle speed cheat.", pName[i], i);
				SendAdminMessage(str);
			}
		}
		else
		{
			GetPlayerVelocity(i, X2, Y2, Z2);
			Speed = floatmul(floatadd(floatadd(floatpower(X2, 2), floatpower(Y2, 2)), floatpower(Z2, 2)), 100.0);
			pAnim = GetPlayerAnimationIndex(i);
			
			switch(pAnim)
			{
				case -1:
				{
					BanPlayer(i, "Anti Cheat", "Parkour Mod", 0);
					break;
				}
				case 958 .. 979:
				{
					if(pInfo[i][AdminLvl] <= 4 && GetPlayerWeapon(i) != 46 && floatround(Speed, floatround_round) >= 15.0)
					{
						BanPlayer(i, "Anti Cheat", "Fly Hack", 0);
						break;
					}
				}
			}

			if(GetPlayerSpecialAction(i) == SPECIAL_ACTION_USEJETPACK && pClass{i} != CLASS_JETTROOPER && !pAdmDuty{i})
			{
				BanPlayer(i, "Anti Cheat", "Jetpack Hack", 0);
				continue;
			}

			weaponid = GetPlayerWeapon(i);
			if(weaponid != WEAPON_PARACHUTE && weaponid != WEAPON_FIST)
			{
				if(pAntiCheat[i][Weap][WeapSlot[weaponid]] != weaponid && pAntiCheat[i][WeapTick] < time)
				{
					format(str, sizeof str, "Hacked Weapon: %s", WeaponNames[weaponid]);
					BanPlayer(i, "Anti Cheat", str, 0);
					continue;
				}

				if(pAntiCheat[i][WeapAmmo][WeapSlot[weaponid]] < GetPlayerAmmo(i))
				{
					format(str, sizeof str, "Hacked Ammo: %s (%d)", WeaponNames[weaponid], pAntiCheat[i][WeapAmmo][WeapSlot[weaponid]] - GetPlayerAmmo(i));
					BanPlayer(i, "Anti Cheat", str, 0);
					continue;
				}
			}

			if(GetPlayerSurfingVehicleID(i) != INVALID_PLAYER_ID)
			{
				new Float: distance = GetPlayerDistanceFromPoint(i, AC_Pos[i][0], AC_Pos[i][1], AC_Pos[i][2]);
				if(floatabs(distance) > 60.0 && !pInfo[i][AdminLvl] && GetPlayerSpecialAction(i) != SPECIAL_ACTION_USEJETPACK)
				{
					format(str, sizeof str, "* Anti Cheat has suspected %s (%d) for possible teleport cheat.", pName[i], i);
					SendAdminMessage(str);
				}
				GetPlayerPos(i, AC_Pos[i][0], AC_Pos[i][1], AC_Pos[i][2]);

				if(Speed >= 7.3 && pInfo[i][AdminLvl] <= 4 && GetPlayerWeapon(i) != WEAPON_PARACHUTE && GetPlayerSpecialAction(i) != SPECIAL_ACTION_USEJETPACK)
				{
					format(str, sizeof str, "* Anti Cheat has suspected %s (%d) for possible speed cheat.", pName[i], i);
					SendAdminMessage(str);
				}
			}
		}

		if(sInfo[MaxPing] != 0 && sInfo[MaxPing] <= GetPlayerPing(i) <= 65535 && !pInfo[i][AdminLvl])
		{
			format(str, sizeof str, "* Anti Cheat has kicked %s (%d) for high ping (%d/%d).", pName[i], i, GetPlayerPing(i), sInfo[MaxPing]);
			SendClientMessageToAll(COLOR_PINK, str);
			KickEx(i);
		}
	}

	SetTimer("AntiCheat", 1200, false); // 1 second
	return 1;
}

BanPlayer(targetid, name[], reason[], expiretime, anticheat = true)
{
	new ip[18], query[200], str[144];
	GetPlayerIp(targetid, ip, sizeof ip);
	
	mysql_format(gSQL, query, sizeof query, "INSERT INTO "#TABLE_BANS" (`ExpireDate`, `IP`, `Name`, `Reason`, `BanBy`) VALUES (%d, '%e', '%e', '%e', '%e')", expiretime, ip, pName[targetid], reason, name);
	mysql_tquery(gSQL, query);

	if(anticheat)
	{		
		format(str, sizeof str, "* Anti Cheat has banned %s (%d). Reason: %s", pName[targetid], targetid, reason);
		SendAdminMessage(str);

		format(str, sizeof str, "* Anti Cheat has banned %s (%d). Reason: Cheats detected.", pName[targetid], targetid);
		SendClientMessageToAll(COLOR_PINK, str);
	}
	else
	{
		format(str, sizeof str, "* %s has banned %s (%d). Reason: %s", name, pName[targetid], targetid, reason);
		SendAdminMessage(str);

		format(str, sizeof str, "* Admin has banned %s (%d). Reason: %s", pName[targetid], targetid, reason);
		SendClientMessageToAll(COLOR_PINK, str);
	}

	SendClientMessage(targetid, COLOR_RED, "* If you think this ban is wrong, take a screenshot and appeal at our forum.");
	SendClientMessage(targetid, COLOR_RED, "Website: "WEBSITE"");

	KickEx(targetid);
	return 1;
}

function StatsTimer()
{
	foreach(new i : Player) SaveStats(i);
	return 1;
}

InitializeSaving()
{
	//new MySQLOpt: options = mysql_init_options();
	//mysql_set_option(options, AUTO_RECONNECT, true);
	gSQL = mysql_connect(MYSQL_HOST, MYSQL_USERNAME, MYSQL_PASSWORD, MYSQL_DATABASE/*, options*/);
	mysql_log(INFO | WARNING | ERROR);
	if(gSQL == MYSQL_INVALID_HANDLE || mysql_errno(gSQL) != 0)
	{
		SendRconCommand("exit");
		return 1;
	}
	return 1;
}

InitializePlayerTDs(playerid)
{
	KillTD[playerid] = CreatePlayerTextDraw(playerid, 320.000000, 270.000000, "~w~Killed ~g~");
	PlayerTextDrawAlignment(playerid, KillTD[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, KillTD[playerid], 255);
	PlayerTextDrawFont(playerid, KillTD[playerid], 2);
	PlayerTextDrawLetterSize(playerid, KillTD[playerid], 0.400000, 2.000000);
	PlayerTextDrawColor(playerid, KillTD[playerid], -1);
	PlayerTextDrawSetOutline(playerid, KillTD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, KillTD[playerid], 1);
	PlayerTextDrawUseBox(playerid, KillTD[playerid], 1);
	PlayerTextDrawBoxColor(playerid, KillTD[playerid], 75);
	PlayerTextDrawTextSize(playerid, KillTD[playerid], 10.000000, 270.000000);
	PlayerTextDrawSetSelectable(playerid, KillTD[playerid], 0);

	DeathTD[playerid] = CreatePlayerTextDraw(playerid, 320.000000, 247.000000, "~w~Killed by ~r~");
	PlayerTextDrawAlignment(playerid, DeathTD[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, DeathTD[playerid], 255);
	PlayerTextDrawFont(playerid, DeathTD[playerid], 2);
	PlayerTextDrawLetterSize(playerid, DeathTD[playerid], 0.400000, 2.000000);
	PlayerTextDrawColor(playerid, DeathTD[playerid], -1);
	PlayerTextDrawSetOutline(playerid, DeathTD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, DeathTD[playerid], 1);
	PlayerTextDrawUseBox(playerid, DeathTD[playerid], 1);
	PlayerTextDrawBoxColor(playerid, DeathTD[playerid], 75);
	PlayerTextDrawTextSize(playerid, DeathTD[playerid], 10.000000, 270.000000);
	PlayerTextDrawSetSelectable(playerid, DeathTD[playerid], 0);

	TeamTD[playerid] = CreatePlayerTextDraw(playerid, 320.000000, 250.000000, "Team Name");
	PlayerTextDrawAlignment(playerid, TeamTD[playerid], 2);
	PlayerTextDrawFont(playerid, TeamTD[playerid], 3);
	PlayerTextDrawLetterSize(playerid, TeamTD[playerid], 0.500, 2.500);
	PlayerTextDrawColor(playerid, TeamTD[playerid], 0xFFFFFFFF);
	PlayerTextDrawSetOutline(playerid, TeamTD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, TeamTD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, TeamTD[playerid], 1);

	PlayerTD[playerid] = CreatePlayerTextDraw(playerid, 211.000000, 359.000000, " ");
	PlayerTextDrawAlignment(playerid, PlayerTD[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, PlayerTD[playerid], 255);
	PlayerTextDrawFont(playerid, PlayerTD[playerid], 2);
	PlayerTextDrawColor(playerid, PlayerTD[playerid], -1);
	PlayerTextDrawSetOutline(playerid, PlayerTD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, PlayerTD[playerid], 0);
	PlayerTextDrawLetterSize(playerid, PlayerTD[playerid], 0.250000, 1.000000);
	PlayerTextDrawSetSelectable(playerid, PlayerTD[playerid], 0);

	IssuerTD[playerid] = CreatePlayerTextDraw(playerid, 211.000000, 389.000000, " ");
	PlayerTextDrawAlignment(playerid, IssuerTD[playerid], 2);
	PlayerTextDrawFont(playerid, IssuerTD[playerid], 2);
	PlayerTextDrawColor(playerid, IssuerTD[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, IssuerTD[playerid], 255);
	PlayerTextDrawSetOutline(playerid, IssuerTD[playerid], 1);
	PlayerTextDrawLetterSize(playerid, IssuerTD[playerid], 0.250000, 1.000000);
	PlayerTextDrawSetShadow(playerid, IssuerTD[playerid], 0);
	PlayerTextDrawSetSelectable(playerid, IssuerTD[playerid], 0);

	StatsTD[playerid] = CreatePlayerTextDraw(playerid, 315.000000, 437.000000, "Name: None - Score: 0 - Rank: None - Team: None - Class: None - Kills: 0 - Deaths: 0 - Heads: 0");
	PlayerTextDrawAlignment(playerid, StatsTD[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, StatsTD[playerid], 255);
	PlayerTextDrawFont(playerid, StatsTD[playerid], 1);
	PlayerTextDrawLetterSize(playerid, StatsTD[playerid], 0.230000, 1.000000);
	PlayerTextDrawColor(playerid, StatsTD[playerid], -1);
	PlayerTextDrawSetOutline(playerid, StatsTD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, StatsTD[playerid], 1);
	PlayerTextDrawUseBox(playerid, StatsTD[playerid], 1);
	PlayerTextDrawBoxColor(playerid, StatsTD[playerid], 100);
	PlayerTextDrawTextSize(playerid, StatsTD[playerid], 0.000000, 660.000000);
	PlayerTextDrawSetSelectable(playerid, StatsTD[playerid], 0);
	
	VehName[playerid] = CreatePlayerTextDraw(playerid, 501.000000, 313.000000, "~y~Vehicle Name");
	PlayerTextDrawBackgroundColor(playerid, VehName[playerid], 255);
	PlayerTextDrawFont(playerid, VehName[playerid], 3);
	PlayerTextDrawLetterSize(playerid, VehName[playerid], 0.339999, 1.200000);
	PlayerTextDrawColor(playerid, VehName[playerid], -1);
	PlayerTextDrawSetOutline(playerid, VehName[playerid], 1);
	PlayerTextDrawSetProportional(playerid, VehName[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, VehName[playerid], 0);
	return 1;
}

ExitPlayerTDs(playerid)
{
	PlayerTextDrawDestroy(playerid, KillTD[playerid]);
	PlayerTextDrawDestroy(playerid, DeathTD[playerid]);
	PlayerTextDrawDestroy(playerid, TeamTD[playerid]);
	PlayerTextDrawDestroy(playerid, StatsTD[playerid]);
	PlayerTextDrawDestroy(playerid, IssuerTD[playerid]);
	PlayerTextDrawDestroy(playerid, PlayerTD[playerid]);
	PlayerTextDrawDestroy(playerid, VehName[playerid]);
}

public OnPlayerText(playerid, text[])
{
	if(pInfo[playerid][Mute] && (gettime() < pInfo[playerid][MuteTime])) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're muted, you can't talk."), 0;

	if(text[0] == '.' && text[1] != EOS && pInfo[playerid][AdminLvl] >= 1)
	{
		new str[144];
		format(str, sizeof str, "* [A] %s: {FFFFFF}%s", pName[playerid], text[1]);
		SendAdminMessage(str);
		return 0;
	}

	if(text[0] == '@' && text[1] != EOS && pInfo[playerid][AdminLvl] >= 5)
	{
		new str[144];
		format(str, sizeof str, "* [M] %s: {FFFFFF}%s", pName[playerid], text[1]);
		SendAdminMessage(str, COLOR_LIMEGREEN, 5);
		return 0;
	}

	if(sInfo[ChatDisabled] && pInfo[playerid][AdminLvl] < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Server chat is disabled."), 0;

	new str[140];
	if(!pAdmDuty{playerid}) format(str, sizeof str, "%s (%d):{FFFFFF} %s", pName[playerid], playerid, text);
	else format(str, sizeof str, "%s %s: {FFFFFF}%s", GetPlayerStaffRank(playerid), pName[playerid], text);
	SendMessageToAll(playerid, GetPlayerColor(playerid), str);
	return 0;
}

SendMessageToAll(playerid, color, message[])
{
	foreach(new i : Player)
	{
		if(!pIgnoring[playerid][i] && !pIgnoring[i][playerid])
		{
			SendClientMessage(i, color, message);
		}
	}
	return 1;
}

public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid, pName[playerid], 21);
	
	for(new i; E_ACCOUNT: i < E_ACCOUNT; i++)
	{
		pInfo[playerid][E_ACCOUNT: i] = 0;
	}
	pLoginAttempts{playerid} = pLastPM{playerid} = 0;

	SpawnPlace[playerid] = MAX_ZONES;
	InitializeConnection(playerid);
	
	new PCount = Iter_Count(Player);
	if(sInfo[Players] < PCount)
	{
		sInfo[Players] = PCount;
		SendClientMessageToAll(COLOR_PINK, "* We've the highest player count right now!");
	}
	pLabel[playerid] = CreateDynamic3DTextLabel("*", 0xFF0000FF, 0.0, 0.0, 0.4, 7.5, playerid, .testlos = 0);
	return 1;
}

/*function DetectProxy(playerid, response_code, data[])
{
	if(response_code == 200 && data[0] == 'Y')
	{
		new str[75];
		format(str, sizeof str, "* Anti Cheat has kicked %s (%d) for using a VPN/ proxy.", pName[playerid], playerid);
		SendAdminMessage(str);
		SendClientMessage(playerid, COLOR_RED, "* Using VPN/ proxy is strictly prohibited!");
		KickEx(playerid);
	}
	return 1;
}*/

InitializeConnection(playerid)
{
	TogglePlayerSpectating(playerid, true);
	PlayerSpectatePlayer(playerid, playerid);
	SetPlayerColor(playerid, COLOR_GREY);
	SetPlayerPos(playerid, 667.7617, 2435.9387, 408.0376);
	SetPlayerFacingAngle(playerid, 218.6621);
	SetPlayerCameraPos(playerid, 676.3365, 2427.5027, 409.1212);
	SetPlayerCameraLookAt(playerid, 667.9286, 2435.5051, 408.0376);

	TextDrawShowForPlayer(playerid, WebsiteTD);
	new IP[16], str[60];
	GetPlayerIp(playerid, IP, sizeof IP);

	/*#if !defined LOCAL
		format(str, sizeof str, "www.shroomery.org/ythan/proxycheck.php?ip=%s", IP);
		HTTP(playerid, HTTP_GET, str, "", "DetectProxy");
	#endif*/

	pRank{playerid} = pClass{playerid} = -1;
	pTeam{playerid} = NO_TEAM;

	InitializeRemoval(playerid);
	InitializePlayerTDs(playerid);
	ShowPlayerBox(playerid);
	format(str, sizeof str, "~g~%s (%d) has connected", pName[playerid], playerid);
	SendBoxMessage(str);

	for (new i; i < sizeof gTeam; i++) GangZoneShowForPlayer(playerid, gTeam[i][TeamBaseID], SetAlpha(gTeam[i][TeamColor], GANGZONE_ALPHA));

	for(new i; i < MAX_ZONES; i++)
	{
		if(gZones[i][ZoneOwner] != NO_TEAM) GangZoneShowForPlayer(playerid, gZones[i][ZoneID], SetAlpha(gTeam[gZones[i][ZoneOwner]][TeamColor], GANGZONE_ALPHA));
		else GangZoneShowForPlayer(playerid, gZones[i][ZoneID], SetAlpha(0xFFFFFFFF, GANGZONE_ALPHA));

		if(gZones[i][ZoneAttacker] != INVALID_PLAYER_ID) GangZoneFlashForPlayer(playerid, gZones[i][ZoneID], SetAlpha(gTeam[gZones[i][ZoneAttacker]][TeamColor], GANGZONE_ALPHA));
	}

	pSpec[playerid][VW] = pSpec[playerid][Int] = pSpec[playerid][Spec] = pAdmDuty{playerid} = 0;
	SQLCheck[playerid] += 1;

	new query[95];
	mysql_format(gSQL, query, sizeof query, "SELECT * FROM "#TABLE_BANS" WHERE `Name` = '%e' OR `IP` = '%e' LIMIT 1", pName[playerid], IP);
	mysql_tquery(gSQL, query, "OnBanCheck", "ii", playerid, SQLCheck[playerid]);
	return 1;
}

ReturnDate(timestamp)
{
	new year, month, day, unused, date[30];
	TimestampToDate(timestamp, year, month, day, unused, unused, unused, 0);

	static monthname[15];
	switch (month)
	{
		case 1: monthname = "January";
		case 2: monthname = "February";
		case 3: monthname = "March";
		case 4: monthname = "April";
		case 5: monthname = "May";
		case 6: monthname = "June";
		case 7: monthname = "July";
		case 8: monthname = "August";
		case 9: monthname = "September";
		case 10: monthname = "October";
		case 11: monthname = "November";
		case 12: monthname = "December";
	}

	format(date, sizeof date, "%i %s, %i", day, monthname, year);
	return date;
}

function OnBanCheck(playerid, check)
{
	if(SQLCheck[playerid] != check) return Kick(playerid);

	if(cache_num_rows() > 1)
	{
		new ID, ExpireDate;

		cache_get_value_name_int(0, "ID", ID);
		cache_get_value_name_int(0, "ExpireDate", ExpireDate);
		if(ExpireDate >= 1 && ExpireDate < gettime())
		{
			SendClientMessage(playerid, COLOR_RED, "* Your account is now unbanned.");
			
			new query[50];
			mysql_format(gSQL, query, sizeof query, "REMOVE * FROM "#TABLE_BANS" WHERE `ID` = %d", ID);
			mysql_pquery(gSQL, query);

			CheckForAccount(playerid);
		}
		else
		{
			new By[MAX_NICK_LENGTH + 1], Name[MAX_NICK_LENGTH + 1], str[130], ip[20], query[65];

			cache_get_value_name(0, "BanBy", By);
			cache_get_value_name(0, "Name", Name);
			cache_get_value_name(0, "IP", ip);

			format(str, sizeof str, "* Account name: %s | Ban ID: %d | Expire date: %s | Banned by: %s", Name, ID, (!ExpireDate) ? ("Permanent") : (ReturnDate(ExpireDate)), By);
			SendClientMessage(playerid, COLOR_RED, str);

			mysql_format(gSQL, query, sizeof query, "UPDATE "#TABLE_BANS" SET `IP` = '%e' WHERE `ID` = %d", ip, ID);
			mysql_pquery(gSQL, query);

			format(str, sizeof str, "* Anti Cheat has kicked %s (%s) for logging in, while being banned.", pName[playerid], Name);
			SendClientMessageToAll(COLOR_PINK, str);

			KickEx(playerid);
		}
	}
	else
	{
		CheckForAccount(playerid);
	}
	return 1;
}

CheckForAccount(playerid)
{
	new query[75];
	mysql_format(gSQL, query, sizeof query, "SELECT * FROM "#TABLE_USERS" WHERE `Name` = '%e' LIMIT 1", pName[playerid]);
	return mysql_tquery(gSQL, query, "OnAccountCheck", "ii", playerid, SQLCheck[playerid]);
}

function OnAccountCheck(playerid, check)
{
	if(SQLCheck[playerid] != check) return Kick(playerid);

	SetPlayerPos(playerid, 667.7617, 2435.9387, 408.0376);
	SetPlayerFacingAngle(playerid, 218.6621);
	SetPlayerCameraPos(playerid, 676.3365, 2427.5027, 409.1212);
	SetPlayerCameraLookAt(playerid, 667.9286, 2435.5051, 408.0376);

	if(cache_num_rows() >= 1)
	{
		cache_get_value_name_int(0, "ID", pInfo[playerid][SQLID]);
		cache_get_value_name(0, "Password", pInfo[playerid][Password], 65);
		cache_get_value_name_int(0, "Tag", pInfo[playerid][CTag]);

		new str[75];
		format(str, sizeof str, "{FFFFFF}Welcome back, %s. Please login to continue.", pName[playerid]);
		Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "FD :: Player Login", str, "Login", "Quit");
	}
	else
	{
		new str[75];
		format(str, sizeof str, "{FFFFFF}Welcome, %s. Please register to continue.", pName[playerid]);
		Dialog_Show(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "FD :: Player Register", str, "Register", "Quit");
	}

	if(strfind(pName[playerid], #TAG, true) != -1 && !pInfo[playerid][CTag])
	{
		SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You've been kicked for using unauthorized "#TAG" community tag.");
		KickEx(playerid);
	}
	return 1;
}

IsInvalidNosVehicle(vehicleid)
{
	new InvalidNosVehicles[] =
	{
		581, 523, 462, 521, 463, 522, 461, 448, 468, 586,
		509, 481, 510, 472, 473, 493, 595, 484, 430, 453,
		452, 446, 454, 590, 569, 537, 538, 570, 449, 463,
		471
	};

	new VehModel = GetVehicleModel(vehicleid);

	for(new i; i < sizeof InvalidNosVehicles; i++) if(VehModel == InvalidNosVehicles[i]) return true;
	return false;
}

//flags:dcc(CMD_DONOR);
CMD:dcc(playerid, params[])
{
	if(pInfo[playerid][DonorLvl] < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Bronze Donor."), 0;
	
	new color1, color2;
	if(sscanf(params, "ii", color1, color2)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/dcc [ID] [ID]"), 0;
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You must be in a vehicle."), 0;
	if(0 < color1 > 254 || 0 < color2 > 254) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Colors must be between 0 ~ 254."), 0;

	ChangeVehicleColor(GetPlayerVehicleID(playerid), color1, color2);
	SendClientMessage(playerid, COLOR_GREEN, "* Successfully changed vehicle colors!");
	return 1;
}

flags:dnos(CMD_DONOR);
CMD:dnos(playerid)
{
	if(pInfo[playerid][DonorLvl] < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Bronze Donor."), 0;
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You must be in a vehicle."), 0;
	new veh = GetPlayerVehicleID(playerid);
	if(IsInvalidNosVehicle(veh)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't add NOS to this vehicle."), 0;

	AddVehicleComponent(veh, 1010);
	SendClientMessage(playerid, COLOR_GREEN, "* Successfully added NOS x10.");
	return 1;
}

flags:dtime(CMD_DONOR);
CMD:dtime(playerid, params[])
{
	if(pInfo[playerid][DonorLvl] < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Bronze Donor.");
	new time;
	if(sscanf(params, "i", time)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/dtime [TIME]");
	if(0 < time > 23) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Time must be between 0 ~ 23");

	SetPlayerTime(playerid, time, 0);
	return 1;
}

flags:dweather(CMD_DONOR);
CMD:dweather(playerid, params[])
{
	if(pInfo[playerid][DonorLvl] < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Bronze Donor."), 0;
	new weather;
	if(sscanf(params, "i", weather)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/dtime [WEATHER]");
	if(1 < weather > 22) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Time must be between 1 ~ 22");

	SetPlayerWeather(playerid, weather);
	return 1;
}

IsValidSkin(SkinID)
{
	if(73 == SkinID || SkinID == 0 || SkinID > 312) return false;
	for(new i; i < sizeof gTeam; i++) if(gTeam[i][TeamSkin] == SkinID) return false;
	return true;
}

//flags:dskin(CMD_DONOR);
CMD:dskin(playerid, params[])
{
	if(pInfo[playerid][DonorLvl] < 2) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Silver Donor."), 0;
	new skinid;
	if(sscanf(params, "i", skinid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/dskin [SKIN]"), 0;
	if(!IsValidSkin(skinid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Skin is invalid."), 0;

	SetPlayerSkin(playerid, skinid);
	return 1;
}

SendCooldownMessage(playerid, time)
{
	new str[75];
	format(str, sizeof str, "ERROR: "COL_GREY"You must wait %d seconds before using this command again.", time - gettime());
	SendClientMessage(playerid, COLOR_RED, str);
	return 1;
}

flags:dbike(CMD_DONOR);
CMD:dbike(playerid)
{
	if(pInfo[playerid][DonorLvl] < 2) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Silver Donor."), 0;
	if(gettime() < pCooldown[playerid][DBIKE]) return SendCooldownMessage(playerid, pCooldown[playerid][DBIKE]), 0;
	
	SpawnPlayerVehicle(playerid, 522);
	pCooldown[playerid][DBIKE] = gettime() + 120;
	return 1;
}

flags:dammo(CMD_DONOR);
CMD:dammo(playerid, params[])
{
	if(pInfo[playerid][DonorLvl] < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Bronze Donor."), 0;
	if(gettime() < pCooldown[playerid][DAMMO]) return SendCooldownMessage(playerid, pCooldown[playerid][DAMMO]), 0;
	new Weapon = GetPlayerWeapon(playerid);
	if(!Weapon) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You must have a weapon in your hand."), 0;
	
	switch(Weapon)
	{
		case WEAPON_GRENADE .. WEAPON_MOLTOV: GivePlayerWeapon(playerid, Weapon, 2);
		case WEAPON_COLT45 .. WEAPON_SNIPER: GivePlayerWeapon(playerid, Weapon, 100);
		case WEAPON_ROCKETLAUNCHER: GivePlayerWeapon(playerid, Weapon, 2);
	}
	pCooldown[playerid][DAMMO] = gettime() + 120;
	return 1;
}

flags:dfix(CMD_DONOR);
CMD:dfix(playerid)
{
	if(pInfo[playerid][DonorLvl] < 2) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Silver Donor."), 0;
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You must be in a vehicle."), 0;
	if(gettime() < pCooldown[playerid][DFIX]) return SendCooldownMessage(playerid, pCooldown[playerid][DFIX]), 0;

	RepairVehicle(GetPlayerVehicleID(playerid));
	SendClientMessage(playerid, COLOR_GREEN, "* You've repaired your vehicle.");
	pCooldown[playerid][DFIX] = gettime() + 300;
	return 1;
}

flags:dboost(CMD_DONOR);
CMD:dboost(playerid)
{
	if(pInfo[playerid][DonorLvl] < 3) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Gold Donor."), 0;
	if(gettime() < pCooldown[playerid][DBOOST]) return SendCooldownMessage(playerid, pCooldown[playerid][DBOOST]), 0;

	new Float: Armor, Float: Health, Float: X, Float: Y, Float: Z;
	GetPlayerPos(playerid, X, Y, Z);
	foreach(new i : Player)
	{
		if(IsPlayerInRangeOfPoint(i, 5.0, X, Y, Z) && pTeam{playerid} == pTeam{i})
		{
			GivePlayerWeapon(i, WEAPON_ROCKETLAUNCHER, 1);
			GetPlayerArmour(i, Armor);
			floatadd(Armor, 20.0);
			if(Armor > 99.0) SetPlayerArmour(i, 99.0);
			else SetPlayerArmour(i, Armor);
			
			GetPlayerHealth(i, Health);
			floatadd(Health, 30.0);
			if(Health > 99.0) SetPlayerHealth(i, 99.0);
			else SetPlayerHealth(i, 99.0);
		}
	}
	SendClientMessage(playerid, COLOR_GREEN, "* Supported with /dboost");
	pCooldown[playerid][DBOOST] = gettime() + 180;
	return 1;
}

flags:dheli(CMD_DONOR);
CMD:dheli(playerid)
{
	if(pInfo[playerid][DonorLvl] < 3) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Gold Donor."), 0;
	if(gettime() < pCooldown[playerid][DHELI]) return SendCooldownMessage(playerid, pCooldown[playerid][DHELI]), 0;

	SpawnPlayerVehicle(playerid, 487);
	pCooldown[playerid][DHELI] = gettime() + 120;
	return 1;
}

flags:dboat(CMD_DONOR);
CMD:dboat(playerid)
{
	if(pInfo[playerid][DonorLvl] < 3) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Gold Donor."), 0;
	if(gettime() < pCooldown[playerid][DBOAT]) return SendCooldownMessage(playerid, pCooldown[playerid][DBOAT]), 0;

	SpawnPlayerVehicle(playerid, 446);
	pCooldown[playerid][DBOAT] = gettime() + 120;
	return 1;
}

flags:dcar(CMD_DONOR);
CMD:dcar(playerid)
{
	if(pInfo[playerid][DonorLvl] < 3) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Gold Donor."), 0;
	if(gettime() < pCooldown[playerid][DCAR]) return SendCooldownMessage(playerid, pCooldown[playerid][DCAR]), 0;

	SpawnPlayerVehicle(playerid, 541);
	pCooldown[playerid][DCAR] = gettime() + 120;
	return 1;
}

//flags:d(CMD_DONOR);
CMD:d(playerid, params[])
{
	if(pInfo[playerid][DonorLvl] < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Bronze Donor."), 0;
	new message[90], str[128];
	if(sscanf(params, "s[90]", message)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/d [MESSAGE]"), 0;

	format(str, sizeof str, "* [VIP] %s %s: {FFFFFF}%s", GetPlayerDonorRank(playerid), pName[playerid], message);
	SendMessageToDonor(str);
	return 1;
}

flags:dheal(CMD_DONOR);
CMD:dheal(playerid)
{
	if(pInfo[playerid][DonorLvl] < 2) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Silver Donor."), 0;
	if(IsEnemyNearBy(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't do this when enemies are near-by."), 0;
	if(gettime() < pCooldown[playerid][DHEAL]) return SendCooldownMessage(playerid, pCooldown[playerid][DHEAL]), 0;

	SetPlayerHealth(playerid, 99.0);
	pCooldown[playerid][DHEAL] = gettime() + 300;
	return 1;
}

flags:darmor(CMD_DONOR);
CMD:darmor(playerid)
{
	if(pInfo[playerid][DonorLvl] < 2) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not a Silver Donor."), 0;
	if(IsEnemyNearBy(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't do this when enemies are near-by."), 0;
	if(gettime() < pCooldown[playerid][DARMOR]) return SendCooldownMessage(playerid, pCooldown[playerid][DARMOR]), 0;

	SetPlayerArmour(playerid, 99.0);
	pCooldown[playerid][DARMOR] = gettime() + 300;
	return 1;
}

SendMessageToDonor(message[128])
{
	foreach(new i : Player)
	{
		SendClientMessage(i, COLOR_DONOR, message);
	}
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if(!pLogged{playerid}) return 0;

	if(IsTeamFull(GetPlayerTeam(playerid)) && pInfo[playerid][DonorLvl] < 1)
	{
		GameTextForPlayer(playerid, "~r~TEAM FULL", 3000, 3);
		return 0;
	}
	else
	{
		pTeam{playerid} = GetPlayerTeam(playerid);
		ShowClassSelection(playerid);
		return 0;
	}
}

public OnPlayerRequestClass(playerid, classid)
{
	if(0 <= classid <= sizeof gTeam - 1)
	{
		SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
		SetPlayerPos(playerid, 667.7617, 2435.9387, 408.0376);
		SetPlayerFacingAngle(playerid, 218.6621);
		SetPlayerCameraPos(playerid, 676.3365, 2427.5027, 409.1212);
		SetPlayerCameraLookAt(playerid, 667.9286, 2435.5051, 408.0376);
		SetPlayerSkin(playerid, gTeam[classid][TeamSkin]);
		new str[15];
		format(str, sizeof str, "%s", gTeam[classid][TeamName]);
		PlayerTextDrawSetString(playerid, TeamTD[playerid], str);
		PlayerTextDrawColor(playerid, TeamTD[playerid], gTeam[classid][TeamColor]);
		PlayerTextDrawShow(playerid, TeamTD[playerid]);
		SetPlayerTeam(playerid, classid);
		SetPlayerColor(playerid, gTeam[classid][TeamColor]);
		pTeam{playerid} = NO_TEAM;
		if(Dialog_Opened(playerid)) Dialog_Close(playerid);
	}
	return 1;
}

function OnPlayerLogin(playerid)
{
	cache_get_value_name_int(0, "Kills", pInfo[playerid][Kills]);
	cache_get_value_name_int(0, "Deaths", pInfo[playerid][Deaths]);
	cache_get_value_name_int(0, "Captures", pInfo[playerid][Captures]);
	cache_get_value_name_int(0, "Heads", pInfo[playerid][Heads]);
	cache_get_value_name_int(0, "Cash", pInfo[playerid][Cash]);
	cache_get_value_name_int(0, "Score", pInfo[playerid][Score]);
	cache_get_value_name_int(0, "Admin", pInfo[playerid][AdminLvl]);
	cache_get_value_name_int(0, "Donor", pInfo[playerid][DonorLvl]);
	cache_get_value_name_int(0, "Hours", pInfo[playerid][Hours]);
	cache_get_value_name_int(0, "Mins", pInfo[playerid][Mins]);
	cache_get_value_name_int(0, "Secs", pInfo[playerid][Secs]);
	cache_get_value_name(0, "Reg", pInfo[playerid][RegDate], 12);

	pLogged{playerid} = 1;
	SetPlayerScore(playerid, pInfo[playerid][Score]);
	ResetPlayerMoney(playerid);
	GivePlayerMoney(playerid, pInfo[playerid][Cash]);
	pRank{playerid} = GetPlayerRank(playerid);

	new ip[18];
	GetPlayerIp(playerid, ip, sizeof (ip));

	new query[75];
	mysql_format(gSQL, query, sizeof query, "UPDATE "#TABLE_USERS" SET `IP` = '%e' WHERE `ID` = %d LIMIT 1", ip, pInfo[playerid][SQLID]);
	mysql_pquery(gSQL, query);

	new str[71];
	if(pInfo[playerid][AdminLvl] >= 1 && pInfo[playerid][DonorLvl] >= 1)
	{
		strcat(str, "* Log in successful, logged in as ");
		strcat(str, GetPlayerStaffRank(playerid));
		strcat(str, " and ");
		strcat(str, GetPlayerDonorRank(playerid));
		strcat(str, " donor.");
	}
	else if(pInfo[playerid][DonorLvl] >= 1)
	{
		strcat(str, "* Log in successful, logged in as ");
		strcat(str, GetPlayerDonorRank(playerid));
		strcat(str, " donor.");
	}
	else if(pInfo[playerid][AdminLvl] >= 1)
	{
		strcat(str, "* Log in successful, logged in as ");
		strcat(str, GetPlayerStaffRank(playerid));
		strcat(str, ".");
	}
	else
	{
		strcat(str, "* Log in successful.");
	}
	SendClientMessage(playerid, COLOR_TOMATO, str);
	return 1;
}

Dialog:DIALOG_LOGIN(playerid, response, listitem, inputtext[])
{
	if (!response)
		return KickEx(playerid);

	new password[65], str[144];
	SHA256_PassHash(inputtext, PASSWORD_SALT, password, 65);

	if (strcmp(pInfo[playerid][Password], password))
	{
		pLoginAttempts{playerid} += 1;

		if (pLoginAttempts{playerid} >= MAX_LOGIN_ATTEMPTS) return KickEx(playerid);

		format(str, sizeof str, "{FFFFFF}Welcome back, %s. Please login to continue.\n\n"COL_RED"Invalid password entered\nThis is your %d/%d attempts.", pName[playerid], pLoginAttempts{playerid}, MAX_LOGIN_ATTEMPTS);
		return Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "FD :: Player Login", str, "Login", "Quit");
	}

	mysql_format(gSQL, str, sizeof str, "SELECT * FROM "#TABLE_USERS" WHERE `ID` = %i", pInfo[playerid][SQLID]);
	mysql_tquery(gSQL, str, "OnPlayerLogin", "i", playerid);

	TogglePlayerSpectating(playerid, false);
	return 1;
}

IsTeamFull(teamid)
{
	#define PLAYERS (0)
	#define TEAMS (1)

	new count[sizeof gTeam][2];
	foreach(new i : Player)
	{
		if(0 <= pTeam{i} <= sizeof gTeam - 1)
		{
			count[pTeam{i}][PLAYERS] ++;
			count[pTeam{i}][TEAMS] = pTeam{i};
		}
	}

	QuickSort_Pair(count, true, 0, sizeof gTeam - 1);

	if(count[0][PLAYERS] > count[1][PLAYERS] + 2 && count[0][TEAMS] == teamid) return true;
	if(count[0][PLAYERS] < count[1][PLAYERS] + 2 && count[1][TEAMS] == teamid) return false;

	#undef PLAYERS
	#undef TEAMS
	return false;
}

QuickSort_Pair(array[][2], bool:desc, left, right)
{
	#define PAIR_FIST (0)
	#define PAIR_SECOND (1)

	new
		tempLeft = left,
		tempRight = right,
		pivot = array[(left + right) / 2][PAIR_FIST],
		tempVar
	;
	while (tempLeft <= tempRight)
	{
		if (desc)
		{
			while (array[tempLeft][PAIR_FIST] > pivot)
			{
				tempLeft++;
			}
			while (array[tempRight][PAIR_FIST] < pivot)
			{
				tempRight--;
			}
		}
		else
		{
			while (array[tempLeft][PAIR_FIST] < pivot)
			{
				tempLeft++;
			}
			while (array[tempRight][PAIR_FIST] > pivot)
			{
				tempRight--;
			}
		}

		if (tempLeft <= tempRight)
		{
			tempVar = array[tempLeft][PAIR_FIST];
			array[tempLeft][PAIR_FIST] = array[tempRight][PAIR_FIST];
			array[tempRight][PAIR_FIST] = tempVar;

			tempVar = array[tempLeft][PAIR_SECOND];
			array[tempLeft][PAIR_SECOND] = array[tempRight][PAIR_SECOND];
			array[tempRight][PAIR_SECOND] = tempVar;

			tempLeft++;
			tempRight--;
		}
	}
	if (left < tempRight)
	{
		QuickSort_Pair(array, desc, left, tempRight);
	}
	if (tempLeft < right)
	{
		QuickSort_Pair(array, desc, tempLeft, right);
	}

	#undef PAIR_FIST
	#undef PAIR_SECOND
}

GetTeamPlayers(teamid)
{
	new count;
	foreach(new i : Player) if(pTeam{i} == teamid) count ++;
	return count;
}

GetTeamZones(teamid)
{
	new count;
	for(new i; i < MAX_ZONES; i++) if(gZones[i][ZoneOwner] == teamid) count++;
	return count;
}

ShowClassSelection(playerid)
{
	new str[350];
	strcat(str, "Class\tRank\n");
	for (new i; i < sizeof gClass; i++)
	{
		if(i != CLASS_DONOR) format(str, sizeof str, "%s%s%s\t%s\n", str, (pRank{playerid} >= gClass[i][ClassRank]) ? (COL_GREEN) : (COL_RED), gClass[i][ClassName], gRank[gClass[i][ClassRank]][RankName]);
		else format(str, sizeof str, "%s%s%s\tDonor\n", str, (pInfo[playerid][DonorLvl] >= 2) ? (COL_GREEN) : (COL_RED), gClass[i][ClassName]);
	}
	Dialog_Show(playerid, DIALOG_CLASS, DIALOG_STYLE_TABLIST_HEADERS, "FD :: Classes", str, "Spawn", "");
	SendClientMessage(playerid, COLOR_TOMATO, "* Select your class now.");
	return 1;
}

Dialog:DIALOG_CLASS(playerid, response, listitem, inputtext[])
{
	if(!response) return ShowClassSelection(playerid);

	new str[144];
	if(pRank{playerid} >= gClass[listitem][ClassRank])
	{
		if(listitem == CLASS_DONOR && pInfo[playerid][DonorLvl] <= 2)
		{
			format(str, sizeof str, "ERROR: "COL_GREY"Class \"%s\" requires Donor level 3 or more status.", gClass[listitem][ClassName]);
			SendClientMessage(playerid, COLOR_TOMATO, str);
			ShowClassSelection(playerid);
			return 1;
		}
		PlayerTextDrawHide(playerid, TeamTD[playerid]);
		pClass{playerid} = listitem;
		format(str, sizeof str, "* You've selected class \"%s\".", gClass[pClass{playerid}][ClassName]);
		SendClientMessage(playerid, COLOR_TOMATO, str);
		StopAudioStreamForPlayer(playerid);
		SetSpawnInfo(playerid, pTeam{playerid}, 0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0);
		SpawnPlayer(playerid);
	}
	else
	{
		format(str, sizeof str, "ERROR: "COL_GREY"Class \"%s\" requires rank %s.", gClass[listitem][ClassName], gRank[gClass[listitem][ClassRank]][RankName]);
		SendClientMessage(playerid, COLOR_TOMATO, str);
		ShowClassSelection(playerid);
	}
	return 1;
}

Dialog:DIALOG_REGISTER(playerid, response, listitem, inputtext[])
{
	if (!response) return KickEx(playerid);

	if (!inputtext[0] || inputtext[0] == ' ')
	{
		SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid password length, password cannot be empty.");

		new str[75];
		format(str, sizeof str, "{FFFFFF}Welcome, %s. Please register to continue.", pName[playerid]);
		Dialog_Show(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "FD :: Player Register", str, "Register", "Quit");
	}

	new len = strlen(inputtext);
	if (len > MAX_PASSWORD_LENGTH || len < MIN_PASSWORD_LENGTH)
	{
		new str[150];
		format(str, sizeof (str), "ERROR: "COL_GREY"Invalid password length, must be between %i ~ %i chars.", MIN_PASSWORD_LENGTH, MAX_PASSWORD_LENGTH);
		SendClientMessage(playerid, COLOR_RED, str);

		format(str, sizeof str, "{FFFFFF}Welcome, %s. Please register to continue.", pName[playerid]);
		Dialog_Show(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "FD :: Player Register", str, "Register", "Quit");
		return 1;
	}

	pLogged{playerid} = 1;
	SHA256_PassHash(inputtext, PASSWORD_SALT, pInfo[playerid][Password], 65);

	new ip[18], year, month, day;
	GetPlayerIp(playerid, ip, sizeof (ip));
	getdate(year, month, day);
	format(pInfo[playerid][RegDate], 12, "%02d/%02d/%d", day, month, year);

	new query[190];
	mysql_format(gSQL, query, sizeof query, "INSERT INTO "#TABLE_USERS" (`Name`, `Password`, `IP`, `Reg`) VALUES ('%e', '%s', '%e', '%s')", pName[playerid], pInfo[playerid][Password], ip, pInfo[playerid][RegDate]);
	mysql_tquery(gSQL, query, "OnPlayerRegister", "i", playerid);

	pRank{playerid} = GetPlayerRank(playerid);
	TogglePlayerSpectating(playerid, false);
	return 1;
}

function OnPlayerRegister(playerid)
{
	pInfo[playerid][SQLID] = cache_insert_id();
	pInfo[playerid][Cash] = 15000;
	SendClientMessage(playerid, COLOR_TOMATO, "* Sign up successful.");
	SendClientMessage(playerid, COLOR_PINK, "* You've been rewarded $15,000 cash for registering.");
	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetPlayerTeam(playerid, pTeam{playerid});
	PlayerTextDrawShow(playerid, StatsTD[playerid]);
	UpdateTD(playerid);
	
	new str[144];
	if(pAdmDuty{playerid})
	{
		SetPlayerInterior(playerid, 3);
		SetPlayerPos(playerid, 369.0934, 173.8329, 1008.3893);
		SetPlayerFacingAngle(playerid, 230.7907);
		SetPlayerSkin(playerid, ADMIN_SKIN);
		SetPlayerVirtualWorld(playerid, 1);
		SetPlayerHealth(playerid, FLOAT_INFINITY);
		GivePlayerWeapon(playerid, WEAPON_MINIGUN, 999999);
		SetPlayerColor(playerid, COLOR_PINK);
	}
	else
	{
		if(SpawnPlace[playerid] == MAX_ZONES)
		{
			strcat(str, "* You spawned at: "COL_RED"Base"COL_WHITE".");
			SendClientMessage(playerid, COLOR_WHITE, str);
		}
		else if(gZones[SpawnPlace[playerid]][ZoneOwner] != pTeam{playerid})
		{
			strcat(str, "* Your team has lost ");
			strcat(str, gZones[SpawnPlace[playerid]][ZoneName]);
			strcat(str, ". You're now spawning at your base.");
			SendClientMessage(playerid, COLOR_RED, str);
			SpawnPlace[playerid] = MAX_ZONES;
		}
		else if(gZones[SpawnPlace[playerid]][ZoneAttacker] != INVALID_PLAYER_ID)
		{
			strcat(str, "* ");
			strcat(str, gZones[SpawnPlace[playerid]][ZoneName]);
			strcat(str, " is under attack. You're now spawning at your base.");
			SpawnPlace[playerid] = MAX_ZONES;
			SendClientMessage(playerid, COLOR_YELLOW, str);
		}
		else
		{
			strcat(str, "* You spawned at: "COL_RED"");
			strcat(str, gZones[SpawnPlace[playerid]][ZoneName]);
			strcat(str, ""COL_WHITE".");
			SendClientMessage(playerid, COLOR_WHITE, str);
		}

		if(SpawnPlace[playerid] < MAX_ZONES)
		{
			SetPlayerPos(playerid, gZones[SpawnPlace[playerid]][ZoneSpawn][0], gZones[SpawnPlace[playerid]][ZoneSpawn][1], gZones[SpawnPlace[playerid]][ZoneSpawn][2]);
			SetPlayerFacingAngle(playerid, gZones[SpawnPlace[playerid]][ZoneSpawn][3]);
		}
		else
		{
			LastSpawn[playerid] = GetSpawnID(playerid);
			switch(LastSpawn[playerid])
			{
				case 0:
				{
					SetPlayerPos(playerid, gTeam[pTeam{playerid}][TeamSpawn1][0], gTeam[pTeam{playerid}][TeamSpawn1][1], gTeam[pTeam{playerid}][TeamSpawn1][2] + 0.5);
				}
				case 1:
				{
					SetPlayerPos(playerid, gTeam[pTeam{playerid}][TeamSpawn2][0], gTeam[pTeam{playerid}][TeamSpawn2][1], gTeam[pTeam{playerid}][TeamSpawn2][2] + 0.5);
				}
				case 2:
				{
					SetPlayerPos(playerid, gTeam[pTeam{playerid}][TeamSpawn3][0], gTeam[pTeam{playerid}][TeamSpawn3][1], gTeam[pTeam{playerid}][TeamSpawn3][2] + 0.5);
				}
			}
		}
		SetPlayerSkin(playerid, gTeam[pTeam{playerid}][TeamSkin]);
		SpawnProtect(playerid);
		SetPlayerInterior(playerid, 0);
		SetPlayerVirtualWorld(playerid, 0);
	}

	if(pSpec[playerid][Spec] && pSpec[playerid][SpecID] == INVALID_PLAYER_ID)
	{
		SetPlayerPos(playerid, pSpec[playerid][Pos][0], pSpec[playerid][Pos][1], pSpec[playerid][Pos][2] + 0.5);
		SetPlayerInterior(playerid, pSpec[playerid][Int]);
		SetPlayerVirtualWorld(playerid, pSpec[playerid][VW]);
		pSpec[playerid][Spec] = pSpec[playerid][VW] = pSpec[playerid][Int] = 0;
		pSpec[playerid][SpecID] = INVALID_PLAYER_ID;
		SendClientMessage(playerid, COLOR_PINK, "* Setting your positon to the old one...");
	}
	pRank{playerid} = GetPlayerRank(playerid);
	return 1;
}

GetSpawnID(playerid)
{
	new ID = random(3);
	return (LastSpawn[playerid] == ID) ? GetSpawnID(playerid) : ID;
}

CMD:sp(playerid)
{
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're spawn protected.");
	new str[100];
	strcat(str, "{FFFFFF}Base\n");
	for(new i; i < MAX_ZONES; i++)
	{
		if(gZones[i][ZoneSpawn][0] == 0.0) continue;

		if(gZones[i][ZoneOwner] == pTeam{playerid})
		{
			strcat(str, COL_GREEN);
		}
		else if(gZones[i][ZoneAttacker] != INVALID_PLAYER_ID)
		{
			strcat(str, COL_YELLOW);
		}
		else
		{
			strcat(str, COL_RED);
		}
		strcat(str, gZones[i][ZoneName]);
		strcat(str, "\n");
	}
	Dialog_Show(playerid, DIALOG_SP, DIALOG_STYLE_LIST, "FD :: Spawn Point", str, "Select", "Cancel");
	return 1;
}

Dialog:DIALOG_SP(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;

	if(!listitem)
	{
		SendClientMessage(playerid, COLOR_GREEN, "* Your new spawn point is: Base.");
		SpawnPlace[playerid] = MAX_ZONES;
		return 1;
	}

	new str[100], x;
	for(new i; i < MAX_ZONES; i++)
	{
		if(gZones[i][ZoneSpawn][0] == 0.0) continue;

		x += 1;
		if(listitem != x) continue;
		
		if(gZones[i][ZoneAttacker] != INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"This zone is currently being captured.");
		if(gZones[i][ZoneOwner] != pTeam{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Your team doesn't owns this zone.");
		if(SpawnPlace[playerid] == i) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You will already spawn there.");

		strcat(str, "* Your new spawn point is: ");
		strcat(str, gZones[i][ZoneName]);
		strcat(str, ".");
		SendClientMessage(playerid, COLOR_GREEN, str);
		SpawnPlace[playerid] = i;
		break;
	}
	return 1;
}

CMD:suicide(playerid)
{
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're spawn protected.");
	if(pClass{playerid} != CLASS_BOMBER) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not Bomber.");
	if(gettime() < pCooldown[playerid][CLASS]) return SendCooldownMessage(playerid, pCooldown[playerid][CLASS]);

	new Float: X, Float: Y, Float: Z, str[40], kills;
	GetPlayerPos(playerid, X, Y, Z);
	SetPlayerHealth(playerid, 0.0);
	foreach(new i : Player)
	{
		if(IsPlayerInRangeOfPoint(i, 5.0, X, Y, Z) && pTeam{i} != pTeam{playerid})
		{
			SetPlayerHealth(i, 0.0);
			kills += 1;
		}
	}
	GivePlayerScore(playerid, kills);
	pInfo[playerid][Kills] += kills;
	CreateExplosion(X, Y, Z, 3, 5.0);
	pCooldown[playerid][CLASS] = (gettime() + 60 * 2);
	format(str, sizeof str, "* You suicided and killed %i enemies.", kills);
	SendClientMessage(playerid, COLOR_GREEN, str);
	return 1;
}

CMD:undis(playerid)
{
	if(pClass{playerid} != CLASS_SPY) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You need to be a Spy to use this command.");

	SetPlayerSkin(playerid, gTeam[pTeam{playerid}][TeamSkin]);
	SetPlayerColor(playerid, gTeam[pTeam{playerid}][TeamColor]);
	SendClientMessage(playerid, gTeam[pTeam{playerid}][TeamColor], "* You've undisguised.");
	new str[30];
	format(str, sizeof str, "%s - %s", gTeam[pTeam{playerid}][TeamName], gClass[pClass{playerid}][ClassName]);
	UpdateDynamic3DTextLabelText(pLabel[playerid], gTeam[pTeam{playerid}][TeamColor], str);
	return 1;
}
alias:undis("undisguise");

CMD:dis(playerid)
{
	if(pClass{playerid} != CLASS_SPY) return SendClientMessage(playerid,COLOR_RED, "ERROR: You need to be spy to use this command.");

	new str[300];
	for(new i; i < sizeof gTeam; i++) format(str, sizeof str, "%s{%06x}%s\n", str, gTeam[i][TeamColor] >>> 8, gTeam[i][TeamName]);
	Dialog_Show(playerid, DIALOG_DIS, DIALOG_STYLE_LIST, "FD :: Disguise", str, "Select", "Cancel");
	return 1;
}
alias:dis("disguise");

Dialog:DIALOG_DIS(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;

	new str[50];
	format(str, sizeof str, "* You disguised as a %s Assault.", gTeam[listitem][TeamName]);
	SendClientMessage(playerid, gTeam[listitem][TeamColor], str);
	SetPlayerColor(playerid, gTeam[listitem][TeamColor]);
	SetPlayerSkin(playerid, gTeam[listitem][TeamSkin]);
	format(str, sizeof str, "%s - Assault", gTeam[listitem][TeamName]);
	UpdateDynamic3DTextLabelText(pLabel[playerid], gTeam[listitem][TeamColor], str);
	return 1;
}

CMD:armour(playerid)
{
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're spawn protected.");
	if(pClass{playerid} != CLASS_MEDIC) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not Medic.");
	if(gettime() < pCooldown[playerid][CLASS]) return SendCooldownMessage(playerid, pCooldown[playerid][CLASS]);
	new Float: X, Float: Y, Float: Z, Float: Health, count;
	GetPlayerPos(playerid, X, Y, Z);
	SetPlayerArmour(playerid, 99.0);
	foreach(new i : Player)
	{
		Health = 0.0;
		if(IsPlayerInRangeOfPoint(i, 3.0, X, Y, Z))
		{
			if(pTeam{playerid} == pTeam{i})
			{
				count += 1;
				GetPlayerArmour(i, Health);
				SetPlayerArmour(i, Health + 40.0);
				if(Health > 99.0) SetPlayerArmour(i, 99.0);
				if(count == 4) break;
			}
		}
	}
	
	pCooldown[playerid][CLASS] = (gettime() + 60);
	SendClientMessage(playerid, COLOR_GREEN, "* You've armoured yourself and some people around you.");
	return 1;
}

CMD:heal(playerid)
{
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're spawn protected.");
	if(pClass{playerid} != CLASS_MEDIC) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not Medic.");
	if(gettime() < pCooldown[playerid][CLASS]) return SendCooldownMessage(playerid, pCooldown[playerid][CLASS]);
	new Float: X, Float: Y, Float: Z, Float: Health, count;
	GetPlayerPos(playerid, X, Y, Z);
	SetPlayerHealth(playerid, 99.0);
	foreach(new i : Player)
	{
		Health = 0.0;
		if(IsPlayerInRangeOfPoint(i, 3.0, X, Y, Z))
		{
			if(pTeam{playerid} == pTeam{i})
			{
				count += 1;
				GetPlayerHealth(i, Health);
				SetPlayerHealth(i, Health + 40.0);
				if(Health > 99.0) SetPlayerHealth(i, 99.0);
				if(count == 4) break;
			}
		}
	}
	
	pCooldown[playerid][CLASS] = (gettime() + 60 * 3);
	SendClientMessage(playerid, COLOR_GREEN, "* You've healed yourself and some people around you.");
	return 1;
}

CMD:repair(playerid)
{
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're spawn protected.");
	if(pClass{playerid} != CLASS_ENGINEER) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not Engineer.");
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You must be in a vehicle.");
	if(gettime() < pCooldown[playerid][CLASS]) return SendCooldownMessage(playerid, pCooldown[playerid][CLASS]);
	
	RepairVehicle(GetPlayerVehicleID(playerid));
	pCooldown[playerid][CLASS] = (gettime() + 60 * 3);
	SendClientMessage(playerid, COLOR_GREEN, "* Your vehicle is fixed.");
	return 1;
}

CMD:jetpack(playerid)
{
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're spawn protected.");
	if(pClass{playerid} != CLASS_JETTROOPER) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not Jet Trooper.");
	if(gettime() < pCooldown[playerid][CLASS]) return SendCooldownMessage(playerid, pCooldown[playerid][CLASS]);

	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
	pCooldown[playerid][CLASS] = (gettime() + 60 * 2);
	SendClientMessage(playerid, COLOR_GREEN, "* Jetpack spawned.");
	return 1;
}

CMD:raid(playerid)
{
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're spawn protected.");
	if(pClass{playerid} != CLASS_AIRTROOPER) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You are not Air Trooper.");
	if(!IsPlayerInDynamicArea(playerid, gTeam[pTeam{playerid}][TeamBaseArea])) return SendClientMessage(playerid, COLOR_RED, "ERROR: You must be in your base to use this command.");
	
	new str[300];
	for(new i; i < sizeof gTeam; i ++) format(str, sizeof str, "%s{%06x}%s\n", str, gTeam[i][TeamColor] >>> 8, gTeam[i][TeamName]);
	Dialog_Show(playerid, DIALOG_RAID, DIALOG_STYLE_LIST, "FD :: Airtrooper Raid", str, "Select", "Cancel");
	return 1;
}

Dialog:DIALOG_RAID(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;

	switch(random(3))
	{
		case 0: SetPlayerPos(playerid, gTeam[listitem][TeamSpawn1][0], gTeam[listitem][TeamSpawn1][1], gTeam[listitem][TeamSpawn1][2] + 500.0);
		case 1: SetPlayerPos(playerid, gTeam[listitem][TeamSpawn2][0], gTeam[listitem][TeamSpawn2][1], gTeam[listitem][TeamSpawn2][2] + 500.0);
		case 2: SetPlayerPos(playerid, gTeam[listitem][TeamSpawn3][0], gTeam[listitem][TeamSpawn3][1], gTeam[listitem][TeamSpawn3][2] + 500.0);
	}
	GivePlayerWeapon(playerid, 46, 1);
	return 1;
}

ShowCHelp(playerid)
{
	new str[250];

	format(str, sizeof str, ""COL_WHITE"Class Name: %s\nClass Ability: ", gClass[pClass{playerid}][ClassName]);
	switch(pClass{playerid})
	{
		case CLASS_ASSAULT: strcat(str, "Strong fight on-foot.");
		case CLASS_MARKSMAN: strcat(str, "Invisible on radar/ mini-map.");
		case CLASS_BOMBER: strcat(str, "Can /suicide to destruct himself.");
		case CLASS_MEDIC: strcat(str, "Able to /heal or /armour team mates.");
		case CLASS_JETTROOPER: strcat(str, "Spawn /jetpack.");
		case CLASS_AIRTROOPER: strcat(str, "Can /raid on bases and go invisible.");
		case CLASS_ENGINEER: strcat(str, "Able to use tanks and /repair vehicles.");
		case CLASS_SCOUT: strcat(str, "Able to find Marksman on their radar/ mini-map.");
		case CLASS_SPY: strcat(str, "Can /disguise as enemy teams.");
		case CLASS_PILOT: strcat(str, "Can pilot all air crafts and helicopters.");
		case CLASS_DONOR: strcat(str, "Smartest and strongest class of them all.");
	}
	strcat(str, "\nClass Weapons:");

	for(new i; i < 5; i++)
	{
		switch(i)
		{
			case 0:
			{
				format(str, sizeof str, "%s %s (%d),", str, WeaponNames[gClass[pClass{playerid}][ClassWeap1][0]], gClass[pClass{playerid}][ClassWeap1][1]);
			}
			case 1:
			{
				format(str, sizeof str, "%s %s (%d)", str, WeaponNames[gClass[pClass{playerid}][ClassWeap2][0]], gClass[pClass{playerid}][ClassWeap2][1]);
			}
			case 2:
			{
				if(gClass[pClass{playerid}][ClassWeap4][0] != 0) format(str, sizeof str, "%s, %s (%d)", str, WeaponNames[gClass[pClass{playerid}][ClassWeap3][0]], gClass[pClass{playerid}][ClassWeap3][1]);
				else
				{
					format(str, sizeof str, "%s and %s (%d).", str, WeaponNames[gClass[pClass{playerid}][ClassWeap3][0]], gClass[pClass{playerid}][ClassWeap3][1]);
					break;
				}
			}
			case 3:
			{
				if(gClass[pClass{playerid}][ClassWeap5][0] != 0) format(str, sizeof str, "%s, %s (%d)", str, WeaponNames[gClass[pClass{playerid}][ClassWeap4][0]], gClass[pClass{playerid}][ClassWeap4][1]);
				else
				{
					format(str, sizeof str, "%s and %s (%d).", str, WeaponNames[gClass[pClass{playerid}][ClassWeap4][0]], gClass[pClass{playerid}][ClassWeap4][1]);
					break;
				}
			}
			case 4:
			{
				format(str, sizeof str, "%s and %s (%d).", str, WeaponNames[gClass[pClass{playerid}][ClassWeap5][0]], gClass[pClass{playerid}][ClassWeap5][1]);
			}
		}
	}
	
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Class Help", str, "Okay", "");
	return 1;
}

SpawnProtect(playerid)
{
	ShowCHelp(playerid);
	ResetPlayerWeapons(playerid);
	SetPlayerHealth(playerid, FLOAT_INFINITY);

	switch(pClass{playerid})
	{
		case CLASS_MARKSMAN:
		{
			SetPlayerColor(playerid, SetAlpha(gTeam[pTeam{playerid}][TeamColor], 0));
			foreach(new i : Player)
			{
				if(pClass{i} == CLASS_SCOUT) SetPlayerMarkerForPlayer(i, playerid, SetAlpha(gTeam[pTeam{playerid}][TeamColor], 50));
			}
		}
		case CLASS_SCOUT:
		{
			SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 999);
			foreach(new i : Player)
			{
				if(pClass{i} == CLASS_MARKSMAN) SetPlayerMarkerForPlayer(playerid, i, gTeam[pTeam{i}][TeamColor]);
			}
		}
		case CLASS_DONOR: SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 999);
	}
	
	if(pClass{playerid} != CLASS_MARKSMAN) SetPlayerColor(playerid, gTeam[pTeam{playerid}][TeamColor]);
	new str[45], time = 10 + (5 * random(3));
	AntiSKt[playerid] = SetTimerEx("SpawnProtection", time * 1000 , false, "i", playerid);
	format(str, sizeof str, "* You've spawn protection for %i seconds.", time);
	SendClientMessage(playerid, COLOR_GREY, str);

	AntiSK[playerid] = 1;
	SendClientMessage(playerid, COLOR_GREY, "* Press key '"COL_CYAN"N"COL_GREY"' to end spawn protection.");
	UpdateDynamic3DTextLabelText(pLabel[playerid], COLOR_RED, "Spawn Protected");
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(PRESSING(newkeys, KEY_NO))
	{
		if(AntiSK[playerid])
		{
			SendClientMessage(playerid, COLOR_RED, "* You've ended your spawn protection.");
			KillTimer(AntiSKt[playerid]);
			SpawnProtection(playerid);
		}
	}
	else if(PRESSING(newkeys, KEY_YES))
	{
		if(IsPlayerInAnyVehicle(playerid))
		{
			switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
			{
				case 520, 425, 447, 460, 476, 487, 488, 497, 511, 512, 513, 519, 548, 469, 553, 563, 577, 592, 593:
				{
					new Float: X, Float: Y, Float: Z;
					GetPlayerPos(playerid, X, Y, Z);
					SetPlayerPos(playerid, X, Y, floatadd(Z, 80.0));
					GivePlayerWeapon(playerid, 46, 1);
				}
			}
		}
	}
	else if(PRESSING(newkeys, KEY_FIRE))
	{
		new Float: X, Float: Y, Float: Z;
		GetPlayerPos(playerid, X, Y, Z);
		if(GetPlayerWeapon(playerid) == 17)
		{
			foreach(new i : Player)
			{
				if(IsPlayerInRangeOfPoint(i, 10.0, X, Y, Z) && pTeam{playerid} != pTeam{i} && i != playerid && GetPlayerState(i) == PLAYER_STATE_ONFOOT && !pGas{playerid})
				{
					ApplyAnimation(i, "ped", "gas_cwr", 0.5, 0, 0, 0, 0, 2500, 1);
				}
			}
		}
	}
	return 1;
}

function SpawnProtection(playerid)
{
	SetPlayerHealth(playerid, 99.0);
	if(pInfo[playerid][DonorLvl] >= 2)
	{
		SetPlayerArmour(playerid, 99);
		SendClientMessage(playerid, COLOR_GREEN, "* As being a Silver VIP, you've spawned with a full armor.");
	}
	if(pInfo[playerid][DonorLvl] >= 4)
	{
		GivePlayerHelmet(playerid);
		GivePlayerGasMask(playerid);
		SendClientMessage(playerid, COLOR_GREEN, "* As being a Platinum VIP, you've spawned with Gas Mask and Helmet.");
	}
	if(!pRank{playerid})
	{
		GivePlayerHelmet(playerid);
		GivePlayerGasMask(playerid);
		SendClientMessage(playerid, COLOR_GREEN, "* As being a new player, you've spawned with Gas Mask and Helmet.");
	}

	AntiSK[playerid] = AntiSKt[playerid] = 0;
	SendClientMessage(playerid, COLOR_RED, "* Your spawn protection has ended.");
	new str[30];
	format(str, sizeof str, "%s - %s", gTeam[pTeam{playerid}][TeamName], gClass[pClass{playerid}][ClassName]);
	UpdateDynamic3DTextLabelText(pLabel[playerid], gTeam[pTeam{playerid}][TeamColor], str);

	GivePlayerWeapon(playerid, gClass[pClass{playerid}][ClassWeap1][0], gClass[pClass{playerid}][ClassWeap1][1]);
	GivePlayerWeapon(playerid, gClass[pClass{playerid}][ClassWeap2][0], gClass[pClass{playerid}][ClassWeap2][1]);
	GivePlayerWeapon(playerid, gClass[pClass{playerid}][ClassWeap3][0], gClass[pClass{playerid}][ClassWeap3][1]);
	GivePlayerWeapon(playerid, gClass[pClass{playerid}][ClassWeap4][0], gClass[pClass{playerid}][ClassWeap4][1]);
	GivePlayerWeapon(playerid, gClass[pClass{playerid}][ClassWeap5][0], gClass[pClass{playerid}][ClassWeap5][1]);
	return 1;
}

function HideDeathTD(playerid)
{
	PlayerTextDrawHide(playerid, DeathTD[playerid]);
	return 1;
}

function HideKillTD(playerid)
{
	PlayerTextDrawHide(playerid, KillTD[playerid]);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	SendDeathMessage(killerid, playerid, reason);
	SetPlayerColor(playerid, COLOR_GREY);
	
	new str[120];
	if (killerid != INVALID_PLAYER_ID)
	{
		new xCash = random(1000 - 100) + 100;
		format(str, sizeof str, "* You got killed by %s and paid $%d.", pName[killerid], xCash);
		SendClientMessage(playerid, COLOR_RED, str);
		pInfo[playerid][Cash] -= xCash;
		pInfo[killerid][Kills]++;
		xCash = random(3000 - 2000) + 1000;
		GivePlayerScore(killerid, 1);
		pInfo[killerid][Cash] += xCash;
		format(str, sizeof str, "* You got 1 score and $%d cash for killing %s.", xCash, pName[playerid]);
		SendClientMessage(killerid, COLOR_GREEN, str);
		
		format(str, sizeof str, "~w~Killed by ~r~%s", pName[killerid]);
		PlayerTextDrawSetString(playerid, DeathTD[playerid], str);
		PlayerTextDrawShow(playerid, DeathTD[playerid]);
		SetTimerEx("HideDeathTD", 3500, false, "i", playerid);

		format(str, sizeof str, "~w~Killed ~g~%s", pName[playerid]);
		PlayerTextDrawSetString(killerid, KillTD[killerid], str);
		PlayerTextDrawShow(killerid, KillTD[killerid]);
		SetTimerEx("HideKillTD", 3500, false, "i", killerid);

		KillStreak(killerid);
		if(KillSpree[playerid] >= 3)
		{
			format(str, sizeof str, "* You stopped %s's killstreak of %d.", pName[playerid], KillSpree[playerid]);
			SendClientMessage(killerid, COLOR_CYAN, str);
			
			format(str, sizeof str, "* %s has stopped your killstreak of %d.", pName[killerid], KillSpree[playerid]);
			SendClientMessage(playerid, COLOR_RED, str);

			format(str, sizeof str, "%s's killing spree of %d has stopped by %s.", pName[playerid], pName[killerid]);
			SendBoxMessage(str);
			KillSpree[playerid] = 0;
		}

		if(CPSpree[playerid] >= 3)
		{
			format(str, sizeof str, "* You stopped %s's capturing spree of %d.", pName[playerid], CPSpree[playerid]);
			SendClientMessage(killerid, COLOR_CYAN, str);
			
			format(str, sizeof str, "* %s has stopped your capturing spree of %d.", pName[killerid], CPSpree[playerid]);
			SendClientMessage(playerid, COLOR_RED, str);
			
			format(str, sizeof str, "%s's capturing spree of %d has stopped by %s.", pName[playerid], pName[killerid]);
			SendBoxMessage(str);
			CPSpree[playerid] = 0;
		}

		for(new i; i < MAX_ZONES; i++)
		{
			if(gZones[i][ZoneAttacker] == playerid)
			{
				format(str, sizeof str, "* You stopped %s from capturing the zone %s, you got +3 score and +$2000.", pName[playerid], gZones[i][ZoneName]);
				SendClientMessage(killerid, COLOR_CYAN, str);
				
				format(str, sizeof str, "* %s stopped you from capturing the zone %s.", pName[killerid], gZones[i][ZoneName]);
				SendClientMessage(playerid, COLOR_RED, str);
				
				GivePlayerScore(killerid, 3);
				pInfo[killerid][Cash] += 2000;
				break;
			}
		}

		if(gBonusPlayer[BonusID] == playerid)
		{
			format(str, sizeof str, "~p~~h~%s has killed bonus player %s and claimed the bonus.", pName[killerid], pName[playerid]);
			SendBoxMessage(str);
			format(str, sizeof str, "* You got %d score and $%d for killing the bonus player.", gBonusPlayer[BonusScore], gBonusPlayer[BonusCash]);
			SendClientMessage(killerid, COLOR_CYAN, str);
			GivePlayerScore(killerid, gBonusPlayer[BonusScore]);
			pInfo[killerid][Cash] += gBonusPlayer[BonusCash];
			gBonusPlayer[BonusScore] = gBonusPlayer[BonusCash] = 0;
			gBonusPlayer[BonusPrv] = gBonusPlayer[BonusID];
			gBonusPlayer[BonusID] = killerid;
			gBonusZone[BonusScore] = random(10 - 3) + 4;
			gBonusZone[BonusCash] = random(8000 - 2000) + 2001;
			format(str, sizeof str, "~p~~h~%s is selected as a bonus player, kill the player and get $%d & %d score.", pName[gBonusPlayer[BonusID]], gBonusPlayer[BonusCash], gBonusPlayer[BonusScore]);
			SendBoxMessage(str);
			KillTimer(gBonusPlayer[BonusTime]);
			gBonusPlayer[BonusTime] = SetTimer("BonusPlayer", 600000, false);
		}
	}
	else
	{
		new xCash = random(2000 - 1000) + 1000;
		format(str, sizeof str, "* You died and paid $%d.", xCash);
		SendClientMessage(playerid, COLOR_RED, str);
		pInfo[playerid][Cash] -= xCash;

		if(KillSpree[playerid] >= 3)
		{
			format(str, sizeof str, "* You died while on a killstreak of %d.", KillSpree[playerid]);
			SendClientMessage(playerid, COLOR_RED, str);

			format(str, sizeof str, "%s's killing spree of %d stopped.", pName[playerid], KillSpree[playerid]);
			SendBoxMessage(str);
		}
		KillSpree[playerid] = 0;

		if(CPSpree[playerid] >= 3)
		{
			format(str, sizeof str, "* You died while on a capturing spree of %d.", CPSpree[playerid]);
			SendClientMessage(playerid, COLOR_RED, str);

			format(str, sizeof str, "%s's capturing spree of %d stopped.", pName[playerid], CPSpree[playerid]);
			SendBoxMessage(str);
		}
		CPSpree[playerid] = 0;

		if(gBonusPlayer[BonusID] == playerid)
		{
			format(str, sizeof str, "~p~~h~%s died mysteriously while being a bonus player.", pName[playerid]);
			SendBoxMessage(str);
			SendBoxMessage("~p~~h~New bonus player being selected in 10 minutes...");
			gBonusPlayer[BonusID] = INVALID_PLAYER_ID;
			gBonusPlayer[BonusScore] = gBonusPlayer[BonusCash] = 0;
			KillTimer(gBonusPlayer[BonusTime]);
			gBonusPlayer[BonusTime] = SetTimer("BonusPlayer", 600000, false);
		}
	}

	new AssistCash = random(1000 - 500) + 500;
	foreach(new i : Player)
	{
		if(pSpec[i][Spec] && pSpec[i][SpecID] == playerid) ForwardSpec(i);
		
		if(Assist[i] == playerid && i != killerid && killerid != INVALID_PLAYER_ID && !pSpec[i][Spec])
		{
			if(pTeam{killerid} == pTeam{i})
			{
				format(str, sizeof str, "* $%d for assisting %s (%d) in killing %s (%d)", AssistCash, pName[killerid], killerid, pName[playerid], playerid);
				SendClientMessage(i, COLOR_CYAN, str);
				pInfo[i][Cash] += AssistCash;
				for(new x; x < 2; x++) TextDrawShowForPlayer(i, AssistBox[x]);
				SetTimerEx("AssistBoxHide", 2000, false, "i", i);
			}
			Assist[i] = INVALID_PLAYER_ID;
		}
	}

	RemovePlayerHelmet(playerid);
	RemovePlayerGasMask(playerid);
	pInfo[playerid][Deaths]++;
	UpdateTD(playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	SQLCheck[playerid] += 1;
	SaveStats(playerid);

	VehTDvar[playerid] = pLogged{playerid} = CPSpree[playerid] = KillSpree[playerid] = DND[playerid] = 0;
	SpawnPlace[playerid] = MAX_ZONES;
	DestroyDynamic3DTextLabel(pLabel[playerid]);
	if(pInfo[playerid][Car] != -1) DestroyVehicle(pInfo[playerid][Car]);
	
	foreach(new i : Player)
	{
		if(pSpec[i][Spec] && pSpec[i][SpecID] == playerid) ForwardSpec(i);
		if(Assist[i] == playerid) Assist[i] = INVALID_PLAYER_ID;
		if(pIgnoring[playerid][i]) pIgnoring[playerid][i] = false;
		if(pIgnoring[i][playerid]) pIgnoring[i][playerid] = false;
	}

	foreach(new i : Helps)
	{
		if(hInfo[i][HelpBy] == playerid)
		{
			RemoveHelp(i);
		}
	}

	new str[100];
	switch(reason)
	{
		case 0: format(str, sizeof str, "~r~%s (%d) has disconnected (Crash/ Timeout)", pName[playerid], playerid);
		case 1: format(str, sizeof str, "~r~%s (%d) has disconnected (Quit)", pName[playerid], playerid);
		case 2: format(str, sizeof str, "~r~%s (%d) has disconnected (Kick/ Ban)", pName[playerid], playerid);
	}

	if(gBonusPlayer[BonusID] == playerid)
	{
		format(str, sizeof str, "~p~~h~Bonus player ~w~%s ~p~~h~disconnected", pName[gBonusPlayer[BonusID]]);
		SendBoxMessage(str);
		SendBoxMessage("~p~~h~New bonus player being selected in 10 minutes...");
		gBonusPlayer[BonusPrv] = gBonusPlayer[BonusID];
		gBonusPlayer[BonusID] = INVALID_PLAYER_ID;

		KillTimer(gBonusPlayer[BonusTime]);
		gBonusPlayer[BonusTime] = SetTimer("BonusPlayer", 60000, false);
	}

	HidePlayerBox(playerid);
	SendBoxMessage(str);
	ExitPlayerTDs(playerid);
	KillTimer(pPauseTimer[playerid]);
	return 1;
}

SaveStats(playerid)
{
	if(pLogged{playerid})
	{
		new hours, mins, secs;
		TotalGameTime(playerid, hours, mins, secs);
		hours += pInfo[playerid][Hours];
		mins += pInfo[playerid][Mins];
		secs += pInfo[playerid][Secs];
		if(secs >= 60)
		{
			secs = 0;
			mins += 1;
			if(mins >= 60)
			{
				mins = 0;
				hours += 1;
			}
		}

		new query[200];
		mysql_format(gSQL, query, sizeof query, "UPDATE "#TABLE_USERS" SET `Kills` = %d, `Deaths` = %d, `Heads` = %d, `Captures` = %d, `Score` = %d, `Cash` = %d, `Hours` = %d, `Mins` = %d, `Secs` = %d WHERE `ID` = %d",
			pInfo[playerid][Kills], pInfo[playerid][Deaths], pInfo[playerid][Heads], pInfo[playerid][Captures], GetPlayerScore(playerid), pInfo[playerid][Cash], hours, mins, secs, pInfo[playerid][SQLID]);
		mysql_pquery(gSQL, query);

		SendClientMessage(playerid, COLOR_TOMATO, "* Stats have been saved.");
		return 1;
	}
	return SendClientMessage(playerid, COLOR_TOMATO, "* Stats have not been saved."), 0;
}

InitGameModeExit()
{
	foreach(new i : Player) SaveStats(i);
	SendClientMessageToAll(COLOR_TOMATO, "* Server shut down.");
	print("Server is /exit");
	SendRconCommand("exit");
	return 1;
}

function AssistBoxHide(playerid)
{
	for(new x; x < 2; x++) TextDrawHideForPlayer(playerid, AssistBox[x]);
	return 1;
}

GetPlayerRank(playerid)
{
	for (new i = sizeof gRank - 1; i > -1; i--)
	{
		if (GetPlayerScore(playerid) >= gRank[i][RankScore])
		{
			return i;
		}
	}
	return 0;
}

KickEx(playerid) return SetTimerEx("Kicked", 1000, false, "i", playerid);

function Kicked(playerid)
{
	return Kick(playerid);
}

Dialog:DIALOG_TAG(playerid, response, listitem, inputtext[])
{
	new str[MAX_NICK_LENGTH + 1];

	if(!response) format(str, sizeof str, "%s"#TAG"", pName[playerid]); // Back
	else format(str, sizeof str, ""#TAG"%s", pName[playerid]); // Front
	
	SetPlayerName(playerid, str);
	GetPlayerName(playerid, pName[playerid], MAX_PLAYER_NAME);
	
	new query[90];
	mysql_format(gSQL, query, sizeof query, "UPDATE "#TABLE_USERS" SET `Tag` = '1' , `Name`= '%e' WHERE `ID` = %d", str, pInfo[playerid][SQLID]);
	mysql_pquery(gSQL, query);
	return 1;
}

CMD:changename(playerid)
{
	if(pInfo[playerid][Cash] < 250000) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You don't have $250,000 to change your name.");
	Dialog_Show(playerid, DIALOG_CNAME, DIALOG_STYLE_INPUT, "FD :: Changing Name", "Enter your new name to continue.\n"COL_RED"Changing name costs $250k!", "Proceed", "Cancel");
	return 1;
}

Dialog:DIALOG_CNAME(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;

	if (MIN_NICK_LENGTH < strlen(inputtext) > MAX_NICK_LENGTH)
	{
		new str[144];
		format(str, sizeof str, "ERROR: "COL_GREY"Invalid name length, must be between %i ~ %i chars.", MIN_NICK_LENGTH, MAX_NICK_LENGTH);
		return SendClientMessage(playerid, COLOR_RED, str);
	}
	
	if(strfind(inputtext, #TAG, true) != -1 && !pInfo[playerid][CTag])
		return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not allowed to use the community tag.");
	
	new query[70];
	mysql_format(gSQL, query, sizeof query, "SELECT * FROM "#TABLE_USERS" WHERE `Name` = '%e'", inputtext);
	mysql_tquery(gSQL, query, "OnPlayerNameChange", "is", playerid, inputtext);
	return 1;
}

function OnPlayerNameChange(playerid, name[])
{
	if (cache_num_rows() >= 1)
	{
		return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"This name is already taken.");
	}
	else
	{
		pInfo[playerid][Cash] -= 250000;
		new str[144], query[75];
		SendClientMessage(playerid, COLOR_TOMATO, "* Name changed, relog with the new name.");
		format(str, sizeof str, "%s has been kicked for name change (New name: %s).", pName[playerid], name);
		SendClientMessageToAll(COLOR_PINK, str);
		SetPlayerName(playerid, "new_name");
		SetPlayerName(playerid, name);
		GetPlayerName(playerid, pName[playerid], MAX_PLAYER_NAME);
		
		mysql_format(gSQL, query, sizeof query, "UPDATE "#TABLE_USERS" SET `Name` = '%e' WHERE `ID` = %d", name, pInfo[playerid][SQLID]);
		mysql_tquery(gSQL, query);
		KickEx(playerid);
	}
	return 1;
}

CMD:changepass(playerid)
{
	Dialog_Show(playerid, DIALOG_PW1, DIALOG_STYLE_INPUT, "FD :: Changing Password 1/2", "Enter your current password to continue", "Proceed", "Cancel");
	return 1;
}

Dialog:DIALOG_PW1(playerid, response, listitem, inputtext[])
{
	if(!response)
		return 1;
		
	/*new len = strlen(inputtext);
	if (len > MAX_PASSWORD_LENGTH || len < MIN_PASSWORD_LENGTH)
	{
		new str[150];
		format(str, sizeof (str), "ERROR: "COL_GREY"Invalid password length, must be between %i ~ %i chars.", MIN_PASSWORD_LENGTH, MAX_PASSWORD_LENGTH);
		return SendClientMessage(playerid, COLOR_RED, str);
	}*/

	new password[64 + 1];
	SHA256_PassHash(inputtext, PASSWORD_SALT, password, sizeof (password));

	if (strcmp(pInfo[playerid][Password], password))
	{
		Dialog_Show(playerid, DIALOG_PW1, DIALOG_STYLE_INPUT, "FD :: Changing Password 1/2", "Enter your current password to continue", "Proceed", "Cancel");
	}
	else
	{
		Dialog_Show(playerid, DIALOG_PW2, DIALOG_STYLE_INPUT, "FD :: Changing Password 2/2", "Enter your new password to continue", "Proceed", "Cancel");
	}
	return 1;
}

Dialog:DIALOG_PW2(playerid, response, listitem, inputtext[])
{
	if(!response)
		return 1;
	
	new len = strlen(inputtext);
	if (len > MAX_PASSWORD_LENGTH || len < MIN_PASSWORD_LENGTH)
	{
		new str[150];
		format(str, sizeof (str), "ERROR: "COL_GREY"Invalid password length, must be between %i ~ %i chars.", MIN_PASSWORD_LENGTH, MAX_PASSWORD_LENGTH);
		return SendClientMessage(playerid, COLOR_RED, str);
	}

	SHA256_PassHash(inputtext, PASSWORD_SALT, pInfo[playerid][Password], 65);

	new query[122];
	mysql_format(gSQL, query, sizeof query, "UPDATE "#TABLE_USERS" SET `Password` = '%e' WHERE `ID` = %d", pInfo[playerid][Password], pInfo[playerid][SQLID]);
	mysql_tquery(gSQL, query);
	return SendClientMessage(playerid, COLOR_TOMATO, "* Password successfully updated.");
}

CMD:admins(playerid)
{
	if(pInfo[playerid][AdminLvl] < 1) return 1;

	new str[500], count;
	foreach(new i : Player)
	{
		if(pInfo[i][AdminLvl] >= 1)
		{
			format(str, sizeof str, "%s* %s %s - Level %d\n", str, GetPlayerStaffRank(i), pName[i], pInfo[i][AdminLvl]);
			count ++;
		}
	}
	if(count) Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Online Admins", str, "Close", "");
	else Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Online Admins", "No admins are online", "Close", "");
	return 1;
}

CMD:donors(playerid)
{
	new str[500], count;
	foreach(new i : Player)
	{
		if(pInfo[i][DonorLvl] >= 1)
		{
			format(str, sizeof str, "%s* %s - %s\n", str, pName[i], GetPlayerDonorRank(i));
			count ++;
		}
	}
	if(count) Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Online Donors", str, "Close", "");
	else Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Online Donors", "No donors online", "Close", "");
	return 1;
}

SendAdminMessage(str[], color = COLOR_CRIMSON, level = 1, duty = -1)
{
	foreach(new i : Player)
	{
		if(pInfo[i][AdminLvl] >= level)
		{
			if(duty == -1) SendClientMessage(i, color, str);
			else if(pAdmDuty{i} == duty) SendClientMessage(i, color, str);
		}
	}
	return 1;
}

ShowRules(playerid)
{
	new str[2000];
	strcat(str, "{FFFFFF}If you want to play on our server, then you've to follow all these rules.\n");
	strcat(str, "Violating any of these rules will lead to punishment according to the rule.\n\n");
	strcat(str, "01- Do not use any hacks or cheats.\n");
	strcat(str, "02- Do not exploit/ abuse bugs, which may include C-Bug, 2 Shot, Slide bug and etc.\n");
	strcat(str, "03- Do not kill people using car ram/ park.\n");
	strcat(str, "04- Do not spawn kill or base rape.\n");
	strcat(str, "05- Do not ask for score and cash from admins.\n");
	strcat(str, "06- Do not AFK/ pause while capturing or DM'ing.\n");
	strcat(str, "07- Do not farm score or cash.\n");
	strcat(str, "08- Do not insult/ provoke or flame.\n");
	strcat(str, "09- Do not advertise any links or any IP.\n");
	strcat(str, "10- Do not discriminate any players' religion or ethnic background.\n");
	strcat(str, "11- Do not impersonate or use similar names as other players/ staff.\n");
	strcat(str, "12- Do not use illegal modifications (mods which give you advantage over others).\n");
	strcat(str, "13- Do not alert the hacker and use valid report reasons in /report.\n");
	strcat(str, "14- Do not share any pornographical content link through PM/ chat.\n");
	strcat(str, "15- If you have lost stats, make a thread on the forum to get it back with proofs.\n");
	strcat(str, "16- Do not log in with anyone else' account.\n");
	strcat(str, "17- Do not use multiple accounts, stick to only one account.\n");
	strcat(str, "18- If you need help, please ask an through /helpme or a tagged member.\n");
	strcat(str, "19- This is a 18+ game, so be mature and don't try to be an arse.");
	
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD ::  Rules", str, "Okay", "");
}

CMD:rules(playerid)
{
	ShowRules(playerid);
	return 1;
}

flags:forcerules(CMD_ADMIN);
CMD:forcerules(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	
	new targetid, str[144];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /forcerules [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(pInfo[targetid][AdminLvl] > pInfo[playerid][AdminLvl]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player's admin level is higher or same as yours."), 0;

	ShowRules(targetid);
	format(str, sizeof str, "%s %s has forced rules on %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendClientMessageToAll(COLOR_PINK, str);
	return 1;
}

flags:unwarn(CMD_ADMIN);
CMD:unwarn(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	
	new targetid, str[144], reason[72];
	if(sscanf(params, "uS(No reason given)[72]", targetid, reason)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /unwarn [ID] [REASON]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(pInfo[targetid][AdminLvl] > pInfo[playerid][AdminLvl]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player's admin level is higher or same as yours."), 0;
	if(pInfo[targetid][Warns] <= 0) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player can't be more un-warned."), 0;
	
	pInfo[targetid][Warns] -= 1;
	format(str, sizeof str, "%s %s has unwarned %s for reason: %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], reason);
	SendClientMessageToAll(COLOR_PINK, str);
	return 1;
}

flags:warn(CMD_ADMIN);
CMD:warn(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	
	new targetid, str[144], reason[72];
	if(sscanf(params, "uS(No reason given)[72]", targetid, reason)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /warn [ID] [REASON]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(pInfo[targetid][AdminLvl] > pInfo[playerid][AdminLvl]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player's admin level is higher or same as yours."), 0;

	pInfo[targetid][Warns] += 1;
	
	format(str, sizeof str, "%s %s has warned %s for reason: %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], reason);
	SendClientMessageToAll(COLOR_PINK, str);

	format(str, sizeof str, "Staff: %s %s\nReason: %s", GetPlayerStaffRank(playerid), pName[playerid], reason);
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_RED"Warning!", str, "Okay", "");

	if(pInfo[targetid][Warns] > 2)
	{
		format(str, sizeof str, "%s has been kicked for reason: maximum warning.", pName[targetid]);
		SendClientMessageToAll(COLOR_PINK, str);
		KickEx(targetid);
	}
	return 1;
}

flags:settag(CMD_ADMIN);
CMD:settag(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 6) return 0;
	new targetid, str[144];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "* /settag [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(pInfo[targetid][CTag]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is already authorized to use the tag."), 0;
	if(pInfo[targetid][AdminLvl] > pInfo[playerid][AdminLvl]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player's admin level is higher or same as yours."), 0;

	pInfo[targetid][CTag] = 1;
	format(str, sizeof str, "%s %s has authorized %s for using the community tag.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendClientMessageToAll(COLOR_PINK, str);
	Dialog_Show(targetid, DIALOG_TAG, DIALOG_STYLE_MSGBOX, "FD :: "#TAG" Tag Selection", "Where do you want your tag?", "Start", "End"); // latter
	return 1;
}

flags:unsettag(CMD_ADMIN);
CMD:unsettag(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 6) return 0;
	new targetid, str[144];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /unsettag [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(!pInfo[targetid][CTag]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is already not authorized to use the tag."), 0;
	if(pInfo[targetid][AdminLvl] > pInfo[playerid][AdminLvl]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player's admin level is higher or same as yours."), 0;
	pInfo[targetid][CTag] = 0;
	format(str, sizeof str, "%s %s has unauthorized %s from using the community tag.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendClientMessageToAll(COLOR_PINK, str);

	new tempname[MAX_NICK_LENGTH + 1];
	format(tempname, sizeof tempname, "%s", pName[targetid]);
	new pos = strfind(tempname, #TAG, true);
	if(pos != -1)
	{
		strdel(tempname, pos, pos + strlen(#TAG));
		SetPlayerName(targetid, tempname);
		GetPlayerName(playerid, pName[playerid], MAX_PLAYER_NAME);
	}
	
	new query[88];
	mysql_format(gSQL, query, sizeof query, "UPDATE "#TABLE_USERS" SET `Tag` = '0', `Name`= '%e' WHERE `ID`= %d", tempname, pInfo[targetid][SQLID]);
	mysql_pquery(gSQL, query);
	return 1;
}

flags:exit(CMD_ADMIN);
CMD:exit(playerid)
{
	if(pInfo[playerid][AdminLvl] < 6) return 0;
	SendClientMessageToAll(COLOR_TOMATO, "* Server is shutting down...");
	InitGameModeExit();
	return 1;
}

GetPlayerToSpectate()
{
	new playerid = INVALID_PLAYER_ID;
	foreach(new i : Player)
	{
		if(IsPlayerSpawned(i) && !pSpec[i][SpecID])
		{
		    playerid = i;
		    break;
		}
	}
	return playerid;
}

ForwardSpec(playerid)
{
	if(Iter_Count(Player) <= 2) return StopSpec(playerid);
	if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING && pSpec[playerid][SpecID] != INVALID_PLAYER_ID)
	{
		new i = GetPlayerToSpectate();
		
		if(i == INVALID_PLAYER_ID)
		{
		    StopSpec(playerid);
		    SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"An error occurred while looking for a player to spectate...");
		}
		
		if(!pSpec[i][Spec])
		{
			StartSpec(playerid, i);
		}
	}
	return 1;
}

StartSpec(playerid, targetid)
{
	foreach(new i : Player) if(pSpec[i][Spec] && pSpec[i][SpecID] == playerid) ForwardSpec(playerid);

	pSpec[playerid][SpecID] = targetid;
	TogglePlayerSpectating(playerid, true);
	if(IsPlayerInAnyVehicle(targetid)) PlayerSpectateVehicle(playerid, GetPlayerVehicleID(targetid));
	else PlayerSpectatePlayer(playerid, targetid);
	SetPlayerInterior(playerid, GetPlayerInterior(targetid));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
	return 1;
}

StopSpec(playerid)
{
	pSpec[playerid][SpecID] = INVALID_PLAYER_ID;
	TogglePlayerSpectating(playerid, false);
	return 1;
}

//flags:specoff(CMD_ADMIN);
CMD:specoff(playerid)
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	return (pSpec[playerid][Spec]) ? StopSpec(playerid) : (SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not spectating."));
}

//flags:spec(CMD_ADMIN);
CMD:spec(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	new targetid;
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /spec [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(targetid == playerid) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't spectate yourself, can you?"), 0;
	if(!IsPlayerSpawned(targetid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"That Player is not spawned."), 0;

	new str[100];
	format(str, sizeof str, "* %s %s is now spectating %s (%d)", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], targetid);
	SendAdminMessage(str);
	
	if(!pSpec[playerid][Spec]) GetPlayerPos(playerid, pSpec[playerid][Pos][0], pSpec[playerid][Pos][1], pSpec[playerid][Pos][2]);
	pSpec[playerid][Spec] = 1;
	StartSpec(playerid, targetid);
	return 1;
}

flags:cleardeaths(CMD_ADMIN);
CMD:cleardeaths(playerid)
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;
	for(new i; i < 15; i++) SendDeathMessage(INVALID_PLAYER_ID, MAX_PLAYERS + 1, -1);
	new str[100];
	format(str, sizeof str, "%s %s has cleared the death list.", GetPlayerStaffRank(playerid), pName[playerid]);
	SendBoxMessage(str);
	return 1;
}

flags:clearbox(CMD_ADMIN);
CMD:clearbox(playerid)
{
	if(pInfo[playerid][AdminLvl] < 3) return 0;
	ClearBoxMessage();
	new str[100];
	format(str, sizeof str, "%s %s has cleared the notification bar.", GetPlayerStaffRank(playerid), pName[playerid]);
	SendBoxMessage(str);
	return 1;
}

flags:slap(CMD_ADMIN);
CMD:slap(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	new targetid;
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/slap [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Target ID is not connected."), 0;

	new Float: X, Float: Y, Float: Z, str[80];
	GetPlayerPos(targetid, X, Y, Z);
	SetPlayerPos(targetid, X, Y, Z + 10.0);
	format(str, sizeof str, "* %s %s has slapped %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendAdminMessage(str);
	PlayerPlaySound(targetid, 1190, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1190, 0.0, 0.0, 0.0);
	return 1;
}

flags:clearchat(CMD_ADMIN);
CMD:clearchat(playerid)
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	for(new i; i <= 75; i++) SendClientMessageToAll(-1, " ");
	new str[65];
	format(str, sizeof str, "* %s %s has cleared the chat.", GetPlayerStaffRank(playerid), pName[playerid]);
	SendClientMessageToAll(COLOR_PINK, str);
	return 1;
}
alias:clearchat("cc");

flags:flip(CMD_ADMIN);
CMD:flip(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	new targetid, str[100];
	if(sscanf(params, "u", targetid))
	{
		if(pInfo[playerid][AdminLvl] <= 3 && !pAdmDuty{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not on admin duty."), 0;
		if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not in any vehicle."), 0;

		format(str, sizeof str, "* %s %s has flipped their vehicle.", GetPlayerStaffRank(playerid), pName[playerid]);
		SendAdminMessage(str);
		SendClientMessage(playerid, COLOR_BLUE, "* /flip [ID] to flip another player's vehicle.");
		targetid = playerid;
	}
	else
	{
		if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
		if(!IsPlayerInAnyVehicle(targetid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not in any vehicle."), 0;

		format(str, sizeof str, "* %s %s has flipped %s %s's vehicle.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
		SendAdminMessage(str);

		format(str, sizeof str, "* You've flipped %s's vehicle.", pName[targetid]);
		SendClientMessage(playerid, COLOR_PINK, str);

		format(str, sizeof str, "* %s %s has flipped your vehicle.", GetPlayerStaffRank(playerid), pName[playerid]);
		SendClientMessage(targetid, COLOR_PINK, str);
	}
	
	new Float: Angle, vehicle = GetPlayerVehicleID(targetid);
	GetVehicleZAngle(vehicle, Angle);
	SetVehicleZAngle(vehicle, Angle);
	return 1;
}

//flags:afix(CMD_ADMIN);
CMD:afix(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	if(pInfo[playerid][AdminLvl] <= 3 && !pAdmDuty{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not on admin duty."), 0;
	new targetid, str[100];
	if(sscanf(params, "u", targetid))
	{
		if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not in any vehicle."), 0;
		RepairVehicle(GetPlayerVehicleID(playerid));

		format(str, sizeof str, "* %s %s has repaired their vehicle.", GetPlayerStaffRank(playerid), pName[playerid]);
		SendAdminMessage(str);
		SendClientMessage(playerid, COLOR_BLUE, "* /afix [ID] to fix another player's vehicle.");
	}
	else
	{
		if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
		if(!IsPlayerInAnyVehicle(targetid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not in any vehicle."), 0;
		RepairVehicle(GetPlayerVehicleID(targetid));

		format(str, sizeof str, "* %s %s has repaired %s's vehicle.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
		SendAdminMessage(str);

		format(str, sizeof str, "* You've repaired %s's vehicle.", pName[targetid]);
		SendClientMessage(playerid, COLOR_PINK, str);

		format(str, sizeof str, "* %s %s has repaired your vehicle.", GetPlayerStaffRank(playerid), pName[playerid]);
		SendClientMessage(targetid, COLOR_PINK, str);
	}
	return 1;
}

flags:givecar(CMD_ADMIN);
CMD:givecar(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 3) return 0;

	new car[20], id, targetid;
	if(sscanf(params, "us[20]", targetid, car)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/givecar [ID] [CAR]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected"), 0;
	id = GetVehicleModelFromName(car);
	if(id == -1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid vehicle name."), 0;

	SpawnPlayerVehicle(targetid, id);

	new str[100];
	format(str, sizeof str, "* %s %s has given you a %s (%i).", GetPlayerStaffRank(playerid), pName[playerid], VehicleNames[id], id);
	SendClientMessage(targetid, COLOR_PINK, str);

	format(str, sizeof str, "* %s %s has given %s a %s (%i).", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], VehicleNames[id], id);
	SendAdminMessage(str);
	return 1;
}

flags:car(CMD_ADMIN);
CMD:car(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;

	new car[20], id = -1;
	if(sscanf(params, "s[20]", car)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/car [CAR]"), 0;
	id = GetVehicleModelFromName(car);
	if(id == -1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid vehicle name."), 0;

	SpawnPlayerVehicle(playerid, id);

	new str[75];
	format(str, sizeof str, "* %s %s has spawned a %s (%i).", GetPlayerStaffRank(playerid), pName[playerid], VehicleNames[id], id);
	SendAdminMessage(str);
	return 1;
}

GetVehicleModelFromName(veh[])
{
	for(new i; i < sizeof VehicleNames; i++)
	{
		if(!strcmp(veh, VehicleNames[i], true)) return i + 400;
	}
	return -1;
}

flags:giveweaponall(CMD_ADMIN);
CMD:giveweaponall(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 3) return 0;

	new Weapon, Ammo, str[80];
	if(sscanf(params, "k<WeaponFunc>i", Weapon, Ammo)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/giveweaponall [WEAPON] [AMMO]"), 0;
	if(Weapon == 38 || Weapon == 46 || Weapon == 0) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid weapon."), 0;

	format(str, sizeof str, "* %s %s has given everyone %s (%d).", GetPlayerStaffRank(playerid), pName[playerid], WeaponNames[Weapon], Ammo);
	SendClientMessageToAll(COLOR_PINK, str);
	foreach(new i : Player) GivePlayerWeapon(i, Weapon, Ammo);
	return 1;
}

SSCANF:WeaponFunc(string[])
{
	if ('0' <= string[0] <= '9')
	{
		new
			ret = strval(string);
		if (0 <= ret <= 18 || 22 <= ret <= 46)
		{
			return ret;
		}
	}
	else
	{
		for(new i; i < sizeof WeaponNames; i++)
		{
			if(!strcmp(WeaponNames[i], string)) return i;
		}
	}
	return -1;
}

flags:giveall(CMD_ADMIN);
CMD:giveall(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 4) return 0;
	new ItemID, Amount, str[70];
	if(sscanf(params, "iI(0)", ItemID, Amount))
	{
		SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"/giveall [ITEM] [AMOUNT*]");
		return SendClientMessage(playerid, COLOR_RED, "ITEM: "COL_GREY"1. Score, 2. Cash, 3. Helmet, 4. Gas Mask, 5. Health, 6. Armour"), 0;
	}
	if(1 < ItemID > 6) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid item entered."), 0;

	switch(ItemID)
	{
		case 1:
		{
			if(pInfo[playerid][AdminLvl] < 4) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't use this."), 0;
			if(21 < Amount > 1 || !Amount) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't give more than 20 score."), 0;

			format(str, sizeof str, "* %s %s has given everyone %d score.", GetPlayerStaffRank(playerid), pName[playerid], Amount);
			SendClientMessageToAll(COLOR_PINK, str);
			foreach(new i : Player) GivePlayerScore(i, Amount);
		}
		case 2:
		{
			if(pInfo[playerid][AdminLvl] < 4) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't use this."), 0;
			if(10001 < Amount > 1 || !Amount) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't give more than $10,000 cash."), 0;

			format(str, sizeof str, "* %s %s has given everyone $%d.", GetPlayerStaffRank(playerid), pName[playerid], Amount);
			SendClientMessageToAll(COLOR_PINK, str);
			foreach(new i : Player) pInfo[i][Cash] += Amount;
		}
		case 3:
		{
			format(str, sizeof str, "* %s %s has given everyone a Helmet.", GetPlayerStaffRank(playerid), pName[playerid]);
			SendClientMessageToAll(COLOR_PINK, str);
			foreach(new i : Player) GivePlayerHelmet(playerid);
		}
		case 4:
		{
			format(str, sizeof str, "* %s %s has given everyone a Gas Mask.", GetPlayerStaffRank(playerid), pName[playerid]);
			SendClientMessageToAll(COLOR_PINK, str);
			foreach(new i : Player) GivePlayerGasMask(playerid);
		}
		case 5:
		{
			format(str, sizeof str, "* %s %s has healed everyone.", GetPlayerStaffRank(playerid), pName[playerid]);
			SendClientMessageToAll(COLOR_PINK, str);
			foreach(new i : Player)
			{
				if(!pAdmDuty{i}) SetPlayerHealth(i, 99.0);
			}
		}
		case 6:
		{
			format(str, sizeof str, "* %s %s has armored everyone.", GetPlayerStaffRank(playerid), pName[playerid]);
			SendClientMessageToAll(COLOR_PINK, str);
			foreach(new i : Player)
			{
				if(!pAdmDuty{i}) SetPlayerArmour(i, 99.0);
			}
		}
	}
	return 1;
}

flags:explode(CMD_ADMIN);
CMD:explode(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;

	new targetid;
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/explode [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;

	new Float: X, Float: Y, Float: Z, str[85];
	GetPlayerPos(targetid, X, Y, Z);
	CreateExplosionForPlayer(targetid, X, Y, Z, 3, 5.0);
	format(str, sizeof str, "* %s %s has exploded %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendAdminMessage(str);
	return 1;
}

//flags:eventhelp(CMD_ADMIN);
CMD:eventhelp(playerid)
{
	if(pInfo[playerid][AdminLvl] < 3) return 0;

	new str[75];
	format(str, sizeof str, "%s Event\n%s Joining\nPlayers list\nEvent Places\nEvent Function", gEvent[Event] ? ("Close") : ("Start"), gEvent[Join] ? ("Disable") : ("Enable"));
	Dialog_Show(playerid, DIALOG_EVENT, DIALOG_STYLE_MSGBOX, "FD :: Event System", str, "Select", "Cancel");
	return 1;
}

Dialog:DIALOG_EVENT(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;

	switch(listitem)
	{
		case 0:
		{
			gEvent[Event] ^= 1;
			new str[65];
			format(str, sizeof str, "* %s %s has %s the event!", GetPlayerStaffRank(playerid), pName[playerid], gEvent[Event] ? ("started") : ("closed"));
			SendClientMessageToAll(COLOR_PINK, str);
		}
		case 1:
		{
			gEvent[Join] ^= 1;
			new str[70];
			format(str, sizeof str, "* %s %s has %s to the event!", GetPlayerStaffRank(playerid), pName[playerid], gEvent[Join] ? ("enabled") : ("disabled"));
			SendClientMessageToAll(COLOR_PINK, str);
		}
		case 2:
		{
			new str[1300], count;
			foreach(new i : Player)
			{
				if(pJoin{i})
				{
					format(str, sizeof str, "%s%s (%i)\n", str, pName[playerid], i);
					count += 1;
				}
			}
			format(str, sizeof str, "%s\n%i Players are in event.", str, count);
			Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Players list", str, "Cancel", "");
		}
		case 3:
		{
			Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Event Places", "Coming soon!", "Select", "Cancel");
		}
		case 4:
		{
			Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Event Functions", "Coming soon!", "Select", "Cancel");
		}
	}
	return 1;
}

flags:ann(CMD_ADMIN);
CMD:ann(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 3) return 0;
	
	new text[100];
	if(sscanf(params, "s[100]", text)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/ann [TEXT]"), 0;

	TextDrawSetString(AnnounceTD, text);
	TextDrawShowForAll(AnnounceTD);
	SetTimer("HideAnnounceTD", 5000, false);
	return 1;
}

function HideAnnounceTD()
{
	TextDrawHideForAll(AnnounceTD);
	return 1;
}

flags:setskin(CMD_ADMIN);
CMD:setskin(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 3) return 0;
	
	new targetid, skinid, str[90];
	if(sscanf(params, "ui", targetid, skinid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/setskin [ID] [SKIN]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "That player is not connected."), 0;
	if(!IsValidSkin(skinid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Skin is invalid."), 0;

	SetPlayerSkin(targetid, skinid);

	format(str, sizeof str, "* %s %s has set %s's skin to %d.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], skinid);
	SendAdminMessage(str);

	format(str, sizeof str, "* You've set %s's skin to %d.", pName[targetid], skinid);
	SendClientMessage(playerid, COLOR_PINK, str);

	format(str, sizeof str, "* %s %s has set your skin to %d.", GetPlayerStaffRank(playerid), pName[playerid], skinid);
	SendClientMessage(targetid, COLOR_PINK, str);
	return 1;
}

flags:akill(CMD_ADMIN);
CMD:akill(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;
	if(pInfo[playerid][AdminLvl] <= 3 && !pAdmDuty{playerid}) return SendClientMessage(playerid, COLOR_RED, "You're not on admin duty."), 0;

	new targetid, str[90], Float: X, Float: Y, Float: Z;

	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /akill [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "That player is not connected."), 0;

	GetPlayerPos(targetid, X, Y, Z);
	CreateExplosionForPlayer(targetid, X, Y, Z, 0, 8.0);
	SetPlayerHealth(targetid, 0.0);
	SetPlayerArmour(targetid, 0.0);

	GameTextForPlayer(targetid, "~r~Died by the hand of god", 5000, 3);

	format(str, sizeof str, "* %s %s has killed %s using hand of God.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendAdminMessage(str);

	format(str, sizeof str, "%s has died by the Hand of God.", pName[targetid]);
	SendClientMessageToAll(COLOR_PINK, str);

	SendClientMessage(targetid, COLOR_RED, "You have died by the Hand Of God for your actions.");
	return 1;
}

flags:spawn(CMD_ADMIN);
CMD:spawn(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;

	new targetid, str[90];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/spawn [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "That player is not connected."), 0;

	if(IsPlayerInAnyVehicle(targetid)) EjectPlayer(targetid);
	SpawnPlayer(targetid);

	format(str, sizeof str, "* %s %s has respawned %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendAdminMessage(str);

	format(str, sizeof str, "* %s %s has respawned you.", GetPlayerStaffRank(playerid), pName[playerid]);
	SendClientMessage(targetid, COLOR_PINK, str);

	format(str, sizeof str, "* You've respawned %s.", pName[targetid]);
	SendClientMessage(playerid, COLOR_PINK, str);
	return 1;
}

flags:disarm(CMD_ADMIN);
CMD:disarm(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;

	new targetid, str[90];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/disarm [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "That player is not connected."), 0;

	ResetPlayerWeapons(targetid);

	format(str, sizeof str, "* %s %s has disarmed %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendAdminMessage(str);

	format(str, sizeof str, "* You've disarmed %s.", pName[targetid]);
	SendClientMessage(playerid, COLOR_PINK, str);
	return 1;
}

flags:ajetpack(CMD_ADMIN);
CMD:ajetpack(playerid)
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;
	if(!pAdmDuty{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You must be on admin duty to use this command."), 0;

	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
	SendClientMessage(playerid, COLOR_PINK, "* Spawned Jetpack.");
	return 1;
}

CMD:freeze(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 1;
	new targetid, str[144];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"/freeze [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(pInfo[playerid][Freeze]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is already freezed."), 0;

	pInfo[playerid][Freeze] = 1;
	TogglePlayerControllable(playerid, 0);
	format(str, sizeof str, "%s %s has freezed %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendClientMessageToAll(COLOR_PINK, str);
	return 1;
}

CMD:unfreeze(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 1;
	new targetid, str[144];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"/unfreeze [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(!pInfo[playerid][Freeze]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not freezed."), 0;

	pInfo[playerid][Freeze] = 0;
	TogglePlayerControllable(playerid, 1);
	format(str, sizeof str, "%s %s has unfreezed %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendClientMessageToAll(COLOR_PINK, str);
	return 1;
}

CMD:mute(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	new targetid, time, reason[40], str[144];
	if(sscanf(params, "udS(No Reason Given)[40]", targetid, time, reason)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/mute [ID] [MINUTES] [REASON*]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(pInfo[targetid][Mute]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is already muted.");
	if(1 < time > 60 && time != 65535) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid mute time, must be between 1 ~ 60 (65535 = session mute)."), 0;

	pInfo[targetid][Mute] = 1;
	if(time != 65535)
	{
		format(str, sizeof str, "%s %s has muted %s for %d minute(s). Reason: %s", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], time, reason);
		pInfo[targetid][MuteTime] = (gettime() + (time * 60));
	}
	else
	{
		format(str, sizeof str, "%s %s has muted %s. Reason: %s", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], reason);
		pInfo[targetid][MuteTime] = time;
	}
	SendClientMessageToAll(COLOR_PINK, str);
	return 1;
}

CMD:unmute(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	new targetid, str[100];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/unmute [ID]"), 0;
	if(targetid != INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(!pInfo[targetid][Mute]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not muted."), 0;

	format(str, sizeof str, "%s %s has unmuted %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendClientMessageToAll(COLOR_PINK, str);
	pInfo[playerid][Mute] = pInfo[playerid][MuteTime] = 0;
	return 1;
}

CMD:acmds(playerid)
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	new str[900];
	strcat(str, ""COL_CRIMSON"Trainee Admins Commands\n");
	strcat(str, ""COL_WHITE"/forcerules, /kick, /warn, /unwarn, /spec, /specoff /say, /adminarea, /aduty, /afix, /goto, /get, /site\n");
	strcat(str, "/helpmes, /clearchat, /slap, /flip, /mute, /unmute\n");
	strcat(str, ""COL_THISTLE"#[TEXT] to use admin chat\n");
	
	if(pInfo[playerid][AdminLvl] >= 2)
	{
		strcat(str, ""COL_CRIMSON"\nJunior Admin Commands\n");
		strcat(str, ""COL_WHITE"/ip, /ban, /unban, /cleardeaths, /spawn, /disarm, /ajetpack, /freeze, /unfreeze\n");
	}

	if(pInfo[playerid][AdminLvl] >= 3)
	{
		strcat(str, ""COL_CRIMSON"\nGeneral Admin Commands\n");
		strcat(str, ""COL_WHITE"/clearbox, /base, /force, /giveweaponall, /eventhelp, /ann, /setarmour, /sethealth, /akill\n");
		strcat(str, "/setskin, /givecar, /rac\n");
	}

	if(pInfo[playerid][AdminLvl] >= 4)
	{
		strcat(str, ""COL_CRIMSON"\nLead Admin Commands\n");
		strcat(str, ""COL_WHITE"/setteam, /getteam, /spawnteam, /giveteam, /smenu, /giveall\n");
	}


	if(pInfo[playerid][AdminLvl] >= 5)
	{
		strcat(str, ""COL_CRIMSON"\nSupervisor Admin Commands\n");
		strcat(str, ""COL_WHITE"/setadmin, /setscore, /setkills, /setcash, /setdeaths\n");
		strcat(str, ""COL_THISTLE"@[TEXT] to use management chat.\n");
	}

	if(pInfo[playerid][AdminLvl] >= 6)
	{
		strcat(str, ""COL_CRIMSON"\nServer Manager Commands\n");
		strcat(str, ""COL_WHITE"/settag, /unsettag, /exit\n");
	}

	if(pInfo[playerid][AdminLvl] >= 7)
	{
		strcat(str, ""COL_CRIMSON"\nCommunity Manager Commands\n");
		strcat(str, ""COL_WHITE"-\n");
	}

	if(pInfo[playerid][AdminLvl] >= 8)
	{
		strcat(str, ""COL_CRIMSON"\nCommunity Owner Commands\n");
		strcat(str, ""COL_WHITE"/setdonor");
	}

	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Admin Commands", str, "Okay", "");
	return 1;
}

public OnPlayerCommandReceived(playerid, cmd[], params[], flags)
{
	if(gettime() < pCMDTick[playerid] && !pInfo[playerid][AdminLvl]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You must wait before using that command..."), 0;
	return 1;
}

public OnPlayerCommandPerformed(playerid, cmd[], params[], result, flags)
{
	if(result == -1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid command entered, please refer to /cmds to check the command."), 0;

	pCMDTick[playerid] = gettime() + 5;
	if(result)
	{
		if(flags & CMD_DONOR)
		{
			new str[60];
			format(str, sizeof str, "* [Donor] %s has used %s.", pName[playerid], cmd);
			SendAdminMessage(str, COLOR_DONOR);
			format(str, sizeof str, "/%s", cmd);
			SetPlayerChatBubble(playerid, str, COLOR_DONOR, 10.0, 2500);
		}
		else if(flags & CMD_ADMIN)
		{
			new str[60];
			format(str, sizeof str, "* [Admin] %s has used %s.", pName[playerid], cmd);
			SendAdminMessage(str, .level = pInfo[playerid][AdminLvl]);
		}
	}
	return 1;
}

CMD:objectives(playerid)
{
	new str[230];
	strcat(str, ""COL_WHITE"Your objectives are:\n\
		\t- Kill players.\n\t- Make killing spree.\n\t- Assist your team in killing.\n\t- Capture zones.\n\t- Make capturing spree.\n\
		\t- Stop foes from capturing zones.\n\t- Assisting your team in capturing zones.");
	
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Objectives", str, "Okay", "");
	return 1;
}
alias:objectives("obj");

CMD:report(playerid, params[])
{
	if(!IsPlayerSpawned(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not spawned.");
	new targetid, reason[60];
	if(sscanf(params, "us[60]", targetid, reason)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/report [ID] [REASON]");
	if(4 < strlen(reason) > 59) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Reason must be between 4 ~ 60");
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected.");

	new str[140];
	format(str, sizeof str, "* [REPORT] %s (%d) reported %s (%d). Reason: %s", pName[playerid], playerid, pName[targetid], targetid, reason);
	SendAdminMessage(str, COLOR_LIMEGREEN);
	SendClientMessage(playerid, COLOR_YELLOW, "* Report sent to online administrators.");
	return 1;
}

CMD:helpme(playerid)
{
	if(!IsPlayerSpawned(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not spawned.");

	Dialog_Show(playerid, DIALOG_RHELP, DIALOG_STYLE_INPUT, "FD :: Request Help", "{FFFFFF}Enter what kind of help you would like to receive, the reason must be between 10 ~ 90 chars.", "Proceed", "Cancel");
	return 1;
}

Dialog:DIALOG_RHELP(playerid, response, listitem, inputtext[])
{
	if(!response) return SendClientMessage(playerid, COLOR_RED, "* You cancelled.");
	if(MIN_HELP_LENGTH < strlen(inputtext) > MAX_HELP_LENGTH)
	{
		SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Only 10 ~ 90 chars. can be written here.");
		return Dialog_Show(playerid, DIALOG_RHELP, DIALOG_STYLE_INPUT, "FD :: Request Help", "{FFFFFF}Enter what kind of help you would like to receive, the reason must be between 10 ~ 90 chars.", "Proceed", "Cancel");
	}

	AddHelp(playerid, inputtext);
	return 1;
}

flags:helprequests(CMD_ADMIN);
CMD:helprequests(playerid)
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	new count = Iter_Free(Helps);
	if(count == -1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"There're no help requests."), 0;
	
	new tempstr[15], str[50], mainstr[66 * MAX_HELPS];
	strcat(mainstr, "ID\tStatus\tFrom\tTime\n");
	foreach(new i : Helps)
	{
		if((gettime() - hInfo[i][HelpTime]) >= 60) format(tempstr, sizeof tempstr, "%d mins ago", (gettime() - hInfo[i][HelpTime]) / 60);
		else format(tempstr, sizeof str, "%d secs ago", gettime() - hInfo[i][HelpTime]);
		format(str, sizeof str, "%d\t%s\t%s\t%s\n", i + 1, (hInfo[i][HelpOpen]) ? ("Read") : ("Unread"), pName[hInfo[i][HelpBy]], tempstr);
		strcat(mainstr, str);
	}
	Dialog_Show(playerid, DIALOG_HELPR, DIALOG_STYLE_TABLIST_HEADERS, "FD :: Help requests", mainstr, "Select", "Cancel");
	return 1;
}
alias:helprequests("helpmes");

Dialog:DIALOG_HELPR(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	new x = -1, str[115]; //possible fix comes here
	foreach(new i : Helps)
	{
		x += 1; //possible fix comes here
		if(listitem != x) continue;
		HelpSelected[playerid] = i;
		SendClientMessage(hInfo[HelpSelected[playerid]][HelpBy], COLOR_YELLOW, "* Your help request is being checked by an Admin.");
		hInfo[i][HelpOpen] = 1;
		format(str, sizeof str, "Help ID: %d\nHelp Info: %s", i + 1, hInfo[i][HelpInfo]);
		break;
	}
	Dialog_Show(playerid, DIALOG_HELPVIEW, DIALOG_STYLE_MSGBOX, "FD :: Help Request...", str, "Delete", "Reply");
	return 1;
}

Dialog:DIALOG_HELPREPLY(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;

	new str[100];
	format(str, sizeof str, "* %s %s has replied to %s's help request.", GetPlayerStaffRank(playerid), pName[playerid], pName[hInfo[HelpSelected[playerid]][HelpBy]]);
	SendAdminMessage(str);

	format(str, sizeof str, "* [HELP] From Admin: %s", inputtext);
	SendClientMessage(hInfo[HelpSelected[playerid]][HelpBy], COLOR_YELLOW, str);
	format(str, sizeof str, "* [HELP] To %s: %s", pName[HelpSelected[playerid]], inputtext);
	HelpSelected[playerid] = -1;
	return 1;
}

Dialog:DIALOG_HELPVIEW(playerid, response, listitem, inputtext[])
{
	if(!response) return Dialog_Show(playerid, DIALOG_HELPREPLY, DIALOG_STYLE_INPUT, "FD :: Help Request Reply", "Type your message that you want to send to player...", "Send", "Cancel");
	if(HelpSelected[playerid] == -1) return 1;

	new str[30];
	SendClientMessage(hInfo[HelpSelected[playerid]][HelpBy], COLOR_YELLOW, "* Your help request was deleted by an admin.");
	format(str, sizeof str, "* Deleted help request ID %d.", HelpSelected[playerid] + 1);
	SendClientMessage(playerid, COLOR_RED, str);

	RemoveHelp(HelpSelected[playerid]);
	HelpSelected[playerid] = -1;
	return 1;
}

CMD:getid(playerid, params[])
{
	new name[MAX_NICK_LENGTH + 1];
	if(sscanf(params, "s[24]", name)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"/getid [NAME]");

	new str[40], count;
	format(str, sizeof str, "* Search results for '%s'...", name);
	foreach(new i : Player)
	{
		if(strfind(pName[i], name) != -1)
		{
			if(!count)
			{
				format(str, sizeof str, "* %d. %s (%d)", count, pName[i], i);
			}
			count += 1;
		}
	}
	if(count > 1) format(str, sizeof str, "* %d results found, be more specific", count);

	SendClientMessage(playerid, (count > 1) ? (COLOR_RED) : (COLOR_DODGER_BLUE), str);
	return 1;
}

CMD:getids(playerid, params[])
{
	new name[MAX_NICK_LENGTH + 1];
	if(sscanf(params, "s[24]", name)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"/id [NAME]");

	new str[40], count;
	format(str, sizeof str, "* Search results for '%s'...", name);
	foreach(new i : Player)
	{
		if(strfind(pName[i], name) != -1)
		{
			count += 1;
			format(str, sizeof str, "* %d. %s (%d)", count, pName[i], i);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, str);
		}
	}
	format(str, sizeof str, "* %d results found...", count);

	SendClientMessage(playerid, COLOR_RED, (!count) ? ("* No results found...") : (str));
	return 1;
}

CMD:top(playerid)
{
	Dialog_Show(playerid, DIALOG_TOP, DIALOG_STYLE_LIST, "FD :: Top Players", "Top Kills\nTop Deaths\nTop Headshots\nTop Cash\nTop Score", "Select", "Cancel");
	return 1;
}

Dialog:DIALOG_TOP(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;

	switch(listitem)
	{
		case 0: mysql_tquery(gSQL, "SELECT * FROM "#TABLE_USERS" ORDER BY `Kills` DESC LIMIT 10", "ShowTopKills", "i", playerid);
		case 1: mysql_tquery(gSQL, "SELECT * FROM "#TABLE_USERS" ORDER BY `Deaths` DESC LIMIT 10", "ShowTopDeaths", "i", playerid);
		case 2: mysql_tquery(gSQL, "SELECT * FROM "#TABLE_USERS" ORDER BY `Heads` DESC LIMIT 10", "ShowTopHeads", "i", playerid);
		case 3: mysql_tquery(gSQL, "SELECT * FROM "#TABLE_USERS" ORDER BY `Cash` DESC LIMIT 10", "ShowTopCash", "i", playerid);
		case 4: mysql_tquery(gSQL, "SELECT * FROM "#TABLE_USERS" ORDER BY `Score` DESC LIMIT 10", "ShowTopScore", "i", playerid);
	}
	return 1;
}

function ShowTopKills(playerid)
{
	new rows = cache_num_rows();
	if(rows < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"An error occurred while executing the query...");
	
	new name[MAX_NICK_LENGTH + 1], kills, str[400];
	for(new i; i < rows; i++)
	{
		cache_get_value_name(i, "Name", name);
		cache_get_value_name_int(i, "Kills", kills);

		format(str, sizeof str, "%s%i. %s - %i kills\n", str, i + 1, name, kills);
	}
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Top Kills", str, "Okay", "");
	return 1;
}

function ShowTopDeaths(playerid)
{
	new rows = cache_num_rows();
	if(rows < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"An error occurred while executing the query...");
	
	new name[MAX_NICK_LENGTH + 1], deaths, str[400];
	for(new i; i < rows; i++)
	{
		cache_get_value_name(i, "Name", name);
		cache_get_value_name_int(i, "Deaths", deaths);

		format(str, sizeof str, "%s%i. %s - %i deaths\n", str, i + 1, name, deaths);
	}
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Top Deaths", str, "Okay", "");
	return 1;
}

function ShowTopHeads(playerid)
{
	new rows = cache_num_rows();
	if(rows < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"An error occurred while executing the query...");
	
	new name[MAX_NICK_LENGTH + 1], heads, str[400];
	for(new i; i < rows; i++)
	{
		cache_get_value_name(i, "Name", name);
		cache_get_value_name_int(i, "Heads", heads);

		format(str, sizeof str, "%s%i. %s - %i headshots\n", str, i + 1, name, heads);
	}
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Top Headshots", str, "Okay", "");
	return 1;
}

function ShowTopCash(playerid)
{
	new rows = cache_num_rows();
	if(rows < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"An error occurred while executing the query...");
	
	new name[MAX_NICK_LENGTH + 1], cash, str[400];
	for(new i; i < rows; i++)
	{
		cache_get_value_name(i, "Name", name);
		cache_get_value_name_int(i, "Cash", cash);

		format(str, sizeof str, "%s%i. %s - $%i\n", str, i + 1, name, cash);
	}
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Top Cash", str, "Okay", "");
	return 1;
}

function ShowTopScore(playerid)
{
	new rows = cache_num_rows();
	if(rows < 1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"An error occurred while executing the query...");
	
	new name[MAX_NICK_LENGTH + 1], score, str[400];
	for(new i; i < rows; i++)
	{
		cache_get_value_name(i, "Name", name);
		cache_get_value_name_int(i, "Score", score);

		format(str, sizeof str, "%s%i. %s - %i score\n", str, i + 1, name, score);
	}
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Top Score", str, "Okay", "");
	return 1;
}

CMD:ignore(playerid, params[])
{
	new targetid, str[65];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/ignore [ID]");
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected.");
	if(targetid == playerid) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't ignore yourself, can you?");
	if(pInfo[targetid][AdminLvl] > 0) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't ignore an administrator.");
	pIgnoring[playerid][targetid] ^= 1;
	if(!pIgnoring[playerid][targetid]) format(str, sizeof str, "* You're now ignoring %s (%i)!", pName[targetid], targetid);
	else format(str, sizeof str, "* You're now not ignoring %s (%d) anymore!", pName[targetid], targetid);
	SendClientMessage(playerid, COLOR_GREY, str);
	return 1;
}

CMD:r(playerid, params[])
{
	new text[90], str[140];
	if(sscanf(params, "s[90]", text)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/tr [MESSAGE]");
	format(str, sizeof str, "* [RADIO] %s (%d): %s", pName[playerid], playerid, text);
	SendTeamMessage(pTeam{playerid}, str);
	SendAdminMessage(str, COLOR_GREY, .duty = 1);
	return 1;
}

CMD:s(playerid, params[])
{
	new text[80], str[130], Float: X, Float: Y, Float: Z;
	if(sscanf(params, "s[80]", text)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/s [MESSAGE]");
	format(str, sizeof str, "* [SAY] %s (%d): %s", pName[playerid], playerid, text);
	GetPlayerPos(playerid, X, Y, Z);
	foreach(new i : Player)
	{
		if(IsPlayerInRangeOfPoint(i, 5.0, X, Y, Z)) SendClientMessage(i, COLOR_YELLOW, str);
	}
	return 1;
}

CMD:commands(playerid)
{
	Dialog_Show(playerid, DIALOG_CMDS, DIALOG_STYLE_LIST, "FD :: Commands", "General\nPlayer\nDonor", "Select", "Cancel");
	return 1;
}
alias:commands("cmds");

Dialog:DIALOG_CMDS(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;

	switch(listitem)
	{
		case 0:
		{
			new str[65 * sizeof gGeneralCommands];
			for(new i; i < sizeof gGeneralCommands; i++)
			{
				strcat(str, COL_WHITE);
				strcat(str, gGeneralCommands[i][CMDName]);
				strcat(str, COL_DODGER_BLUE);
				strcat(str, " - ");
				strcat(str, gGeneralCommands[i][CMDInfo]);
				strcat(str, "\n");
			}
			Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: General Commands", str, "Okay", "");
		}
		case 1:
		{
			new str[65 * sizeof gPlayerCommands];
			for(new i; i < sizeof gPlayerCommands; i++)
			{
				strcat(str, COL_WHITE);
				strcat(str, gPlayerCommands[i][CMDName]);
				strcat(str, COL_DODGER_BLUE);
				strcat(str, " - ");
				strcat(str, gPlayerCommands[i][CMDInfo]);
				strcat(str, "\n");
			}
			Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Player Commands", str, "Okay", "");
		}
		case 2:
		{
			new str[65 * sizeof gDonorCommands];
			for(new i; i < sizeof gDonorCommands; i++)
			{
				strcat(str, COL_WHITE);
				strcat(str, gDonorCommands[i][CMDName]);
				strcat(str, COL_DODGER_BLUE);
				strcat(str, " - ");
				strcat(str, gDonorCommands[i][CMDInfo]);
				strcat(str, "\n");
			}

			strcat(str, COL_WHITE);
			strcat(str, "NOTE: Amount of stars show the donation level required for it.");

			Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Donator Commands", str, "Okay", "");
		}
	}
	return 1;
}

CMD:savestats(playerid)
{
	if(!IsPlayerSpawned(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not spawned.");

	SaveStats(playerid);
	return 1;
}

CMD:pm(playerid, params[])
{
	new targetid, msg[90];
	if(!IsPlayerSpawned(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not spawned.");
	if(sscanf(params, "us[80]", targetid, msg)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/pm [ID] [MESSAGE]");
	if(targetid == playerid) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't send a PM to yourself.");
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "That player is not connected.");
	if(pIgnoring[targetid][playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"That person is ignoring you.");
	if(pIgnoring[playerid][targetid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're ignoring that person.");
	if(DND[targetid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"That person is not accepting any PMs.");

	SendPrivateMessage(playerid, targetid, msg);
	return 1;
}

CMD:rpm(playerid, params[])
{
	new msg[90];
	if(!IsPlayerSpawned(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not spawned.");
	if(sscanf(params, "s[80]", msg)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/rpm [MESSAGE]");
	if(pLastPM{playerid} == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"No one has PM'ed you back.");
	if(pIgnoring[pLastPM{playerid}][playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"That person is ignoring you.");
	if(pIgnoring[playerid][pLastPM{playerid}]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're ignoring that person.");
	if(DND[pLastPM{playerid}]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"That person is not accepting any PMs.");

	SendPrivateMessage(playerid, pLastPM{playerid}, msg);
	return 1;
}

SendPrivateMessage(playerid, targetid, msg[])
{
	new str[140];
	format(str, sizeof str, "[PM] From %s (%d): %s", pName[playerid], playerid, msg);
	SendClientMessage(targetid, COLOR_YELLOW, str);
	format(str, sizeof str, "[PM] To %s (%d): %s", pName[targetid], targetid, msg);
	SendClientMessage(playerid, COLOR_YELLOW, str);
	
	pLastPM{targetid} = playerid;
	if(IsPlayerPaused(targetid)) SendClientMessage(playerid, COLOR_GREY, "[PM] That player is paused right now...");
	if(sInfo[ReadPM])
	{
		new level = 1;
		if(pInfo[playerid][AdminLvl] > 1 && pInfo[playerid][AdminLvl] > pInfo[targetid][AdminLvl])
		{
			level = pInfo[playerid][AdminLvl];
		}
		else if(pInfo[targetid][AdminLvl] > 1 && pInfo[playerid][AdminLvl] < pInfo[targetid][AdminLvl])
		{
			level = pInfo[targetid][AdminLvl];
		}

		format(str, sizeof str, "* [PM] %s (%d) to %s (%d): %s", pName[playerid], playerid, pName[targetid], targetid, msg);
		SendAdminMessage(str, COLOR_GREY, level);
	}
	return 1;
}

CMD:dnd(playerid)
{
	DND[playerid] ^= 1;
	SendClientMessage(playerid, COLOR_GREY, (DND[playerid]) ? ("* You've enabled the DND mode.") : ("* You've disabled the DND mode."));
	return 1;
}

flags:rac(CMD_ADMIN);
CMD:rac(playerid)
{
	if(pInfo[playerid][AdminLvl] < 3) return 0;

	new str[67];
	format(str, sizeof str, "%s %s has respawned all vehicles.", GetPlayerStaffRank(playerid), pName[playerid]);
	SendAdminMessage(str);
	for(new i = GetVehiclePoolSize(); i >= 1; i--)
	{
		if(IsValidVehicle(i))
		{
			if(!IsVehOccupied(i)) SetVehicleToRespawn(i);
		}
	}
	return 1;
}

IsVehOccupied(veh)
{
	foreach(new i : Player)
	{
		if(IsPlayerInVehicle(i, veh)) return 1;
	}
	return 0;
}

flags:sethealth(CMD_ADMIN);
CMD:sethealth(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;
	if(pInfo[playerid][AdminLvl] <= 3 && !pAdmDuty{playerid}) return SendClientMessage(playerid, COLOR_RED, "You're not on admin duty."), 0;

	new targetid, str[100], Float:Health;
	if(sscanf(params, "uf", targetid, Health)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /sethealth [ID] [HEALTH]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "That player is not connected."), 0;
	
	SetPlayerHealth(targetid, Health);
	format(str, sizeof str, "* %s %s has set %s's health to %0.1f", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], Health);
	SendAdminMessage(str);
	return 1;
}

flags:setarmour(CMD_ADMIN);
CMD:setarmour(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;
	if(pInfo[playerid][AdminLvl] <= 3 && !pAdmDuty{playerid}) return SendClientMessage(playerid, COLOR_RED, "You're not on admin duty."), 0;

	new targetid, str[100], Float:Armour;
	if(sscanf(params, "uf", targetid, Armour)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /setarmour [ID] [AMOUNT]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "That player is not connected."), 0;
	
	SetPlayerArmour(targetid, Armour);
	format(str, sizeof str, "* %s %s has set %s's armour to %0.1f", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], Armour);
	SendAdminMessage(str);
	return 1;
}

//flags:oban(CMD_ADMIN);
CMD:oban(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 3) return 0;

	new target[MAX_NICK_LENGTH + 1], reason[50], time;
	if(sscanf(params, "s[20]dS(No reason given)[50]", target, time, reason)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /oban [NAME] [DAYS] [REASON]"), 0;
	if(time < 0 || time > 365) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid ban time, must be between 0 ~ 365 (0 = permanent ban)."), 0;

	new query[65];

	mysql_format(gSQL, query, sizeof query, "SELECT * FROM "#TABLE_USERS" WHERE `Name` = '%e'", target);
	if(mysql_tquery(gSQL, query, "OnAccountExist", "i", playerid))
	{
		new str[144], expiretime = (gettime() + (((time * 24) * 60) * 60));
		if(time > 0) format(str, sizeof str, "* %s %s has offline banned %s for reason %s till %s.", GetPlayerStaffRank(playerid), pName[playerid], target, reason, ReturnDate(expiretime));
		else format(str, sizeof str, "* %s %s has permanently offline banned %s for reason %s.", GetPlayerStaffRank(playerid), pName[playerid], target, reason);
		SendClientMessageToAll(COLOR_PINK, str);

		mysql_format(gSQL, query, sizeof query, "INSERT INTO "#TABLE_BANS" (`ExpireDate`, `IP`, `Name`, `Reason`, `BanBy`) VALUES (%d, '0.0.0.0', '%e', '%e', '%e')", expiretime, target, reason, pName[playerid]);
		mysql_tquery(gSQL, query);
	}
	else
	{
		SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"That account doesn't exist.");	
	}
	return 1;
}

flags:ban(CMD_ADMIN);
CMD:ban(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;
	
	new targetid, str[144], reason[50], time;
	if(sscanf(params, "udS(No reason given)[50]", targetid, time, reason)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /ban [ID] [DAYS] [REASON]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(pInfo[targetid][AdminLvl] > pInfo[playerid][AdminLvl]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player's admin level is higher or same as yours."), 0;
	if(time < 0 || time > 365) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid ban time, must be between 0 ~ 365 (0 = permanent ban)."), 0;

	new expiretime = (gettime() + (((time * 24) * 60) * 60));

	if(time > 0) format(str, sizeof str, "* %s %s has banned %s for reason %s till %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], reason, ReturnDate(expiretime));
	else format(str, sizeof str, "* %s %s has permanently banned %s for reason %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], reason);
	SendClientMessageToAll(COLOR_PINK, str);
	BanPlayer(targetid, pName[playerid], reason, (!time) ? 0 : expiretime);
	return 1;
}

//flags:unban(CMD_ADMIN);
CMD:unban(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;
	
	new name[24], query[105];
	if(sscanf(params, "s[24]", name)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"/unban [NAME/ IP]"), 0;
	mysql_format(gSQL, query, sizeof query, "SELECT * FROM "#TABLE_BANS" WHERE `Name` = '%e' OR `IP` = '%e' LIMIT 1", name, name);
	mysql_tquery(gSQL, query, "OnPlayerUnban", "is", playerid, name);
	return 1;
}

function OnPlayerUnban(playerid, content[])
{
	new query[100], str[85];
	if(cache_num_rows() >= 1)
	{
		mysql_format(gSQL, query, sizeof query, "REMOVE * FROM "#TABLE_BANS" WHERE `Name` = '%e' or `IP` = '%e' LIMIT 1", content, content);
		mysql_tquery(gSQL, query);
		format(str, sizeof str, "* %s %s has unbanned %s.", GetPlayerStaffRank(playerid), pName[playerid], content);
		SendAdminMessage(str);
		SendClientMessage(playerid, COLOR_RED, "* That account/ IP is now unbanned.");
	}
	else
	{
		mysql_format(gSQL, query, sizeof query, "SELECT * FROM "#TABLE_USERS" WHERE `Name` = '%e'", content);
		if(mysql_tquery(gSQL, query, "OnAccountExist", "i", playerid))
		{
			SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"That account isn't banned.");
		}
		else
		{
			SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"That account doesn't exist.");	
		}
	}
	return 1;
}

function OnAccountExist(playerid)
{
	if(cache_num_rows() >= 1) return 1;
	return 0;
}

flags:kick(CMD_ADMIN);
CMD:kick(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	new targetid, str[144], reason[72];
	if(sscanf(params, "uS(No reason given)[72]", targetid, reason)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /kick [ID] [REASON]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(pInfo[targetid][AdminLvl] > pInfo[playerid][AdminLvl]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player's admin level is higher or same as yours."), 0;

	format(str, sizeof str, "%s %s has kicked %s for reason: %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], reason);
	SendClientMessageToAll(COLOR_PINK, str);
	KickEx(targetid);
	return 1;
}

flags:ip(CMD_ADMIN);
CMD:ip(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 2) return 0;
	new str[140], targetid, ip[18];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /ip [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;

	GetPlayerIp(targetid, ip, sizeof ip);
	format(str, sizeof str, "* %s's IP: %s", pName[targetid], ip);
	SendClientMessage(playerid, COLOR_BLUE, str);
	return 1;
}

//flags:say(CMD_ADMIN);
CMD:say(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	new str[140], msg[95];
	if(sscanf(params, "s[95]", msg)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /say [TEXT]"), 0;

	format(str, sizeof str, "%s %s:{FFFFFF} %s", GetPlayerStaffRank(playerid), pName[playerid], msg);
	SendClientMessageToAll(COLOR_PINK, str);
	return 1;
}

flags:setdonor(CMD_ADMIN);
CMD:setdonor(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 8) return 0;
	new str[144], targetid, level, query[75];
	if(sscanf(params, "ud", targetid, level)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/setdonor [ID] [LEVEL]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(level < 0 || level > 3) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid donor rank."), 0;
	if(pInfo[targetid][DonorLvl] == level) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is already that level."), 0;
	
	mysql_format(gSQL, query, sizeof query, "UPDATE "#TABLE_USERS" SET `Donor` = %d WHERE `ID` = %d", level, pInfo[targetid][SQLID]);
	mysql_tquery(gSQL, query);
	pInfo[targetid][DonorLvl] = level;
	if(!level)
	{
		format(str, sizeof str, "* %s %s has removed %s's donor level.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
		SendAdminMessage(str);
	}
	else
	{
		format(str, sizeof str, "* %s %s has set %s's donor level to %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], GetPlayerDonorRank(targetid));
		SendAdminMessage(str);
		switch(level)
		{
			case 1:
			{
				if(pInfo[targetid][Deaths] > 100) pInfo[targetid][Deaths] -= 100;
				GivePlayerScore(targetid, 750);
				pInfo[targetid][Cash] += 2500000;
			}
			case 2:
			{
				if(pInfo[targetid][Deaths] > 300) pInfo[targetid][Deaths] -= 300;
				GivePlayerScore(targetid, 1500);
				pInfo[targetid][Cash] += 7500000;
			}
			case 3:
			{
				if(pInfo[targetid][Deaths] > 500) pInfo[targetid][Deaths] -= 500;
				GivePlayerScore(targetid, 3000);
				pInfo[targetid][Cash] += 15000000;
			}
		}
	}
	return 1;
}

flags:setcash(CMD_ADMIN);
CMD:setcash(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 5) return 0;
	new targetid, cash, str[144];
	if(sscanf(params, "ud", targetid, cash)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /setcash [ID] [CASH]."), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(targetid == playerid && (pInfo[playerid][AdminLvl] <= 5)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't set your own stats."), 0;

	pInfo[targetid][Cash] = cash;
	format(str, sizeof str, "* %s %s has set %s's cash to $%d.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], cash);
	SendAdminMessage(str);
	format(str, sizeof str, "* %s %s has set your cash to $%d.", GetPlayerStaffRank(playerid), pName[playerid], cash);
	SendClientMessage(targetid, COLOR_PINK, str);
	format(str, sizeof str, "* You've set %s' cash to $%d.", pName[targetid], cash);
	SendClientMessage(playerid, COLOR_PINK, str);
	return 1;
}

flags:setdeaths(CMD_ADMIN);
CMD:setdeaths(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 5) return 0;
	new targetid, deaths, str[144];
	if(sscanf(params, "ud", targetid, deaths)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /setdeaths [ID] [DEATHS]."), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(targetid == playerid && (pInfo[playerid][AdminLvl] <= 5)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't set your own stats."), 0;

	pInfo[targetid][Deaths] = deaths;
	format(str, sizeof str, "* %s %s has set %s 's deaths to %d.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], deaths);
	SendAdminMessage(str);
	format(str, sizeof str, "* %s %s has set your deaths to %d.", GetPlayerStaffRank(playerid), pName[playerid], deaths);
	SendClientMessage(targetid, COLOR_PINK, str);
	format(str, sizeof str, "* You've set %s' deaths to %d.", pName[targetid], deaths);
	SendClientMessage(playerid, COLOR_PINK, str);
	UpdateTD(playerid);
	return 1;
}

flags:setkills(CMD_ADMIN);
CMD:setkills(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 5) return 0;
	new targetid, kills, str[144];
	if(sscanf(params, "ud", targetid, kills)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /setkills [ID] [KILLS]."), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(targetid == playerid && (pInfo[playerid][AdminLvl] <= 5)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't set your own stats."), 0;

	pInfo[targetid][Kills] = kills;
	format(str, sizeof str, "* %s %s has set %s's kills to %d.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], kills);
	SendAdminMessage(str);
	format(str, sizeof str, "* %s %s has set your kills to %d.", GetPlayerStaffRank(playerid), pName[playerid], kills);
	SendClientMessage(targetid, COLOR_PINK, str);
	format(str, sizeof str, "* You've set %s' kills to %d.", pName[targetid], kills);
	SendClientMessage(playerid, COLOR_PINK, str);
	UpdateTD(playerid);
	return 1;
}

flags:setscore(CMD_ADMIN);
CMD:setscore(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 5) return 0;
	new targetid, score, str[144];
	if(sscanf(params, "ud", targetid, score)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /setscore [ID] [SCORE]."), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(targetid == playerid && (pInfo[playerid][AdminLvl] <= 5)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't set your own stats."), 0;

	SetPlayerScore(targetid, score);
	format(str, sizeof str, "* %s %s has set %s's score to %d.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], score);
	SendAdminMessage(str);

	format(str, sizeof str, "* %s %s has set your score to %d.", GetPlayerStaffRank(playerid), pName[playerid], score);
	SendClientMessage(targetid, COLOR_PINK, str);

	format(str, sizeof str, "* You've set %s' score to %d.", pName[targetid], score);
	SendClientMessage(playerid, COLOR_PINK, str);
	UpdateTD(playerid);
	return 1;
}

SSCANF:TeamFunc(string[])
{
	if('1' <= string[0] <= '5') return strval(string) - 1;
	else for(new i; i < sizeof gTeam; i++) if(!strcmp(string, gTeam[i][TeamName], true)) return i;
	return NO_TEAM;
}

flags:base(CMD_ADMIN);
CMD:base(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 3) return 0;
	new teamid;
	if(sscanf(params, "k<TeamFunc>", teamid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: "COL_GREY"/base [TEAM NAME/ ID]"), 0;
	if(teamid == NO_TEAM) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid team name."), 0;

	new str[85];
	format(str, sizeof str, "* %s %s has teleported to team %s's base.", GetPlayerStaffRank(playerid), pName[playerid], gTeam[teamid][TeamName]);
	SendAdminMessage(str);
	switch(random(3))
	{
		case 0: SetPlayerPos(playerid, gTeam[teamid][TeamSpawn1][0], gTeam[teamid][TeamSpawn1][1], gTeam[teamid][TeamSpawn1][2] + 1.0);
		case 1: SetPlayerPos(playerid, gTeam[teamid][TeamSpawn2][0], gTeam[teamid][TeamSpawn2][1], gTeam[teamid][TeamSpawn2][2] + 1.0);
		case 2: SetPlayerPos(playerid, gTeam[teamid][TeamSpawn3][0], gTeam[teamid][TeamSpawn3][1], gTeam[teamid][TeamSpawn3][2] + 1.0);
	}
	SetPlayerVirtualWorld(playerid, 0);
	SetPlayerInterior(playerid, 0);
	return 1;
}

flags:setteam(CMD_ADMIN);
CMD:setteam(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 4) return 0;
	new str[90], targetid, teamid;
	if(sscanf(params, "uk<TeamFunc>", targetid, teamid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /setteam [ID] [TEAM NAME/ ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(teamid == NO_TEAM) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid team name."), 0;

	format(str, sizeof str, "* %s %s has set %s's team to %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], gTeam[teamid][TeamName]);
	SendAdminMessage(str);
	format(str, sizeof str, "* %s %s has set your team to %s.", GetPlayerStaffRank(playerid), pName[playerid], gTeam[teamid][TeamName]);
	SendClientMessage(targetid, COLOR_PINK, str);
	pTeam{targetid} = teamid;
	SpawnPlayer(targetid);
	return 1;
}

flags:force(CMD_ADMIN);
CMD:force(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 3) return 0;
	new str[90], targetid;
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /force [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(!IsPlayerSpawned(targetid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"That Player is not spawned."), 0;

	format(str, sizeof str, "* %s %s has forced %s to class selection.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendAdminMessage(str);
	format(str, sizeof str, "* %s %s has forced you to class selection.", GetPlayerStaffRank(playerid), pName[playerid]);
	SendClientMessage(targetid, COLOR_PINK, str);

	ForceClassSelection(playerid);
	TogglePlayerSpectating(playerid, true);
	TogglePlayerSpectating(playerid, false);
	return 1;
}

flags:getteam(CMD_ADMIN);
CMD:getteam(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 4) return 0;
	new str[90], teamid, Float: X, Float: Y, Float: Z;
	if(sscanf(params, "k<TeamFunc>", teamid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /getteam [TEAM NAME/ ID]"), 0;
	if(teamid == NO_TEAM) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid team name."), 0;

	format(str, sizeof str, "* %s %s has teleported team %s to themself.", GetPlayerStaffRank(playerid), pName[playerid], gTeam[teamid][TeamName]);
	SendAdminMessage(str);
	GetPlayerPos(playerid, X, Y, Z);
	foreach(new i : Player)
	{
		format(str, sizeof str, "* %s %s has teleported your team to themself.", GetPlayerStaffRank(playerid), pName[playerid], gTeam[teamid][TeamName]);
		SendClientMessage(i, COLOR_PINK, str);
		SetPlayerPos(i, X, Y, Z + 0.5);
	}
	return 1;
}

flags:spawnteam(CMD_ADMIN);
CMD:spawnteam(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 4) return 0;
	new str[90], teamid;
	if(sscanf(params, "k<TeamFunc>", teamid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /spawnteam [TEAM NAME/ ID]"), 0;
	if(teamid == NO_TEAM) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid team name."), 0;

	format(str, sizeof str, "* %s %s has respawned team %s.", GetPlayerStaffRank(playerid), pName[playerid], gTeam[teamid][TeamName]);
	SendAdminMessage(str);
	foreach(new i : Player)
	{
		if(pTeam{i} == teamid)
		{
			format(str, sizeof str, "* %s %s has respawned your team.", GetPlayerStaffRank(playerid), pName[playerid], gTeam[teamid][TeamName]);
			SendClientMessage(i, COLOR_PINK, str);
			SpawnPlayer(i);
		}
	}
	return 1;
}

flags:setadmin(CMD_ADMIN);
CMD:setadmin(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 5) return 0;
	
	new str[144], targetid, level;
	if(sscanf(params, "ud", targetid, level)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /setadmin [ID] [LEVEL]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(level < 0 || level > pInfo[playerid][AdminLvl]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Invalid admin rank."), 0;
	if(pInfo[targetid][AdminLvl] == level) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is already that level."), 0;

	new tempstr[22], query[55];
	format(tempstr, sizeof tempstr, GetPlayerStaffRank(targetid));
	pInfo[targetid][AdminLvl] = level;
	if(pInfo[targetid][AdminLvl] > level)
	{
		if(!level)
		{
			format(str, sizeof str, "* %s %s has fired %s from staff team.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
			SendAdminMessage(str);
		}
		else
		{
			format(str, sizeof str, "* %s %s has demoted %s from %s to %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], tempstr, gStaff[level]);
			SendAdminMessage(str);
		}
	}
	else
	{
		format(str, sizeof str, "* %s %s has promoted %s from %s to %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid], tempstr, gStaff[level]);
		SendAdminMessage(str);
	}
	mysql_format(gSQL, query, sizeof query, "UPDATE "#TABLE_USERS" SET `Admin` = %d WHERE `ID`= %d", level, pInfo[targetid][SQLID]);
	mysql_tquery(gSQL, query);
	return 1;
}

CMD:spree(playerid, params[])
{
	new targetid = playerid;
	if(!sscanf(params, "u", targetid))
	{
		if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected.");
	}
	else
	{
		SendClientMessage(playerid, COLOR_BLUE, "* /spree [ID] to view another player's stats.");
	}
	ShowSpree(playerid, targetid);
	return 1;
}

ShowSpree(playerid, targetid)
{
	new str[80];
	format(str, sizeof str, "* %s (%i) | Capturing spree: %i | Killing Spree: %i", pName[targetid], targetid, CPSpree[targetid], KillSpree[targetid]);
	SendClientMessage(playerid, COLOR_BLUE, str);
	return 1;
}

CMD:stats(playerid, params[])
{
	new targetid = playerid;
	if(!sscanf(params, "u", targetid))
	{
		if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected.");
	}
	else
	{
		SendClientMessage(playerid, COLOR_BLUE, "* /stats [ID] to view another player's stats.");
	}
	ShowStats(playerid, targetid);
	return 1;
}

ShowStats(playerid, targetid)
{
	new str[500], hours, mins, secs, Float: ratio = ((pInfo[targetid][Deaths] <= 0) ? (0.0) : (floatdiv(pInfo[targetid][Kills], pInfo[targetid][Deaths])));
	
	TotalGameTime(playerid, hours, mins, secs);
	hours += pInfo[targetid][Hours];
	mins += pInfo[targetid][Mins];
	secs += pInfo[targetid][Secs];
	if(secs >= 60)
	{
		secs = 0;
		mins += 1;
		if(mins >= 60)
		{
			mins = 0;
			hours += 1;
		}
	}

	strcat(str, ""COL_WHITE"Name: %s (%d)\nScore: %d\nCash: $%d\nRank: %s\nTeam: %s\nClass: %s\nKills: %d\nDeaths: %d\n\
	Headshots: %d\nCaptures: %i\nK/D Ratio: %0.2f\nStaff: %s\nDonor: %s\nTotal playtime: %d hours, %d minutes and %d seconds\nRegister date: %s");
	
	format(str, sizeof str, str, pName[targetid], targetid, GetPlayerScore(targetid), pInfo[targetid][Cash], gRank[pRank{targetid}][RankName],
	gTeam[pTeam{targetid}][TeamName], gClass[pClass{targetid}][ClassName], pInfo[targetid][Kills], pInfo[targetid][Deaths], pInfo[targetid][Heads],
	pInfo[targetid][Captures], ratio, GetPlayerStaffRank(targetid), GetPlayerDonorRank(targetid), hours, mins, secs, pInfo[targetid][RegDate]);
	
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Player Statistics", str, "Okay", "");
	return 1;
}

TotalGameTime(playerid, &hours, &minutes, &seconds)
{
	new time = NetStats_GetConnectedTime(playerid);

	seconds = (time / 1000) % 60;
	minutes =  (time / (1000 * 60)) % 60;
	hours = (time / (1000 * 60 * 60));
}

flags:site(CMD_ADMIN);
CMD:site(playerid)
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	
	SendClientMessageToAll(COLOR_BLUE, "Community's "COL_WHITE"| "#SERVER_NAME" | "COL_BLUE""WEBSITE);
	GameTextForAll("~n~~n~~n~~w~"#SERVER_NAME"~n~~b~~h~~h~"#WEBSITE, 3000, 3);
	return 1;
}

//flags:goto(CMD_ADMIN);
CMD:goto(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	if(pInfo[playerid][AdminLvl] <= 3 && !pAdmDuty{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not on admin duty."), 0;
	new targetid, str[144];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /goto [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(targetid == playerid) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't teleport to yourself, can you?"), 0;

	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(targetid, X, Y, Z);
	SetPlayerPos(playerid, X + 0.5, Y + 0.5, Z + 0.5);
	SetPlayerInterior(playerid, GetPlayerInterior(targetid));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
	
	format(str, sizeof str, "* %s %s has teleported to you.", GetPlayerStaffRank(playerid), pName[playerid]);
	SendClientMessage(targetid, COLOR_PINK, str);

	format(str, sizeof str, "* %s %s has teleported to %s.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendAdminMessage(str);

	format(str, sizeof str, "* You have teleported to %s.", pName[targetid]);
	SendClientMessage(playerid, COLOR_PINK, str);
	return 1;
}

//flags:get(CMD_ADMIN);
CMD:get(playerid, params[])
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	if(pInfo[playerid][AdminLvl] <= 3 && !pAdmDuty{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not on admin duty."), 0;
	
	new targetid, str[144];
	if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /get [ID]"), 0;
	if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Player is not connected."), 0;
	if(targetid == playerid) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't teleport yourself to yourself, can you?"), 0;

	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(playerid, X, Y, Z);
	SetPlayerPos(targetid, X, Y, Z);
	SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));
	SetPlayerInterior(targetid, GetPlayerInterior(playerid));
	
	format(str, sizeof str, "* %s %s has teleported you to their position.", GetPlayerStaffRank(playerid), pName[playerid]);
	SendClientMessage(targetid, COLOR_PINK, str);

	format(str, sizeof str, "* %s %s has teleported %s to their position.", GetPlayerStaffRank(playerid), pName[playerid], pName[targetid]);
	SendAdminMessage(str);

	format(str, sizeof str, "* You have teleported %s to you.", pName[targetid]);
	SendClientMessage(playerid, COLOR_PINK, str);
	return 1;
}

//flags:aduty(CMD_ADMIN);
CMD:aduty(playerid)
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't go on duty while in spawn protection.");

	new str[70];
	pAdmDuty{playerid} ^= 1;
	format(str, sizeof str, "* %s %s is now %s admin duty.", GetPlayerStaffRank(playerid), pName[playerid], (pAdmDuty{playerid}) ? ("on") : ("off"));
	SendClientMessageToAll(COLOR_PINK, str);
	ResetPlayerWeapons(playerid);
	SetPlayerHealth(playerid, (pAdmDuty{playerid}) ? FLOAT_INFINITY : 99.0);
	if(!pAdmDuty{playerid})
	{
		SetPlayerTeam(playerid, pTeam{playerid});
		SpawnPlayer(playerid);
		return 1;
	}
	GivePlayerWeapon(playerid, 38, 999999);
	SetPlayerTeam(playerid, NO_TEAM);
	SetPlayerSkin(playerid, ADMIN_SKIN);
	SetPlayerColor(playerid, COLOR_PINK);
	UpdateTD(playerid);
	format(str, sizeof str, "%s", GetPlayerStaffRank(playerid));
	UpdateDynamic3DTextLabelText(pLabel[playerid], COLOR_RED, str);
	return 1;
}

//flags:smenu(CMD_ADMIN);
CMD:smenu(playerid)
{
	if(pInfo[playerid][AdminLvl] < 4) return 0;
	new str[300], small[5];
	strcat(str, "Setting Type\tValue\n");
	
	strcat(str, ""COL_WHITE"Read PMs\t");
	strcat(str, sInfo[ReadPM] ? (COL_GREEN"Yes") : (COL_RED"No"));

	strcat(str, "\n"COL_WHITE"Chat Disabled\t");
	strcat(str, sInfo[ChatDisabled] ? (COL_GREEN"Yes") : (COL_RED"No"));

	strcat(str, "\n"COL_WHITE"Max Ping\t");
	strcat(str, sInfo[MaxPing] ? (COL_GREEN) : (COL_RED));
	if(sInfo[MaxPing])
	{
		valstr(small, sInfo[MaxPing]);
		strcat(str, small);
	}
	else strcat(str, "Disabled");

	strcat(str, "\n"COL_WHITE"Weather\t");
	valstr(small, sInfo[Weather]);
	strcat(str, small);

	strcat(str, "\nTime\t");
	valstr(small, sInfo[Time]);
	strcat(str, small);

	strcat(str, "\nSave all stats");

	Dialog_Show(playerid, DIALOG_SMENU, DIALOG_STYLE_TABLIST_HEADERS, "FD :: Server Control Panel", str, "Change", "Cancel");
	return 1;
}

Dialog:DIALOG_SMENU(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	
	new str[144];
	switch(listitem)
	{
		case 0:
		{
			if(pInfo[playerid][AdminLvl] < 6) return 0;
			sInfo[ReadPM] ^= 1;
			format(str, sizeof str, "* %s %s has %s reading the PMs.", GetPlayerStaffRank(playerid), pName[playerid], (sInfo[ReadPM]) ? ("enabled") : ("disabled"));
			SendAdminMessage(str);
			return callcmd::smenu(playerid), 1;
		}
		case 1:
		{
			if(pInfo[playerid][AdminLvl] < 6) return 0;
			sInfo[ChatDisabled] ^= 1;
			format(str, sizeof str, "* %s %s has %s the chat.", GetPlayerStaffRank(playerid), pName[playerid], (!sInfo[ChatDisabled]) ? ("enabled") : ("disabled"));
			SendClientMessageToAll(COLOR_PINK, str);
			return callcmd::smenu(playerid), 1;
		}
		case 2:
		{
			if(pInfo[playerid][AdminLvl] < 6) return 0;
			Dialog_Show(playerid, DIALOG_MPING, DIALOG_STYLE_INPUT, "FD :: Max Ping", "Enter the maximum ping", "Change", "Cancel");
		}
		case 3: Dialog_Show(playerid, DIALOG_WEATHER, DIALOG_STYLE_INPUT, "FD :: Weather", "Enter world weather", "Change", "Cancel");
		case 4: Dialog_Show(playerid, DIALOG_TIME, DIALOG_STYLE_INPUT, "FD :: Time", "Enter world time", "Change", "Cancel");
		case 5:
		{
			format(str, sizeof str, "* %s %s has saved server and player stats.", GetPlayerStaffRank(playerid), pName[playerid]);
			SendAdminMessage(str);
			SaveConfig();
			StatsTimer();
			return callcmd::smenu(playerid), 1;
		}
	}
	return 1;
}

Dialog:DIALOG_MPING(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	
	if(!strlen(inputtext)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY" You can't leave the max ping dialog empty.");
	if(strval(inputtext) == sInfo[MaxPing]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY" The current max ping is already this.");
	if(strval(inputtext) != 0 && 600 <= strval(inputtext) >= 1001) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY" Invalid ping, must be between 600 ~ 1000 ms.");
	
	sInfo[MaxPing] = strval(inputtext);
	new str[144];
	if(sInfo[MaxPing]) format(str, sizeof str, "* %s %s has set the max ping value to %d.", GetPlayerStaffRank(playerid), pName[playerid], sInfo[MaxPing]);
	else format(str, sizeof str, "* %s %s has disabled ping kicker.", GetPlayerStaffRank(playerid), pName[playerid]);
	SendClientMessageToAll(COLOR_PINK, str);
	return callcmd::smenu(playerid), 1;
}

Dialog:DIALOG_TIME(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	if(!strlen(inputtext)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't leave the server time dialog empty.");
	if(strval(inputtext) == sInfo[Time]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"The current time is already this.");

	SetWorldTime(strval(inputtext));
	sInfo[Time] = strval(inputtext);
	new str[75];
	format(str, sizeof str, "* %s %s has set the world time to %d.", GetPlayerStaffRank(playerid), pName[playerid], sInfo[Time]);
	SendClientMessageToAll(COLOR_PINK, str);
	return callcmd::smenu(playerid), 1;
}

Dialog:DIALOG_WEATHER(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	if(!strlen(inputtext)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't leave the server weather dialog empty.");
	if(strval(inputtext) == sInfo[Weather]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"The current weather is already this.");
	
	SetWeather(strval(inputtext));
	sInfo[Weather] = strval(inputtext);
	new str[70];
	format(str, sizeof str, "* %s %s has set the world weather to %d.", GetPlayerStaffRank(playerid), pName[playerid], sInfo[Weather]);
	SendClientMessageToAll(COLOR_PINK, str);
	return callcmd::smenu(playerid), 1;
}

CMD:credits(playerid)
{
	new str[500];
	strcat(str, ""COL_RED""#SERVER_NAME" - Script version "#SCRIPT_REV" by "COL_WHITE"eXpose\n\
	"COL_RED"Community Owners: "COL_WHITE"eXpose and Flake\n\
	"COL_RED"Mapper: "COL_WHITE"N/ A\n\
	\n"COL_RED"Special thanks to: "COL_WHITE"Jarnu, Gammix, OstGot, Slice, Ralfie, Southclaw and the SA-MP team.\n\n\
	"COL_WHITE"We'd also like to thank all the admins for their efforts.");

	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD ::  Credits", str, "Okay", "");
	return 1;
}

CMD:adminarea(playerid)
{
	if(pInfo[playerid][AdminLvl] < 1) return 0;
	if(pInfo[playerid][AdminLvl] <= 3 && !pAdmDuty{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You're not on admin duty."), 0;

	new str[70];
	format(str, sizeof str, "* %s %s has teleported to Admin Area.", GetPlayerStaffRank(playerid), pName[playerid]);
	SendAdminMessage(str);
	SetPlayerPos(playerid, 369.0934, 173.8329, 1008.3893);
	SetPlayerFacingAngle(playerid, 230.7907);
	SetPlayerInterior(playerid, 3);
	SetPlayerVirtualWorld(playerid, 1);
	return 1;
}

CMD:chelp(playerid)
{
	ShowCHelp(playerid);
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid)
{
	new params[5];
	valstr(params, clickedplayerid);
	return callcmd::stats(playerid, params), 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
	if(damagedid != INVALID_PLAYER_ID && IsPlayerPaused(damagedid))
	{
		return GameTextForPlayer(playerid, "~w~Warning~n~~r~Player is AFK!", 3000, 3), 0;
	}

	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if(hittype != BULLET_HIT_TYPE_NONE && 0 <= weaponid <= WEAPON_MOLTOV)
	{
		BanPlayer(playerid, "Anti Cheat", "Bullet Crasher", 0);
		return 0;
	}
	
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid, bodypart)
{
	if(issuerid != INVALID_PLAYER_ID)
	{
		if(pAdmDuty{playerid})
		{
			return GameTextForPlayer(issuerid, "~w~Warning~n~~r~Do not attack admins on duty!", 3000, 3), 0;
		}

		if(pTeam{playerid} == pTeam{issuerid})
		{
			return GameTextForPlayer(issuerid, "~w~Warning~n~~r~Do not attack your team mates!", 3000, 3), 0;
		}

		if(IsPlayerInAnyVehicle(issuerid) && IsPlayerInDynamicArea(playerid, gTeam[pTeam{playerid}][TeamBaseArea]))
		{
			new vehid = GetVehicleModel(GetPlayerVehicleID(issuerid));
			if(vehid == 432 || vehid == 520 || vehid == 425 || vehid == 447) return GameTextForPlayer(issuerid, "~r~BASE RAPE IS NOT ALLOWED", 3500, 3), 0;
		}

		if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT && GetPlayerState(issuerid) == PLAYER_STATE_DRIVER)
		{
			if(weaponid == 49 || weaponid == 50)
			{
				new Float: X, Float: Y, Float: Z;
				GetPlayerPos(playerid, X, Y, Z);
				SetPlayerPos(playerid, X, Y, Z + 2.0);
				GameTextForPlayer(issuerid, "~w~Warning~n~~r~Do not car park/ car ram!", 3000, 3);
			}
		}

		new str[105];
		if(!AntiSK[playerid] && weaponid == 34 && bodypart == 9 && !pAdmDuty{playerid})
		{
			Assist[playerid] = INVALID_PLAYER_ID;
			if(!pHelmet{playerid})
			{
				SetPlayerHealth(playerid, 0.0);
				GameTextForPlayer(playerid, "~n~~r~Headshot", 3000, 3);
				GameTextForPlayer(issuerid, "~n~~g~Headshot", 3000, 3);
				new Float: x, Float: y, Float: z, Float: fDistance;
				GetPlayerPos(playerid, x, y, z);
				fDistance = GetPlayerDistanceFromPoint(issuerid, x, y, z);
				format(str, sizeof str, "~g~%s ~w~has headshotted ~r~%s ~w~from the distance of %0.2f metres.", pName[issuerid], pName[playerid], fDistance);
				SendBoxMessage(str);
				pInfo[issuerid][Heads] += 1;

				PlayerPlaySound(playerid, 1055, 0.0, 0.0, 0.0);
				PlayerPlaySound(issuerid, 1055, 0.0, 0.0, 0.0);
			}
			else
			{
				RemovePlayerHelmet(playerid);
				format(str, sizeof str, "~g~You broke %s's helmet.", pName[playerid]);
				GameTextForPlayer(issuerid, str, 3000, 3);
				format(str, sizeof str, "~r~%s broke your helmet.", pName[issuerid]);
				GameTextForPlayer(playerid, str, 3000, 3);
			}
		}

		KillTimer(PlayerTDt[playerid]);
		PlayerTDt[playerid] = 0;
		format(str,sizeof str,"~r~%s (-%.2f) ~n~~r~%s", pName[issuerid], amount, WeaponNames[weaponid]);
		PlayerTextDrawSetString(playerid, PlayerTD[playerid], str);
		PlayerTextDrawShow(playerid, PlayerTD[playerid]);
		PlayerTDt[playerid] = SetTimerEx("PlayerTDhide", 3000, 0, "i", playerid);
		PlayerTDvar[playerid] = 1;

		KillTimer(IssuerTDt[issuerid]);
		IssuerTDt[issuerid] = 0;
		format(str,sizeof str,"~g~%s (%.2f) ~n~~g~%s", pName[playerid], amount, WeaponNames[weaponid]);
		PlayerTextDrawSetString(issuerid, IssuerTD[issuerid], str);
		PlayerTextDrawShow(issuerid, IssuerTD[issuerid]);
		IssuerTDt[issuerid] = SetTimerEx("IssuerTDhide", 3000, 0, "i", issuerid);
		IssuerTDvar[issuerid] = 1;

		PlayerPlaySound(issuerid, 17802, 0.0, 0.0, 0.0);

		Assist[issuerid] = playerid;
	}
	return 1;
}

function PlayerTDhide(playerid)
{
	if(PlayerTDvar[playerid])
	{
		PlayerTextDrawHide(playerid, PlayerTD[playerid]);
		PlayerTDvar[playerid] = 0;
	}
	return 1;
}

function IssuerTDhide(playerid)
{
	if(IssuerTDvar[playerid])
	{
		PlayerTextDrawHide(playerid, IssuerTD[playerid]);
		IssuerTDvar[playerid] = 0;
	}
	return 1;
}

function VehTDhide(playerid)
{
	if(VehTDvar[playerid])
	{
		PlayerTextDrawHide(playerid, VehName[playerid]);
		VehTDvar[playerid] = 0;
	}
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	if(!ispassenger)
	{
		new string[25];
		format(string, sizeof string, "~y~%s", VehicleNames[GetVehicleModel(vehicleid) - 400]);
		PlayerTextDrawSetString(playerid, VehName[playerid], string);
		PlayerTextDrawShow(playerid, VehName[playerid]);
		SetTimerEx("VehTDhide", 2500, false, "i", playerid);
		VehTDvar[playerid] = 1;

		new targetid = INVALID_PLAYER_ID;
		foreach(new i : Player)
		{
			if(i != playerid && GetPlayerVehicleID(i) == vehicleid && GetPlayerVehicleSeat(i) == 0)
			{
				targetid = i;
				break;
			}
		}

		if(targetid != INVALID_PLAYER_ID && pTeam{targetid} == pTeam{playerid})
		{
			EjectPlayer(playerid);

			GameTextForPlayer(playerid, "~w~Warning~n~~r~DON'T JACK YOUR TEAM MATES", 3, 3000);
			return 0;
		}
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	VehTDhide(playerid);
	return 1;
}

Dialog:DIALOG_SHOP(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	switch(listitem)
	{
		case 0:
		{
			new Float: Health;
			if(GetPlayerHealth(playerid, Health) >= 95.0) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Your health is in good state.");
			
			SetPlayerHealth(playerid, 99.0);
			pInfo[playerid][Cash] -= 1000;
			SendClientMessage(playerid, COLOR_GREEN, "* You purchased 'Health' for $1000.");
		}
		case 1:
		{
			new Float: Armour;
			if(GetPlayerArmour(playerid, Armour) >= 95.0) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Your armour is in good state.");
			
			SetPlayerArmour(playerid, 99.0);
			pInfo[playerid][Cash] -= 2000;
			SendClientMessage(playerid, COLOR_GREEN, "* You purchased 'Armour' for $2000.");
		}
		case 2:
		{
			if(pHelmet{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You already have helmet.");
			
			GivePlayerHelmet(playerid);
			pInfo[playerid][Cash] -= 3000;
			SendClientMessage(playerid, COLOR_GREEN, "* You purchased 'Helmet' for $3000.");
		}
		case 3:
		{
			if(pGas{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You already have gas mask.");
			
			GivePlayerGasMask(playerid);
			pInfo[playerid][Cash] -= 3000;
			SendClientMessage(playerid, COLOR_GREEN, "* You purchased 'Gas Mask' for $3000.");
		}
		case 4:
		{
			new str[200];
			strcat(str, "Item\tCost\n");
			for(new i; i < sizeof gShopWeapons; i++)
			{
				format(str, sizeof str, "%s%s\t$%d\n", str, WeaponNames[gShopWeapons[i][sWeaponID]], gShopWeapons[i][sWeaponCost]);
			}
			
			Dialog_Show(playerid, DIALOG_WEAPONS, DIALOG_STYLE_TABLIST_HEADERS, "FD :: Weapons", str, "Select", "Cancel");
		}
	}
	return 1;
}

Dialog:DIALOG_WEAPONS(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;

	new str[70];
	if(pInfo[playerid][Cash] < gShopWeapons[listitem][sWeaponCost])
	{
		format(str, sizeof str, "ERROR: "COL_GREY"You've insufficient funds to purchase '%s'.");
		SendClientMessage(playerid, COLOR_RED, str);
		return 1;
	}
	
	GivePlayerWeapon(playerid, gShopWeapons[listitem][sWeaponID], gShopWeapons[listitem][sWeaponAmmo]);
	pInfo[playerid][Cash] -= gShopWeapons[listitem][sWeaponCost];
	format(str, sizeof str, "* You purchased '%s' for $%d.", WeaponNames[gShopWeapons[listitem][sWeaponID]], gShopWeapons[listitem][sWeaponCost]);
	SendClientMessage(playerid, COLOR_GREEN, str);
	return 1;
}

public OnPlayerEnterDynamicCP(playerid, checkpointid)
{
	if(pAdmDuty{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't access checkpoints while on admin duty."), 0;
	if(pSpec[playerid][Spec]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't access checkpoints while spectating."), 0;
	
	new array[2], i;
	Streamer_GetArrayData(STREAMER_TYPE_CP, checkpointid, E_STREAMER_EXTRA_ID, array, 2);
	i = array[1];

	switch(array[0])
	{
		case CP_TYPE_SHOP:
		{
			if(gShop[i][ShopTeam] != NO_TEAM && gShop[i][ShopTeam] != pTeam{playerid}) return SendClientMessage(playerid, COLOR_RED, "ERROR: You can't access your enemy's shop.");
			if(IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't access your shop in a vehicle.");
				
			Dialog_Show(playerid, DIALOG_SHOP, DIALOG_STYLE_TABLIST_HEADERS, "FD :: Shop", "Item\tPrice\nHealth\t$1000\nArmour\t$2000\nHelmet\t$3000\nGas Mask\t$3000\nWeapons", "Select", "Cancel");
			return 1;
		}
		case CP_TYPE_ZONE:
		{
			new buf[150];
			if (gZones[i][ZoneAttacker] != INVALID_PLAYER_ID)
			{
				if (pTeam{playerid} == pTeam{gZones[i][ZoneAttacker]})
				{
					if(IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't capture the zone in a vehicle.");

					TextDrawShowForPlayer(playerid, ZoneTextdraw[i]);
					gZones[i][ZonePlayer] += 1;
					SendClientMessage(playerid, COLOR_GREEN, "* Stay in the checkpoint to assist your teammate in capturing the zone.");
				}
			}
			else
			{
				if(pTeam{playerid} == gZones[i][ZoneOwner]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"Your team already owns this zone.");
				if(IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't capture the zone in a vehicle.");
				
				buf[0] = EOS;
				if(gZones[i][ZoneOwner] != NO_TEAM)
				{
					strcat(buf, "* The zone is controlled by team ");
					strcat(buf, gTeam[gZones[i][ZoneOwner]][TeamName]);
				}
				else
				{
					strcat(buf, "* The zone is uncontrolled");
				}
				strcat(buf, ".");
				SendClientMessage(playerid, COLOR_GREEN, buf);
				GangZoneFlashForAll(gZones[i][ZoneID], SetAlpha(gTeam[pTeam{playerid}][TeamColor], GANGZONE_ALPHA));
				gZones[i][ZoneAttacker] = playerid;
				gZones[i][ZonePlayer] = 1;
				gZones[i][ZoneTick] = 0;
				KillTimer(gZones[i][ZoneTimer]);

				//(CAPTURE_TIME * (1000 - (200 * (pInfo[playerid][DonorLvl] - 1)))) / 1000
				//1000 - (200 * (pInfo[playerid][DonorLvl] - 1))
				format(buf, sizeof buf, "* Stay in the checkpoint for %d seconds to capture the zone.", (pInfo[playerid][DonorLvl] < 2) ? CAPTURE_TIME : 15);
				SendClientMessage(playerid, COLOR_GREEN, buf);
				gZones[i][ZoneTimer] = SetTimerEx("OnZoneUpdate", (pInfo[playerid][DonorLvl] < 2) ? 1000 : 600, true, "i", i);
				buf[0] = EOS;
				strcat(buf, "~p~Team ");
				strcat(buf, gTeam[pTeam{playerid}][TeamName]);
				strcat(buf, " is trying to capture ");
				strcat(buf, gZones[i][ZoneName]);
				if(gZones[i][ZoneOwner] != NO_TEAM)
				{
					strcat(buf, " against team ");
					strcat(buf, gTeam[gZones[i][ZoneOwner]][TeamName]);
				}
				strcat(buf, ".");
				SendBoxMessage(buf);

				if(gBonusZone[BonusID] == i)
				{
					format(buf, sizeof buf, "* You're capturing a bonus zone and will get %d score and $%d.", gBonusZone[BonusScore], gBonusZone[BonusCash]);
					SendClientMessage(playerid, COLOR_CYAN, buf);
				}
				TextDrawShowForPlayer(playerid, ZoneTextdraw[i]);
			}
			return 1;
		}
	}
	return 1;
}

UpdateTD(playerid)
{
	new string[200];
	if(pAdmDuty{playerid})
	{
		format(string, sizeof string, "~y~Name: ~w~%s ~y~- ~r~Admin Duty ~y~- ~r~%s", pName[playerid], GetPlayerStaffRank(playerid));
	}
	else
	{
		pRank{playerid} = GetPlayerRank(playerid);
		format(string, sizeof string, "~y~Name: ~w~%s ~y~- Score: ~w~%d ~y~- Rank: ~w~%s ~y~- Team: ~w~%s ~y~- Class: ~w~%s ~y~- Kills: ~w~%d ~y~- Deaths: ~w~%d ~y~- Heads: ~w~%d",
			pName[playerid], GetPlayerScore(playerid), gRank[pRank{playerid}][RankName], gTeam[pTeam{playerid}][TeamName], gClass[pClass{playerid}][ClassName], pInfo[playerid][Kills], pInfo[playerid][Deaths], pInfo[playerid][Heads]);
	}

	PlayerTextDrawSetString(playerid, StatsTD[playerid], string);
}

function OnZoneUpdate(zoneid)
{
	if(IsPlayerPaused(gZones[zoneid][ZoneAttacker])) return 1;

	switch(gZones[zoneid][ZonePlayer])
	{
		case 1: gZones[zoneid][ZoneTick] += 1;
		case 2: gZones[zoneid][ZoneTick] += 2;
		default: gZones[zoneid][ZoneTick] += 3;
	}

	new str[150];
	if(gZones[zoneid][ZoneOwner] != NO_TEAM)
	{
		strcat(str, "~y~Capturing...~n~~g~Progress: ~w~%d%%~n~~r~Captured by: ~w~%s~n~~g~Capturing by: ~w~%s~n~~b~Assist: ~w~%d");
		format(str, sizeof str, str, gZones[zoneid][ZoneTick] * 4, gTeam[gZones[zoneid][ZoneOwner]][TeamName], gTeam[gZones[zoneid][ZoneAttacker]][TeamName], (gZones[zoneid][ZonePlayer] - 1));
	}
	else
	{
		strcat(str, "~y~Capturing...~n~~g~Progress: ~w~%d%%~n~~r~Captured by: ~w~No One~n~~g~Capturing by: ~w~%s~n~~b~Assist: ~w~%d");
		format(str, sizeof str, str, gZones[zoneid][ZoneTick] * 4, gTeam[gZones[zoneid][ZoneAttacker]][TeamName], (gZones[zoneid][ZonePlayer] - 1));
	}
	TextDrawSetString(ZoneTextdraw[zoneid], str);

	foreach(new i : Player)
	{
		if (!pAdmDuty{i} && !pSpec[i][Spec] && IsPlayerInDynamicCP(i, gZones[zoneid][ZoneCPID]) && !IsPlayerInAnyVehicle(i) && pTeam{i} == pTeam{gZones[zoneid][ZoneAttacker]})
		{
			TextDrawShowForPlayer(i, ZoneTextdraw[zoneid]);
		}
	}

	if (gZones[zoneid][ZoneTick] > CAPTURE_TIME)
	{
		CapStreak(gZones[zoneid][ZoneAttacker]);
		SendClientMessage(gZones[zoneid][ZoneAttacker], COLOR_GREEN, "* You have successfully captured the zone, +3 score and +$3000.");
		GivePlayerScore(gZones[zoneid][ZoneAttacker], 3);
		pInfo[gZones[zoneid][ZoneAttacker]][Cash] += 3000;
		
		if(!pRank{gZones[zoneid][ZoneAttacker]})
		{
			SendClientMessage(gZones[zoneid][ZoneAttacker], COLOR_GREEN, "* You have received extra +2 score and +$2000 as a new player.");
			GivePlayerScore(gZones[zoneid][ZoneAttacker], 2);
			pInfo[gZones[zoneid][ZoneAttacker]][Cash] += 2000;
		}
		if(gBonusZone[BonusID] == zoneid)
		{
			format(str, sizeof str, "~p~~h~%s has captured the bonus zone %s and claimed the bonus.", pName[gZones[zoneid][ZoneAttacker]], gZones[zoneid][ZoneName]);
			SendBoxMessage(str);
			SendBoxMessage("~p~~h~New capture zone being selected in 10 minutes...");
			format(str, sizeof str, "* You got %d score and $%d for capturing the bonus zone.", gBonusZone[BonusScore], gBonusZone[BonusCash]);
			SendClientMessage(gZones[zoneid][ZoneAttacker], COLOR_CYAN, str);
			GivePlayerScore(gZones[zoneid][ZoneAttacker], gBonusZone[BonusScore]);
			pInfo[gZones[zoneid][ZoneAttacker]][Cash] += gBonusZone[BonusCash];
			gBonusZone[BonusScore] = gBonusZone[BonusCash] = 0;
			gBonusZone[BonusPrv] = gBonusZone[BonusID];
			gBonusZone[BonusID] = MAX_ZONES;
			KillTimer(gBonusZone[BonusTime]);
			gBonusZone[BonusTime] = SetTimer("BonusZone", 600000, false);
		}

		foreach(new p : Player)
		{
			if (IsPlayerInDynamicCP(p, gZones[zoneid][ZoneCPID]))
			{
				if (p != gZones[zoneid][ZoneAttacker] && pTeam{p} == pTeam{gZones[zoneid][ZoneAttacker]} && ! IsPlayerInAnyVehicle(p))
				{
					SendClientMessage(p, COLOR_GREEN, "* You have assisted your teammate to capture the zone, +2 score and +$1500.");
					GivePlayerScore(p, 2);
					pInfo[p][Cash] += 1500;
					UpdateTD(p);
				}
				TextDrawHideForPlayer(p, ZoneTextdraw[zoneid]);
			}
		}
		
		TextDrawHideForPlayer(gZones[zoneid][ZoneAttacker], ZoneTextdraw[zoneid]);
		UpdateTD(gZones[zoneid][ZoneAttacker]);

		GangZoneStopFlashForAll(gZones[zoneid][ZoneID]);
		GangZoneShowForAll(gZones[zoneid][ZoneID], SetAlpha(gTeam[pTeam{gZones[zoneid][ZoneAttacker]}][TeamColor], GANGZONE_ALPHA));

		KillTimer(gZones[zoneid][ZoneTimer]);

		new text[150];
		strcat(text, "~p~Team ");
		strcat(text, gTeam[pTeam{gZones[zoneid][ZoneAttacker]}][TeamName]);
		strcat(text, " successfully captured ");
		strcat(text, gZones[zoneid][ZoneName]);
		if(gZones[zoneid][ZoneOwner] != NO_TEAM)
		{
			strcat(text, " against team ");
			strcat(text, gTeam[gZones[zoneid][ZoneOwner]][TeamName]);
		}
		strcat(text, ".");
		SendBoxMessage(text);
		
		if(gZones[zoneid][ZoneOwner] != NO_TEAM)
		{
			format(text, sizeof text, "* Your team has lost %s and you've lost -1 score.", gZones[zoneid][ZoneName]);
			foreach(new i : Player)
			{
				if(pTeam{i} == gZones[zoneid][ZoneOwner] && !pAdmDuty{i})
				{
					GivePlayerScore(i, -1);
					SendClientMessage(i, gTeam[gZones[zoneid][ZoneOwner]][TeamColor], text);
				}
			}
		}
		
		format(text, sizeof text, "* Your team has captured %s and you've gained 1 score.", gZones[zoneid][ZoneName]);
		foreach(new i : Player)
		{
			if(pTeam{i} == pTeam{gZones[zoneid][ZoneAttacker]} && !pAdmDuty{i} && i != gZones[zoneid][ZoneAttacker])
			{
				GivePlayerScore(i, 1);
				SendClientMessage(i, gTeam[pTeam{gZones[zoneid][ZoneAttacker]}][TeamColor], text);
			}
		}

		pInfo[gZones[zoneid][ZoneAttacker]][Captures] += 1;
		gZones[zoneid][ZoneOwner] = pTeam{gZones[zoneid][ZoneAttacker]};
		gZones[zoneid][ZoneAttacker] = INVALID_PLAYER_ID;

		format(str, sizeof str, "%s\n{FFFFFF}Controlled by %s", gZones[zoneid][ZoneName], gTeam[gZones[zoneid][ZoneOwner]][TeamName]);
		UpdateDynamic3DTextLabelText(gZones[zoneid][ZoneLabel], gTeam[gZones[zoneid][ZoneOwner]][TeamColor], str);
	}
	return 1;
}

public OnPlayerLeaveDynamicCP(playerid, checkpointid)
{
	if(IsPlayerInAnyVehicle(playerid)) return 0;
	if(pSpec[playerid][Spec] || pAdmDuty{playerid}) return 0;

	new array[2], i;
	Streamer_GetArrayData(STREAMER_TYPE_CP, checkpointid, E_STREAMER_EXTRA_ID, array, 2);
	i = array[1];

	switch(array[0])
	{
		case CP_TYPE_SHOP: return 1;
		case CP_TYPE_ZONE:
		{
			if(pTeam{playerid} == pTeam{gZones[i][ZoneAttacker]})
			{
				gZones[i][ZonePlayer] -= 1;
				
				if(!gZones[i][ZonePlayer])
				{
					SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You failed to capture the zone, there were no teammates left in the checkpoint.");

					GangZoneStopFlashForAll(gZones[i][ZoneID]);

					new buf[150];
					strcat(buf, "~p~Team ");
					strcat(buf, gTeam[pTeam{playerid}][TeamName]);
					strcat(buf, " failed to capture zone ");
					strcat(buf, gZones[i][ZoneName]);
					if(gZones[i][ZoneOwner] != NO_TEAM)
					{
						strcat(buf, " against team ");
						strcat(buf, gTeam[gZones[i][ZoneOwner]][TeamName]);
					}
					strcat(buf, ".");
					SendBoxMessage(buf);

					gZones[i][ZoneAttacker] = INVALID_PLAYER_ID;
					KillTimer(gZones[i][ZoneTimer]);
				}
				else if (gZones[i][ZoneAttacker] == playerid)
				{
					foreach(new p : Player)
					{
						if(pTeam{p} == pTeam{playerid} && IsPlayerInDynamicCP(p, checkpointid) && !pAdmDuty{p} && !pSpec[p][Spec])
						{
							SendClientMessage(playerid, COLOR_GREEN, "* You're now capturing the zone as the original capturer left the checkpoint.");
							gZones[i][ZoneAttacker] = p;
							break;
						}
					}
				}

				TextDrawHideForPlayer(playerid, ZoneTextdraw[i]);
			}
			return 1;
		}
	}
	return 1;
}

CMD:sc(playerid)
{
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't change classes while in spawn protection.");
	if(IsEnemyNearBy(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't do this when enemies are near-by.");

	pInfo[playerid][Deaths] -= 1;
	ForceClassSelection(playerid);
	SetPlayerHealth(playerid, 0.0);
	return 1;
}

CMD:kill(playerid)
{
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't request death while in spawn protection.");
	if(IsEnemyNearBy(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't do this when enemies are near-by.");

	SetPlayerHealth(playerid, 0.0);
	return 1;
}

CMD:st(playerid)
{
	if(AntiSK[playerid]) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't change teams while in spawn protection.");
	if(IsEnemyNearBy(playerid)) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You can't do this when enemies are near-by.");

	ForceClassSelection(playerid);
	SetPlayerHealth(playerid, 0.0);
	pInfo[playerid][Deaths] -= 1;
	return 1;
}

CMD:teams(playerid)
{
	new str[300];
	strcat(str, "Team Name\tPlayers\n");
	for(new i; i < sizeof gTeam; i++)
	{
		format(str, sizeof str, "%s{%06x}%s\t%d players\n", str, gTeam[i][TeamColor] >>> 8, gTeam[i][TeamName], GetTeamPlayers(i));
	}
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "FD :: Teams", str, "Okay", "");
	return 1;
}

CMD:team(playerid)
{
	new str[90];
	format(str, sizeof str, ""COL_WHITE"Our team {%06x}%s "COL_WHITE"has %d online players and %d zones captured!", gTeam[pTeam{playerid}][TeamColor] >>> 8, gTeam[pTeam{playerid}][TeamName], GetTeamPlayers(pTeam{playerid}), GetTeamZones(pTeam{playerid}));
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Team Info", str, "Okay", "");
	return 1;
}

CMD:ranks(playerid)
{
	new str[700];
	strcat(str, "Rank\tRank Name\tScore\n");
	for(new i; i < sizeof gRank; i++)
	{
		if(pRank{playerid} > i) strcat(str, COL_GREEN);
		else if(pRank{playerid} == i) strcat(str, COL_CYAN);
		else strcat(str, COL_RED);
		format(str, sizeof str, "%s%i\t%s\t%d\n", str, i + 1, gRank[i][RankName], gRank[i][RankScore]);
	}
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "FD :: Ranks", str, "Okay", "");
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	if(pClass{forplayerid} == CLASS_SCOUT && pClass{playerid} == CLASS_MARKSMAN)
	{
		SetPlayerMarkerForPlayer(forplayerid, playerid, SetAlpha(gTeam[pTeam{playerid}][TeamColor], 50));
	}
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	if(pClass{forplayerid} == CLASS_SCOUT && pClass{playerid} == CLASS_MARKSMAN)
	{
		SetPlayerMarkerForPlayer(forplayerid, playerid, SetAlpha(gTeam[pTeam{playerid}][TeamColor], 0));
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	UpdateSpec(playerid);
	
	if (newstate == PLAYER_STATE_DRIVER)
	{
		switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
		{
			case 432:
			{
				if(pClass{playerid} != CLASS_ENGINEER && pClass{playerid} != CLASS_DONOR && !pAdmDuty{playerid})
				{
					EjectPlayer(playerid);
					SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You need to be Engineer to Donor to drive Rhino.");
					return 1;
				}
			}
			case 520, 425:
			{
				if(pClass{playerid} != CLASS_PILOT && pClass{playerid} != CLASS_DONOR && !pAdmDuty{playerid})
				{
					EjectPlayer(playerid);
					SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You need to be Pilot or Donor to pilot Hydra or Hunter.");
					return 1;
				}
				SendClientMessage(playerid, COLOR_GREY, "* Press to '"COL_CYAN"Y"COL_GREY"' eject yourself.");
			}
			case 447:
			{
				if(pClass{playerid} != CLASS_DONOR && pClass{playerid} != CLASS_PILOT && !pAdmDuty{playerid})
				{
					EjectPlayer(playerid);
					SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"You need to be Donor or Pilot to pilot Sea-Sparrow.");
					return 1;
				}
				SendClientMessage(playerid, COLOR_GREY, "* Press to '"COL_CYAN"Y"COL_GREY"' eject yourself.");
			}
			case 460, 476, 487, 488, 497, 511, 512, 513, 519, 548, 469, 553, 563, 577, 592, 593: SendClientMessage(playerid, COLOR_GREY, "* Press to '"COL_CYAN"Y"COL_GREY"' eject yourself.");
		}
	}
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	switch(vehicleid)
	{
		case 520, 425, 447: SetVehicleHealth(vehicleid, 550.0);
		case 432, 528, 427: SetVehicleHealth(vehicleid, 1500.0);
	}
	return 1;
}

CMD:bonus(playerid)
{
	new str[200], small[5];
	if(gBonusZone[BonusID] == MAX_ZONES)
	{
		strcat(str, "No Bonus zone is selected.\n");
	}
	else
	{
		strcat(str, "Zone ");
		strcat(str, gZones[gBonusZone[BonusID]][ZoneName]);
		strcat(str, " has been selected as a bonus zone, capture it to get $");
		valstr(small, gBonusZone[BonusCash]);
		strcat(str, small);
		strcat(str, " cash and ");
		valstr(small, gBonusZone[BonusScore]);
		strcat(str, small);
		strcat(str, " score.\n");
	}
	
	if(gBonusPlayer[BonusID] == INVALID_PLAYER_ID)
	{
		strcat(str, "No Bonus player is selected.");
	}
	else
	{
		strcat(str, "Player ");
		strcat(str, pName[gBonusPlayer[BonusID]]);
		strcat(str, " has been selected as a bonus player, kill the player to get $");
		valstr(small, gBonusPlayer[BonusCash]);
		strcat(str, small);
		strcat(str, " cash and ");
		valstr(small, gBonusPlayer[BonusScore]);
		strcat(str, small);
		strcat(str, " score.");
	}
	
	Dialog_Show(playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "FD :: Bonus Information", str, "Okay", "");
	return 1;
}

function BonusZone()
{
	if(Iter_Count(Player) < 5) return 1;
	
	new str[100];
	if(gBonusZone[BonusID] == MAX_ZONES)
	{
		new ID = GetBonusZoneID();
		gBonusZone[BonusID] = ID;
		gBonusZone[BonusCash] = random(15000 - 5500) + 5501;
		gBonusZone[BonusScore] = random(13 - 5) + 6;
		format(str, sizeof str, "~p~~h~%s is selected as a bonus zone, capture it and get $%d & %d score.", gZones[ID][ZoneName], gBonusZone[BonusCash], gBonusZone[BonusScore]);
		SendBoxMessage(str);
	}
	else
	{
		format(str, sizeof str, "~p~~h~No one captured the bonus zone ~w~%s", gZones[gBonusZone[BonusID]][ZoneName]);
		SendBoxMessage(str);
		SendBoxMessage("~p~~h~New capture zone being selected in 10 minutes...");
		gBonusZone[BonusPrv] = gBonusZone[BonusID];
		gBonusZone[BonusID] = MAX_ZONES;
	}

	gBonusZone[BonusTime] = SetTimer("BonusZone", 600000, false);
	return 1;
}

function BonusPlayer()
{
	if(Iter_Count(Player) < 5) return 1;
	
	new str[100];
	if(gBonusPlayer[BonusID] == INVALID_PLAYER_ID)
	{
		new ID = GetBonusPlayerID();
		gBonusPlayer[BonusID] = ID;
		gBonusPlayer[BonusScore] = random(10 - 3) + 4;
		gBonusPlayer[BonusCash] = random(8000 - 2000) + 2001;
		format(str, sizeof str, "~p~~h~%s is selected as a bonus player, kill the player and get $%d & %d score.", pName[gBonusPlayer[BonusID]], gBonusPlayer[BonusCash], gBonusPlayer[BonusScore]);
		SendBoxMessage(str);
	}
	else
	{
		format(str, sizeof str, "~p~~h~No one killed bonus player ~w~%s", pName[gBonusPlayer[BonusID]]);
		SendBoxMessage(str);
		SendBoxMessage("~p~~h~New bonus player being selected in 10 minutes...");
		gBonusPlayer[BonusPrv] = gBonusPlayer[BonusID];
		gBonusPlayer[BonusID] = INVALID_PLAYER_ID;
	}

	gBonusPlayer[BonusTime] = SetTimer("BonusPlayer", 60000, false);
	return 1;
}

public OnPlayerEnterDynamicArea(playerid, areaid)
{
	if(pClass{playerid} == CLASS_AIRTROOPER)
	{
		for(new i; i < sizeof gTeam; i++)
		{
			if(pTeam{playerid} != i && gTeam[i][TeamBaseArea] == areaid)
			{
				SetPlayerColor(playerid, SetAlpha(gTeam[pTeam{playerid}][TeamColor], 0));
				GameTextForPlayer(playerid, "~n~~n~~w~YOU ARE NOW INVISIBLE!", 3000, 3);

				break;
			}
		}
	}
	return 1;
}

public OnPlayerLeaveDynamicArea(playerid, areaid)
{
	if(pClass{playerid} == CLASS_AIRTROOPER)
	{
		for(new i; i < sizeof gTeam; i++)
		{
			if(pTeam{playerid} != i && gTeam[i][TeamBaseArea] == areaid)
			{
				SetPlayerColor(playerid, SetAlpha(gTeam[pTeam{playerid}][TeamColor], 100));
				GameTextForPlayer(playerid, "~n~~n~~w~YOU ARE NO MORE INVISIBLE!", 3000, 3);

				break;
			}
		}
	}
	return 1;
}

public OnPlayerPauseStateChange(playerid, pausestate)
{
	if(pausestate)
	{
		pPauseTimer[playerid] = SetTimerEx("PauseTimer", 1000, true, "i", playerid);
	}
	else
	{
		KillTimer(pPauseTimer[playerid]);

		if(!GetPlayerPausedTime(playerid)) return 1;
		new str[35];
		format(str, sizeof str, "* You were AFK for %d seconds.", GetPlayerPausedTime(playerid));
		SendClientMessage(playerid, COLOR_GREY, str);
	}
	return 1;
}

function PauseTimer(playerid)
{
	new str[17];
	format(str, sizeof str, "AFK (%d seconds)", GetPlayerPausedTime(playerid) / 1000);
	SetPlayerChatBubble(playerid, str, COLOR_RED, 5.0, 900);
	return 1;
}

GivePlayerHelmet(playerid)
{
	if(IsValidDynamicObject(pHelmetObj[playerid])) DestroyDynamicObject(pHelmetObj[playerid]);

	pHelmetObj[playerid] = CreateDynamicObject(1916, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .playerid = playerid);
	AttachDynamicObjectToPlayer(pHelmetObj[playerid], playerid, 0.128000, 0.049999, 0.006000, 0.0, 0.0, 0.0);
	pHelmet[playerid] = 1;
	return 1;
}

GivePlayerGasMask(playerid)
{
	pGasObj[playerid] = CreateDynamicObject(19472, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .playerid = playerid);
	AttachDynamicObjectToPlayer(pGasObj[playerid], playerid, -0.022, 0.137, 0.1, 3.9, 86.0, 93.0);
	pGas{playerid} = 1;
	return 1;
}

RemovePlayerHelmet(playerid)
{
	if(IsValidDynamicObject(pHelmetObj[playerid])) DestroyDynamicObject(pHelmetObj[playerid]);
	
	pHelmetObj[playerid] = INVALID_OBJECT_ID;
	pHelmet{playerid} = 0;
	return 1;
}

RemovePlayerGasMask(playerid)
{
	if(IsValidDynamicObject(pGasObj[playerid])) DestroyDynamicObject(pGasObj[playerid]);
	
	pGasObj[playerid] = INVALID_OBJECT_ID;
	pGas{playerid} = 0;
	return 1;
}

AddHelp(playerid, info[])
{
	new id = Iter_Free(Helps);
	
	if(id == -1) return SendClientMessage(playerid, COLOR_RED, "ERROR: "COL_GREY"An error occurred while sending the help request...");

	hInfo[id][HelpOpen] = 0;
	hInfo[id][HelpBy] = playerid;
	format(hInfo[id][HelpInfo], MAX_HELP_LENGTH, info);
	hInfo[id][HelpTime] = gettime();
	SendClientMessage(playerid, COLOR_YELLOW, "* Your help request has been sent to admins.");
	SendAdminMessage("* A player has sent a help request!");
	Iter_Add(Helps, id);
	return 1;
}

RemoveHelp(id)
{
	if(!Iter_Contains(Helps, id)) return 0;

	Iter_Remove(Helps, id);

	hInfo[id][HelpOpen] = hInfo[id][HelpTime] = 0;
	hInfo[id][HelpBy] = INVALID_PLAYER_ID;
	hInfo[id][HelpInfo][0] = EOS;
	return 1;
}

GivePlayerScore(playerid, score)
{
	SetPlayerScore(playerid, GetPlayerScore(playerid) + score);
}

SendTeamMessage(teamid, str[])
{
	foreach(new i : Player)
	{
		if(pTeam{i} == teamid && !pAdmDuty{i})
		{
			SendClientMessage(i, gTeam[teamid][TeamColor], str);
		}
	}
	return 1;
}

GiveTeamScore(teamid, score)
{
	foreach(new i : Player)
	{
		if(pTeam{i} == teamid && !pAdmDuty{i})
		{
			GivePlayerScore(i, score);
		}
	}
	return 1;
}

AntiDeAMX()
{
	new protect[][] =
	{
		"Protection",
		"Anti De AMX"
	};
	#pragma unused protect
}

SpawnPlayerVehicle(playerid, model)
{
	new Float: x, Float: y, Float: z, Float: ang;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, ang);
	
	if(pInfo[playerid][Car] != -1) DestroyPlayerVehicle(pInfo[playerid][Car]);
	new vehicleid = CreateVehicle(model, x, y, z, ang, -1, -1, -1);
	PutPlayerInVehicle(playerid, vehicleid, 0);
	pInfo[playerid][Car] = vehicleid;
	return 1;
}

DestroyPlayerVehicle(vehicleid)
{
	new Float: x, Float: y, Float: z;
	foreach(new i : Player)
	{
		if(pInfo[i][Car] == vehicleid) pInfo[i][Car] = -1;
		if(IsPlayerInVehicle(i, vehicleid))
		{
			//RemovePlayerFromVehicle(i);
			GetPlayerPos(i, x, y, z);
			SetPlayerPos(i, x, y, z + 1);
		}
	}
	
	DestroyVehicle(vehicleid);
}

EjectPlayer(playerid)
{
	new Float: X, Float: Y, Float: Z;
	GetPlayerPos(playerid, X, Y, Z);
	SetPlayerPos(playerid, X, Y, Z + 2.0);
	return 1;
}

IsEnemyNearBy(playerid)
{
	new Float: PosX, Float: PosY, Float: PosZ;
	GetPlayerPos(playerid, PosX, PosY, PosZ);
	foreach(new i : Player) if(pSpec[playerid][Spec] && IsPlayerInRangeOfPoint(i, 8.0, PosX, PosY, PosZ) && pTeam{playerid} != pTeam{i}) return 1;
	return 0;
}

forward InitializeConfig();
public InitializeConfig()
{
	if(cache_num_rows())
	{
		cache_get_value_name_int(0, "ReadPM", sInfo[ReadPM]);
		cache_get_value_name_int(0, "ChatDisabled", sInfo[ChatDisabled]);
		cache_get_value_name_int(0, "MaxPing", sInfo[MaxPing]);
		cache_get_value_name_int(0, "Time", sInfo[Time]);
		cache_get_value_name_int(0, "Weather", sInfo[Weather]);
		cache_get_value_name_int(0, "Players", sInfo[Players]);

		SetWeather(sInfo[Weather]);
		SetWorldTime(sInfo[Time]);
	}
	else
	{
		mysql_pquery(gSQL, "INSERT INTO "#TABLE_SETTINGS" (`ReadPM`, `ChatDisabled`, `MaxPing`, `Time`, `Weather`, `Players`) VALUES('1', '0', '900', '7', '1', '0')");
	}
	return 1;
}

SaveConfig()
{
	new query[160];

	mysql_format(gSQL, query, sizeof query, "UPDATE "#TABLE_SETTINGS" SET `ReadPM` = '%d', `ChatDisabled` = '%d', `MaxPing` = '%d', `Time` = '%d', `Weather` = '%d', `Players` = '%d' WHERE 1",
		sInfo[ReadPM],
		sInfo[ChatDisabled],
		sInfo[MaxPing],
		sInfo[Time],
		sInfo[Weather],
		sInfo[Players]
	);
	mysql_pquery(gSQL, query);
	return 1;
}

GetBonusZoneID()
{
	new i = random(MAX_ZONES - 1);
	return (gBonusZone[BonusPrv] == i) ? GetBonusZoneID() : i;
}

GetBonusPlayerID()
{
	new i = Iter_Random(Player);
	return (gBonusPlayer[BonusPrv] == i) ? GetBonusPlayerID() : i;
}

/*FixTdBracket(playerid)
{
	new Fixed[25];
	strmid(Fixed, str_replace(']', ')', pName[playerid]), 0, MAX_NICK_LENGTH + 1);
	strmid(Fixed, str_replace('[', '(', Fixed), 0, MAX_NICK_LENGTH + 1);
	return Fixed;
}

str_replace(sSearch, sReplace, const sSubject[], &iCount = 0)
{
	new sReturn[128];
	format(sReturn, sizeof sReturn, sSubject);
	for(new i = 0; i < sizeof sReturn; i++) if(sReturn[i] == sSearch) sReturn[i] = sReplace;
	return sReturn;
}*/

CapStreak(playerid)
{
	CPSpree[playerid] += 1;
	new val = -1;
	for(new i; i < sizeof gCPSpree; i++)
	{
		if(gCPSpree[i][Spree] == CPSpree[playerid])
		{
			val = i;
			break;
		}
	}

	if(val != -1)
	{
		new str[70];
		format(str, sizeof str, "%s is on a capturing spree of %d captures.", pName[playerid], CPSpree[playerid]);
		SendBoxMessage(str);

		GivePlayerScore(playerid, gCPSpree[val][Score]);
		pInfo[playerid][Cash] += gCPSpree[val][Cash];

		format(str, sizeof str, "* You got %d score and $%d for being on capturing spree of %d.", gCPSpree[val][Score], gCPSpree[val][Cash], CPSpree[playerid]);
		SendClientMessage(playerid, COLOR_CYAN, str);
	}
	return 1;
}

KillStreak(playerid)
{
	KillSpree[playerid] += 1;
	new val = -1;
	for(new i; i < sizeof gKillSpree; i++)
	{
		if(gKillSpree[i][Spree] == KillSpree[playerid])
		{
			val = i;
			break;
		}
	}

	if(val != -1)
	{
		new str[140];
		format(str, sizeof str, "%s is on a killing spree of %d kills.", pName[playerid], KillSpree[playerid]);
		SendBoxMessage(str);

		GivePlayerScore(playerid, gKillSpree[val][Score]);
		pInfo[playerid][Cash] += gKillSpree[val][Cash];

		format(str, sizeof str, "* You got %d score and $%d for being on killing spree of %d.", (KillSpree[playerid] <= 50) ? (KillSpree[playerid]) : (KillSpree[playerid] / 2), KillSpree[playerid] * 100, KillSpree[playerid]);
		SendClientMessage(playerid, COLOR_CYAN, str);
	}
	return 1;
}

UpdateSpec(playerid)
{
	foreach(new i : Player)
	{
		if(pSpec[i][Spec] && pSpec[i][SpecID] == playerid)
		{
			if(IsPlayerInAnyVehicle(playerid)) PlayerSpectateVehicle(i, GetPlayerVehicleID(playerid));
			else PlayerSpectatePlayer(i, playerid);
		}
	}
}
