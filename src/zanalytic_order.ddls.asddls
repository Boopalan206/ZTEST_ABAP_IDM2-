@EndUserText.label: 'Analytical Order'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_TEST_ANA_CUST'
define custom entity ZANALYTIC_ORDER
{
  key IDOC_YEAR   : abap.string;
  key IDOC_MONTH  : abap.string;
  key CUSTOMER    : abap.string;
      TOTAL_VALUE : abap.string;
      Value       : abap.string;
      Delay_value : abap.string;
      Percentage  : abap.string;
      Days_delay  : abap.string;
      Reason      : abap.string;




}
