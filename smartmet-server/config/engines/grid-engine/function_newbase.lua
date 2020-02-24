----------------------------------------------------------------------
-- Global definitions
----------------------------------------------------------------------

local ParamValueMissing = -16777216;
local debug = 0;


----------------------------------------------------------------------
-- Weather texts for weather symbols in different languages:
----------------------------------------------------------------------

local weather = {};

weather['en'] = {}
weather['en'][1] = "sunny";
weather['en'][2] = "partly cloudy";
weather['en'][3] = "cloudy";
weather['en'][21] = "light showers";
weather['en'][22] = "showers";
weather['en'][23] = "heavy showers";
weather['en'][31] = "light rain";
weather['en'][32] = "rain";
weather['en'][33] = "heavy rain";
weather['en'][41] = "light snow showers";
weather['en'][42] = "snow showers";
weather['en'][43] = "heavy snow showers";
weather['en'][51] = "light snowfall";
weather['en'][52] = "snowfall";
weather['en'][53] = "heavy snowfall";
weather['en'][61] = "thundershowers";
weather['en'][62] = "heavy thundershowers";
weather['en'][63] = "thunder";
weather['en'][64] = "heavy thunder";
weather['en'][71] = "light sleet showers";
weather['en'][72] = "sleet showers";
weather['en'][73] = "heavy sleet showers";
weather['en'][81] = "light sleet rain";
weather['en'][82] = "sleet rain";
weather['en'][83] = "heavy sleet rain";
weather['en'][91] = "fog";
weather['en'][92] = "fog";

weather['sv'] = {}
weather['sv'][1] = "klart";
weather['sv'][2] = "halvklart";
weather['sv'][3] = "mulet";
weather['sv'][21] = "lätta regnskurar";
weather['sv'][22] = "regnskurar";
weather['sv'][23] = "kraftiga regnskurar";
weather['sv'][31] = "lätt regn";
weather['sv'][32] = "regn";
weather['sv'][33] = "rikligt regn";
weather['sv'][41] = "lätta snöbyar";
weather['sv'][42] = "snöbyar";
weather['sv'][43] = "täta snöbyar";
weather['sv'][51] = "lätt snöfall";
weather['sv'][52] = "snöfall";
weather['sv'][53] = "ymnigt snöfall";
weather['sv'][61] = "åskskurar";
weather['sv'][62] = "kraftiga åskskurar";
weather['sv'][63] = "åska";
weather['sv'][64] = "häftigt åskväder";
weather['sv'][71] = "lätta skurar av snöblandat regn";
weather['sv'][72] = "skurar av snöblandat regn";
weather['sv'][73] = "kraftiga skurar av snöblandad regn";
weather['sv'][81] = "lätt snöblandat regn";
weather['sv'][82] = "snöblandat regn";
weather['sv'][83] = "kraftigt snöblandat regn";
weather['sv'][91] = "dis";
weather['sv'][92] = "dimma";

weather['et'] = {}
weather['et'][1] = "selge";
weather['et'][2] = "poolpilves";
weather['et'][3] = "pilves";
weather['et'][21] = "kerged vihmahood";
weather['et'][22] = "hoogvihm";
weather['et'][23] = "tugevad vihmahood";
weather['et'][31] = "nõrk vihmasadu";
weather['et'][32] = "vihmasadu";
weather['et'][33] = "vihmasadu";
weather['et'][41] = "nõrgad lumehood";
weather['et'][42] = "hooglumi";
weather['et'][43] = "tihedad lumesajuhood";
weather['et'][51] = "nõrk lumesadu";
weather['et'][52] = "lumesadu";
weather['et'][53] = "tihe lumesadu";
weather['et'][61] = "äikesehood";
weather['et'][62] = "tugevad äikesehood";
weather['et'][63] = "äike";
weather['et'][64] = "tugev äike";
weather['et'][71] = "ñörgad lörtsihood";
weather['et'][72] = "lörtsihood";
weather['et'][73] = "tugev lörtsihood";
weather['et'][81] = "nõrk lörtsisadu";
weather['et'][82] = "lörtsisadu";
weather['et'][83] = "tugev lörtsisadu";
weather['et'][91] = "udu";
weather['et'][92] = "uduvinet";

