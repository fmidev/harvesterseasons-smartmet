#!/bin/bash
# Split countries with Islands far from the mainland into several areas
# Russia split in Euro / Siberia / Pacific
cd Asia/Russian_Federation
[ ! -f Russian_Federation_Euro.lst ] && grep -P DSM_10_N.+_00_E0[234567].+_ < Russian_Federation.lst > Russian_Federation_Euro.lst\
 && grep -P DSM_10_N8.+_00_E080_ < Russian_Federation.lst >> Russian_Federation_Euro.lst
[ ! -f Russian_Federation_Siberia.lst ] && grep -P DSM_10_N.+_00_E1[012].+_ < Russian_Federation.lst > Russian_Federation_Siberia.lst\
 && grep -P DSM_10_N.*_00_E0[89].+_ < Russian_Federation.lst >> Russian_Federation_Siberia.lst\
 && grep -P DSM_10_N.*_00_E130_ < Russian_Federation.lst >> Russian_Federation_Siberia.lst
[ ! -f Russian_Federation_Pacific.lst ] && grep -P DSM_10_N.+_00_E1[345678].+_ < Russian_Federation.lst > Russian_Federation_Pacific.lst
[ ! -f Russian_Federation_Pacific_East.lst ] && grep -P DSM_10_N.+_00_W.+_ < Russian_Federation.lst > Russian_Federation_Pacific_East.lst
cd ..
parallel ln -sTT Russian_Federation ::: Russian_Federation_Euro Russian_Federation_Pacific Russian_Federation_Pacific_East Russian_Federation_Siberia
cd ..
# France
cd Europe/France/
[ ! -f France_.lst ] && mv France.lst France_.lst
[ ! -f France.lst ] && grep -P DSM_10_N[45].+_00_W00[12345]_ < France_.lst > France.lst\
 && grep -P DSM_10_N[45].+_00_E00[1234567]_ < France_.lst >> France.lst\
 && grep -P DSM_10_N5.+_00_W008_ < France_.lst >> France.lst\
[ ! -f France_Corsica.lst ] && grep -P DSM_10_N4.+_00_E00[89]_ < France_.lst > France_Corsica.lst
[ ! -f France_Guiana.lst ] && grep -P DSM_10_N0[2345]_00_W05[1234]_ < France_.lst > France_Guiana.lst
[ ! -f France_Caribbean.lst ] && grep -P DSM_10_N1[4568]_00_W06.+_ < France_.lst > France_Caribbean.lst
[ ! -f France_Reunion.lst ] && grep -P DSM_10_S2[12]_00_E055_ < France_.lst > France_Reunion.lst
[ ! -f France_Mayotte.lst ] && grep -P DSM_10_S1[34]_00_E045_ < France_.lst > France_Mayotte.lst
cd ..
parallel ln -sT France France_{} ::: Guiana Corsica Reunion Mayotte Caribbean
cd ..
# Portugal
cd Europe/Portugal
[ ! -f Portugal_.lst ] && mv Portugal.lst Portugal_.lst
[ ! -f Portugal.lst ] && grep -P DSM_10_N3[6789].+_00_W0[10].+_ < Portugal_.lst > Portugal.lst && grep -P DSM_10_N4.+_00_W00.+_ < Portugal_.lst >> Portugal.lst
[ ! -f Portugal_Madeira.lst ] && grep -P DSM_10_N3[023]_00_W01[678]_ < Portugal_.lst > Portugal_Madeira.lst
[ ! -f Portugal_Azores.lst ] && grep -P DSM_10_N3[6789]_00_W02[5689]_ < Portugal_.lst > Portugal_Azores.lst && grep -P DSM_10_N.+_00_W03.+_ < Portugal_.lst >> Portugal_Azores.lst
cd ..
parallel ln -sT Portugal Portugal_{} ::: Madeira Azores
cd ..
# Spain
cd Europe/Spain
[ ! -f Spain_.lst ] && mv Spain.lst Spain_.lst
[ ! -f Spain.lst ] && grep -P DSM_10_N[45].+_00_W00[12345]_ < Spain_.lst > Spain.lst
[ ! -f Spain_Canary_Islands.lst ] && grep -P DSM_10_N2.+_00_W01[345678]_ < Spain_.lst > Spain_Canary_Islands.lst
cd ..
ln -sT Spain Spain_Canary_Islands
cd ..
# Svalbard & Jan Mayen
cd Europe/Svalbard_and_Jan_Mayen
[ ! -f Svalbard.lst ] && grep -P DSM_10_N[78].+_00_E0[123].+_ < Svalbard_and_Jan_Mayen.lst > Svalbard.lst
[ ! -f Jan_Mayen.lst ] && grep -P DSM_10_N7[01]_00_W0[01][0987]_ < Svalbard_and_Jan_Mayen.lst > Jan_Mayen.lst
[ ! -f Bear_Island.lst ] && grep -P DSM_10_N74_00_E01[89]_ < Svalbard_and_Jan_Mayen.lst > Bear_Island.lst
cd ..
parallel ln -sT Svalbard_and_Jan_Mayen {} ::: Svalbard Jan_Mayen Bear_Island
cd ..
# New Zealand
cd Oceania/New_Zealand
[ ! -f New_Zealand_.lst ] && mv New_Zealand.lst New_Zealand_.lst
[ ! -f New_Zealand.lst ] && grep -P DSM_10_S3.+_00_E1[67].+_ < New_Zealand_.lst > New_Zealand.lst\
 && grep -P DSM_10_S4[01234567]_00_E1[67].+_ < New_Zealand_.lst >> New_Zealand.lst
