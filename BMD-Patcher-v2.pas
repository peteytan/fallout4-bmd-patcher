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

function setDescription(prop: IInterface; identifier: String; textToWrite: String): String;
var
  fValue: float;
  sValue: string;
  description, temp: string;
begin
  if (GetElementEditValues(prop, 'Property') = 'Keywords') then begin
    if GetElementEditValues(prop, 'Value 1 - FormID') = identifier then begin
      description := description + textToWrite;
    end;
  end;

  if (GetElementEditValues(prop, 'Property') = 'Enchantments') then begin
    if GetElementEditValues(prop, 'Value 1 - FormID') = identifier then begin
      description := description + textToWrite;
    end;
  end;

  if (GetElementEditValues(prop, 'Property') = identifier) and setChecker(prop) then begin
    // If Value 1 is float, execute this code block
    if (GetElementEditValues(prop, 'Value 1 - Float') <> null) then begin
    fValue := GetElementEditValues(prop, 'Value 1 - Float') * 100; // make decimal and integer
      if fValue > 0 then begin
        temp := '+' + floattostr(fValue) + textToWrite;
        description := description + temp;
      end;
      if fValue < 0 then begin
        temp := floattostr(fValue) + textToWrite;
        description := description + temp;
      end;
    end;
  end;
  Result:= description
end;

function Process(e: IInterface;): Integer;
var
  props, prop: IInterface;
  i: integer;
  temp, finalText: string;
  fValue: float;
  sValue: string;
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

    // Special Section to handle specific properties that don't match an easy format.
    finalText := finalText + setDescription(prop, 'HasSilencer [KYWD:001E05D6]', 'Suppressed. ');
    finalText := finalText + setDescription(prop, 'EnchWeapModBleed "Bleed" [ENCH:0009733E]', 'Causes Bleeding. ');
    finalText := finalText + setDescription(prop, 'ap_melee_ArmorPenetrate [KYWD:00097342]', 'Armor Piercing. ');
    finalText := finalText + setDescription(prop, 'AttackTypeExtraLimbDamage [KYWD:000D3FC8]', 'Extra Limb Damage. ');
    finalText := finalText + setDescription(prop, 'AttackTypeChanceCripple [KYWD:000D3FCC]', 'Chance to cripple. ');
    finalText := finalText + setDescription(prop, 'EnchModDisarm "Disarm" [ENCH:00246C08]', 'Chance to disarm. ');
    finalText := finalText + setDescription(prop, 'dn_HasMeleeMod_ShockAndStun [KYWD:000C44D5]', 'Chance to stun. ');

    if GetElementEditValues(prop, 'Property') = 'ActorValues' then begin
      if GetElementEditValues(prop, 'Value 1 - FormID') = 'ArmorPenetration "Armor Penetration" [AVIF:00097341]' then begin
        fValue := GetElementEditValues(prop, 'Value 2 - Float');
        temp := '+' + floattostr(fValue) + ' Armor Pierce. ';
        finalText := finalText + temp;
      end;
    end;

    if (GetElementEditValues(prop, 'Property') = 'DamageTypeValues') and (GetElementEditValues(prop, 'Function Type') = 'ADD') then begin
      if GetElementEditValues(prop, 'Value 1 - FormID') = 'dtEnergy [DMGT:00060A81]' then begin
        fValue := GetElementEditValues(prop, 'Value 2 - Float');
        temp := '+' + floattostr(fValue) + ' Energy Damage. ';
        finalText := finalText + temp;
      end;
    end;

    finalText := finalText + setDescription(prop, 'AmmoCapacity', '% Ammo Capacity. ');
    finalText := finalText + setDescription(prop, 'AttackDamage', '% Damage. ');
    finalText := finalText + setDescription(prop, 'CriticalDamageMult', '% Critical Damamge. ');
    finalText := finalText + setDescription(prop, 'SecondaryDamage', '% Bash Damage. ');
    finalText := finalText + setDescription(prop, 'Speed', '% Fire Rate. ');
    finalText := finalText + setDescription(prop, 'ReloadSpeed', '% Reload Time. ');
    finalText := finalText + setDescription(prop, 'SightedTransitionSeconds', '% Sight Time. ');
    finalText := finalText + setDescription(prop, 'AttackActionPointCost', '% VATS Cost. ');
    finalText := finalText + setDescription(prop, 'AimModelConeIronSightsMultiplier', '% Sight Spread. ');
    // Recoil has a Min/Max value just like range, but in general these are the same so no point to account for min/max
    finalText := finalText + setDescription(prop, 'AimModelRecoilMinDegPerShot', '% Recoil. ');
    finalText := finalText + setDescription(prop, 'AimModelBaseStability', '% SightSway. ');
    finalText := finalText + setDescription(prop, 'OutOfRangeDamageMult', '% Max Range Damage. ');

    // alternative if speed was a SET instead of MUL+ADD
    if (GetElementEditValues(prop, 'Property') = 'Speed') and not setChecker(prop) then begin
      fValue := GetElementEditValues(prop, 'Value 1 - Float');
      fValue := fValue * 100 - 100;
      if fValue > 0 then begin
        temp := '+' + floattostr(fValue) + '% Fire Rate. ';
        finalText := finalText + temp;
      end;
      if fValue < 0 then begin
        temp := floattostr(fValue) + '% Fire Rate. ';
        finalText := finalText + temp;
      end;
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
          finalText := finalText + temp;
        end
        else begin
          temp := floattostr(minRange) + 'x Range. ';
          finalText := finalText + temp;
        end;
      end
      // if range values are different, create the two entries
      else begin
        if minRange > 0.0 then begin
          temp := '+' + floattostr(minRange) + 'x Min Range. ';
          finalText := finalText + temp;
        end
        else begin
          temp := floattostr(minRange) + 'x Min Range. ';
          finalText := finalText + temp;
        end;

        if maxRange > 0.0 then begin
          temp := '+' + floattostr(maxRange) + 'x Max Range. ';
          finalText := finalText + temp;
        end
        else begin
          temp := floattostr(maxRange) + 'x Max Range. ';
          finalText := finalText + temp;
        end;
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
          finalText := finalText + temp;
        end
        else begin
          temp := floattostr(minSpread * 100) + '% Spread. ';
          finalText := finalText + temp;
        end;
      end
      // if range values are different, create the two entries
      else begin
        if minSpread > 0.0 then begin
          temp := '+' + floattostr(minSpread * 100) + '% Min Spread. ';
          finalText := finalText + temp;
        end
        else begin
          temp := floattostr(minSpread * 100) + '% Min Spread. ';
          finalText := finalText + temp;
        end;

        if maxSpread > 0.0 then begin
          temp := '+' + floattostr(maxSpread * 100) + '% Max Spread. ';
          finalText := finalText + temp;
        end
        else begin
          temp := floattostr(maxSpread * 100) + '% Max Spread. ';
          finalText := finalText + temp;
        end;
      end;
    end;
  end;

  if finalText = '' then begin
    finalText := 'Standard.'
  end;
  SetEditValue(ElementByName(e, 'DESC - Description'), finalText);

end;
end.
