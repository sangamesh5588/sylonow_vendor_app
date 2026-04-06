# ORDER_VALUE_CALCULATION.md

Serive Discounted Price = this should come from service_listings table not from orders table

AddOns Discounted Price = this should come from service_add_ons table

Total Order Value = Service Discounted Price + AddOns Discounted Price (if any)

Revenue = Total Order Value _ 60% - (Total Order Value _ 5% + Total Order Value \* 5% of 18% GST)

Amount to be collect from user = Total Order Value - Revenue
