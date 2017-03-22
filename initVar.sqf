//Antistasi var settings
//If some setting can be modified it will be commented with a // after it.
//Make changes at your own risk!!
//You do not have enough balls to make any modification and after making a Bug report because something is wrong. You don't wanna be there. Believe me.
//Not commented lines cannot be changed.
//Don't touch them.
antistasiVersion = "v 1.7 -- modded";

servidoresOficiales = ["Antistasi Official EU","Antistasi Official EU - TEST", "Antistasi:Altis Official", "Antistasi:Altis Official 1.7 Test"];//this is for author's fine tune the official servers. If I get you including your server in this variable, I will create a special variable for your server. Understand?

debug = false;//debug variable, not useful for everything..

cleantime = 900;//time to delete dead bodies, vehicles etc..
distanciaSPWN = 1200;//initial spawn distance. Less than 1Km makes parked vehicles spawn in your nose while you approach.
musicON = true;
civPerc = 0.1;//initial % civ spawn rate
//minefieldMrk = [];
minimoFPS = 15;//initial FPS minimum.
//destroyedCities = [];
autoHeal = false;
allowPlayerRecruit = true;
recruitCooldown = 0;
AAFpatrols = 0;//0
planesAAFcurrent = 0;
helisAAFcurrent = 0;
APCAAFcurrent = 0;
tanksAAFcurrent= 0;
savingClient = false;
incomeRep = false;
closeMarkersUpdating = 0;
altVersion = "";
enableRestart = true;

//All weapons, MOD ones included, will be added to this arrays, but it's useless without integration, as if those weapons don't spawn, players won't be able to collect them, and after, unlock them in the arsenal.
allMagazines = [];
_cfgmagazines = configFile >> "cfgmagazines";
for "_i" from 0 to (count _cfgMagazines) -1 do
	{
	_magazine = _cfgMagazines select _i;
	if (isClass _magazine) then
		{
		_nombre = configName (_magazine);
		allMagazines pushBack _nombre;
		};
	};

arifles = [];
srifles = [];
mguns = [];
hguns = [];
mlaunchers = [];
rlaunchers = [];
AS_allWeapons = [];
AS_allMagazines = [];

hayRHS = false;
hayUSAF = false;
hayGREF = false;
hayACE = false;

replaceFIA = false;
AS_customGroups = false;

lockedWeapons = ["Laserdesignator"];

_allPrimaryWeapons = "
    ( getNumber ( _x >> ""scope"" ) isEqualTo 2
    &&
    { getText ( _x >> ""simulation"" ) isEqualTo ""Weapon""
    &&
    { getNumber ( _x >> ""type"" ) isEqualTo 1 } } )
" configClasses ( configFile >> "cfgWeapons" );

_allHandGuns = "
    ( getNumber ( _x >> ""scope"" ) isEqualTo 2
    &&
    { getText ( _x >> ""simulation"" ) isEqualTo ""Weapon""
    &&
    { getNumber ( _x >> ""type"" ) isEqualTo 2 } } )
" configClasses ( configFile >> "cfgWeapons" );

_allLaunchers = "
    ( getNumber ( _x >> ""scope"" ) isEqualTo 2
    &&
    { getText ( _x >> ""simulation"" ) isEqualTo ""Weapon""
    &&
    { getNumber ( _x >> ""type"" ) isEqualTo 4 } } )
" configClasses ( configFile >> "cfgWeapons" );

allAccessories = [];
_allAccessories = "
    ( getNumber ( _x >> ""scope"" ) isEqualTo 2
    &&
    { getText ( _x >> ""simulation"" ) isEqualTo ""Weapon""
    &&
    { getNumber ( _x >> ""type"" ) isEqualTo 131072 } } )
" configClasses ( configFile >> "cfgWeapons" );

{
_nombre = configName _x;
_tipo = [_nombre] call BIS_fnc_itemType;
_tipo = _tipo select 1;
if ((_tipo == "AccessoryMuzzle") || (_tipo == "AccessoryPointer") || (_tipo == "AccessorySights")) then {
	allAccessories pushBackUnique _nombre;
};
} forEach _allAccessories;

