@AbapCatalog.sqlViewName: 'ZSALES_ALP'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales ALP - Test'
@Metadata.ignorePropagatedAnnotations: true

@OData.publish: true
@OData.entitySet.name: 'SalesAnalyticalSet'

@Metadata.allowExtensions: true
define view ZTEST_SALES_ALP as select from vbak as vh inner join vbap as vp on vh.vbeln = vp.vbeln
{
  
  key vh.vbeln as SalesDocument,
  key vp.posnr as Item,
  key vh.vkorg as SalesORg,
  vp.werks as Palnt,
  vh.spart as Division,
  vh.vtweg as distibutionchannel,
  vp.brgew as GrossWeight,
  
  @DefaultAggregation: #SUM
  @UI.dataPoint: { qualifier: 'Netprice'}
  vp.netwr as Netprice,
  vp.waerk as Currency,
  vh.audat as documentDate,
  case substring(vh.audat,5,2)
    when '01' then concat('JAN-', substring(vh.audat, 1, 4))
    when '02' then concat('FEB-', substring(vh.audat, 1, 4))
    when '03' then concat('MAR-', substring(vh.audat, 1, 4)) 
    when '04' then concat('APR-', substring(vh.audat, 1, 4))
    when '05' then concat('MAY-', substring(vh.audat, 1, 4))
    when '06' then concat('JUN-', substring(vh.audat, 1, 4))
    when '07' then concat('JUL-', substring(vh.audat, 1, 4))
    when '08' then concat('AUG-', substring(vh.audat, 1, 4))
    when '09' then concat('SEP-', substring(vh.audat, 1, 4))
    when '10' then concat('OCT-', substring(vh.audat, 1, 4))
    when '11' then concat('NOV-', substring(vh.audat, 1, 4))
    when '12' then concat('DEC-', substring(vh.audat, 1, 4))
  else 'DUMMY'
  end as DOCUMENT_MONYEAR 
  
  
      
}
