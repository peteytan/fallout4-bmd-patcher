unit userscript;

//##############//##############
// Created by mephiston1
//
// This script reads all the properties of a specific weapon mod and then based
// on those values, will create a description that follows the format of
// Better Mod Descriptions, giving you actual percentages of the property.
//
// This script is far from finished, and has only been tested to work on grips
// receivers, and barrels on ballistic weapons.
// This DOES NOT work on melee, heavy, or energy weapons.
//
// TODO:
// - This only works on MUL+ADD Function Types. Function Types of SET are not yet
// accounted for and will cause the script to break.
// - Could probably refactor all the code of getting the element value into a
// helper function. Would need a table to map properties to description text.
//##############//##############
function setChecker(e: IInterface;): boolean;
begin
  if GetElementEditValues(e, 'Function Type') = 'MUL+ADD' then begin
    Result := true;
  end
  else begin
    Result := false;
  end;
end;


function Process(e: IInterface;): Integer;
var
  props, prop: IInterface;
  i: integer;
  description, temp: string;
  aValue1: float;
  aValue2: string;
  bMinRange, bMaxRange, bMinSpread, bMaxSpread: boolean;
  minRange, maxRange, minSpread, maxSpread: float;
begin
  bMinRange := false;
  bMaxRange := false;
  bMinSpread := false;
  bMaxSpread := false;

  if Signature(e) <> 'OMOD' then
    Exit;

  // getting Properties array inside DATA subrecord
  props := ElementByPath(e, 'DATA\Properties');
  // iterating over properties, indexed starting from 0
  for i := 0 to Pred(ElementCount(props)) do begin

    // getting Nth property
    prop := ElementByIndex(props, i);

    // compare Property field and skip to the next property if doesn't match
    if GetElementEditValues(prop, 'Property') = 'Keywords' then begin
      if GetElementEditValues(prop, 'Value 1 - FormID') = 'HasSilencer [KYWD:001E05D6]' then begin
        temp := 'Suppressed. ';
        description := description + temp;
      end;
    end;

    if GetElementEditValues(prop, 'Property') = 'ActorValues' then begin
      if GetElementEditValues(prop, 'Value 1 - FormID') = 'ArmorPenetration "Armor Penetration" [AVIF:00097341]' then begin
        aValue1 := GetElementEditValues(prop, 'Value 2 - Float');
        temp := '+' + floattostr(aValue1) + ' Armor Pierce. ';
        description := description + temp;
      end;
    end;

    // Turns out most WeaponMods go off the vanilla magazines, so we'll leave this out for now.
    // if GetElementEditValues(prop, 'Property') = 'Ammo Capacity' and setChecker then begin
    //   aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
    //   aValue1 := aValue1 * 100;
    //   if aValue1 > 0 then begin
    //     temp := '+' + floattostr(aValue1) + '% Ammo Capacity. ';
    //     description := description + temp;
    //   end;
    //   if aValue1 < 0 then begin
    //     temp := floattostr(aValue1) + '% Ammo Capacity. ';
    //     description := description + temp;
    //   end;
    // end;

    if (GetElementEditValues(prop, 'Property') = 'AttackDamage') and setChecker(prop) then begin
      aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
      aValue1 := aValue1 * 100;
      if aValue1 <> 0 then begin
        temp := '+' + floattostr(aValue1) + '% Damage. ';
        description := description + temp;
      end;
    end;

    if (GetElementEditValues(prop, 'Property') = 'CriticalDamageMult') and setChecker(prop) then begin
      aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
      aValue1 := aValue1 * 100;
      if aValue1 <> 0 then begin
        temp := '+' + floattostr(aValue1) + '% Critical Damage. ';
        description := description + temp;
      end;
    end;

    if (GetElementEditValues(prop, 'Property') = 'SecondaryDamage') and setChecker(prop) then begin
      aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
      aValue1 := aValue1 * 100;
      temp := '+' + floattostr(aValue1) + '% Bash Damage. ';
      description := description + temp;
    end;

    if (GetElementEditValues(prop, 'Property') = 'Speed') and setChecker(prop) then begin
      aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
      aValue1 := aValue1 * 100;
      temp := '+' + floattostr(aValue1) + '% Fire Rate. ';
      description := description + temp;
    end;

    if (GetElementEditValues(prop, 'Property') = 'ReloadSpeed') and setChecker(prop) then begin
      aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
      aValue1 := aValue1 * 100;
      if aValue1 > 0 then begin
        temp := '+' + floattostr(aValue1) + '% Reload Time. ';
        description := description + temp;
      end;
      if aValue1 < 0 then begin
        temp := floattostr(aValue1) + '% Reload Time. ';
        description := description + temp;
      end;
      description := description + temp;
    end;

    // We only want range modifiers, not actual hardcoded range changes
    if (GetElementEditValues(prop, 'Property') = 'MinRange') and setChecker(prop) then begin
      bMinRange := true;
      minRange := GetElementEditValues(prop, 'Value 1 - Float');
    end;

    if (GetElementEditValues(prop, 'Property') = 'MaxRange') and setChecker(prop) then begin
      bMaxRange := true;
      maxRange := GetElementEditValues(prop, 'Value 1 - Float');
    end;

    // Check for MinRange and MaxRange properties, and if they are the same
    // If they are, consolidate into one entry, if not write two entries.
    // Ensure this block of code only runs once when both conditions are met.
    if bMinRange and bMaxRange then begin
      bMinRange := false;
      bMaxRange := false;
      if minRange = maxRange then begin
        if minRange > 0.0 then begin
          temp := '+' + floattostr(minRange) + 'x Range. ';
          description := description + temp;
        end
        else begin
          temp := floattostr(minRange) + 'x Range. ';
          description := description + temp;
        end;
      end
      // if range values are different, create the two entries
      else begin
        if minRange > 0.0 then begin
          temp := '+' + floattostr(minRange) + 'x Min Range. ';
          description := description + temp;
        end
        else begin
          temp := floattostr(minRange) + 'x Min Range. ';
          description := description + temp;
        end;
      end;
      if maxRange > 0.0 then begin
        temp := '+' + floattostr(maxRange) + 'x Max Range. ';
        description := description + temp;
      end
      else begin
        temp := floattostr(maxRange) + 'x Max Range. ';
        description := description + temp;
      end;
    end;

    // Handle cases where only one range is modified. Could probably refactor
    // this with above code, but too lazy write now.
    if bMinRange and not bMaxRange then begin
      bMinRange := false;
      if minRange > 0.0 then begin
        temp := '+' + floattostr(minRange) + 'x Min Range. ';
        description := description + temp;
      end
      else begin
        temp := floattostr(minRange) + 'x Min Range. ';
        description := description + temp;
      end;
    end;

    if not bMinRange and bMaxRange then begin
      bMaxRange := false;
      if maxRange > 0.0 then begin
        temp := '+' + floattostr(maxRange) + 'x Max Range. ';
        description := description + temp;
      end
      else begin
        temp := floattostr(maxRange) + 'x Max Range. ';
        description := description + temp;
      end;
    end;

    if (GetElementEditValues(prop, 'Property') = 'SightedTransitionSeconds') and setChecker(prop) then begin
      aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
      aValue1 := aValue1 * 100;
      if aValue1 > 0 then begin
        temp := '+' + floattostr(aValue1) + '% Sight Time. ';
        description := description + temp;
      end;
      if aValue1 < 0 then begin
        temp := floattostr(aValue1) + '% Sight Time. ';
        description := description + temp;
      end;
    end;

    if (GetElementEditValues(prop, 'Property') = 'AttackActionPointCost') and setChecker(prop) then begin
      aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
      aValue1 := aValue1 * 100;
      if aValue1 > 0 then begin
        temp := '+' + floattostr(aValue1) + '% VATS Cost. ';
        description := description + temp;
      end;
      if aValue1 < 0 then begin
        temp := floattostr(aValue1) + '% VATS Cost. ';
        description := description + temp;
      end;
    end;


    if (GetElementEditValues(prop, 'Property') = 'AimModelMinConeDegrees') and setChecker(prop) then begin
      bMinSpread := true;
      minSpread := GetElementEditValues(prop, 'Value 1 - Float');
    end;

    if (GetElementEditValues(prop, 'Property') = 'AimModelMaxConeDegrees') and setChecker(prop) then begin
      bMaxSpread := true;
      maxSpread := GetElementEditValues(prop, 'Value 1 - Float');
    end;

    // Like minRange and maxRange, but for spreads
    if bMinSpread and bMaxSpread then begin
      bMinSpread := false;
      bMaxSpread := false;
      if minSpread = maxSpread then begin
        if minSpread > 0.0 then begin
          temp := '+' + floattostr(minSpread * 100) + '% Spread. ';
          description := description + temp;
        end
        else begin
          temp := floattostr(minSpread * 100) + '% Spread. ';
          description := description + temp;
        end;
      end
      // if range values are different, create the two entries
      else begin
        if minSpread > 0.0 then begin
          temp := '+' + floattostr(minSpread * 100) + '% Min Spread. ';
          description := description + temp;
        end
        else begin
          temp := floattostr(minSpread * 100) + '% Min Spread. ';
          description := description + temp;
        end;
      end;
      if maxSpread > 0.0 then begin
        temp := '+' + floattostr(maxSpread * 100) + '% Max Spread. ';
        description := description + temp;
      end
      else begin
        temp := floattostr(maxSpread * 100) + '% Max Spread. ';
        description := description + temp;
      end;
    end;

    // Handle cases where only one range is modified. Could probably refactor
    // this with above code, but too lazy write now.
    if bMinRange and not bMaxRange then begin
      bMinRange := false;
      if minRange > 0.0 then begin
        temp := '+' + floattostr(minRange) + 'x Min Range. ';
        description := description + temp;
      end
      else begin
        temp := floattostr(minRange) + 'x Min Range. ';
        description := description + temp;
      end;
    end;

    if not bMinRange and bMaxRange then begin
      bMaxRange := false;
      if maxRange > 0.0 then begin
        temp := '+' + floattostr(maxRange) + 'x Max Range. ';
        description := description + temp;
      end
      else begin
        temp := floattostr(maxRange) + 'x Max Range. ';
        description := description + temp;
      end;
    end;

    if (GetElementEditValues(prop, 'Property') = 'AimModelConeIronSightsMultiplier') and setChecker(prop) then begin
      aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
      aValue1 := aValue1 * 100;
      if aValue1 > 0 then begin
        temp := '+' + floattostr(aValue1) + '% Sight Spread. ';
        description := description + temp;
      end;
      if aValue1 < 0 then begin
        temp := floattostr(aValue1) + '% Sight Spread. ';
        description := description + temp;
      end;
    end;

    // Recoil has a Min/Max value just like range, but in general these are the same
    // so no point having more code to account for different values
    if (GetElementEditValues(prop, 'Property') = 'AimModelRecoilMinDegPerShot') and setChecker(prop) then begin
      aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
      aValue1 := aValue1 * 100;
      if aValue1 > 0 then begin
        temp := '+' + floattostr(aValue1) + '% Recoil. ';
        description := description + temp;
      end;
      if aValue1 < 0 then begin
        temp := floattostr(aValue1) + '% Recoil. ';
        description := description + temp;
      end;
    end;

    if (GetElementEditValues(prop, 'Property') = 'AimModelBaseStability') and setChecker(prop) then begin
      aValue1 := GetElementEditValues(prop, 'Value 1 - Float');
      aValue1 := aValue1 * -100;
      if aValue1 > 0 then begin
        temp := '+' + floattostr(aValue1) + '% Sight Sway. ';
        description := description + temp;
      end;
      if aValue1 < 0 then begin
        temp := floattostr(aValue1) + '% Sight Sway. ';
        description := description + temp;
      end;
    end;

  end;

  SetEditValue(ElementByName(e, 'DESC - Description'), description);
end;
end.