primaryMagazines = [];
{
_nombre = configName _x;
_nombre = [_nombre] call BIS_fnc_baseWeapon;
if (not(_nombre in lockedWeapons)) then
	{
	_magazines = getArray (configFile / "CfgWeapons" / _nombre / "magazines");
	primaryMagazines pushBackUnique (_magazines select 0);
	lockedWeapons pushBackUnique _nombre;
	AS_allWeapons pushBackUnique _nombre;
	_weapon = [_nombre] call BIS_fnc_itemType;
	_weaponType = _weapon select 1;
	switch (_weaponType) do
		{
		case "AssaultRifle": {arifles pushBack _nombre};
		case "MachineGun": {mguns pushBack _nombre};
		case "SniperRifle": {srifles pushBack _nombre};
		case "Handgun": {hguns pushBack _nombre};
		case "MissileLauncher": {mlaunchers pushBack _nombre};
		case "RocketLauncher": {rlaunchers pushBack _nombre};
		};

	};
} forEach _allPrimaryWeapons + _allHandGuns + _allLaunchers;

AS_allWeapons pushBackUnique "Rangefinder";
AS_allWeapons pushBackUnique "Binocular";
AS_allWeapons pushBackUnique "Laserdesignator";
AS_allWeapons pushBackUnique "Laserdesignator_02";
AS_allWeapons pushBackUnique "Laserdesignator_03";

//rhs detection and integration

if ("rhs_weap_akms" in lockedWeapons) then {
	hayRHS = true;
};
if ("rhs_weap_m4a1_d" in lockedWeapons) then {
	hayUSAF = true;
};
if ("rhs_weap_m92" in AS_allWeapons) then {
	hayGREF = true;
};

if (!isNil "ace_common_settingFeedbackIcons") then {
	hayACE = true;
};

if ((side petros) == independent) then {
	replaceFIA = true;
	altVersion = "GREEN";
};

if (isClass (configFile >> "CfgPatches" >> "javelinTest")) then {
	AS_customGroups = true;
};

missionPath = [(str missionConfigFile), 0, -15] call BIS_fnc_trimString;

//------------------ unit module ------------------//


// all statics, used to calculate defensive strength when spawning attacks -- templates add OPFOR statics
allStatMGs = 		["B_HMG_01_high_F"];
allStatATs = 		["B_static_AT_F"];
allStatAAs = 		["B_static_AA_F"];
allStatMortars = 	["B_G_Mortar_01_F"];

side_blue = west; // <<<<<< player side, always, at all times, no exceptions
side_green = independent;
side_red = east;

lrRadio = "";

vfs = [];

// Initialisation of units and gear
vehFIA = [];

call {
	if (worldName == "Altis") exitWith {
		call compile preprocessFileLineNumbers "Templates\CIV_ALTIS.sqf";
	};

	if (worldName == "Tanoa") exitWith {
		call compile preprocessFileLineNumbers "Templates\CIV_TANOA.sqf";
	};

	call compile preprocessFileLineNumbers "Templates\CIV_ALTIS.sqf"; // default
};

call {

	if (replaceFIA) exitWith {
		if (hayGREF) then {
			call compile preprocessFileLineNumbers "Templates\PLAYER_GREF.sqf";
		} else {
			call compile preprocessFileLineNumbers "Templates\PLAYER_IND_FIA.sqf";
		};

		if (hayUSAF) then {
			call compile preprocessFileLineNumbers "Templates\IND_USAF.sqf";
			call compile preprocessFileLineNumbers "Templates\RED_USMC.sqf";
		} else {
			call compile preprocessFileLineNumbers "Templates\IND_NATO.sqf";
			call compile preprocessFileLineNumbers "Templates\RED_NATO_SF.sqf";
		};

		if (hayRHS) then {
			call compile preprocessFileLineNumbers "Templates\BLUE_VMF.sqf";
		} else {
			call compile preprocessFileLineNumbers "Templates\BLUE_CSAT.sqf";
		};
	};

	/*if (replaceFIA) exitWith {
		call compile preprocessFileLineNumbers "Templates\PLAYER_GREF.sqf";
		call compile preprocessFileLineNumbers "Templates\IND_USAF.sqf";
		call compile preprocessFileLineNumbers "Templates\RED_USMC.sqf";
		call compile preprocessFileLineNumbers "Templates\BLUE_VMF.sqf";
	};*/

	call compile preprocessFileLineNumbers "Templates\PLAYER_FIA.sqf";

	if (hayRHS) then {
		call compile preprocessFileLineNumbers "Templates\IND_AFRF.sqf";
		call compile preprocessFileLineNumbers "Templates\RED_VMF.sqf";
	} else {
		call compile preprocessFileLineNumbers "Templates\IND_AAF.sqf";
		call compile preprocessFileLineNumbers "Templates\RED_CSAT.sqf";
	};

	if (hayUSAF) then {
		call compile preprocessFileLineNumbers "Templates\BLUE_USAF.sqf";
	} else {
		call compile preprocessFileLineNumbers "Templates\BLUE_NATO.sqf";
	};
};

