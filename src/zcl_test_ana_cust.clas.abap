CLASS zcl_test_ana_cust DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES : BEGIN OF ty_data,
              cust   TYPE ZITR_ANALYTIC_DE_CUSTOMER,
              year   TYPE zitr_analytic_de_year,
              mon    TYPE zitr_analytic_de_month,
              netwr  TYPE netwr,
              credat TYPE sy-datum,
              cretim TYPE sy-uzeit,
              ddate  TYPE sy-datum,
              dtime  TYPE  sy-uzeit,
              status TYPE edi_status,
              days   TYPE i,
              flag   TYPE char1,
            END OF ty_data.

    TYPES : BEGIN OF ty_o_data,
              year   TYPE char4,
              mon    TYPE char2,
              netwr  TYPE netwr,
              credat TYPE sy-datum,
              cretim TYPE sy-uzeit,
              ddate  TYPE sy-datum,
              dtime  TYPE  sy-uzeit,
              status TYPE edi_status,
              days   TYPE i,
              flag   TYPE char1,
              cust   TYPE kunnr,
            END OF ty_o_data.


    DATA: ls_out      TYPE zanalytic_cust,
          lt_out      TYPE STANDARD TABLE OF zanalytic_cust,
          ls_out1     TYPE zanalytic_order,
          lt_out1     TYPE STANDARD TABLE OF zanalytic_order,
          ls_filter   TYPE /iwbep/s_mgw_select_option,
          ls_options  TYPE /iwbep/s_cod_select_option,
          lv_year     TYPE zitr_analytic_de_year,
          lv_year2    TYPE zitr_analytic_de_year,
          lv_month    TYPE zitr_analytic_de_month,
          lt_amount   TYPE TABLE OF e1edp01,
          lt_cust     TYPE TABLE OF e1edka1,
          ls_amount   TYPE e1edp01,
          ls_cust     TYPE e1edka1,
          lt_data     TYPE TABLE OF ty_data,
          ls_data     TYPE ty_data,
          ls_data1    TYPE ty_o_data,
          lt_data1    TYPE TABLE OF ty_o_data,
          lv_amount   TYPE netwr,
          lv_total    TYPE netwr,
          lv_ndelay   TYPE netwr,
          lv_delay    TYPE netwr,
          lt_edid4    TYPE TABLE OF edid4,
          ls_edid4    TYPE  edid4,
          lv_count    TYPE i,
          lv_cust     TYPE kunnr,
          lv_customer TYPE kunnr,
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
    INTERFACES if_rap_query_aggregation. " Interface for Aggregation

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_test_ana_cust IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    CASE io_request->get_entity_id( ).

      WHEN 'ZANALYTIC_CUST'.
        IF io_request->is_data_requested(  ).

          DATA(lv_offset) = io_request->get_paging( )->get_offset( ).
          DATA(lv_page_size) = io_request->get_paging( )->get_page_size( ).
          DATA(lv_max_rows) = COND #( WHEN lv_page_size = if_rap_query_paging=>page_size_unlimited THEN 0
                                      ELSE lv_page_size ).

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
            lv_month3 = sy-datum+4(2).
            lv_day3    = sy-datum+6(2).

            CONCATENATE lv_year3 lv_month3 lv_day3 INTO lv_from.
            CONDENSE lv_from.
          ENDIF.

          SELECT * FROM edidc INTO TABLE lt_edidc
       WHERE credat  BETWEEN lv_from AND lv_to
             AND  mestyp EQ 'ORDERS' AND  status IN ('51','53','64').

          IF lt_edidc IS NOT INITIAL.
            SELECT * FROM edid4 INTO CORRESPONDING FIELDS OF TABLE  lt_edid4
                    FOR ALL ENTRIES IN lt_edidc WHERE docnum EQ lt_edidc-docnum
                                   AND segnam  IN ('E1EDP01' , 'E1EDKA1') .
            SELECT * FROM edids INTO TABLE lt_edids
                     FOR ALL ENTRIES IN lt_edidc WHERE docnum EQ lt_edidc-docnum AND status IN ('51','53','64').
          ENDIF.
          SORT : lt_edid4 BY docnum segnam,
                 lt_edids BY docnum DESCENDING.
          LOOP AT lt_edidc INTO ls_edidc.
            LOOP AT lt_edid4 INTO ls_edid4 WHERE docnum = ls_edidc-docnum
                                                 AND      segnam = 'E1EDP01'.

              IF sy-subrc EQ 0.
                ls_amount = ls_edid4-sdata.
                ls_data-year = ls_edidc-credat+0(4).
                ls_data-mon = ls_edidc-credat+4(2).
                ls_data-netwr = ls_amount-netwr + ls_data-netwr.
                ls_data-credat = ls_edidc-credat.
                ls_data-cretim = ls_edidc-cretim.
                ls_data-status = ls_edidc-status.
              ENDIF.
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
              ls_data-ddate = ls_edids-credat.
              ls_data-dtime = ls_edids-cretim.
            ENDIF.
            DATA(lv_days) = ls_data-ddate - ls_data-credat.
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
          SORT : lt_loop BY cust.
          DELETE ADJACENT DUPLICATES FROM lt_loop COMPARING cust.

          LOOP AT lt_loop INTO DATA(ls_loop).
            ls_out-idoc_year = ls_loop-year.
            ls_out-idoc_month = ls_loop-mon.
            ls_out-customer = ls_loop-cust.

            LOOP AT lt_total INTO DATA(ls_total) WHERE year = ls_loop-year AND mon = ls_loop-mon.
              lv_total = lv_total + ls_total-netwr.
              AT END OF cust.
                ls_out-total_value = lv_total.
              ENDAT.
            ENDLOOP.

            LOOP AT lt_ndelay INTO DATA(ls_ndelay) WHERE year = ls_loop-year AND mon = ls_loop-mon.
              lv_ndelay = ls_ndelay-netwr + lv_ndelay.
              AT END OF cust.
                ls_out-value = lv_ndelay.
              ENDAT.
            ENDLOOP.

            LOOP AT lt_delay INTO DATA(ls_delay) WHERE year = ls_loop-year AND mon = ls_loop-mon.
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

          io_response->set_data( lt_out  ).

          ""Set Total Number of records in lt_data container
          IF io_request->is_total_numb_of_rec_requested( ).
            io_response->set_total_number_of_records( lines( lt_out ) ).
          ENDIF.

        ENDIF.

      WHEN 'ZANALYTIC_ORDER'.

        IF io_request->is_data_requested(  ).

          DATA(lv_offset1) = io_request->get_paging( )->get_offset( ).
          DATA(lv_page_size1) = io_request->get_paging( )->get_page_size( ).
          DATA(lv_max_rows1) = COND #( WHEN lv_page_size1 = if_rap_query_paging=>page_size_unlimited THEN 0
                                      ELSE lv_page_size ).

