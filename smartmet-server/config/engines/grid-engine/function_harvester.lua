ParamValueMissing = -16777216;
debug = 0;

-- ###########################################################################################
-- FUNCTION for an index if ensemble members are to 90 % under a threshold or only 10 %?
--  The function returns 0 for only 10% are over, 1 for between 10 and 90 % and 2 for over 90%
-- ###########################################################################################

function HARVIDX(numOfParams,params)
  local result = {};
  if (debug == 1) then
    for index, value in pairs(params) do
      print(index.." : "..value);
    end
  end
  if (numOfParams > 0) then 
    local count = 0;
    local agree = 0;
    local nans = 0;
    local disagree = 0;
    local threshold = params[1];
    for index, value in pairs(params) do
      if (value ~= ParamValueMissing and index > 1) then
        if (value ~= value) then
          nans = nans + 1;
        elseif (value < threshold) then
	        agree = agree + 1;
	        count = count + 1;
	      else
	        disagree = disagree + 1;
 	        count = count + 1;
        end
      else 
        if (index > 1) then 
          nans = nans +1;
        end
      end
    end
    result.message = 'OK';
--    result.value = agree;
    if (count < nans) then
--      result.message = 'Too many NaNs ' .. nans;
      result.value = ParamValueMissing;
    elseif (agree / count >= 0.9) then
       result.value = 2;
    elseif (agree / count <= 0.1) then
    	result.value = 0;
    else
    	result.value = 1;
    end
  else
    result.message = 'OK';
    result.value = ParamValueMissing;
  end

  return result.value,result.message;
end

-- ################################################################################################
-- FUNCTION for an index if ensemble members are to a given percent over a threshold or 1-percent?
--  The function returns 0 for only (1-percent) are over, 1 for between boundaries and 2 for over
-- calling ENSOVER{threshold;percent;parameterlist} percent as value 0..1
-- #################################################################################################

function ENSOVER(numOfParams,params)
  local result = {};
  if (debug == 1) then
    for index, value in pairs(params) do
      print(index.." : "..value);
    end
  end
  if (numOfParams > 0) then 
    local count = 0;
    local agree = 0;
    local nans = 0;
    local disagree = 0;
    local threshold = params[1];
    local percent = params[2];
    for index, value in pairs(params) do
      if (value ~= ParamValueMissing and index > 2) then
        if (value ~= value) then
          nans = nans + 1;
        elseif (value >= threshold) then
      	  agree = agree + 1;
	        count = count + 1;
      	else
	        disagree = disagree + 1;
 	        count = count + 1;
        end
      else 
        if (index > 2) then 
          nans = nans +1;
        end
      end
    end
    result.message = 'OK';
--    result.value = agree;
    if (count < nans) then
--      result.message = 'Too many NaNs '+ nans;
      result.value = ParamValueMissing;
    elseif (agree / count >= percent) then
       result.value = 2;
    elseif (agree / count <= (1 - percent)) then
    	result.value = 0;
    else
    	result.value = 1;
    end
  else
    result.message = 'OK';
    result.value = ParamValueMissing;
  end

  return result.value,result.message;
end
-- ################################################################################################
-- FUNCTION for an index if ensemble members are to a given percent undeer a threshold or 1-percent?
--  The function returns 0 for only (1-percent) are over, 1 for between boundaries and 2 for over
-- calling ENSUNDER{threshold;percent;parameterlist} percent as number between 0-1
-- #################################################################################################

function ENSUNDER(numOfParams,params)
  local result = {};
  if (debug == 1) then
    for index, value in pairs(params) do
      print(index.." : "..value);
    end
  end
  if (numOfParams > 0) then 
    local count = 0;
    local agree = 0;
    local nans = 0;
    local disagree = 0;
    local threshold = params[1];
    local percent = params[2];
    for index, value in pairs(params) do
      if (value ~= ParamValueMissing and index > 2) then
        if (value ~= value) then
          nans = nans + 1;
        elseif (value <= threshold) then
      	  agree = agree + 1;
          count = count + 1;
      	else
	        disagree = disagree + 1;
 	        count = count + 1;
        end
      else 
        if (index > 2) then 
          nans = nans +1;
        end
      end
    end
    result.message = 'OK';
--    result.value = agree;
    if (count < nans) then
--      result.message = 'Too many NaNs '+ nans;
      result.value = ParamValueMissing;
    elseif (agree / count >= percent) then
       result.value = 2;
    elseif (agree / count <= (1 - percent)) then
      result.value = 0;
    else
    	result.value = 1;
    end
  else
    result.message = 'OK';
    result.value = ParamValueMissing;
  end

  return result.value,result.message;
end

-- #################################################################################################
--- FUNCTION to calculate the nth percentile
--- call PCNTL{percentile;paramList} percentile in (range 0 to 100)
-- #################################################################################################

function PCNTL(numOfParams,params)
	local result = {};
	local percentile = params[1];
	if percentile > 100 or percentile < 0 then 
		result.value = ParamValueMissing;
		result.message = 'Percentile value out of range 0-100';
	else
		local numSamples = numOfParams - 1;
		local target = math.floor(numSamples * percentile / 100);
		local sortedList = {unpack(params,2,numOfParams)};
		table.sort(sortedList);
		result.value = sortedList[target];
		result.message = 'OK';
	end
	return result.value,result.message;
end

-- ###########################################################################################
-- FUNCTION for calculating snow depth (elevation) from Snow water equivalent and snow denisty
--  The function returns snow depth in m; inputs HSNOW-M and RSN (solution from ERA5 / ECMWF)
-- ###########################################################################################

function SNOWDEPTH(numOfParams,params)
  local result = {};
  if (debug == 1) then
    for index, value in pairs(params) do
      print(index.." : "..value);
    end
  end
  if (numOfParams >= 2) then 
    local snowdepth = 0;
    local swe = params[1];
    local rsn = params[2];
    if (rsn < 100) then 
      rsn = 100; 
    end
    if (swe > 0.0001) then 
      snowdepth = 1000.0 * swe / rsn;
    else
      snowdepth = 0;
    end

		result.value = snowdepth;
		result.message = 'OK';
	else
    result.message = 'error in parameters - need 2';
  end
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
    functionNames = 'HARVIDX,ENSOVER,ENSUNDER,PCNTL,SNOWDEPTH';
  end
  
  return functionNames;

end