weather['fi'] = {}
weather['fi'][1] = "selkeää";
weather['fi'][2] = "puolipilvistä";
weather['fi'][3] = "pilvistä";
weather['fi'][21] = "heikkoja sadekuuroja";
weather['fi'][22] = "sadekuuroja";
weather['fi'][23] = "voimakkaita sadekuuroja";
weather['fi'][31] = "heikkoa vesisadetta";
weather['fi'][32] = "vesisadetta";
weather['fi'][33] = "voimakasta vesisadetta";
weather['fi'][41] = "heikkoja lumikuuroja";
weather['fi'][42] = "lumikuuroja";
weather['fi'][43] = "voimakkaita lumikuuroja";
weather['fi'][51] = "heikkoa lumisadetta";
weather['fi'][52] = "lumisadetta";
weather['fi'][53] = "voimakasta lumisadetta";
weather['fi'][61] = "ukkoskuuroja";
weather['fi'][62] = "voimakkaita ukkoskuuroja";
weather['fi'][63] = "ukkosta";
weather['fi'][64] = "voimakasta ukkosta";
weather['fi'][71] = "heikkoja räntäkuuroja";
weather['fi'][72] = "räntäkuuroja";
weather['fi'][73] = "voimakkaita räntäkuuroja";
weather['fi'][81] = "heikkoa räntäsadetta";
weather['fi'][82] = "räntäsadetta";
weather['fi'][83] = "voimakasta räntäsadetta";
weather['fi'][91] = "utua";
weather['fi'][92] = "sumua";

weather['default'] = weather['fi'];


----------------------------------------------------------------------
-- WindCompass8 texts in different languages:
----------------------------------------------------------------------

local windCompass8 = {};

windCompass8['en'] = {
  "N","NE","E","SE","S","SW","W","NW"
};

windCompass8['default'] = windCompass8['en'];


----------------------------------------------------------------------
-- WindCompass16 texts in different languages:
----------------------------------------------------------------------

local windCompass16 = {};

windCompass16['en'] = {
  "N","NNE","NE","ENE","E","ESE","SE","SSE",
  "S","SSW","SW","WSW","W","WNW","NW","NNW"
};

windCompass16['default'] = windCompass16['en'];



----------------------------------------------------------------------
-- WindCompass32 texts in different languages:
----------------------------------------------------------------------

local windCompass32 = {};

windCompass32['en'] = {
  "N", "NbE", "NNE", "NEbN", "NE", "NEbE", "ENE", "EbN",
  "E", "EbS", "ESE", "SEbE", "SE", "SEbS", "SSE", "SbE",
  "S", "SbW", "SSW", "SWbS", "SW", "SWbW", "WSW", "WbS",
  "W", "WbN", "WNW", "NWbW", "NW", "NWbN", "NNW", "NbW"
};

windCompass32['default'] = windCompass32['en'];




-- ***********************************************************************
--  FUNCTION : SSI / SummerSimmerIndex
-- ***********************************************************************
--  This is an internal function used by NB_FeelsLikeTemperature function.
-- ***********************************************************************

function SSI(rh,t)

  local simmer_limit = 14.5;

  if (t <= simmer_limit) then 
    return t;
  end

  if (rh == ParamValueMissing) then 
    return ParamValueMissing;
  end

  if (t == ParamValueMissing) then 
    return ParamValueMissing;
  end

  local rh_ref = 50.0 / 100.0;
  local r = rh / 100.0;

  local value =  (1.8 * t - 0.55 * (1 - r) * (1.8 * t - 26) - 0.55 * (1 - rh_ref) * 26) / (1.8 * (1 - 0.55 * (1 - rh_ref)));         
  return value;

