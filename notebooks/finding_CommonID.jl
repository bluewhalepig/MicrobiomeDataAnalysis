using CSV, DataFrames

### Finding matches to "cleared" recovered Malawi samples (Guiliherme) 

#Load the csv with all the Malawi samples that we have in lab, "tenative" samples. 
tentative_samples_list = CSV.read("", DataFrame) #DataFrame is the type that it produces

#Load the csvs with all the recovered Malawi samples that are 'cleared' 
ID1 = dropmissing(CSV.read("KhulaMW_BiospecimenTemplate_T1_10.03.2024.xlsx")) #dropmissing 
ID2 = dropmissing(CSV.read("KhulaMW_BiospecimenTemplate_T2_10.03.2024.xlsx"))
ID3 = dropmissing(CSV.read("KhulaMW_BiospecimenTemplate_T3_10.03.2024.xlsx"))

#Vertically concatenating the three tables (stacking the csv files)
combined_ID_tables = unique(vcat(ID1,ID2,ID3), [:specimenID])   #unique function will get rid of repeats 

#Find the common IDs by inner join on
common_ids = innerjoin(tenative_samples, combined_ID_tables, on =:sample => :specimenID) # the '=>' is a pair. sample and specimenID are the two header names that you are comparing 
    #joins don't respects order 

#Get rid of the redundant sample column 
output_data = select!(common_ids, Not(:sample)) #!() means it is changing the common_ids without creating a copy of it 


#Save output in a xlxs file 
output_file = "output.csv"
CSV.write(output_file, output_data) 

#Print confirmation that code has run 
print("Extraction complete! Saved to: ", output_file) 