[ ! -f New_Zealand_Chatham_Islands.lst ] && grep -P DSM_10_S.*_00_W17.+_ < New_Zealand.lst > New_Zealand_Chatham_Islands.lst
[ ! -f New_Zealand_Auckland_Islands.lst ] && grep -P DSM_10_S51_00_E16.+_ < New_Zealand.lst > New_Zealand_Auckland_Islands.lst
[ ! -f New_Zealand_Snares_Islands.lst ] && grep -P DSM_10_S49_00_E16.+_ < New_Zealand.lst > New_Zealand_Snares_Islands.lst
[ ! -f New_Zealand_Campbell_Island.lst ] && grep -P DSM_10_S53_00_E16.+_ < New_Zealand.lst > New_Zealand_Campbell_Island.lst
[ ! -f New_Zealand_Antipodes_Island.lst ] && grep -P DSM_10_S50_00_E17.+_ < New_Zealand.lst > New_Zealand_Antipodes_Island.lst
cd ..
parallel ln -sT New_Zealand New_Zealand_{} ::: Antipodes_Island Auckland_Islands Campbell_Island Chatham_Islands Snares_Islands
cd ..
# Australia is better without Tasmania
cd Oceania/Australia
[ ! -f Australia_.lst ] && mv Australia.lst Australia_.lst && grep -P DSM_10_S[123].+_00_E.+_ < Australia_.lst > Australia.lst
[ ! -f Australia_Tasmania.lst ] && grep -P DSM_10_S4.+_00_E.+_ < Australia_.lst > Australia_Tasmania.lst
cd ..
ln -sT Australia Australia_Tasmania
cd ..
# Kiribati is across the antimeridian
cd Oceania/Kiribati
[ ! -f Kiribati_East.lst ] && grep -P DSM_10_.+_00_W.+_ < Kiribati.lst > Kiribati_East.lst
[ ! -f Kiribati_West.lst ] && grep -P DSM_10_.+_00_E.+_ < Kiribati.lst > Kiribati_West.lst
cd ..
parallel ln -sT Kiribati Kiribati_{} ::: East West
cd ..
# Fiji is across the antimeridian
cd Oceania/Fiji
[ ! -f Fiji_East.lst ] && grep -P DSM_10_.+_00_W1.+_ < Fiji.lst > Fiji_East.lst
[ ! -f Fiji_West.lst ] && grep -P DSM_10_.+_00_E1.+_ < Fiji.lst > Fiji_West.lst
cd ..
parallel ln -sT Fiji Fiji_{} ::: East West
cd ..
# Chile
cd South_America/Chile
[ ! -f Chile_.lst ] && mv Chile.lst Chile_.lst
[ ! -f Chile.lst ] && grep -P DSM_10_S.+_00_W0[67].+_ < Chile_.lst > Chile.lst
[ ! -f Chile_Easter_Island.lst ] && grep -P DSM_10_S.+_00_W1.+_ < Chile_.lst > Chile_Easter_Island.lst
[ ! -f Chile_Fernandez_Islands.lst ] && grep -P DSM_10_S.+_00_W08.+_ < Chile_.lst > Chile_Fernandez_Islands.lst\
 && grep -P DSM_10_S.+_00_W079_ < Chile_.lst >> Chile_Isla_Sala_y_Gomez.lst
cd ..
parallel ln -sT Chile Chile_{} ::: Easter_Island Isla_Sala_y_Gomez
cd ..
# Seychelles has one island in Caribbean
cd Seven_seas_\(open_ocean\)/Seychelles
[ ! -f Seychelles_West.lst ] && grep -P DSM_10_N.+_00_W.+_ < Seychelles.lst > Seychelles_West.lst
[ ! -f Seychelles_.lst ] && mv Seychelles.lst Seychelles_.lst\
 && grep -P DSM_10_S.+_00_E.+_ < Seychelles_.lst > Seychelles.lst
