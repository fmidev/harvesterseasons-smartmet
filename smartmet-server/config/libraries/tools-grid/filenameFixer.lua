

function fixFilename(numOfParams,params)

  --for index, value in pairs(params) do
  --  print(index.." : "..value);
  --end

  f = params[1];
  
  if (string.sub(f,1,2) == "fc") then
    n = "FC_"..string.sub(f,3,10).."T"..string.sub(f,11,12).."0000_"..string.sub(f,14,17)..".grib";
    return n;
  end
    
  return params[1];
  
end





function getFunctionNames(type)

  local functionNames = '';

  if (type == 6) then 
    functionNames = 'fixFilename';
  end
      
  return functionNames;

end


