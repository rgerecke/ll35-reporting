"### Vendor Involvement

__Vendor Name__: {`Vendor Name [If none, N/A]`}

{`Vendor Involvement`}

{
  ifelse(
    `Update Description`=='',
    '',
    str_glue_data(data, '
    ### Update Description

    {`Update Description`}

    '
    ))
}
"
