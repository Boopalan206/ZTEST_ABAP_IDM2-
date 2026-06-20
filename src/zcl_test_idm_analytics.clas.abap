CLASS zcl_test_idm_analytics DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.


    TYPES : BEGIN OF ty_data,
              docnum TYPE edidc-docnum,
              cust   TYPE kunnr,
              year   TYPE char4,
              mon    TYPE char2,
              mestyp TYPE edi_mestyp,
              netwr  TYPE netwr,
              credat TYPE sy-datum,
              cretim TYPE sy-uzeit,
              ddate  TYPE sy-datum,
              dtime  TYPE  sy-uzeit,
              status TYPE edi_status,
              days   TYPE int8,
              flag   TYPE char1,
              Reason TYPE string,
            END OF ty_data.

    DATA: ls_out      TYPE zidm_odr_analytics,
          lt_out      TYPE STANDARD TABLE OF zidm_odr_analytics,
          lv_year     TYPE zitr_analytic_de_year,
          lv_month    TYPE zitr_analytic_de_month,
          lt_amount   TYPE TABLE OF e1edp01,
          lt_cust     TYPE TABLE OF e1edka1,
          ls_amount   TYPE e1edp01,
          ls_cust     TYPE e1edka1,
          lt_data     TYPE TABLE OF ty_data,
          ls_data     TYPE ty_data,
          lv_amount   TYPE netwr,
          lv_total    TYPE netwr,
          lv_ndelay   TYPE netwr,
          lv_delay    TYPE netwr,
          lt_edid4    TYPE TABLE OF edid4,
          ls_edid4    TYPE  edid4,
          lv_count    TYPE i,
          lv_cust     TYPE kunnr,
          lv_customer TYPE kunnr,
          lv_days     TYPE int8,
          lv_from     TYPE sy-datum,
          lv_to       TYPE sy-datum,
          lt_edidc    TYPE TABLE OF edidc,
          ls_edidc    TYPE  edidc,
          lt_edids    TYPE TABLE OF edids,
          ls_edids    TYPE  edids.
    DATA : lv_year3(4)  TYPE c,
           lv_month3(2) TYPE c,
           lv_day3(2)   TYPE c.
    INTERFACES if_rap_query_provider .
    INTERFACES if_rap_query_aggregation.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_test_idm_analytics IMPLEMENTATION.


  METHOD if_rap_query_provider~select.


    IF io_request->is_data_requested(  ).

      DATA(lv_offset) = io_request->get_paging( )->get_offset( ).
      DATA(lv_page_size) = io_request->get_paging( )->get_page_size( ).
      DATA(lv_max_rows) = COND #( WHEN lv_page_size = if_rap_query_paging=>page_size_unlimited THEN 0
                                  ELSE lv_page_size ).

      DATA(sort_elements) = io_request->get_sort_elements( ).
      DATA(lt_sort_criteria) = VALUE string_table( FOR sort_element IN sort_elements
                                                 ( sort_element-element_name && COND #( WHEN sort_element-descending = abap_true
                                                                                        THEN ` descending`
                                                                                        ELSE ` ascending` ) ) ).
      DATA(lv_sort_string)  = COND #( WHEN lt_sort_criteria IS INITIAL THEN `IDOC_YEAR`
                                                                       ELSE concat_lines_of( table = lt_sort_criteria sep = `, ` ) ).

