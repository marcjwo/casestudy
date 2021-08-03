view: order_items {
  sql_table_name: public.order_items ;;
  drill_fields: [detail*]


### DIMENSIONS FROM THE TABLE DIRECTLY------------------------------------------------------------------------------------

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension_group: created {
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
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: delivered {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.delivered_at ;;
  }

  dimension: inventory_item_id {
    type: number
    # hidden: yes
    sql: ${TABLE}.inventory_item_id ;;
  }

  dimension: order_id {
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension_group: returned {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.returned_at ;;
  }

  dimension: sale_price {
    type: number
    sql: ${TABLE}.sale_price ;;
  }

  dimension_group: shipped {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.shipped_at ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension: user_id {
    type: number
    # hidden: yes
    sql: ${TABLE}.user_id ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }


### ADDITIONS TO VIEW  --------------------------------------------------------------------------------------------

  measure: count_distinct_orders {
    type: count_distinct
    sql: ${order_id} ;;
  }

  measure: total_sale_price{
    type: sum
    description: "Total sales from items sold"
    sql: ${sale_price} ;;
    value_format_name: usd
  }

  measure: average_sale_price{
    type: average
    description: "Average sale price from items sold"
    sql: ${sale_price} ;;
    value_format_name: usd
  }

  measure: cumulative_total_sales {
    type: running_total
    description: "Cumulative total sales from items sold"
    sql: ${sale_price} ;;
    value_format_name: usd
  }

  measure: total_gross_revenue {
    type: sum
    description: "Total revenue from completed sales (cancelled and returned orders excluded)"
    filters: [status: "-Cancelled,-Returned"]
    sql: ${sale_price} ;;
    value_format_name: usd
  }


  measure: total_cost {
    type: sum
    description: "COGS"
    sql: ${inventory_items.cost} ;;
    value_format_name: usd
  }


  measure: average_cost {
    type: average
    description: "Average COGS"
    sql: ${inventory_items.cost} ;;
    value_format_name: usd
  }

  measure: total_gross_margin {
    type: number
    description: "Total difference between total revenue from completed sales and COGS"
    sql: ${total_gross_revenue}-${total_cost} ;;
    value_format_name: usd
    drill_fields: [inventory_items.product_category, inventory_items.product_brand]
    html: {{ rendered_value }} margin of {{ total_gross_revenue._rendered_value }} total product revenue!;;
  }


  ## as averaging a previously defined measure does not work, this workaround -- is there a nicer way??
  measure: average_gross_margin {
    type: number
    description: "Average difference between total revenue from completed sales and COGS"
    sql: (${total_gross_revenue}-${total_cost})/${count} ;;
    value_format_name: usd
  }


  measure: gross_margin_in_percent {
    type: number
    description: "Gross margin %"
    label: "Gross margin in %"
    sql: 1.00*nullif(${total_gross_margin},0)/nullif(${total_gross_revenue},0) ;;
    value_format_name: percent_2
  }

  measure: items_returned_count_statusbased {
    type: count
    description: "Number of items returned"
###    sql: ${id} ;;
    filters: [status: "Returned"]
  }

  measure: items_returned_count_datebased {
    type: count
    description: "Number of items returned"
###    sql: ${id};;
    filters: [returned_date: "-NULL"]
  }

  measure: item_return_rate {
    type: number
    description: "Item Return Rate in %"
    sql: 1.000*${items_returned_count_statusbased}/nullif(${count},0) ;;
    value_format_name: percent_3
  }

  measure: number_of_customers_that_returned_an_item_once {
    type: count_distinct
    description: "Amount of unique customers returning an item"
    sql: ${user_id} ;;
    filters: [returned_date: "-NULL"]
  }

  measure: distinct_customer_count {
    type: count_distinct
    description: "Total customer count"
    sql: ${user_id} ;;
  }

  measure: percentage_of_customers_with_returns {
    type: number
    description: "Unique customers returning an item in %"
    sql: ${number_of_customers_that_returned_an_item_once}/${distinct_customer_count} ;;
    value_format_name: percent_4
  }

  measure: average_spend_per_customer {
    type: number
    description: "Average spend per customer"
    sql: ${total_gross_revenue}/${distinct_customer_count} ;;
    value_format_name: usd
  }



  # ----- Sets of fields for drilling ------------------------------------------------------------------------------------
  set: detail {
    fields: [
      id,
      users.id,
      users.first_name,
      users.last_name,
      inventory_items.id,
      inventory_items.product_name
    ]
  }
}