end





-- ***********************************************************************
--  FUNCTION : NB_SummerSimmerIndex
-- ***********************************************************************
--  SummerSimmerIndex
-- ***********************************************************************

function NB_SummerSimmerIndex(numOfParams,params)

  local result = {};

  if (numOfParams ~= 2) then
    result.message = 'Invalid number of parameters!';
    result.value = 0;  
    return result.value,result.message;
  end

  local rh = params[1];
  local t = params[2];
  local simmer_limit = 14.5;

  -- The chart is vertical at this temperature by 0.1 degree accuracy
  if (t <= simmer_limit) then 
    result.message = 'OK';
    result.value = t;
    return result.value,result.message;
  end

  if (rh == ParamValueMissing) then 
    result.message = 'OK';
    result.value = ParamValueMissing;
    return result.value,result.message;
  end

  if (t == ParamValueMissing) then 
    result.message = 'OK';
    result.value = ParamValueMissing;
    return result.value,result.message;
  end

  -- SSI

  -- When in Finland and when > 14.5 degrees, 60% is approximately
  -- the minimum mean monthly humidity. However, Google wisdom
  -- claims most humans feel most comfortable either at 45%, or
  -- alternatively somewhere between 50-60%. Hence we choose
  -- the middle ground 50%

  local rh_ref = 50.0 / 100.0;
  local r = rh / 100.0;

  result.message = 'OK';
  result.value =  (1.8 * t - 0.55 * (1 - r) * (1.8 * t - 26) - 0.55 * (1 - rh_ref) * 26) / (1.8 * (1 - 0.55 * (1 - rh_ref)));         
  return result.value,result.message;

end






-- ***********************************************************************
--  FUNCTION : NB_FeelsLikeTemperature
-- ***********************************************************************

function NB_FeelsLikeTemperature(numOfParams,params)

  local result = {};

  if (numOfParams ~= 4) then
    result.message = 'Invalid number of parameters!';
    result.value = 0;  
    return result.value,result.message;
  end

  local wind = params[1];
  local rh = params[2];
  local temp = params[3]; 
  local rad = params[4];

  if (wind == ParamValueMissing) then 
    result.message = 'OK';
    result.value = ParamValueMissing;
    return result.value,result.message;
  end

  if (temp == ParamValueMissing) then 
    result.message = 'OK';
    result.value = ParamValueMissing;
    return result.value,result.message;
  end
  
  if (rh == ParamValueMissing) then 
    result.message = 'OK';
    result.value = ParamValueMissing;
    return result.value,result.message;
  end

  -- Calculate adjusted wind chill portion. Note that even though
  -- the Canadien formula uses km/h, we use m/s and have fitted
  -- the coefficients accordingly. Note that (a*w)^0.16 = c*w^16,
  -- i.e. just get another coefficient c for the wind reduced to 1.5 meters.

  local a = 15.0;   -- using this the two wind chills are good match at T=0
  local t0 = 37.0;  -- wind chill is horizontal at this T

  local chill = a + (1 - a / t0) * temp + a / t0 * math.pow(wind + 1, 0.16) * (temp - t0);

  -- Heat index

  local heat = SSI(rh, temp);

  -- Add the two corrections together

  local feels = temp + (chill - temp) + (heat - temp);

  -- Radiation correction done only when radiation is available
  -- Based on the Steadman formula for Apparent temperature,
  -- we just inore the water vapour pressure adjustment

  if (rad ~= ParamValueMissing) then
  
    -- Chosen so that at wind=0 and rad=800 the effect is 4 degrees
    -- At rad=50 the effect is then zero degrees
    
    local absorption = 0.07;
    feels = feels + 0.7 * absorption * rad / (wind + 10) - 0.25;

  end

  result.message = 'OK';
  result.value = feels;
  return result.value,result.message;
  
end





