-----------------------------------------------------------------------------
--
--  Logical unit: IfsInventoryHandler
--  Component:    ORDER
--
--  IFS Developer Studio Template Version 3.0
--
--  Date    Sign    History
--  ------  ------  ---------------------------------------------------------
-----------------------------------------------------------------------------

layer Core;

-------------------- PUBLIC DECLARATIONS ------------------------------------


-------------------- PRIVATE DECLARATIONS -----------------------------------


-------------------- LU SPECIFIC IMPLEMENTATION METHODS ---------------------


-------------------- LU SPECIFIC PRIVATE METHODS ----------------------------


-------------------- LU SPECIFIC PROTECTED METHODS --------------------------


-------------------- LU SPECIFIC PUBLIC METHODS -----------------------------
PROCEDURE Send_Inventory_Sf (
   min_interval_ IN NUMBER)
IS
   json_ CLOB;
   json_object_ JSON_OBJECT_T;
   json_array_  JSON_ARRAY_T:=JSON_ARRAY_T();
   
   warehouse_ VARCHAR2(100);
   qty_ NUMBER;
   part_no_ VARCHAR2(100);
   uom_ VARCHAR2(100);
   
   CURSOR get_inventroy_data_ IS
      SELECT t.warehouse AS warehouse_,
             (t.qty_onhand - t.qty_reserved) AS qty_,
             t.part_no AS part_no_,
             (Inventory_Part_API.Get_Unit_Meas(t.contract, t.part_no)) as uom_
      FROM Inventory_Part_In_Stock_tab t
      WHERE (t.warehouse = 'CCTS-MAIN-ST'
          OR t.warehouse = 'CCTS-FON'
          OR t.warehouse = 'SVCTRK-D231'
          OR t.warehouse = 'SVCTRK-D232'
          OR t.warehouse = 'SVCTRK-D233'
          OR t.warehouse = 'SVCTRK-D234') 
         AND t.rowversion < sysdate AND t.rowversion >= SYSDATE - (min_interval_ / (24 * 60));

BEGIN
   OPEN get_inventroy_data_;
   LOOP
      FETCH get_inventroy_data_
      into warehouse_, qty_, part_no_, uom_;
      EXIT WHEN get_inventroy_data_%notfound; 
    
      json_object_ := JSON_OBJECT_T.parse('{
      "Location": {
         "IFS_Id__c": "' || warehouse_ || '"
      },
      "Product2": {
         "Sales_Part_No__c": "' || part_no_ || '"
      },
      "QuantityOnHand": ' || qty_ || ',
      "QuantityUnitOfMeasure": "' || uom_ || '"
    }');
    
      json_array_.append(json_object_);
  END LOOP;
  CLOSE get_inventroy_data_;
  
  json_ := json_array_.stringify();
  
  plsql_rest_sender_API.Call_Rest_EndPoint2(rest_service_ => 'SEND_INVENTORY_SF',
                                            xml_          => json_,
                                            http_method_  => 'POST');
END Send_Inventory_Sf;

-------------------- LU  NEW METHODS -------------------------------------
