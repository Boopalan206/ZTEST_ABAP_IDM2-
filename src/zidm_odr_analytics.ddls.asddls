@EndUserText.label: 'Order Type IDoc analytics'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_TEST_IDM_ANALYTICS'

define custom entity ZIDM_ODR_ANALYTICS

{

      @UI.lineItem: [{ position: 10 , label: 'IDOC Year'}]
      @AnalyticsDetails.query.axis: #FREE
      @AnalyticsDetails.query.sortDirection: #ASC

  key IDOC_YEAR   : abap.string;

      @UI.lineItem: [{ position: 20 , label: 'IDOC Month'}]
      @UI.selectionField: [{ position: 20  }]
      @AnalyticsDetails.query.axis: #FREE
  key IDOC_MONTH  : abap.string;

      @UI.lineItem: [{ position: 30 , label: 'Customer'}]
      @UI.selectionField: [{ position: 10  }]
      @AnalyticsDetails.query.axis: #FREE
      @AnalyticsDetails.query.sortDirection:#ASC
  key CUSTOMER    : abap.string;

      @UI.lineItem: [{ position: 40 , label: 'Message Type'}]
      @AnalyticsDetails.query.axis: #FREE
      MESTYP      : abap.string;

      @UI.lineItem: [{ position: 50 , label: 'Total Value'}]
      @AnalyticsDetails.query.axis: #FREE
      @Aggregation.default: #SUM
      TOTAL_VALUE : abap.string;

      Value       : abap.string;

      @UI.lineItem: [{ position: 60 , label: 'Delay Value'}]
      @AnalyticsDetails.query.axis: #FREE
      @Aggregation.default: #SUM
      Delay_Value : abap.string;

      @UI.lineItem: [{ position: 70 , label: 'Percentage'}]
      @AnalyticsDetails.query.axis: #FREE
      Percentage  : abap.string;

      @UI.lineItem: [{ position: 80 , label: 'No of Delay Days'}]
      @AnalyticsDetails.query.axis: #FREE
      @Aggregation.default: #SUM
      Days_Delay  : abap.string;

      @UI.lineItem: [{ position: 90 , label: 'Reason'}]
      @UI.selectionField: [{ position: 30  }]
      @AnalyticsDetails.query.axis: #FREE
      Reason      : abap.string;
}
