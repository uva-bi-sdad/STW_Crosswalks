create materialized view if not exists stw_pathways.crosswalk_info as (
    with a as (
        select soc,
            soc_title,
            count(*) > 1 detailed
        from onet_25_1.onet19_soc18
        group by soc,
            soc_title
    ),
    b as (
        select b.*,
            detailed
        from a
            join onet_25_1.onet19_soc18 b on a.soc = b.soc
    ),
    c as (
        select element_id,
            element_name
        from onet_25_1.content_model_reference
        where element_name = ANY(
                '{"Biology",
                  "Building and Construction",
                  "Chemistry",
                  "Computers and Electronics",
                  "Design",
                  "Economics and Accounting",
                  "Engineering and Technology",
                  "Food Production",
                  "Mathematics",
                  "Mechanical",
                  "Medicine and Dentistry",
                  "Physics",
                  "Production and Processing",
                  "Telecommunications"
                 }'::text []
            )
    ),
    d as (
        select *
        from c a
            join onet_25_1.knowledge b on a.element_id = b.element_id
            and scale_id = 'LV'
            and data_value >= 4.5
    ),
    e as (
        select distinct soc,
            detailed,
            onet,
            onet_title,
            onetsoc_code is not null technical
        from b a
            left join d b on onet = onetsoc_code
        order by onet
    ),
    f as (
        select e.*,
            entry_ed = ANY(
                '{"No formal educational credential",
 						    "High school diploma or equivalent",
 						    "Postsecondary nondegree award",
 						    "Some college, no degree",
 						    "Associate''s degree"
 					       }'::text []
            ) ed_bls
        from stw_pathways.bls_ep_ed a
            right join e ON soc18 = soc
    ),
    g AS (
        select onetsoc_code,
            least(sum(data_value), 100) >= 50 ed_onet
        from onet_25_1.education_training_experience
        where scale_id = 'RL'
            and category < 6
        group by onetsoc_code
    ),
    h as (
        select a.*,
            ed_onet
        from f a
            left join g b on onet = onetsoc_code
        order by onet
    )
    select *
    from h
);