-- ***********************************************************************
--  FUNCTION : NB_WindChill
-- ***********************************************************************
-- Return the wind chill, e.g., the equivalent no-wind temperature
-- felt by a human for the given wind speed.
--
-- The formula is the new official one at FMI taken into use in 12.2003.
-- See: http://climate.weather.gc.ca/climate_normals/normals_documentation_e.html
--
-- Note that Canadian formula uses km/h:
--
-- W = 13.12 + 0.6215 × Tair - 11.37 × V10^0.16 + 0.3965 × Tair × V10^0.16
-- W = Tair + [(-1.59 + 0.1345 × Tair)/5] × V10m, when V10m < 5 km/h
--
-- \param wind The observed wind speed in m/s
-- \param temp The observed temperature in degrees Celsius
-- \return Equivalent no-wind temperature
-- ***********************************************************************

function NB_WindChill(numOfParams,params)

  local result = {};

  if (numOfParams ~= 2) then
    result.message = 'Invalid number of parameters!';
    result.value = 0;  
    return result.value,result.message;
  end

  local wind = params[1];
  local temp = params[2];

  if (wind == ParamValueMissing or temp == ParamValueMissing or wind < 0) then
    result.message = "OK!"
    result.value = ParamValueMissing;
    return result.value,result.message;
  end

  local kmh = wind * 3.6;

  if (kmh < 5.0) then
    result.message = "OK"
    result.value = temp + (-1.59 + 0.1345 * temp) / 5.0 * kmh;
    return result.value,result.message;
  end

  local wpow = math.pow(kmh, 0.16);

  result.message = "OK"
  result.value = 13.12 + 0.6215 * temp - 11.37 * wpow + 0.3965 * temp * wpow;
  return result.value,result.message;

end





-- ***********************************************************************
--  FUNCTION : NB_WindCompass8
-- ***********************************************************************

function NB_WindCompass8(language,numOfParams,params)

  local result = {};

    -- for index, value in pairs(params) do
    --   print(index.." : "..value);
    -- end

  if (numOfParams ~= 1) then
    result.message = 'Invalid number of parameters!';
    result.value = 0;  
    return result.value,result.message;
  end

  local windDir = params[1];

  if (windDir == ParamValueMissing) then
    result.message = "OK"
    result.value = "nan"; --ParamValueMissing;
    return result.value,result.message;
  end

  local i = math.floor(((windDir + 22.5) / 45) % 8) + 1;
 
  result.message = "OK"
  if (windCompass8[language] ~= nil  and  windCompass8[language][i] ~= nil) then 
    result.value = windCompass8[language][i];
  else
    if (windCompass8['default'] ~= nil  and  windCompass8['default'][i] ~= nil) then 
    result.value = windCompass8['default'][i]
   end
  end
  
  return result.value,result.message;
  
end





-- ***********************************************************************
--  FUNCTION : NB_WindCompass16
-- ***********************************************************************

function NB_WindCompass16(language,numOfParams,params)

  local result = {};

  if (numOfParams ~= 1) then
    result.message = 'Invalid number of parameters!';
    result.value = 0;  
    return result.value,result.message;
  end

  local windDir = params[1];

  if (windDir == ParamValueMissing) then
    result.message = "OK"
    result.value = "nan"; --ParamValueMissing;
    return result.value,result.message;
  end

  local i = math.floor(((windDir + 11.25) / 22.5)) % 16 + 1;

  result.message = "OK"
  if (windCompass16[language] ~= nil  and  windCompass16[language][i] ~= nil) then 
    result.value = windCompass16[language][i];
  else
    if (windCompass16['default'] ~= nil  and  windCompass16['default'][i] ~= nil) then 
    result.value = windCompass16['default'][i]
   end
  end

  return result.value,result.message;

end





-- ***********************************************************************
--  FUNCTION : NB_WindCompass32
-- ***********************************************************************