cd ..
ln -sT Seychelles Seychelles_West
cd ..
# St Helena Ascension Tristan da Cunha
cd Seven_seas_\(open_ocean\)/Saint_Helena___Ascension_and_Tristan_Da_Cunha
[ ! -f Saint_Helena.lst ] && grep -P DSM_10_S1[67]_00_W006_ < Saint_Helena___Ascension_and_Tristan_Da_Cunha.lst > Saint_Helena.lst
[ ! -f Ascension.lst ] && grep -P DSM_10_S08_00_W015_ < Saint_Helena___Ascension_and_Tristan_Da_Cunha.lst > Ascension.lst
[ ! -f Tristan_Da_Cunha.lst ] && grep -P DSM_10_S[34][18]_00_W01[013]_ < Saint_Helena___Ascension_and_Tristan_Da_Cunha.lst > Tristan_Da_Cunha.lst
cd ..
parallel ln -sT Saint_Helena___Ascension_and_Tristan_Da_Cunha ::: Ascension Saint_Helena Tristan_Da_Cunha
cd ..
# French Antarctic Islands
cd Seven_seas_\(open_ocean\)/French_Southern_and_Antarctic_Lands
[ ! -f Crozet_Islands.lst ] && grep -P DSM_10_S4.+_00_E05.+_ < French_Southern_and_Antarctic_Lands.lst > Crozet_Islands.lst
[ ! -f Amsterdam_Island.lst ] && grep -P DSM_10_S3[89]_00_E077_ < French_Southern_and_Antarctic_Lands.lst > Amsterdam_Island.lst
[ ! -f Kerguelen.lst ] && grep -P DSM_10_S[45].+_00_E06.+_ < French_Southern_and_Antarctic_Lands.lst > Kerguelen.lst
cd ..
parallel ln -sT French_Southern_and_Antarctic_Lands ::: Crozet_Islands Amsterdam_Island Kerguelen
cd ..
# Canada split in North / South 
cd North_America/Canada
[ ! -f Canada_.lst ] && mv Canada.lst Canada_.lst
[ ! -f Canada_North.lst ] && grep -P DSM_10_N7.+_00_W.+_ < Canada_.lst > Canada_North.lst
# && grep -P DSM_10_N8.+_00_W.+_ < Canada_.lst >> Canada_North.lst
[ ! -f Canada.lst ] && grep -P DSM_10_N[456].+_00_W.+_ < Canada_.lst > Canada.lst\
 && grep -P DSM_10_N70_00_W.+_ < Canada_.lst >> Canada.lst
cd ..
ln -sT Canada Canada_North
cd ..
# United States: Alaska, Hawai and Atolles 
cd North_America/United_States
[ ! -f United_States_.lst ] && mv United_States.lst United_States_.lst
[ ! -f United_States.lst ] && grep -P DSM_10_N[234].+_00_W0[6789].+_ < United_States_.lst > United_States.lst\
 && grep -P DSM_10_N[234].+_00_W1[012].+_ < United_States_.lst >> United_States.lst
[ ! -f United_States_Alaska.lst ] && grep -P DSM_10_N[567].+_00_W1.+_ < United_States_.lst > United_States_Alaska.lst
[ ! -f United_States_Bering_West.lst ] && grep -P DSM_10_N5.+_00_E17.+_ < United_States_.lst > United_States_Bering_West.lst
[ ! -f United_States_Atolles.lst ] && grep -P DSM_10_N2[567].+_00_W17.+_ < United_States_.lst > United_States_Atolles.lst
[ ! -f United_States_Hawai.lst ] && grep -P DSM_10_N[12].+_00_W1[56].+_ < United_States_.lst > United_States_Hawai.lst
cd ..
parallel ln -sT United_States United_States_{} ::: Alaska Bering_West Hawai Atolles
cd ..
# US minor islands
cd North_America/United_States_Minor_Outlying_Islands
[ ! -f United_States_Minor_Island_1.lst ] && grep -P DSM_10_N28_00_W17[89]_ < United_States_Minor_Outlying_Islands.lst > United_States_Minor_Island_1.lst
[ ! -f United_States_Minor_Island_2.lst ] && grep -P DSM_10_N0[56]_00_W163_ < United_States_Minor_Outlying_Islands.lst > United_States_Minor_Island_2.lst
[ ! -f United_States_Minor_Island_3.lst ] && grep -P DSM_10_S01_00_W16[01]_ < United_States_Minor_Outlying_Islands.lst > United_States_Minor_Island_3.lst
[ ! -f United_States_Minor_Island_4.lst ] && grep -P DSM_10_N16_00_W170_ < United_States_Minor_Outlying_Islands.lst > United_States_Minor_Island_4.lst
[ ! -f United_States_Minor_Island_5.lst ] && grep -P DSM_10_N19_00_E166_ < United_States_Minor_Outlying_Islands.lst > United_States_Minor_Island_5.lst
[ ! -f United_States_Minor_Island_6.lst ] && grep -P DSM_10_N00_00_W177_ < United_States_Minor_Outlying_Islands.lst > United_States_Minor_Island_6.lst
cd ..
parallel ln -sT United_States_Minor_Outlying_Islands United_States_Minor_Island_{} ::: 1 2 3 4 5 6
cd ..
