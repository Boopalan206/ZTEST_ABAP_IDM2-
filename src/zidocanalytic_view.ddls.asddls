@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IDOC analytical view'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZIDOCAnalytic_View as select from zitr_analytic_01
{
   key idoc_year as IdocYear,
   key idoc_month as IdocMonth,
   key customer as Customer,
   idoc_process_time as IdocProcessTime,
   idoc_delayed as IdocDelayed,
   idoc_delayed_perc as IdocDelayedPerc,
   total_value as TotalValue,
   average_days_delayed as AverageDaysDelayed,
   reason as Reason 
};