function NB_WindCompass32(language,numOfParams,params)

  local result = {};

  if (numOfParams ~= 1) then
    result.message = 'Invalid number of parameters!';
    result.value = 0;  
    return result.value,result.message;
  end

  local windDir = params[1];

  if (windDir == ParamValueMissing) then
    result.message = "OK"
    result.value = "nan"; --ParamValueMissing;
    return result.value,result.message;
  end

  local i = math.floor((windDir + 5.625) / 11.25) % 32 + 1;

  result.message = "OK"
  if (windCompass32[language] ~= nil  and  windCompass32[language][i] ~= nil) then 
    result.value = windCompass32[language][i];
  else
    if (windCompass32['default'] ~= nil  and  windCompass32['default'][i] ~= nil) then 
    result.value = windCompass32['default'][i]
   end
  end

  return result.value,result.message;

end






-- ***********************************************************************
--  FUNCTION : NB_WeatherText
-- ***********************************************************************

function NB_WeatherText(language,numOfParams,params)

  local result = {};

  if (numOfParams ~= 1) then
    result.message = 'Invalid number of parameters!';
    result.value = 0;  
    return result.value,result.message;
  end

  local weatherSymbol = params[1];

  result.message = "OK"
  
  if (weather[language] ~= nil  and  weather[language][weatherSymbol] ~= nil)  then 
    result.value = weather[language][weatherSymbol];
  else
    if (weather['default'] ~= nil and weather['default'][weatherSymbol] ~= nil) then  
      result.value = weather['default'][weatherSymbol];
    end
  end

  return result.value,result.message;

end
 




-- ***********************************************************************
--  FUNCTION : SnowWaterRatio
-- ***********************************************************************
--  Calculate water to snow conversion factor
-- 
-- The formula is based on the table given on page 12 of the
-- M.Sc thesis by Ivan Dube titled "From mm to cm... Study of
-- snow/liquid water ratios in Quebec".
-- 
-- \param t The air temperature
-- \param ff The wind speed in m/s
-- \return The snow/water ratio
-- ***********************************************************************

function SnowWaterRatio(t,ff)

  if (t == ParamValueMissing or ff == ParamValueMissing) then
    return 10.0;
  end

  local knot = 0.51444444444444444444;

  if (ff < 10 * knot) then
    if (t > 0) then
      return 10;
    elseif (t > -5) then
      return 11;
    elseif (t > -10) then
      return 14;
    elseif (t > -20) then
      return 17;
    else
      return 15;
    end  
  elseif (ff < 20 * knot) then
    if (t > -5) then
      return 10;
    elseif (t > -10) then
      return 12;
    elseif (t > -20) then
      return 15;
    else
      return 13;
    end
  end
  
  if (t > -10) then
    return 10;
  elseif (t > -15) then
    return 11;
  elseif (t > -20) then
    return 14;
  end
  
  return 12;
end





-- ***********************************************************************
--  FUNCTION : NB_Snow1h
-- ***********************************************************************

function NB_Snow1h(numOfParams,params)

  local result = {};

  if (numOfParams ~= 4) then
    result.message = 'Invalid number of parameters!';
    result.value = 0;  
    return result.value,result.message;
  end

  local snow1h = params[1];
  local t = params[2];
  local wspd = params[3];
  local prec1h = params[4];

  -- Use the actual Snow1h if it is present

  if (snow1h ~= ParamValueMissing) then
    result.message = 'OK';
    result.value = snow1h;  
    return result.value,result.message;
  end
  
  if (t == kFloatMissing or wspd == kFloatMissing or prec1h == kFloatMissing) then
    result.message = 'OK';
    result.value = ParamValueMissing;
    return result.value,result.message;
  end

  snow1h = prec1h * SnowWaterRatio(t, wspd);  

  result.message = 'OK';
  result.value = snow1h;  
  return result.value,result.message;
end




-- ***********************************************************************
--  Cloudiness8th
-- ***********************************************************************

