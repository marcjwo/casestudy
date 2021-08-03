view: customer_behavior {
  derived_table: {
    persist_for: "24 hours"
    distribution_style: even
    sortkeys: ["user_id"]
    sql: SELECT
            o.user_id as user_id,
            u.created_at as signup_date,
            MIN(o.created_at) as first_order_date,
            MAX(o.created_at) as last_order_date,
            COUNT(DISTINCT o.order_id) as lifetime_orders,
            SUM(o.sale_price) as lifetime_revenue
          FROM order_items o
          JOIN users u
          ON o.user_id = u.id
          GROUP BY 1,2
       ;;
  }

### DIMENSIONS FROM THE TABLE DIRECTLY------------------------------------------------------------------------------------


  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: user_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.user_id ;;
  }

  dimension_group: first_order_date {
    type: time
    sql: ${TABLE}.first_order_date ;;
  }

  dimension_group: signup_at {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      month_name,
      quarter,
      year
    ]
    sql: ${TABLE}.signup_date ;;
  }

  dimension_group: drillfake_signup_at {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      month_name,
      quarter,
      year
    ]
    sql: ${TABLE}.signup_date ;;
  }

  ### https://profservices.dev.looker.com/looks/832

  dimension_group: last_order_date {
    type: time
    sql: ${TABLE}.last_order_date ;;
  }

  dimension: lifetime_orders {
    type: number
    sql: ${TABLE}.lifetime_orders ;;
  }

  dimension: lifetime_revenue {
    type: number
    sql: ${TABLE}.lifetime_revenue ;;
  }

### ADDITIONAL DIMENSIONS AND MEASURES FROM THE TABLE DIRECTLY------------------------------------------------------------------------------------


  dimension: lifetime_revenue_bucket {
    type: tier
    tiers: [5,20,50,100,500,1000]
    style: integer
    sql: ${lifetime_revenue} ;;
    value_format: "$#.00;($#.00)"
  }

  dimension: lifetime_order_bucket {
    type: tier
    tiers: [1,2,3,6,10]
    style: integer
    sql: ${lifetime_orders} ;;
  }

  # DOES NOT WORK AS RELIABLE AS COUNTING THE LIFETIMEORDERS
  # dimension: recurring_customer {
  #   type: yesno
  #   sql: ${first_order_date_date} <> ${last_order_date_date} ;;
  # }

  dimension: recurring_customer {
    type: yesno
    sql: ${lifetime_orders} > 1 ;;
  }

  dimension: days_since_last_order {
    type: duration_day
    sql_start: ${last_order_date_date} ;;
    sql_end: current_date ;;
  }

  dimension_group:  lifetime {
    type: duration
    intervals: [day,month,year]
    sql_start: ${first_order_date_raw} ;;
    sql_end:  ${last_order_date_raw};;
  }


  dimension: days_since_signup {
    type: duration_day
    sql_start: ${signup_at_date} ;;
    sql_end: current_date ;;
  }

  dimension: months_since_signup {
    type: duration_month
    sql_start: ${signup_at_date} ;;
    sql_end: current_date ;;
  }

  dimension: active_user {
    type: yesno
    sql: ${days_since_last_order} < 90  ;;
  }

  measure: average_lifetime_revenue {
    type: average
    sql: ${lifetime_revenue} ;;
    value_format: "$#.00;($#.00)"
  }

  measure: repurchasers {
    type: count_distinct
    sql: ${user_id} ;;
    filters: [recurring_customer: "yes"]
  }

  measure: repurchase_ratio {
    type: number
    sql: 1.00 * (${repurchasers}/${count}) ;;
    value_format_name: percent_2
  }

  # ----- Sets of fields for drilling ------
  set: detail {
    fields: [
      users.traffic_source,
      inventory_items.product_name,
      inventory_items.product_brand,
    ]
  }
}
