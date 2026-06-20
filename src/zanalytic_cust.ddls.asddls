@EndUserText.label: 'Analytical Customer'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_TEST_ANA_CUST'
define custom entity ZANALYTIC_CUST

{
  key IDOC_YEAR   : abap.string;
  key IDOC_MONTH  : abap.string;
  key CUSTOMER    : abap.string;
      TOTAL_VALUE : abap.string;
      Value       : abap.string;
      Delay_Value : abap.string;
      Percentage  : abap.string;
      Days_Delay  : abap.string;
      Reason      : abap.string;

}