********************************************************************** Filter
      TRY.
          DATA(lt_ranges) = io_request->get_filter( )->get_as_ranges( ).
          ""filter manipulation

          " Look for IDOC_NUMBER filter
          DATA(lt_idoc_YEAR) = COND #( WHEN line_exists( lt_ranges[ name = 'IDOC_YEAR' ] )
                                      THEN lt_ranges[ name = 'IDOC_YEAR' ]-range
                            ).

          " Look for CREATION_DATE filter
          DATA(lt_idoc_month) = COND #( WHEN line_exists( lt_ranges[ name = 'IDOC_MONTH' ] )
                                      THEN lt_ranges[ name = 'IDOC_MONTH' ]-range
                            ).

          " Look for MESSAGE_TYPE field filter
          DATA(lt_CUSTOMER) = COND #( WHEN line_exists( lt_ranges[ name = 'CUSTOMER' ] )
                                        THEN lt_ranges[ name = 'CUSTOMER' ]-range
                              ).
      ENDTRY.

      LOOP AT lt_idoc_year INTO DATA(wa_idoc_year).

        lv_year = wa_idoc_year-low.

      ENDLOOP.

      LOOP AT lt_idoc_month INTO DATA(wa_idoc_month).

        lv_month = wa_idoc_month-low.

      ENDLOOP.

      IF lv_year IS NOT INITIAL AND lv_month IS NOT INITIAL.
        CONCATENATE lv_year lv_month '00' INTO lv_from.
        CONDENSE lv_from.

        CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
          EXPORTING
            day_in            = lv_from
          IMPORTING
            last_day_of_month = lv_to.

      ELSE.

        lv_to = sy-datum.

        lv_year3 = sy-datum+0(4) - 1.
        lv_month3 = sy-datum+4(2) .
        lv_day3    = sy-datum+6(2).

        CONCATENATE lv_year3 lv_month3 lv_day3 INTO lv_from.
        CONDENSE lv_from.
      ENDIF.


******************************************


      SELECT * FROM edidc INTO TABLE lt_edidc
              WHERE credat  BETWEEN lv_from AND lv_to
                    AND mestyp = 'ORDERS'
                    AND  status IN ('51','53','64').

      CLEAR : lv_from, lv_to.

      IF lt_edidc IS NOT INITIAL.

        SELECT * FROM edid4 INTO CORRESPONDING FIELDS OF TABLE  lt_edid4
                FOR ALL ENTRIES IN lt_edidc WHERE docnum EQ lt_edidc-docnum
                               AND segnam  IN ('E1EDP01' , 'E1EDKA1') .

        SELECT * FROM edids INTO TABLE lt_edids
            FOR ALL ENTRIES IN lt_edidc WHERE docnum EQ lt_edidc-docnum

                                     AND status IN ('51','53','64').

      ENDIF.

      SORT : lt_edid4 BY docnum ,
             lt_edids BY docnum DESCENDING.
      LOOP AT lt_edidc INTO ls_edidc.
        LOOP AT lt_edid4 INTO ls_edid4 WHERE docnum = ls_edidc-docnum AND segnam = 'E1EDP01' .

          ls_amount = ls_edid4-sdata.
          ls_data-netwr = ls_amount-netwr + ls_data-netwr.
          ls_data-year = ls_edidc-credat+0(4).
          ls_data-mon = ls_edidc-credat+4(2).
          ls_data-mestyp = ls_edidc-mestyp.
          ls_data-credat = ls_edidc-credat.
          ls_data-cretim = ls_edidc-cretim.
          ls_data-status = ls_edidc-status.
          ls_data-docnum   = ls_edidc-docnum.

        ENDLOOP.

        LOOP AT lt_edid4 INTO ls_edid4 WHERE docnum = ls_edidc-docnum AND
                                      segnam EQ 'E1EDKA1'.
          IF sy-subrc EQ 0.
            ls_cust = ls_edid4-sdata.
            IF ls_cust-parvw = 'AG'.
              ls_data-cust = ls_cust-partn.
            ENDIF.
          ENDIF.
        ENDLOOP.

        READ TABLE lt_edids INTO ls_edids WITH KEY docnum = ls_edidc-docnum.
        IF sy-subrc EQ 0.
          DATA(lv_string) = ls_edids-statxt.

          REPLACE ALL OCCURRENCES OF '&1' IN lv_string WITH ls_edids-stapa1.
          REPLACE ALL OCCURRENCES OF '&2' IN lv_string WITH ls_edids-stapa2.
          REPLACE ALL OCCURRENCES OF '&3' IN lv_string WITH ls_edids-stapa3.
          REPLACE ALL OCCURRENCES OF '&4' IN lv_string WITH ls_edids-stapa4.

          ls_data-reason = lv_string.
          ls_data-ddate = ls_edids-credat.
          ls_data-dtime = ls_edids-cretim.

          CLEAR lv_string.
        ENDIF.
        lv_days = ls_data-ddate - ls_data-credat.
        IF lv_days NE 0.
          ls_data-flag = 'X'.
          ls_data-days = lv_days.
        ENDIF.
        APPEND ls_data TO lt_data.
        CLEAR: ls_data,ls_cust,ls_amount.

      ENDLOOP.

      DATA(lt_loop) = lt_data.
      DATA(lt_total) = lt_data.
      DATA(lt_ndelay) = lt_data.
      DELETE lt_ndelay WHERE flag EQ 'X'.
      DATA(lt_delay) = lt_data.
      DELETE lt_delay WHERE flag NE 'X'.

      SORT : lt_loop BY  cust year mon mestyp.
      SORT : lt_total BY docnum.

      DELETE ADJACENT DUPLICATES FROM lt_loop COMPARING  year mon cust mestyp.

      LOOP AT lt_loop INTO DATA(ls_loop).

        ls_out-idoc_year = ls_loop-year.
        ls_out-idoc_month = ls_loop-mon.
        ls_out-customer = ls_loop-cust.
        ls_out-mestyp  = ls_loop-mestyp.

        LOOP AT lt_total INTO DATA(ls_total) WHERE cust = ls_loop-cust
                                               AND year = ls_loop-year
                                               AND mon = ls_loop-mon
                                               AND mestyp = ls_loop-mestyp.

          lv_total = lv_total + ls_total-netwr.
          ls_out-reason = ls_total-reason.

          AT END OF cust.
            ls_out-total_value = lv_total.
          ENDAT.

        ENDLOOP.

        LOOP AT lt_ndelay INTO DATA(ls_ndelay) WHERE cust = ls_loop-cust
                                                 AND year = ls_loop-year
                                                 AND mon = ls_loop-mon
                                                 AND mestyp = ls_loop-mestyp .

          lv_ndelay = ls_ndelay-netwr + lv_ndelay.
          AT END OF cust.
            ls_out-value = lv_ndelay.
          ENDAT.

        ENDLOOP.

        LOOP AT lt_delay INTO DATA(ls_delay) WHERE cust = ls_loop-cust
                                               AND year = ls_loop-year
                                               AND mon = ls_loop-mon
                                               AND mestyp = ls_loop-mestyp.

          lv_delay = ls_delay-netwr + lv_delay.
          lv_days = ls_delay-days + lv_days.
          lv_count = lv_count + 1.
          AT END OF cust.
            ls_out-delay_value = lv_delay.
            ls_out-days_delay = lv_days / lv_count.
          ENDAT.

        ENDLOOP.

        ls_out-percentage = ls_out-delay_value / ls_out-value.
        APPEND ls_out TO lt_out.

        CLEAR : ls_out,lv_total,lv_ndelay,lv_delay,lv_days,lv_count.

      ENDLOOP.

       IF lv_sort_string IS NOT INITIAL.
          SORT lt_out BY (lv_sort_string).
        ENDIF.

