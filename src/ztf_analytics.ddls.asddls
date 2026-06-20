@EndUserText.label: 'Table Functions'
define table function ZTF_ANALYTICS
  with parameters
    Date1 : abap.dats,
    Date2 : abap.dats
returns
{
  mandt                : mandt;
  idoc_number          : edi_docnum;
  idoc_year            : abap.char(4);
  idoc_month           : abap.char(2);
  idoc_delayed         : netwr;
  average_days_delayed : abap.int8;
  monthyear            : abap.char(10);
  customer             : kunnr;
  customername         : name1_gp;
  reason               : abap.string;
  total_value          : netwr;
  idoc_net_error_51    : netwr;
  idoc_net_error_56    : netwr;
  idoc_net_ready_64    : netwr;
  idoc_net_success_53  : netwr;
  idoc_credat          : abap.dats;
}
implemented by method
  class_name=>method_name;
