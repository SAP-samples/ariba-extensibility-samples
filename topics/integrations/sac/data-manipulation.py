import json

def on_input(data):
    
    # The api. object offers some convenience functions in SAP Data Intelligence
    # for more information check out: 
    # https://help.sap.com/viewer/97fce0b6d93e490fadec7e7021e9016e/Cloud/en-US/021180336add475bbd712b0ce5d393c1.html
    
    api.logger.info("OpenAPI client message: {data}")
    
    # Convert the body byte data type to string and replacing single quotes
    json_string = data.body.decode('utf8').replace("'", '"')
    
    # Converting to JSON
    json_struct = json.loads(json_string)
    
    records_csv = "SMVendorID,Name,TimeUpdated\n"
    
    # Track number of inactive suppliers
    count = 0
    
    # Checking the records exist in the response
    if 'Records' in json_struct:
        for record in json_struct['Records']:
            
            # Process only records that are inactive
            if record['Active'] == False:
                count += 1
                
                # Prepare CSV line
                line =  f'"{record["SMVendorID"]}","{record["Name"]}","{record["TimeUpdated"]}"\n' 
                
                api.logger.info(f"Line: {line}")
                
                records_csv += line
    
    api.logger.info(f"Total inactive suppliers processed: {count}")
    api.send("output", records_csv)

api.set_port_callback("input1", on_input)