********************************************************************** Filter
          TRY.
              DATA(lt_ranges2) = io_request->get_filter( )->get_as_ranges( ).
              ""filter manipulation

              " Look for IDOC_NUMBER filter
              DATA(lt_idoc_YEAR2) = COND #( WHEN line_exists( lt_ranges2[ name = 'IDOC_YEAR' ] )
                                          THEN lt_ranges2[ name = 'IDOC_YEAR' ]-range
                                ).

              " Look for CREATION_DATE filter
              DATA(lt_idoc_month2) = COND #( WHEN line_exists( lt_ranges2[ name = 'IDOC_MONTH' ] )
                                          THEN lt_ranges2[ name = 'IDOC_MONTH' ]-range
                                ).

              " Look for MESSAGE_TYPE field filter
              DATA(lt_CUSTOMER2) = COND #( WHEN line_exists( lt_ranges2[ name = 'CUSTOMER' ] )
                                            THEN lt_ranges2[ name = 'CUSTOMER' ]-range
                                  ).
          ENDTRY.


          LOOP AT lt_idoc_year2 INTO DATA(wa_idoc_year2).

            lv_year = wa_idoc_year2-low.

          ENDLOOP.

          LOOP AT lt_idoc_month2 INTO DATA(wa_idoc_month2).

            lv_month = wa_idoc_month2-low.

          ENDLOOP.

          IF lv_year IS NOT INITIAL AND lv_month IS NOT INITIAL.

            lv_year2   = lv_year - 1.

            CONCATENATE lv_year2 lv_month '00' INTO lv_from.
            CONDENSE lv_from.

            CONCATENATE lv_year lv_month '00' INTO lv_to.
            CONDENSE lv_to.

          ELSE.

            lv_to = sy-datum.

            lv_year3 = sy-datum+0(4) - 1.
            lv_month3 = sy-datum+4(2).
            lv_day3    = sy-datum+6(2).

            CONCATENATE lv_year3 lv_month3 lv_day3 INTO lv_from.
            CONDENSE lv_from.

          ENDIF.

          SELECT * FROM edidc INTO TABLE lt_edidc
                         WHERE credat  BETWEEN lv_from AND lv_to
                               AND  mestyp EQ 'LOIPRO' AND  status IN ('51','53','64').

          IF lt_edidc IS NOT INITIAL.
            SELECT * FROM edid4 INTO CORRESPONDING FIELDS OF TABLE  lt_edid4
                    FOR ALL ENTRIES IN lt_edidc WHERE docnum EQ lt_edidc-docnum
                                   AND segnam  IN ('E1EDP01' , 'E1EDKA1') .
            SELECT * FROM edids INTO TABLE lt_edids
                     FOR ALL ENTRIES IN lt_edidc WHERE docnum EQ lt_edidc-docnum AND status IN ('51','53','64').
          ENDIF.

          SORT : lt_edid4 BY docnum segnam,
                 lt_edids BY docnum DESCENDING.
          LOOP AT lt_edidc INTO ls_edidc.
            LOOP AT lt_edid4 INTO ls_edid4 WHERE docnum = ls_edidc-docnum
                                             AND segnam = 'E1EDP01'.

              IF sy-subrc EQ 0.
                ls_amount = ls_edid4-sdata.
                ls_data1-year = ls_edidc-credat+0(4).
                ls_data1-mon = ls_edidc-credat+4(2).
                ls_data1-netwr = ls_amount-netwr + ls_data1-netwr.
                ls_data1-credat = ls_edidc-credat.
                ls_data1-cretim = ls_edidc-cretim.
                ls_data1-cretim = ls_edidc-status.
              ENDIF.

            ENDLOOP.

            LOOP AT lt_edid4 INTO ls_edid4 WHERE docnum = ls_edidc-docnum AND
                                          segnam EQ 'E1EDKA1'.
              IF sy-subrc EQ 0.
                ls_cust = ls_edid4-sdata.
                IF ls_cust-parvw = 'AG'.
                  ls_data1-cust = ls_cust-partn.
                ENDIF.
              ENDIF.
            ENDLOOP.
            READ TABLE lt_edids INTO ls_edids WITH KEY docnum = ls_edidc-docnum.
            IF sy-subrc EQ 0.
              ls_data1-ddate = ls_edids-credat.
              ls_data1-dtime = ls_edids-cretim.
            ENDIF.
            DATA(lv_days1) = ls_data1-ddate - ls_data1-credat.
            IF lv_days1 NE 0.
              ls_data1-flag = 'X'.
              ls_data1-days = lv_days1.
            ENDIF.
            APPEND ls_data1 TO lt_data1.
            CLEAR: ls_data1,ls_cust,ls_amount.
          ENDLOOP.

          DATA(lt_loop1) = lt_data.
          DATA(lt_total1) = lt_data.
          DATA(lt_ndelay1) = lt_data.
          DELETE lt_ndelay1 WHERE flag EQ 'X'.
          DATA(lt_delay1) = lt_data.
          DELETE lt_delay1 WHERE flag NE 'X'.
          SORT : lt_loop1 BY cust.
          DELETE ADJACENT DUPLICATES FROM lt_loop1 COMPARING cust.
          LOOP AT lt_loop1 INTO DATA(ls_loop1).
            ls_out1-idoc_year = ls_loop1-year.
            ls_out1-idoc_month = ls_loop1-mon.
            ls_out1-customer   = ls_loop1-cust.
            LOOP AT lt_total1 INTO DATA(ls_total1) WHERE year = ls_loop1-year AND mon = ls_loop1-mon.
              lv_total = lv_total + ls_total1-netwr.
              AT END OF cust.
                ls_out1-total_value = lv_total.
              ENDAT.
            ENDLOOP.
            LOOP AT lt_ndelay1 INTO DATA(ls_ndelay1) WHERE year = ls_loop1-year AND mon = ls_loop1-mon.
              lv_ndelay = ls_ndelay1-netwr + lv_ndelay.
              AT END OF cust.
                ls_out1-value = lv_ndelay.
              ENDAT.
            ENDLOOP.
            LOOP AT lt_delay1 INTO DATA(ls_delay1) WHERE year = ls_loop1-year AND mon = ls_loop1-mon.
              lv_delay = ls_delay1-netwr + lv_delay.
              lv_days1 = ls_delay1-days + lv_days1.
              lv_count = lv_count + 1.
              AT END OF cust.
                ls_out1-delay_value = lv_delay.
                ls_out1-days_delay = lv_days1 / lv_count.
              ENDAT.
            ENDLOOP.
            ls_out-percentage = ls_out1-delay_value / ls_out1-value.
            APPEND ls_out1 TO lt_out1.

            CLEAR : ls_out1,lv_total,lv_ndelay,lv_delay,lv_days1,lv_count.
          ENDLOOP.



          io_response->set_data( lt_out1  ).


          ""Set Total Number of records in lt_data container
          IF io_request->is_total_numb_of_rec_requested( ).
            io_response->set_total_number_of_records( lines( lt_out1 ) ).
          ENDIF.

        ENDIF.

    ENDCASE.
  ENDMETHOD.


ENDCLASS.