AS_allWeapons pushBackUnique indRF;
[genWeapons, "genAmmo"] call AS_fnc_MAINT_missingAmmo;

posHQ = getMarkerPos guer_respawn;

// deprecated variables, used to maintain compatibility
call compile preprocessFileLineNumbers "Lists\basicLists.sqf";
vehAAFAT = enemyMotorpool;
planesAAF = indAirForce;
soldadosAAF = infList_sniper + infList_NCO + infList_special + infList_auto + infList_regular + infList_crew + infList_pilots;
//------------------ /unit module ------------------//

#include "Compositions\spawnPositions.sqf"
#include "Scripts\SHK_Fastrope.sqf"

if (!isServer and hasInterface) exitWith {};

AAFpatrols = 0;//0
skillAAF = 0;
smallCAmrk = [];
smallCApos = [];
reducedGarrisons = [];

// camps
campsFIA = [];
campList = [];
campNames = ["Camp Spaulding","Camp Wagstaff","Camp Firefly","Camp Loophole","Camp Quale","Camp Driftwood","Camp Flywheel","Camp Grunion","Camp Kornblow","Camp Chicolini","Camp Pinky",
			"Camp Fieramosca","Camp Bulldozer","Camp Bambino","Camp Pedersoli"];
usedCN = [];
cName = "";
cList = false;

// roadblocks and watchposts
FIA_RB_list = [];
FIA_WP_list = [];

expCrate = ""; // Devin's crate

if (!isServer) exitWith {};

server setVariable ["milActive", 0, true];
server setVariable ["civActive", 0, true];
server setVariable ["expActive", false, true];
server setVariable ["blockCSAT", false, true];
server setVariable ["jTime", 0, true];

server setVariable ["lockTransfer", false, true];

server setVariable ["genLMGlocked",true,true];
server setVariable ["genGLlocked",true,true];
server setVariable ["genSNPRlocked",true,true];
server setVariable ["genATlocked",true,true];
server setVariable ["genAAlocked",true,true];

//Pricing values for soldiers, vehicles
{server setVariable [_x,50,true]} forEach [guer_sol_RFL,guer_sol_R_L,guer_sol_UN];
{server setVariable [_x,100,true]} forEach [guer_sol_AR,guer_sol_MED,guer_sol_ENG,guer_sol_EXP,guer_sol_GL,guer_sol_TL,guer_sol_AM];
{server setVariable [_x,150,true]} forEach [guer_sol_MRK,guer_sol_LAT,guer_sol_SL,guer_sol_OFF,guer_sol_SN,guer_sol_AA];
{server setVariable [_x,100,true]} forEach infList_regular;
{server setVariable [_x,150,true]} forEach infList_auto;
{server setVariable [_x,150,true]} forEach infList_crew;
{server setVariable [_x,150,true]} forEach infList_pilots;
{server setVariable [_x,200,true]} forEach infList_special;
{server setVariable [_x,200,true]} forEach infList_NCO;
{server setVariable [_x,200,true]} forEach infList_sniper;

server setVariable ["C_Offroad_01_F",300,true];//200
server setVariable ["C_Van_01_transport_F",600,true];//600
server setVariable ["C_Heli_Light_01_civil_F",12000,true];//12000
server setVariable [guer_veh_quad,50,true];//50
server setVariable [guer_veh_offroad,200,true];//200
server setVariable [guer_veh_truck,450,true];//300
server setVariable [guer_veh_technical,700,true];//700
{server setVariable [_x,400,true]} forEach [guer_stat_MGH,"B_G_Boat_Transport_01_F",guer_veh_engineer];//400
{server setVariable [_x,800,true]} forEach [guer_stat_mortar,guer_stat_AT,guer_stat_AA];//800

server setVariable [vfs select 0,300,true];
server setVariable [vfs select 1,600,true];//600
server setVariable [vfs select 2,6000,true];//12000
server setVariable [vfs select 3,50,true];//50
server setVariable [vfs select 4,200,true];//200
server setVariable [vfs select 5,450,true];//300
server setVariable [vfs select 6,700,true];//700
server setVariable [vfs select 7,400,true];//700
server setVariable [vfs select 8,800,true];
server setVariable [vfs select 9,800,true];
server setVariable [vfs select 10,800,true];

