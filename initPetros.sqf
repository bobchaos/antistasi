removeHeadgear petros;
removeGoggles petros;
petros setSkill 1;
petros setVariable ["inconsciente",false,true];
petros setVariable ["respawning",false];

//[] remoteExec ["petrosAnimation", 2];
[] remoteExec ["AS_fnc_rearmPetros", 2];

petros addEventHandler ["HandleDamage",
        {
        private ["_unit","_part","_dam","_injurer"];
        _part = _this select 1;
        _dam = _this select 2;
        _injurer = _this select 3;

        if (isPlayer _injurer) then
            {
            [_injurer,60] remoteExec ["AS_fnc_punishPlayer", _injurer];
            _dam = 0;
            };
        if ((isNull _injurer) or (_injurer == petros)) then {_dam = 0};
        if (_part == "") then
            {
            if (_dam > 0.95) then
                {
                if (!(petros getVariable "inconsciente")) then
                    {
                    _dam = 0.9;
                    [petros] spawn inconsciente;
                    }
                else
                    {
                    petros removeAllEventHandlers "HandleDamage";
                    };
                };
            };
        _dam
        }];

petros addMPEventHandler ["mpkilled",
    {
    removeAllActions petros;
    _killer = _this select 1;
    if (isServer) then
        {
            diag_log format ["MAINTENANCE: Petros died. Killer: %1; type: %2", _killer, typeOf _killer];
        if ((side _killer == side_red) or (side _killer == side_green)) then
             {
            [] spawn
                {
                garrison setVariable ["FIA_HQ",[],true];
                for "_i" from 0 to round random 3 do {
                    if (count unlockedWeapons > 4) then {
                        _cosa = selectRandom unlockedWeapons;
                        diag_log format ["weapon: %1", _cosa];
                        unlockedWeapons = unlockedWeapons - [_cosa];
                        lockedWeapons = lockedWeapons + [_cosa];
                        if (_cosa in unlockedRifles) then {unlockedRifles = unlockedRifles - [_cosa]};
                        _mag = (getArray (configFile / "CfgWeapons" / _cosa / "magazines") select 0);
                        if (!isNil "_mag") then {unlockedMagazines = unlockedMagazines - [_mag]; diag_log format ["weapon/mag: %1", _mag];};
                    };
                 };
                publicVariable "unlockedWeapons";

                for "_i" from 0 to round random 8 do {
                    _cosa = selectRandom unlockedMagazines;
                    if !(isNil "_cosa") then {
                        diag_log format ["mag: %1", _cosa];
                        unlockedMagazines = unlockedMagazines - [_cosa];
                    };
                };
                publicVariable "unlockedMagazines";

                for "_i" from 0 to round random 5 do {
                    _cosa = selectRandom (unlockedItems - ["ItemMap","ItemWatch","ItemCompass","FirstAidKit","Medikit","ToolKit","ItemRadio"] - aceItems - aceAdvMedItems);
                    diag_log format ["item: %1", _cosa];
                    unlockedItems = unlockedItems - [_cosa];
                    if (_cosa in unlockedOptics) then {unlockedOptics = unlockedOptics - [_cosa]; publicVariable "unlockedOptics"};
                };
                publicVariable "unlockedItems";

                clearMagazineCargoGlobal caja;
                clearWeaponCargoGlobal caja;
                clearItemCargoGlobal caja;
                clearBackpackCargoGlobal caja;

                [] remoteExec ["AS_fnc_MAINT_arsenal", 2];

                waitUntil {sleep 6; isPlayer Slowhand};
                [] remoteExec ["placementSelection",Slowhand];
               };
            }
        else
            {
            _viejo = petros;
            grupoPetros = createGroup side_blue;
            publicVariable "grupoPetros";
            petros = grupoPetros createUnit [guer_sol_OFF, position _viejo, [], 0, "NONE"];
            grupoPetros setGroupId ["Petros","GroupColor4"];
            petros setIdentity "amiguete";
            petros setName "Petros";
            //petros disableAI "MOVE";
            //petros disableAI "AUTOTARGET";
            petros forceSpeed 0;
            if (group _viejo == grupoPetros) then {[[Petros,"mission"],"AS_fnc_addActionMP"] call BIS_fnc_MP;} else {[[Petros,"buildHQ"],"AS_fnc_addActionMP"] call BIS_fnc_MP;};
             call compile preprocessFileLineNumbers "initPetros.sqf";
            deleteVehicle _viejo;
            publicVariable "petros";
            };
        };
   }];