******************************************
      io_response->set_data( lt_out  ).

      ""Set Total Number of records in lt_data container
      IF io_request->is_total_numb_of_rec_requested( ).
        io_response->set_total_number_of_records( lines( lt_out ) ).
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD if_rap_query_aggregation~get_aggregated_elements.

    DATA lt_aggregated_elements TYPE if_rap_query_aggregation=>tt_aggregation_elements.

    DATA(it_aggregated_elements) = VALUE if_rap_query_aggregation=>tt_aggregation_elements(
          ( input_element = 'TOTAL_VALUE' aggregation_method = if_rap_query_aggregation=>co_standard_aggregation_method-sum )
          ( input_element = 'DELAY_VALUE' aggregation_method = if_rap_query_aggregation=>co_standard_aggregation_method-sum )
        ).

    rt_aggregated_elements = it_aggregated_elements.

  ENDMETHOD.

  METHOD if_rap_query_aggregation~get_grouped_elements.

    DATA lt_grouped_elements TYPE if_rap_query_aggregation=>tt_grouped_elements.

    APPEND 'IDOC_YEAR' TO rt_grouped_elements.
    APPEND 'IDOC_MONTH' TO rt_grouped_elements.
    APPEND 'CUSTOMER' TO rt_grouped_elements.
    APPEND 'MESTYP' TO rt_grouped_elements.
    APPEND 'PERCENTAGE' TO rt_grouped_elements.
    APPEND 'DAYS_DELAY' TO rt_grouped_elements.
    APPEND 'REASON' TO rt_grouped_elements.

  ENDMETHOD.

ENDCLASS.