if (hayRHS) then {
	server setVariable [vfs select 2,6000,true];
	server setVariable [vfs select 11,5000,true];
	server setVariable [vfs select 12,600,true];
	server setVariable [vehTruckAA, 800, true];
};

server setVariable ["hr",8,true];//initial HR value
server setVariable ["resourcesFIA",1000,true];//Initial FIA money pool value
server setVariable ["resourcesAAF",0,true];//Initial AAF resources
server setVariable ["skillFIA",0,true];//Initial skill level for FIA soldiers
server setVariable ["prestigeNATO",5,true];//Initial Prestige NATO
server setVariable ["prestigeCSAT",5,true];//Initial Prestige CSAT

server setVariable ["enableFTold",false,true]; // extended fast travel mode
server setVariable ["enableMemAcc",false,true]; // simplified arsenal access
server setVariable ["enableWpnProf",false,true]; // class-based weapon proficiences, MP only

server setVariable ["easyMode",false,true]; // higher income
server setVariable ["hardMode",false,true];
server setVariable ["testMode",false,true];

staticsToSave = []; publicVariable "staticsToSave";
prestigeOPFOR = 50;//Initial % support for AAF on each city
if (not cadetMode) then {prestigeOPFOR = 75};//if you play on vet, this is the number
prestigeBLUFOR = 0;//Initial % FIA support on each city
planesAAFmax = 0;
helisAAFmax = 0;
APCAAFmax = 0;
tanksAAFmax = 0;
cuentaCA = 600;//600
lastIncome = 0;
prestigeIsChanging = false;
cityIsSupportChanging = false;
resourcesIsChanging = false;
savingServer = false;
misiones = [];
revelar = false;

vehInGarage = ["C_Van_01_transport_F","C_Offroad_01_F","C_Offroad_01_F",guer_veh_quad,guer_veh_quad,guer_veh_quad]; // initial motorpool
destroyedBuildings = []; publicVariable "destroyedBuildings";
reportedVehs = [];
hayXLA = false;
hayTFAR = false;
hayACEhearing = false;
hayACEMedical = false;
//TFAR detection and config.
if (isClass (configFile >> "CfgPatches" >> "task_force_radio")) then
    {
    hayTFAR = true;
    unlockedItems pushBackUnique "ItemRadio";//making this items Arsenal available.
	unlockedItems pushBackUnique ([AS_radio_tfar_B, AS_radio_tfar_G] select replaceFIA);
    tf_no_auto_long_range_radio = true; publicVariable "tf_no_auto_long_range_radio";//set to false and players will start with LR radio, uncomment the last line of so.
	//tf_give_personal_radio_to_regular_soldier = false;
	tf_west_radio_code = "";publicVariable "tf_west_radio_code";//to make enemy vehicles usable as LR radio
	tf_east_radio_code = tf_west_radio_code; publicVariable "tf_east_radio_code"; //to make enemy vehicles usable as LR radio
	tf_guer_radio_code = tf_west_radio_code; publicVariable "tf_guer_radio_code";//to make enemy vehicles usable as LR radio
	tf_same_sw_frequencies_for_side = true; publicVariable "tf_same_sw_frequencies_for_side";
	tf_same_lr_frequencies_for_side = true; publicVariable "tf_same_lr_frequencies_for_side";
    //unlockedBackpacks pushBack "tf_rt1523g_sage";//uncomment this if you are adding LR radios for players
    };

//ACE detection and ACE item availability in Arsenal
if (!isNil "ace_common_settingFeedbackIcons") then
	{
	unlockedItems = unlockedItems + ["ACE_EarPlugs","ACE_RangeCard","ACE_Clacker","ACE_M26_Clacker","ACE_DeadManSwitch","ACE_DefusalKit","ACE_MapTools","ACE_Flashlight_MX991","ACE_Sandbag_empty","ACE_wirecutter","ACE_RangeTable_82mm","ACE_SpareBarrel","ACE_EntrenchingTool","ACE_Cellphone","ACE_ConcertinaWireCoil","ACE_CableTie","ACE_SpottingScope","ACE_Tripod","ACE_Chemlight_HiWhite","ACE_Chemlight_HiRed"];
	unlockedBackpacks pushBackUnique "ACE_TacticalLadder_Pack";
	unlockedWeapons pushBackUnique "ACE_VMH3";
	unlockedMagazines = unlockedMagazines + ["ACE_HandFlare_White","ACE_HandFlare_Red"];
	genItems = genItems + ["ACE_Kestrel4500","ACE_ATragMX"];

	hayACE = true;
	if (isClass (configFile >> "CfgSounds" >> "ACE_EarRinging_Weak")) then
		{
		hayACEhearing = true;
		};
	if (isClass (ConfigFile >> "CfgSounds" >> "ACE_heartbeat_fast_3")) then
		{
		if (ace_medical_level != 0) then
			{
			hayACEMedical = true;
			unlockedItems = unlockedItems + ["ACE_fieldDressing","ACE_bloodIV_500","ACE_bloodIV","ACE_epinephrine","ACE_morphine","ACE_bodyBag"];
			};
		};
	};

