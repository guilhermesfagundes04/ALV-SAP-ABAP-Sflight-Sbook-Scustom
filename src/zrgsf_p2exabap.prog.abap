* Parte 2 - Exercícios ABAP
" Leitura de tabelas (selects), loops, read tables e ALV

REPORT zrgsf_p2exabap.

TABLES: sflight, sbook, scustom.

TYPES: BEGIN OF ty_parte2,
         carrid     TYPE sflight-carrid,
         connid     TYPE sflight-connid,
         fldate     TYPE sflight-fldate,
         price      TYPE sflight-price,
         planetype  TYPE sflight-planetype,
         customid   TYPE sbook-customid,
         name       TYPE scustom-name,
         country    TYPE scustom-country,
         luggweight TYPE sbook-luggweight,
       END OF ty_parte2,

       BEGIN OF ty_sflight,
         carrid    TYPE sflight-carrid,
         connid    TYPE sflight-connid,
         fldate    TYPE sflight-fldate,
         price     TYPE sflight-price,
         planetype TYPE sflight-planetype,
       END OF ty_sflight,

       BEGIN OF ty_sbook,
         carrid     TYPE sbook-carrid,
         connid     TYPE sbook-connid,
         fldate     TYPE sbook-fldate,
         bookid     TYPE sbook-bookid,
         luggweight TYPE sbook-luggweight,
         customid   TYPE sbook-customid,
       END OF ty_sbook,

       BEGIN OF ty_scustom,
         id      TYPE scustom-id,
         name    TYPE scustom-name,
         country TYPE scustom-country,
       END OF ty_scustom.

DATA: gt_parte2  TYPE TABLE OF ty_parte2,
      gt_sflight TYPE TABLE OF ty_sflight,
      gt_sbook   TYPE TABLE OF ty_sbook,
      gt_scustom TYPE TABLE OF ty_scustom.

SELECTION-SCREEN BEGIN OF BLOCK bc01 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS: s_carrid FOR sbook-carrid,
                  s_connid FOR sbook-connid,
                  s_fldate FOR sbook-fldate.

SELECTION-SCREEN END OF BLOCK bc01.

START-OF-SELECTION.

  PERFORM zf_busca.

END-OF-SELECTION.

  PERFORM zf_tratamento.
  PERFORM zf_exibe.

FORM zf_busca.

  SELECT carrid, connid, fldate, bookid, luggweight, customid
    FROM sbook
    INTO CORRESPONDING FIELDS OF TABLE @gt_sbook
    WHERE carrid IN @s_carrid
      AND connid IN @s_connid
      AND fldate IN @s_fldate.

  IF sy-subrc IS INITIAL.

    SELECT carrid, connid, fldate, price, planetype
      FROM sflight
      INTO CORRESPONDING FIELDS OF TABLE @gt_sflight
      FOR ALL ENTRIES IN @gt_sbook
      WHERE carrid EQ @gt_sbook-carrid
        AND connid EQ @gt_sbook-connid
        AND fldate EQ @gt_sbook-fldate.

    SELECT id, name, country
      FROM scustom
      INTO CORRESPONDING FIELDS OF TABLE @gt_scustom
      FOR ALL ENTRIES IN @gt_sbook
      WHERE id EQ @gt_sbook-customid.

  ENDIF.

  PERFORM zf_ordenacao.

ENDFORM.

FORM zf_ordenacao.

  SORT: gt_sbook BY carrid ASCENDING connid ASCENDING fldate,
        gt_sflight BY carrid ASCENDING connid ASCENDING fldate ASCENDING,
        gt_scustom BY id ASCENDING.

ENDFORM.

FORM zf_tratamento.

  CLEAR gt_parte2.

  FIELD-SYMBOLS: <fs_parte2>  TYPE ty_parte2,
                 <fs_sbook>   TYPE ty_sbook,
                 <fs_sflight> TYPE ty_sflight,
                 <fs_scustom> TYPE ty_scustom.

  LOOP AT gt_sbook ASSIGNING <fs_sbook>.

    APPEND INITIAL LINE TO gt_parte2 ASSIGNING <fs_parte2>.

    <fs_parte2>-carrid     = <fs_sbook>-carrid.
    <fs_parte2>-connid     = <fs_sbook>-connid.
    <fs_parte2>-fldate     = <fs_sbook>-fldate.
    <fs_parte2>-customid   = <fs_sbook>-customid.
    <fs_parte2>-luggweight = <fs_sbook>-luggweight.

    READ TABLE gt_sflight ASSIGNING <fs_sflight> WITH KEY carrid = <fs_sbook>-carrid connid = <fs_sbook>-connid BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      <fs_parte2>-price     = <fs_sflight>-price.
      <fs_parte2>-planetype = <fs_sflight>-planetype.
    ENDIF.

    READ TABLE gt_scustom ASSIGNING <fs_scustom> WITH KEY id = <fs_sbook>-customid BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      <fs_parte2>-name    = <fs_scustom>-name.
      <fs_parte2>-country = <fs_scustom>-country.
    ENDIF.

  ENDLOOP.

ENDFORM.

FORM zf_exibe.
  DATA: lr_table     TYPE REF TO cl_salv_table,
        lr_functions TYPE REF TO cl_salv_functions,
        lr_columns   TYPE REF TO cl_salv_columns_table,
        lr_column    TYPE REF TO cl_salv_column.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lr_table
                              CHANGING  t_table      = gt_parte2 ). "Aqui vai ser a minha tabela interna global principal

      lr_functions = lr_table->get_functions( ).
      lr_functions->set_all( abap_true ).

      lr_columns = lr_table->get_columns( ).
      lr_columns->set_optimize( abap_true ).

      lr_table->display( ).
    CATCH cx_salv_msg.
    CATCH cx_salv_not_found.
  ENDTRY.
ENDFORM.