function NB_Cloudiness8th(numOfParams,params)

  local result = {};

  if (numOfParams ~= 1) then
    result.message = 'Invalid number of parameters!';
    result.value = 0;  
    return result.value,result.message;
  end

  local totalCloudCover = params[1];

  local n = math.ceil(totalCloudCover / 12.5);

  result.message = 'OK';
  result.value = n;  
  return result.value,result.message;
end



function MY_TEXT(language,numOfParams,params)

  local result = {};

  if (numOfParams ~= 1) then
    result.message = 'Invalid number of parameters!';
    result.value = 0;  
    return result.value,result.message;
  end

  if (params[1] <= 280) then
    if (language == "en") then
      result.value = "COLD";
    else
      result.value = "KYLMÄÄ";
    end
  else
    if (language == "en") then
      result.value = "NOT SO COLD";
    else
      result.value = "EI NIIN KYLMÄÄ";
    end
  end

  result.message = "OK"
  return result.value,result.message;
  
end



-- ***********************************************************************
--  FUNCTION : getFunctionNames
-- ***********************************************************************
--  The function returns the list of available functions in this file.
--  In this way the query server knows which function are available in
--  each LUA file.
-- 
--  Each LUA file should contain this function. The 'type' parameter
--  indicates how the current LUA function is implemented.
--
--    Type 1 : 
--      Function takes two parameters as input:
--        - numOfParams => defines how many values is in the params array
--        - params      => Array of float values
--      Function returns two parameters:
--        - result value (function result or ParamValueMissing)
--        - result string (=> 'OK' or an error message)
--
--    Type 2 : 
--      Function takes three parameters as input:
--        - columns       => Number of the columns in the grid
--        - rows          => Number of the rows in the grid
--        - params        => Grid values (= Array of float values)
--      Function return one parameter:
--        - result array  => Array of float values (must have the same 
--                           number of values as the input 'params'.               
--
--    Type 3 : 
--      Function takes four parameters as input:
--        - columns       => Number of the columns in the grid
--        - rows          => Number of the rows in the grid
--        - params1       => Grid 1 values (= Array of float values)
--        - params2       => Grid 2 values (= Array of float values)
--      Function return one parameter:
--        - result array  => Array of float values (must have the same 
--                           number of values as the input 'params1'.               
--  
--    Type 4 : 
--      Function takes five parameters as input:
--        - columns       => Number of the columns in the grid
--        - rows          => Number of the rows in the grid
--        - params1       => Grid 1 values (= Array of float values)
--        - params2       => Grid 2 values (= Array of float values)
--        - params3       => Grid point angles to latlon-north (= Array of float values)
--      Function return one parameter:
--        - result array  => Array of float values (must have the same 
--                           number of values as the input 'params1'.
--      Can be use for example in order to calculate new Wind U- and V-
--      vectors when the input vectors point to grid-north instead of
--      latlon-north.               
--
--    Type 5 : 
--      Function takes three parameters as input:
--        - language    => defines the used language
--        - numOfParams => defines how many values is in the params array
--        - params      => Array of float values
--      Function return two parameters:
--        - result value (string)
--        - result string (=> 'OK' or an error message)
--      Can be use for example for translating a numeric value to a string
--      by using the given language.  
--  
--    Type 6 : 
--      Function takes two parameters as input:
--        - numOfParams => defines how many values is in the params array
--        - params      => Array of string values
--      Function return one parameters:
--        - result value (string)
--      This function takes an array of strings and returns a string. It
--      is used for example in order to get additional instructions for
--      complex interpolation operations.  
--  
-- ***********************************************************************
 
function getFunctionNames(type)

  local functionNames = '';

  if (type == 1) then 
    functionNames = 'NB_SummerSimmerIndex,NB_FeelsLikeTemperature,NB_WindChill,NB_Snow1h,NB_Cloudiness8th';
  end
  
  if (type == 5) then 
    functionNames = 'NB_WindCompass8,NB_WindCompass16,NB_WindCompass32,NB_WeatherText,MY_TEXT';
  end

  return functionNames;

end