// texture mod detection
FIA_texturedVehicles = [];
FIA_texturedVehicleConfigs = [];
_allVehicles = configFile >> "CfgVehicles";
for "_i" from 0 to (count _allVehicles - 1) do {
    _vehicle = _allVehicles select _i;
    if (toUpper (configName _vehicle) find "DGC_FIAVEH" >= 0) then {
    	FIA_texturedVehicles pushBackUnique (configName _vehicle);
    	FIA_texturedVehicleConfigs pushBackUnique _vehicle;
    };
};

if !(isnil "XLA_fnc_addVirtualItemCargo") then {
	hayXLA = true;
};
hayBE = false;
#include "Scripts\BE_modul.sqf"
[] call fnc_BE_initialize;
if !(isNil "BE_INIT") then {hayBE = true; publicVariable "hayBE"};

// texture mod detection
FIA_texturedVehicles = [];
FIA_texturedVehicleConfigs = [];
_allVehicles = configFile >> "CfgVehicles";
for "_i" from 0 to (count _allVehicles - 1) do {
    _vehicle = _allVehicles select _i;
    if (toUpper (configName _vehicle) find "DGC_FIAVEH" >= 0) then {
    	FIA_texturedVehicles pushBackUnique (configName _vehicle);
    	FIA_texturedVehicleConfigs pushBackUnique _vehicle;
    };
};

allItems = genItems + genOptics + genVests + genHelmets;

[unlockedWeapons, "unlockedMagazines"] call AS_fnc_MAINT_missingAmmo;

if (worldName == "Altis") then {
	{
		server setVariable [_x select 0,_x select 1]
	} forEach [
		["Therisa",154],["Zaros",371],["Poliakko",136],["Katalaki",95],["Alikampos",115],["Neochori",309],["Stavros",122],["Lakka",173],["AgiosDionysios",84],["Panochori",264],["Topolia",33],["Ekali",9],["Pyrgos",531],["Orino",45],["Neri",242],["Kore",133],["Kavala",660],["Aggelochori",395],["Koroni",32],["Gravia",291],["Anthrakia",143],["Syrta",151],["Negades",120],["Galati",151],["Telos",84],["Charkia",246],["Athira",342],["Dorida",168],["Ifestiona",48],["Chalkeia",214],["AgiosKonstantinos",39],["Abdera",89],["Panagia",91],["Nifi",24],["Rodopoli",212],["Kalithea",36],["Selakano",120],["Frini",69],["AgiosPetros",11],["Feres",92],["AgiaTriada",8],["Paros",396],["Kalochori",189],["Oreokastro",63],["Ioannina",48],["Delfinaki",29],["Sofia",179],["Molos",188]
		];
	call compile preprocessFileLineNumbers "roadsDB.sqf";
};

publicVariable "unlockedWeapons";
publicVariable "unlockedRifles";
publicVariable "unlockedItems";
publicVariable "unlockedOptics";
publicVariable "unlockedBackpacks";
publicVariable "unlockedMagazines";
publicVariable "miembros";
publicVariable "vehInGarage";
publicVariable "reportedVehs";
publicVariable "hayACE";
publicVariable "hayTFAR";
publicVariable "hayXLA";
publicVariable "hayACEhearing";
publicVariable "hayACEMedical";
publicVariable "skillAAF";
publicVariable "misiones";
publicVariable "revelar";
publicVariable "FIA_texturedVehicles";
publicVariable "FIA_texturedVehicleConfigs";
publicVariable "hayBE";
publicVariable "FIA_WP_list";
publicVariable "FIA_RB_list";
publicVariable "reducedGarrisons";

if (isMultiplayer) then {[[petros,"hint","Variables Init Completed"],"commsMP"] call BIS_fnc_MP;};